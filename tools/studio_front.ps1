# Brings the Studio window whose title contains $Title to the front (restoring it if minimised). A Studio window that is
# minimised or behind another one draws no 3D: screen_capture then returns the HUD on plain white (2026-11-08).
#   & "C:\Roblox 3rd game\tools\studio_front.ps1" StudioTest
param([string]$Title = "StudioTest")
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class StudioWin {
	public delegate bool EnumProc(IntPtr h, IntPtr l);
	[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
	[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
	[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
	[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
	[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
	[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
	[DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, int f, int e);
	public static IntPtr Find(string part) {
		IntPtr found = IntPtr.Zero;
		EnumWindows(delegate (IntPtr h, IntPtr l) {
			if (!IsWindowVisible(h)) return true;
			var sb = new StringBuilder(512);
			GetWindowText(h, sb, 512);
			if (sb.ToString().Contains(part) && sb.ToString().Contains("Roblox Studio")) { found = h; return false; }
			return true;
		}, IntPtr.Zero);
		return found;
	}
}
"@
$h = [StudioWin]::Find($Title)
if ($h -eq [IntPtr]::Zero) { "no Studio window with $Title"; exit 1 }
if ([StudioWin]::IsIconic($h)) { [void][StudioWin]::ShowWindow($h, 9) }
# An Alt tap lets a background process take the foreground.
[StudioWin]::keybd_event(0x12, 0, 0, 0)
[StudioWin]::keybd_event(0x12, 0, 2, 0)
"front: " + [StudioWin]::SetForegroundWindow($h)
