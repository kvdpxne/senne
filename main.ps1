<#
.SYNOPSIS
Automatically switches Windows theme between light/dark based on sunrise/sunset times.
.DESCRIPTION
- Fetches geographic coordinates for a given city (OpenStreetMap API).
- Retrieves sunrise/sunset times (Sunrise-Sunset API).
- Toggles Windows 10/11 theme at the correct times.
- Runs in a loop with error handling and delays.
#>

# The name of the place or city location to be sent in the body of the request
# to the service that converts the address to latitude and longitude.
$CITY = "Lublin"

$CHECK_INTERVAL_SECONDS = 20  # Retry delay on API failure
$LOOP_DELAY_SECONDS = 60  # Normal delay between checks

$GEOCODING_API = "https://nominatim.openstreetmap.org"
$SUN_API = "https://api.sunrise-sunset.org"

function Test-InternetConnection() {
  try {
    $null = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
    Write-Output "[INFO] Internet connection confirmed."
    return $true
  } catch {
    Write-Warning "[WARNING] No internet connection detected. Retrying in $CHECK_INTERVAL_SECONDS seconds..."
    return $false
  }
}

function Get-GeocodingData {
  param ([string]$city)

  try {
    Write-Output "[STATUS] Fetching coordinates for: $city"
    $response = Invoke-RestMethod -Uri "$GEOCODING_API/search?q=$city&format=json" -ErrorAction Stop

    if (-not $response) {
      throw "[ERROR] No geographic data found for '$city'."
    }

    $firstResult = $response | Select-Object -First 1
    Write-Output "[SUCCESS] Coordinates found: Lat=$($firstResult.lat), Lon=$($firstResult.lon)"
    return $firstResult
  } catch {
    Write-Error "[API ERROR] GeoData fetch failed: $_"
    return $null
  }
}

function Get-SunsetSunriseData {
  param ([string]$lat, [string]$lon)

  try {
    Write-Output "[STATUS] Fetching sunrise/sunset times for Lat=$lat, Lon=$lon"
    $response = Invoke-RestMethod -Uri "$SUN_API/json?lat=$lat&lng=$lon&date=today" -ErrorAction Stop

    if ($response.status -ne "OK") {
      throw "[API ERROR] Status: $($response.status)"
    }

    Write-Output "[SUCCESS] Sunrise: $($response.results.sunrise), Sunset: $($response.results.sunset)"
    return $response.results
  } catch {
    Write-Error "[API ERROR] SunsetSunrise fetch failed: $_"
    return $null
  }
}


function Set-WindowsTheme {
  param ([bool]$useLightTheme)

  try {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"

    $apps = "AppsUseLightTheme"
    $system = "SystemUsesLightTheme"

    $isLight = (Get-ItemProperty -Path $path -Name $apps).AppsUseLightTheme
    $isLight = (Get-ItemProperty -Path $path -Name $system).SystemUsesLightTheme

    if ($useLightTheme) {
      if (1 -eq $isLight) {
        return
      }

      Write-Output "[THEME] Switching to LIGHT theme (daytime)"
      Set-ItemProperty -Path $path -Name $apps -Value 1
      Set-ItemProperty -Path $path -Name $system -Value 1
    } else {
      if (0 -eq $isLight) {
        return
      }

      Write-Output "[THEME] Switching to DARK theme (nighttime)"
      Set-ItemProperty -Path $path -Name $apps -Value 0
      Set-ItemProperty -Path $path -Name $system -Value 0
    }
  } catch {
    Write-Error "[THEME ERROR] Failed to apply theme: $_"
  }
}

$startTime = Get-Date
$first = $true

$sunriseTime = $null
$sunsetTime = $null

# --- Main Loop ---
Write-Output $startTime
Write-Output "=== Starting Theme Switcher ==="
Write-Output "City: $CITY | Check Interval: ${CHECK_INTERVAL_SECONDS}s"

while ($true) {
  $now = Get-Date

  try {
    if ($now -ge $sunsetTime -or $now -lt $sunriseTime) {
      Set-WindowsTheme -useLightTheme $false
    } else {
      Set-WindowsTheme -useLightTheme $true
    }
  } catch {
    Write-Error "[TIME ERROR] Failed to parse sunrise/sunset times: $_"
  }

  if ($first -or ($startTime.Year -lt $now.Year -or $startTime.DayOfYear -lt $now.DayOfYear)) {
    if (-not (Test-InternetConnection)) {
      Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
      continue
    }

    $geocodingData = Get-GeocodingData -city $CITY
    if (-not $geocodingData) {
      Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
      continue
    }

    $sunData = Get-SunsetSunriseData -lat $geocodingData.lat -lon $geocodingData.lon
    if (-not $sunData) {
      Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
      continue
    }

    $sunriseTime = [DateTime]::Parse($sunData.sunrise)
    $sunsetTime = [DateTime]::Parse($sunData.sunset)

    $first = $false
  }

  Start-Sleep -Seconds $LOOP_DELAY_SECONDS
}