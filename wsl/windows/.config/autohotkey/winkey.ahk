; Win key like Omarchy's Super: tapping it alone does nothing, Win+Space opens
; app search. Win+<key> combos (GlazeWM, Win+L, Win+Shift+S...) are untouched.
; Started at login by a shortcut in the Startup folder.
#Requires AutoHotkey v2.0
#SingleInstance Force

; A dummy key between Win down and Win up stops Windows opening Start on release.
; Send it once per press, not on every auto-repeat while Win is held: a stream of
; injected keys makes Windows drop GlazeWM's keyboard hook.
~LWin::
{
    Send "{Blind}{vkE8}"
    KeyWait "LWin"
}

; Win+Space: open Start (search is focused, so typing searches apps).
; Replaces Windows' Win+Space keyboard-layout switcher.
#Space::Send "^{Esc}"
