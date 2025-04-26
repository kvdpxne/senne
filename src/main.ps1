$workingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($workingDirectory -ne (Get-Location)) {
  Set-Location -Path $workingDirectory
}

. ./constants.ps1
. ./fetch-geocoding-location-data.ps1
. ./fetch-sun-times-data.ps1
. ./internet-connection-checker.ps1
. ./logging.ps1
. ./theme-changer.ps1

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

$OFFESET = $true

$SUNRISE_OFFSET = "0:30"
$SUNSET_OFFSET = "-1:00"

# The date when the script was started
$start = Get-Date -Format $GOOD_FORMAT

# The longitude and latitude of the defined city
$longitude = $null
$latitude = $null

# The time of sunrise and sunset
$sunrise = $null
$sunset = $null

Write-Log "The powershell script named 'senna' was run correctly."
Write-Log "The start time was set as: '$start' and the location was set to: '$CITY'."

while ($true) {
  $now = Get-Date
  $before = $sunrise -and $sunset

  if ($before -and $now.DayOfYear -eq $start.DayOfYear -and $now.Year -eq $start.Year) {
    Set-WindowsTheme -UseLightTheme ($now -ge $sunrise -and $now -lt $sunset)
    Start-Sleep -Seconds $LOOP_DELAY_SECONDS
    continue
  }

  if (-not (Test-InternetConnection -RetryCount 3)) {
    Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
    continue
  }

  if (-not $longitude -or -not $latitude) {
    $result = Get-Geocoding-Location-Data -Location $CITY
    if (-not $result) {
      Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
      continue
    }

    $longitude = $result.lon
    $latitude = $result.lat
  }

  $result = Get-SunsetSunriseData -Latitude $latitude -Longitude $longitude -Date $now
  if (-not $result) {
    Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
    continue
  }

  $sunrise = $result.sunrise
  $sunset = $result.sunset

  if ($OFFESET) {
    $sunrise += [TimeSpan]$SUNRISE_OFFSET
    $sunset += [TimeSpan]$SUNSET_OFFSET
  }

  $start = $now
}