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

$InformationPreference = "Continue" # Wymusza wyświetlanie wszystkich komunikatów informacyjnych

function Test-InternetConnection() {
  try {
    $null = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
    Write-Information "[INFO] Internet connection confirmed."
    return $true
  } catch {
    Write-Warning "[WARNING] No internet connection detected. Retrying in $CHECK_INTERVAL_SECONDS seconds..."
    return $false
  }
}

function Get-GeocodingData {
  param ([string]$city)

  try {
    Write-Information "[STATUS] Fetching coordinates for: $city"
    $response = Invoke-RestMethod -Uri "$GEOCODING_API/search?q=$city&format=json" -ErrorAction Stop

    if (-not $response) {
      throw "[ERROR] No geographic data found for '$city'."
    }

    $firstResult = $response | Select-Object -First 1
    Write-Information "[SUCCESS] Coordinates found: Lat=$($firstResult.lat), Lon=$($firstResult.lon)"
    return $firstResult
  } catch {
    Write-Error "[API ERROR] GeoData fetch failed: $_"
    return $null
  }
}

function Convert-UtcTimeToLocal {
  param (
    [string]$time
  )

  # Parse UTC time string (format like "7:23:45 AM") to DateTime
  $utcTime = [DateTime]::ParseExact(
    $time,
    "h:mm:ss tt",
    [System.Globalization.CultureInfo]::InvariantCulture
  )

  # Convert to local time zone
  return $utcTime.ToLocalTime()
}

function Get-SunsetSunriseData {
  param ([string]$lat, [string]$lon, [System.DateTime]$date)

  try {
    Write-Information "[STATUS] Fetching sunrise/sunset times for Lat=$lat, Lon=$lon"

    $formattedDate = Get-Date -Format "yyyy-MM-dd" $date
    $url = "$SUN_API/json?lat=$lat&lng=$lon&date=$formattedDate"
    $response = Invoke-RestMethod -Uri $url -ErrorAction Stop

    if ($response.status -ne "OK") {
      throw "[API ERROR] Status: $($response.status)"
    }

    # Convert UTC times to local time zone
    $localSunrise = Convert-UtcTimeToLocal -time $response.results.sunrise
    $localSunset = Convert-UtcTimeToLocal -time $response.results.sunset

    Write-Information "[SUCCESS] Sunrise (local): $localSunrise, Sunset (local): $localSunset"

    return @{
      sunrise = $localSunrise
      sunset = $localSunset
    }
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

      Write-Information "[THEME] Switching to LIGHT theme (daytime)"
      Set-ItemProperty -Path $path -Name $apps -Value 1
      Set-ItemProperty -Path $path -Name $system -Value 1
    } else {
      if (0 -eq $isLight) {
        return
      }

      Write-Information "[THEME] Switching to DARK theme (nighttime)"
      Set-ItemProperty -Path $path -Name $apps -Value 0
      Set-ItemProperty -Path $path -Name $system -Value 0
    }
  } catch {
    Write-Error "[THEME ERROR] Failed to apply theme: $_"
  }
}

# The date when the script was started
$start = Get-Date

# The longitude and latitude of the defined city
$longitude = $null
$latitude = $null

# The time of sunrise and sunset
$sunrise = $null
$sunset = $null

# --- Main Loop ---
Write-Information $start
Write-Information "=== Starting Theme Switcher ==="
Write-Information "City: $CITY | Check Interval: ${CHECK_INTERVAL_SECONDS}s"

while ($true) {
  $now = Get-Date
  $before = $sunrise -and $sunset

  if ($before -and $now.DayOfYear -eq $start.DayOfYear -and $now.Year -eq $start.Year) {
    Set-WindowsTheme -useLightTheme ($now -ge $sunrise -and $now -lt $sunset)
    Start-Sleep -Seconds $LOOP_DELAY_SECONDS
    continue
  }

  if (-not (Test-InternetConnection)) {
    Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
    continue
  }

  if (-not $longitude -or -not $latitude) {
    $result = Get-GeocodingData -city $CITY
    if (-not $result) {
      Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
      continue
    }

    $longitude = $result.lon
    $latitude = $result.lat
  }

  $result = Get-SunsetSunriseData -lat $latitude -lon $longitude -date $now
  if (-not $result) {
    Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
    continue
  }

  $sunrise = $result.sunrise
  $sunset = $result.sunset

  $start = $now
}