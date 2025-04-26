. ./logging.ps1

$GEOCODING_API = "https://nominatim.openstreetmap.org"

<#
.SYNOPSIS
    Retrieves geocoding data (latitude/longitude) for a specified location.

.DESCRIPTION
    This function queries a geocoding API to obtain geographic coordinates for
    a given city or location. It handles API responses, error conditions, and
    provides detailed logging.

.PARAMETER Location
    The city or address to geocode. This parameter is mandatory.

.PARAMETER ApiEndpoint
    The base URL of the geocoding API. Defaults to $GEOCODING_API if available.

.PARAMETER MaxResults
    Maximum number of results to consider from API response. Default is 1.

.PARAMETER TimeoutSec
    Timeout in seconds for the API request. Default is 10 seconds.

.EXAMPLE
    $coordinates = Get-GeocodingData -Location "New York"
    Retrieves coordinates for New York City.

.EXAMPLE
    $geoData = Get-GeocodingData -Location "1600 Pennsylvania Ave" -MaxResults 3
    Gets up to 3 possible matches for the White House address.

.OUTPUTS
    PSCustomObject
    Returns an object with geographic data including lat/lon coordinates.
    Returns $null if no results found or if an error occurs.

.NOTES
    Requires $GEOCODING_API variable to be set with the API endpoint URL.
    Consider implementing rate limiting for bulk requests.
#>
function Get-Geocoding-Location-Data {
  [CmdletBinding()]
  [OutputType([PSObject])]
  param(
    [Parameter(
      Mandatory=$true,
      Position=0,
      HelpMessage="Enter a city name or address"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter(Mandatory=$false)]
    [string]$ApiEndpoint = $GEOCODING_API,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 10)]
    [int]$MaxResults = 1,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 60)]
    [int]$TimeoutSec = 10
  )

  begin {
    # Validate API endpoint
    if ([string]::IsNullOrWhiteSpace($ApiEndpoint)) {
      throw "Geocoding API endpoint is not configured. Please set `$GEOCODING_API or provide -ApiEndpoint parameter."
    }

    # Remove trailing slash from API endpoint if present
    $ApiEndpoint = $ApiEndpoint.TrimEnd('/')
    Write-Log "Using geocoding API endpoint: $ApiEndpoint" -Level "DEBUG"
  }

  process {
    try {
      # URL encode the location query
      Add-Type -AssemblyName System.Web
      $encodedLocation = [System.Web.HttpUtility]::UrlEncode($Location)
      $uri = "$ApiEndpoint/search?q=$encodedLocation&format=json&limit=$MaxResults"

      Write-Log "Fetching coordinates for: $Location"
      Write-Log "API Request URI: $uri" -Level "DEBUG"

      # Make API request
      $response = Invoke-RestMethod -Uri $uri -TimeoutSec $TimeoutSec -ErrorAction Stop

      if (-not $response -or $response.Count -eq 0) {
        Write-Warning "[WARNING] No geographic data found for '$Location'"
        return $null
      }

      # Process and return results
      $results = $response | Select-Object -First $MaxResults

      foreach ($result in $results) {
        Write-Log "Found location: $($result.display_name) Coordinates: Lat=$($result.lat), Lon=$($result.lon) Importance: $($result.importance)"
      }

      # Return single result if MaxResults=1, otherwise return array
      if ($MaxResults -eq 1) {
        return $results[0]
      } else {
        return $results
      }

    } catch [System.Net.WebException] {
      Write-Error "[NETWORK ERROR] Failed to connect to geocoding service: $($_.Exception.Message)"
      return $null
    } catch [System.Exception] {
      Write-Error "[API ERROR] Geocoding request failed: $($_.Exception.Message)"
      return $null
    }
  }

  end {
    Write-Log "Geocoding operation completed for: $Location" -Level "DEBUG"
  }
}