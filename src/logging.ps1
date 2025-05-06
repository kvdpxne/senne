. ./constants.ps1

<#
.SYNOPSIS
    Writes log messages to multiple outputs including console and Windows Event Log.

.DESCRIPTION
    This function provides centralized logging with the following features:
    - Color-coded console output (when available)
    - Windows Event Log integration
    - Multiple log levels (INFO, WARN, ERROR, DEBUG)
    - Automatic event source creation
    - Configurable application name and log source

.PARAMETER Message
    The log message to be recorded (required).

.PARAMETER Level
    The severity level of the message (INFO, WARN, ERROR, DEBUG). Default is INFO.

.PARAMETER LogName
    The Windows Event Log name. Default is "Application".

.PARAMETER EventId
    The event ID to use in Event Log. Default is 1001.

.EXAMPLE
    Write-Log -Message "Application started" -Level INFO
    Writes an informational message to all outputs.

.NOTES
    Requires administrative privileges to create new event sources.
    Console colors are only applied when running in interactive mode.
#>
function Write-Log {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
    [string]$Level = "INFO",

    [Parameter(Mandatory = $false)]
    [string]$LogName = "Application",

    [Parameter(Mandatory = $false)]
    [int]$EventId = 1001
  )

  begin {
    # Map log level to console colors and event log entry types
    $levelConfig = @{
      "INFO"  = @{ Color = "Cyan";   Type = [System.Diagnostics.EventLogEntryType]::Information }
      "WARN"  = @{ Color = "Yellow"; Type = [System.Diagnostics.EventLogEntryType]::Warning }
      "ERROR" = @{ Color = "Red";    Type = [System.Diagnostics.EventLogEntryType]::Error }
      "DEBUG" = @{ Color = "Gray";   Type = [System.Diagnostics.EventLogEntryType]::Information }
    }

    # Create timestamp and formatted message
    $timestamp = Get-Date -Format $GOOD_FORMAT
    $job = Get-Job
    $jobName = if ($job) { $job.Name } else { "main" }

    $consoleMessage = "$timestamp $($Level.PadLeft(5)) $PID --- [$jobName] : $Message"
    $sourceName = "senne"
  }

  process {
    try {
      # Console output (only in interactive mode)
      if ("Hidden" -ne $host.UI.RawUI.WindowStyle) {
        $color = $levelConfig[$Level].Color
        Write-Host $consoleMessage -ForegroundColor $color
      }

      #
      if ("DEBUG" -eq $Level) {
        return
      }

      # Ensure event source exists
      if (-not [System.Diagnostics.EventLog]::SourceExists($sourceName)) {
        try {
          [System.Diagnostics.EventLog]::CreateEventSource($sourceName, $LogName)
          Write-Verbose "Created new EventLog source: $sourceName"
        } catch {
          Write-Warning "Failed to create EventLog source '$sourceName': $_"
          return
        }
      }

      try {
        Write-EventLog -LogName $LogName -Source $sourceName -EntryType $levelConfig[$Level].Type -EventId $EventId -Message $Message -ErrorAction Stop
        Write-Verbose "Successfully logged [$Level] message to EventLog"
      } catch {
        Write-Warning "Failed to write to EventLog: $_"
      }
    } catch {
      Write-Warning "Unexpected error in Write-Log: $_"
    }
  }
}