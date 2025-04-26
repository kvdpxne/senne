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

.EXAMPLE
    Write-Log -Message "Disk space low" -Level WARN -ApplicationName "DiskMonitor"
    Writes a warning with custom application name.

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
    [string]$SourceName = "senne",

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
    $consoleMessage = "$timestamp $($Level.PadLeft(5)) : $Message"
  }

  process {
    try {
      # Console output (only in interactive mode)
      if ($host.UI.RawUI.WindowStyle -ne "Hidden") {
        $color = $levelConfig[$Level].Color
        Write-Host $consoleMessage -ForegroundColor $color
      }

      # Ensure event source exists
      if (-not [System.Diagnostics.EventLog]::SourceExists($SourceName)) {
        try {
          [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
          Write-Verbose "Created new EventLog source: $SourceName"
        } catch {
          Write-Warning "Failed to create EventLog source '$SourceName': $_"
          return
        }
      }

      try {
        Write-EventLog -LogName $LogName -Source $SourceName -EntryType $levelConfig[$Level].Type -EventId $EventId -Message $Message -ErrorAction Stop
        Write-Verbose "Successfully logged [$Level] message to EventLog"
      } catch {
        Write-Warning "Failed to write to EventLog: $_"
      }
    } catch {
      Write-Warning "Unexpected error in Write-Log: $_"
    }
  }
}