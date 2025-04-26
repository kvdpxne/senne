. ./logging.ps1

<#
.SYNOPSIS
    Tests internet connectivity by pinging a reliable host.

.DESCRIPTION
    This function checks internet connectivity by attempting to ping Google's public DNS server (8.8.8.8).
    It provides configurable options for retries, timeout, and custom times.data hosts.

.PARAMETER TestHost
    The host or IP address to times.data connectivity against. Default is Google DNS (8.8.8.8).

.PARAMETER RetryCount
    Number of times to retry the connection times.data if the first attempt fails. Default is 1.

.PARAMETER RetryIntervalSeconds
    Seconds to wait between retry attempts. Default is 5 seconds.

.PARAMETER TimeoutSeconds
    Maximum time to wait for each ping response. Default is 2 seconds.

.PARAMETER Quiet
    When specified, suppresses all output messages.

.EXAMPLE
    Test-InternetConnection
    Tests basic internet connectivity with default settings.

.EXAMPLE
    Test-InternetConnection -TestHost "1.1.1.1" -RetryCount 3 -TimeoutSeconds 1
    Tests connectivity against Cloudflare DNS with 3 retries and 1 second timeout.

.OUTPUTS
    Boolean
    Returns $true if internet connection is available, $false otherwise.
#>
function Test-InternetConnection {
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Mandatory = $false)]
    [string]$TestHost = "8.8.8.8",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$RetryCount = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 60)]
    [int]$RetryIntervalSeconds = 5,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$TimeoutSeconds = 2,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
  )
  begin {
    $attempt = 0
    $success = $false
  }

  process {
    do {
      $attempt++
      try {
        $null = Test-Connection -ComputerName $TestHost -Count 1 -ErrorAction "Stop"
        $success = $true

        if (-not $Quiet) {
          Write-Log "Internet connection confirmed (attempt $attempt of $RetryCount)"
        }
        break
      } catch {
        $success = $false
        if (-not $Quiet) {
          if ($attempt -lt $RetryCount) {
            Write-Warning "[ATTEMPT $attempt/$RetryCount] No internet connection detected. Retrying in $RetryIntervalSeconds seconds..."
          } else {
            Write-Warning "[FINAL ATTEMPT] No internet connection detected after $RetryCount attempts."
          }
        }

        if ($attempt -lt $RetryCount) {
          Start-Sleep -Seconds $RetryIntervalSeconds
        }
      }
    } while ($attempt -lt $RetryCount)
  }

  end {
    return $success
  }
}