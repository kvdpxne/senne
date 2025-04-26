<#
.SYNOPSIS
    Converts a UTC time string to the local time zone equivalent.

.DESCRIPTION
    This function parses a UTC time string and converts it to the local system time zone.
    It supports multiple input formats and provides comprehensive error handling.

.PARAMETER Time
    The UTC time string to convert. Supports formats like "7:23:45 AM", "HH:mm:ss", etc.

.PARAMETER InputFormat
    The format of the input time string. Default is "h:mm:ss tt" (e.g., "7:23:45 AM").
    Other common formats include "HH:mm:ss" (24-hour format).

.PARAMETER OutputFormat
    The desired output format. If not specified, returns a DateTime object.

.EXAMPLE
    Convert-UtcTimeToLocal -Time "7:23:45 AM"
    Converts UTC time "7:23:45 AM" to local time.

.EXAMPLE
    Convert-UtcTimeToLocal -Time "13:45:00" -InputFormat "HH:mm:ss" -OutputFormat "hh:mm tt"
    Converts 24-hour UTC time to local 12-hour format with AM/PM.

.EXAMPLE
    "19:30:00" | Convert-UtcTimeToLocal -InputFormat "HH:mm:ss"
    Pipeline input example with 24-hour format.

.OUTPUTS
    DateTime or String
    Returns a DateTime object by default, or formatted string if OutputFormat is specified.

.NOTES
    Time zone conversion uses the system's local time zone settings.
    For UTC times without dates, the current date is assumed.
#>
function Convert-UtcTimeToLocal {
  [CmdletBinding()]
  [OutputType([DateTime], ParameterSetName='Default')]
  [OutputType([String], ParameterSetName='Formatted')]
  param(
    [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$true,
      Position=0,
      HelpMessage="UTC time string to convert"
    )]
    [string]$Time,

    [Parameter(Mandatory=$false)]
    [string]$InputFormat = "h:mm:ss tt",

    [Parameter(Mandatory=$false)]
    [string]$OutputFormat
  )

  begin {
    # List of common time formats to try if parsing fails with specified format
    $commonFormats = @(
      "h:mm:ss tt",    # 12-hour with AM/PM
      "HH:mm:ss",      # 24-hour
      "h:mm tt",       # 12-hour without seconds
      "HH:mm",         # 24-hour without seconds
      "H:mm:ss",       # 24-hour with single digit hour
      "h:mm:ss.fff tt" # With milliseconds
    )

    # Add user-specified format first if it's not already in the list
    if ($commonFormats -notcontains $InputFormat) {
      $commonFormats = @($InputFormat) + $commonFormats
    }
  }

  process {
    try {
      $utcTime = $null
      $parseSuccess = $false

      # Try parsing with specified format first
      try {
        $utcTime = [DateTime]::ParseExact(
          $Time,
          $InputFormat,
          [System.Globalization.CultureInfo]::InvariantCulture,
          [System.Globalization.DateTimeStyles]::AssumeUniversal
        )
        $parseSuccess = $true
        Write-Verbose "Successfully parsed time using specified format: $InputFormat"
      } catch {
        Write-Verbose "Failed to parse with specified format '$InputFormat', trying common formats..."
      }

      # If parsing failed, try common formats
      if (-not $parseSuccess) {
        foreach ($format in $commonFormats) {
          try {
            $utcTime = [DateTime]::ParseExact(
              $Time,
              $format,
              [System.Globalization.CultureInfo]::InvariantCulture,
              [System.Globalization.DateTimeStyles]::AssumeUniversal
            )
            $parseSuccess = $true
            Write-Verbose "Successfully parsed time using format: $format"
            break
          } catch {
            continue
          }
        }
      }

      if (-not $parseSuccess) {
        throw "Could not parse the time string '$Time' with any known format."
      }

      # Convert to local time
      $localTime = $utcTime.ToLocalTime()

      # Apply output formatting if requested
      if ($OutputFormat) {
        return $localTime.ToString($OutputFormat)
      }

      return $localTime
    } catch {
      Write-Error "Failed to convert UTC time: $_"
      throw
    }
  }
}