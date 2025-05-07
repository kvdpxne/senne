. ./datetime-converter.ps1
. ./logging.ps1

<#
.SYNOPSIS
    Retrieves sunrise and sunset times for a specific location and date.

.DESCRIPTION
    This function queries a sunrise-sunset API to obtain accurate solar event times
    for a given latitude, longitude, and date. Results are converted to local time.

.PARAMETER Latitude
    The latitude coordinate in decimal degrees (-90 to 90). Required.

.PARAMETER Longitude
    The longitude coordinate in decimal degrees (-180 to 180). Required.

.PARAMETER Date
    The date for which to retrieve solar times. Defaults to current date.

.PARAMETER ApiEndpoint
    The base URL of the sunrise-sunset API. Defaults to $SUN_API if available.

.PARAMETER TimeoutSec
    Timeout in seconds for the API request. Default is 10 seconds.

.EXAMPLE
    Get-SunsetSunriseData -Latitude 40.7128 -Longitude -74.0060
    Gets sunrise/sunset times for New York City on the current date.

.EXAMPLE
    Get-SunsetSunriseData -Latitude 51.5074 -Longitude -0.1278 -Date "2023-06-21"
    Gets solar times for London on summer solstice 2023.

.OUTPUTS
    PSCustomObject
    Returns an object with Sunrise and Sunset properties in local time.
    Returns $null if the API request fails.

.NOTES
    Requires $SUN_API variable to be set with the API endpoint URL.
    Consider caching results for repeated requests to the same location/date.
#>
function Get-SunsetSunriseData {
  [CmdletBinding()]
  [OutputType([PSObject])]
  param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(-90, 90)]
    [double]$Latitude,

    [Parameter(Mandatory=$true)]
    [ValidateRange(-180, 180)]
    [double]$Longitude,

    [Parameter(Mandatory=$false)]
    [DateTime]$Date = (Get-Date),

    [Parameter(Mandatory=$false)]
    [string]$ApiEndpoint = $SUN_API,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 60)]
    [int]$TimeoutSec = 10
  )

  begin {
    # Validate API endpoint
    if ([string]::IsNullOrWhiteSpace($ApiEndpoint)) {
      throw "Sun API endpoint is not configured. Please set `$SUN_API or provide -ApiEndpoint parameter."
    }

    # Remove trailing slash from API endpoint if present
    $ApiEndpoint = $ApiEndpoint.TrimEnd('/')
    Write-Log "Using Sun API endpoint: $ApiEndpoint" -Level "DEBUG"
  }

  process {
    try {
      $formattedDate = Get-Date -Format "yyyy-MM-dd" $Date
      $url = "$ApiEndpoint/json?lat=$Latitude&lng=$Longitude&date=$formattedDate"

      Write-Log "Fetching solar times for $formattedDate at Lat=$Latitude, Lon=$Longitude"
      Write-Log "API Request URL: $url" -Level "DEBUG"

      # Make API request
      $response = Invoke-RestMethod -Uri $url -TimeoutSec $TimeoutSec -ErrorAction Stop

      if ($response.status -ne "OK") {
        throw "API returned status: $($response.status)"
      }

      # Convert UTC times to local time zone
      $localSunrise = Convert-UtcTimeToLocal -Time $response.results.sunrise
      $localSunset = Convert-UtcTimeToLocal -Time $response.results.sunset

      Write-Log "Solar times retrieved: Sunrise (local): $($localSunrise.ToString("HH:mm:ss")) Sunset (local): $($localSunset.ToString("HH:mm:ss"))"

      # Return structured data
      return [PSCustomObject]@{
        Date = $Date
        Sunrise = $localSunrise
        Sunset = $localSunset
      }
    } catch [System.Net.WebException] {
      Write-Error "[NETWORK ERROR] Failed to connect to Sun API: $($_.Exception.Message)"
      return $null
    } catch [System.Exception] {
      Write-Error "[API ERROR] Solar data request failed: $($_.Exception.Message)"
      return $null
    }
  }

  end {
    Write-Verbose "Solar data retrieval completed for $formattedDate"
  }
}