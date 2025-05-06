$workingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($workingDirectory -ne (Get-Location)) {
  Set-Location -Path $workingDirectory
}

. ./constants.ps1
. ./fetch-geocoding-location-data.ps1
. ./fetch-sun-times-data.ps1
. ./get-current-weather.ps1
. ./internet-connection-checker.ps1
. ./logging.ps1
. ./theme-changer.ps1

$CHECK_INTERVAL_SECONDS = 20  # Retry delay on API failure
$LOOP_DELAY_SECONDS = 60  # Normal delay between checks
$DELAY_BWR = 16 * 60

$OFFESET = $true

$SUNRISE_OFFSET = "0:30"
$SUNSET_OFFSET = "-1:00"

# Nazwa miejsca lub miejscowości pobierana z pliku, która zostanie
# przekonwertowana na długość i szerokość geograficzną
$location = Get-Content "./location.txt" -Encoding "UTF8"

# Czas uruchomienia skryptu, później czas ostatniej aktualizacji czasu wschodu
# i zachodu słońca (czas iteracji)
$when = Get-Date -Format $GOOD_FORMAT

# Czas ostatniej odpowiedzi na żądanie o uzyskanie aktualnej pogody
$last = $null

# Długość i szerokość geograficzna
$longitude = $null
$latitude = $null

# Czas wschodu i zachodu słońca
$sunrise = $null
$sunset = $null

# Poziom zachmurzenia w procentach
$cloudy = 0

Write-Log "The powershell script named 'senna' was run correctly."
Write-Log "The start time was set as: '$when' and the location was set to: '$location'."

while ($true) {
  # Czas aktualnie wykonywanej iteracji
  $now = Get-Date

  # Sprawdza, czy czas wschodu i zachodu słońca jest zdefiniowany
  if ($sunrise -and $sunset) {
    # Określa, czy aktualnie jest dzień (z uwzględniemiem przesunięcia)
    $day = $now -ge $sunrise -and $now -lt $sunset

    # Sprawdza, czy aktualnie jest dzień (z uwzględniemiem przesunięcia) oraz
    # czy jest to pierwsze żadanie lub czy mineło wystarczająco wiele czasu od
    # ostatniego żadania
    if ($day -and (-not $last -or $DELAY_BWR -le ($now - $last).TotalSeconds)) {
      if (-not (Test-InternetConnection -RetryCount 3 -Quiet)) {
        Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
        continue
      }

      $result = Get-CurrentWeather -Latitude $latitude -Longitude $longitude
      if (-not $result) {
        Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
        continue
      }

      $cloudy = $result.Code
      $last = $now
    }

    # Sprawdza, czy czas wschodu i zachodu słońca został uaktualniony w innym
    # dniu niż obecny dzień otrzymany z czasu iteracji
    if ($now.DayOfYear -eq $when.DayOfYear) {
      Set-WindowsTheme -UseLightTheme ($day -and 75 -gt $cloudy)
      Start-Sleep -Seconds $LOOP_DELAY_SECONDS
      continue
    }
  }

  if (-not (Test-InternetConnection -RetryCount 3)) {
    Start-Sleep -Seconds $CHECK_INTERVAL_SECONDS
    continue
  }

  if (-not $longitude -or -not $latitude) {
    $result = Get-Geocoding-Location-Data -Location $location
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

  # Ustawia czas ostatniej aktualizacji czasu wschodu i zachodu słońca na czas
  # aktualnie wykonywanej iteracji
  $when = $now
}