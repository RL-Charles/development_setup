# Windows side of the setup: the apps, login items and settings that aren't
# plain files. Run through `dotfiles.sh windows`, after `dotfiles.sh install`
# has put the config files in place. Safe to re-run.

# Apps. GlazeWM must be 3.x (the old 2.x can't read config.yaml) and it installs
# Zebar alongside; its installer asks for admin once.
$apps = @(
  'glzr-io.glazewm',       # tiling WM with Omarchy's bindings (~\.glzr\glazewm)
  'AutoHotkey.AutoHotkey', # Win key tweaks (~\.config\autohotkey\winkey.ahk)
  'SamHocevar.WinCompose'  # compose key (~\.XCompose)
)
foreach ($id in $apps) {
  winget list --id $id --exact | Out-Null
  if ($LASTEXITCODE -ne 0) {
    winget install --id $id --exact --scope user --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
      # Some installers (GlazeWM) are machine-wide only
      winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements
    }
  }
}

# Login items, as shortcuts in the Startup folder. GlazeWM starts Zebar itself
# (startup_commands in its config).
$startup = [Environment]::GetFolderPath('Startup')
$shell = New-Object -ComObject WScript.Shell
function Set-Startup($name, $target, $arguments) {
  $link = $shell.CreateShortcut("$startup\$name.lnk")
  $link.TargetPath = $target
  $link.Arguments = $arguments
  $link.Save()
}
Set-Startup 'GlazeWM' "$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe" 'start'
Set-Startup 'WinKey' "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" "`"$env:USERPROFILE\.config\autohotkey\winkey.ahk`""
Set-Startup 'CopyPopup' "$env:SystemRoot\System32\conhost.exe" "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.config\copy-popup\copy-popup.ps1`""

# Key repeat: shortest delay before repeating, fastest repeat rate. Applied live
# (no sign-out) and saved to HKCU\Control Panel\Keyboard.
#   Delay: 0-3 (250/500/750/1000 ms). Speed: 0-31 (~2.5-30 repeats/s).
Add-Type -Name User32 -Namespace Win -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool SystemParametersInfo(uint action, uint param, System.IntPtr vparam, uint flags);
'@
$SPI_SETKEYBOARDSPEED = 0x0B
$SPI_SETKEYBOARDDELAY = 0x17
$SAVE_AND_BROADCAST = 0x03  # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
[void][Win.User32]::SystemParametersInfo($SPI_SETKEYBOARDDELAY, 0, [System.IntPtr]::Zero, $SAVE_AND_BROADCAST)
[void][Win.User32]::SystemParametersInfo($SPI_SETKEYBOARDSPEED, 31, [System.IntPtr]::Zero, $SAVE_AND_BROADCAST)

Write-Host 'Windows setup done. Sign out and back in (or run the Startup shortcuts) to start GlazeWM, Zebar and the Win key script.'
