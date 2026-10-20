# Captures the Mediary Windows window into docs/screenshots/windows-home-<theme>.png.
#
# Usage: pwsh tool/windows_capture.ps1 -Theme light
#
# Assumes build/windows/x64/runner/Release/Mediary.exe was built with
# SCREENSHOT_DEMO=true and SCREENSHOT_THEME=<theme>. Launches the app,
# sizes the window to the work area, captures it (screen copy with a
# PrintWindow fallback for locked sessions), then quits the app.
param([Parameter(Mandatory = $true)][ValidateSet("light", "dark")][string]$Theme)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing

$exe = "build\windows\x64\runner\Release\Mediary.exe"
Start-Process -FilePath $exe
Write-Host "Waiting for Mediary window..."

$proc = $null
for ($i = 0; $i -lt 60; $i++) {
  $proc = Get-Process -Name "Mediary" -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if ($proc) { break }
  Start-Sleep -Seconds 1
}
if (-not $proc) { throw "Mediary window did not appear within 60s" }

# Let the first frame and the demo task fully render.
Start-Sleep -Seconds 8

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  // DWMWA_EXTENDED_FRAME_BOUNDS = 9: visible frame, excludes the
  // invisible DWM shadow border that GetWindowRect includes.
  [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hWnd, int attr, out RECT rect, int size);
}
"@

$hwnd = $proc.MainWindowHandle
[Win32]::ShowWindow($hwnd, 9) | Out-Null        # SW_RESTORE
[Win32]::SetForegroundWindow($hwnd) | Out-Null
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$winW = [Math]::Min(1280, $wa.Width)
$winH = [Math]::Min(800, $wa.Height)
[Win32]::MoveWindow($hwnd, 0, 0, $winW, $winH, $true) | Out-Null
Start-Sleep -Seconds 3

$rect = New-Object Win32+RECT
$hr = [Win32]::DwmGetWindowAttribute($hwnd, 9, [ref]$rect, [System.Runtime.InteropServices.Marshal]::SizeOf($rect))
if ($hr -ne 0) {
  Write-Host "DwmGetWindowAttribute failed (hr=$hr); using GetWindowRect."
  [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
}
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
Write-Host "Window rect: $($rect.Left),$($rect.Top) ${w}x${h}"

$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmp.Size)
$g.Dispose()

# Fallback: if the screen capture is pure black (e.g. locked session),
# use PrintWindow instead.
$center = $bmp.GetPixel([int]($w / 2), [int]($h / 2))
if ($center.R -lt 5 -and $center.G -lt 5 -and $center.B -lt 5) {
  Write-Host "Screen capture is black; falling back to PrintWindow."
  $bmp.Dispose()
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g2 = [System.Drawing.Graphics]::FromImage($bmp)
  $hdc = $g2.GetHdc()
  [Win32]::PrintWindow($hwnd, $hdc, 2) | Out-Null   # PW_RENDERFULLCONTENT
  $g2.ReleaseHdc($hdc)
  $g2.Dispose()
}

New-Item -ItemType Directory -Force -Path docs\screenshots | Out-Null
$out = "$PWD\docs\screenshots\windows-home-$Theme.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Saved $out"

# Mirror into the website assets so the site picks up the same shot.
$webDir = "$PWD\website\src\assets\screenshots"
New-Item -ItemType Directory -Force -Path $webDir | Out-Null
Copy-Item $out "$webDir\windows-home-$Theme.png" -Force
Write-Host "Mirrored to website assets"

Stop-Process -Name "Mediary" -Force -ErrorAction SilentlyContinue
