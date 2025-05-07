<#
.SYNOPSIS
    Sets the Windows application and system theme to either light or dark mode.

.DESCRIPTION
    This function modifies Windows registry settings to switch between light and dark themes
    for both applications and system UI elements. It includes validation and error handling.

.PARAMETER UseLightTheme
    Boolean parameter that specifies whether to use light theme ($true) or dark theme ($false).

.PARAMETER Force
    When specified, applies the theme even if it's already set to the requested mode.

.EXAMPLE
    Set-WindowsTheme -UseLightTheme $true
    Switches to light theme if not already set.

.EXAMPLE
    Set-WindowsTheme -UseLightTheme $true -Force
    Forces light theme application even if already set.

.NOTES
    Requires administrative privileges to modify registry settings.
    Some applications may require restart to fully apply theme changes.
#>
function Set-WindowsTheme {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param (
    [Parameter(Mandatory=$true)]
    [bool]$UseLightTheme,

    [Parameter(Mandatory=$false)]
    [switch]$Force
  )

  begin {
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $appsValue = "AppsUseLightTheme"
    $systemValue = "SystemUsesLightTheme"

    # Theme mode names for logging
    $themeMode = if ($UseLightTheme) { "LIGHT" } else { "DARK" }
  }

  process {
    try {
      # Verify registry path exists
      if (-not (Test-Path -Path $themePath)) {
        throw "Registry path not found: $themePath"
      }

      # Get current theme settings
      $currentApps = (Get-ItemProperty -Path $themePath -Name $appsValue -ErrorAction Stop).$appsValue
      $currentSystem = (Get-ItemProperty -Path $themePath -Name $systemValue -ErrorAction Stop).$systemValue

      # Determine if change is needed
      $desiredValue = [int]$UseLightTheme
      $needsChange = $Force -or ($currentApps -ne $desiredValue) -or ($currentSystem -ne $desiredValue)

      if (-not $needsChange) {
        Write-Verbose "Theme already set to requested mode: $themeMode"
        return
      }

      # Apply theme changes
      Write-Log "Switching to $themeMode theme..."

      Set-ItemProperty -Path $themePath -Name $appsValue -Value $desiredValue -ErrorAction Stop
      Set-ItemProperty -Path $themePath -Name $systemValue -Value $desiredValue -ErrorAction Stop

      Write-Log "Theme successfully applied"
    } catch [System.Security.SecurityException] {
      Write-Error "[PERMISSION ERROR] Access denied. Try running as Administrator: $_"
    } catch [System.Exception] {
      Write-Error "[THEME ERROR] Failed to apply theme: $_"
    }
  }

  end {
    Write-Verbose "Theme configuration completed"
  }
}