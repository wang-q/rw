﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Notes:
; WinGetPos, X, Y, W, H, A  ; "A" to get the active window's pos.
; MsgBox, The active window is at %X%`,%Y% with width and height [%W%, %H%]

; Hoy Key Symbols
; Symbol	#	= Win (Windows logo key)
; Symbol	!	= Alt
; Symbol	^	= Control
; Symbol	+	= Shift
; Symbol	& = An ampersand may be used between any two keys or mouse buttons to combine them into a custom hotkey.

; Watch out for the Microsoft Office Apps Pop-up!
; Pops up whhen user presses various combinations of Windows key with Alt and Shift and Home.
; To disable the Microsoft Office 360 pop-up, add this registry ket to your system:
; Note: Solution taken from AHK Forum: https://www.autohotkey.com/boards/viewtopic.php?t=65573
; ----
; Run: REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32
; This will add a registry key that will make the Office key run a useless command, effectively disabling it.
; It does not block the individual hot keys - it only removes the loading of the Office app.
; To reverse it, just delete the key (the Shell folder did not previously exist, so it can be completely removed)
; Run: REG DELETE HKCU\Software\Classes\ms-officeapp\Shell

; ----------------------------
; Icon
; ----------------------------
InitializeIcon()

InitializeIcon() {
    ; Set the System tray icon (should sit next to the AHK file)
    if FileExist("icon.ico") {
        Menu, Tray, Icon, icon.ico
    }
}

; ----------------------------
; Actions
; ----------------------------

; Move
#!^+Left::
    MoveToEdge("Left")
return

#!^+Right::
    MoveToEdge("Right")
return

#!^+Up::
    MoveToEdge("Top")
return

#!^+Down::
    MoveToEdge("Bottom")
return

; Center window
#!^C::
    MoveWindowToCenter()
return

; Maximize window
#!^+M::
    ResizeAndCenterShift(1)
return

#!^M::
    LoopM()
return

; Vertical half screen

; ----------------------------
; Functions
; ----------------------------

GetWindowNumber() {
    ; Get the Active window
    WinGetPos, WinX, WinY, WinW, WinH, A  ; "A" to get the active window's pos.
    SysGet, numMonitors, MonitorCount
    Loop %numMonitors% {
        SysGet, monitor, MonitorWorkArea, %A_Index%
        if (monitorLeft <= WinX && WinX < monitorRight && monitorTop <= WinY && WinY <= monitorBottom){
            ; We have found the monitor that this window sits inside (at least the top-left corner)
            return %A_Index%
        }
    }
    return 1    ; If we can't find a matching window, just return 1 (Primary)
}

LoopM() {
    WinNum := GetWindowNumber()

    ; Set the screen variables
    SysGet, Mon, MonitorWorkArea, %WinNum%
    ScreenW := MonRight - MonLeft
    ScreenH := MonBottom - MonTop
    ScreenM := Min(ScreenW, ScreenH)

    ; "A" to get the active window's pos
    WinGetPos, WinX, WinY, WinW, WinH, A

    ; 4:3 window
    BaseW := Floor(ScreenM * 4 / 3)
    BaseH := ScreenM
    serials := [ 1, 0.9, 0.7, 0.5 ]

    NewW := WinW
    NewH := WinH

    if ( WinW = Floor(BaseW * serials[1]) ) {
        NewW := Floor(BaseW * serials[2])
        NewH := Floor(BaseH * serials[2])
    } else if ( WinW = Floor(BaseW * serials[2]) ) {
        NewW := Floor(BaseW * serials[3])
        NewH := Floor(BaseH * serials[3])
    } else if ( WinW = Floor(BaseW * serials[3]) ) {
        NewW := Floor(BaseW * serials[4])
        NewH := Floor(BaseH * serials[4])
    } else if ( WinW = Floor(BaseW * serials[4]) ) {
        NewW := Floor(BaseW * serials[1])
        NewH := Floor(BaseH * serials[1])
    } else {
        NewW := Floor(BaseW * serials[1])
        NewH := Floor(BaseH * serials[1])
    }

    DoResizeAndCenter(WinNum, NewW, NewH)
}

GetCenterCoordinates(ByRef A, WinNum, ByRef NewX, ByRef NewY, WinW, WinH) {
    ; Set the screen variables
    SysGet, Mon, MonitorWorkArea, %WinNum%
    ScreenW := MonRight - MonLeft
    ScreenH := MonBottom - MonTop

    ; Calculate the position based on the given dimensions [W|H]
    NewX := (ScreenW-WinW)/2 + MonLeft ; Adjust for monitor offset
    NewY := (ScreenH-WinH)/2 + MonTop ; Adjust for monitor offset
}

EnsureWindowIsRestored() {
    WinGet, ActiveWinState, MinMax, A
    if (ActiveWinState != 0)
        WinRestore, A
}

RestoreMoveAndResize(A, NewX, NewY, NewW, NewH) {
    EnsureWindowIsRestored() ; Always ensure the window is restored before any move or resize operation
;    MsgBox Move to: (X/Y) %NewX%, %NewY%; (W/H) %NewW%, %NewH%
    WinMove, A, , NewX, NewY, NewW, NewH
}

DoResizeAndCenter(WinNum, NewW, NewH) {
    GetCenterCoordinates(A, WinNum, NewX, NewY, NewW, NewH)
    RestoreMoveAndResize(A, NewX, NewY, NewW, NewH)
}

MoveWindowToCenter() {
    WinGetPos, WinX, WinY, WinW, WinH, A  ; "A" to get the active window's pos.
    WinNum := GetWindowNumber()
    DoResizeAndCenter(WinNum, WinW, WinH)
    return
}

MoveToEdge(Edge) {
    ; Get monitor and window dimensions
    WinNum := GetWindowNumber()
    SysGet, Mon, MonitorWorkArea, %WinNum%
    WinGetPos, WinX, WinY, WinW, WinH, A  ; "A" to get the active window's pos.

    ; Set window coordinates
    if InStr(Edge, "Left")
        NewX := MonLeft
    if InStr(Edge, "Right")
        NewX := MonRight - WinW
    if InStr(Edge, "Top")
        NewY := MonTop
    if InStr(Edge, "Bottom")
        NewY := MonBottom - WinH

    ; MsgBox NewX/NewY = %NewX%,%NewY%
    RestoreMoveAndResize(A, NewX, NewY, NewW, NewH)
    return
}

CalculateSizeByWinRatio(ByRef NewW, ByRef NewH, WinNum, Ratio) {
    WinNum := GetWindowNumber()
    SysGet, Mon, MonitorWorkArea, %WinNum%
    NewH := (MonBottom - MonTop) * Ratio
    NewW := Floor(NewH * 4 / 3)
}

ResizeAndCenter(Ratio) {
    WinNum := GetWindowNumber()
    CalculateSizeByWinRatio(NewW, NewH, WinNum, Ratio)
    DoResizeAndCenter(WinNum, NewW, NewH)
}

CalculateSizeByWinRatioShift(ByRef NewW, ByRef NewH, WinNum, Ratio) {
    WinNum := GetWindowNumber()
    SysGet, Mon, MonitorWorkArea, %WinNum%
    NewW := (MonRight - MonLeft) * Ratio
    NewH := (MonBottom - MonTop) * Ratio
}

ResizeAndCenterShift(Ratio) {
    WinNum := GetWindowNumber()
    CalculateSizeByWinRatioShift(NewW, NewH, WinNum, Ratio)
    DoResizeAndCenter(WinNum, NewW, NewH)
}