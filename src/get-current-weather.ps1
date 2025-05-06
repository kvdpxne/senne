. ./constants.ps1
. ./logging.ps1

function Get-CurrentWeather() {
  [CmdletBinding()]
  [OutputType([PSObject])]
  param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(-90, 90)]
    [double]$Latitude,

    [Parameter(Mandatory=$true)]
    [ValidateRange(-180, 180)]
    [double]$Longitude
  )

  begin {
    $endpoint = $WEATHER_API.TrimEnd('/')
    Write-Log "Using Weather API endpoint: $endpoint" -Level "DEBUG"
  }

  process {
    try {
      $url = "$endpoint/forecast?latitude=$Latitude&longitude=$Longitude&current=cloud_cover"

      Write-Log "Fetching current weather for "
      Write-Log "API Request URL: $url" -Level "DEBUG"

      $response = Invoke-RestMethod -Uri $url -TimeoutSec 10 -ErrorAction Stop
      if (-not $response) {
        throw "API returned status: $($response.status)"
      }
      Write-Log $response.current

    } catch [System.Net.WebException] {
      Write-Error "[NETWORK ERROR] Failed to connect to Weather API: $($_.Exception.Message)"
      return $null
    }
  }

  end {
    return [PSCustomObject]@{
      Code = $response.current.cloud_cover
    }
  }
}