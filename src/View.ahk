/**
 *	bug.n - tiling window management
 *	Copyright (c) 2010-2012 joten
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 *	@version 8.3.0
 */

View_init(m, v) {
	Global
	
	View_#%m%_#%v%_aWndId         := 0
	View_#%m%_#%v%_layout_#1      := 1
	View_#%m%_#%v%_layout_#2      := 1
	View_#%m%_#%v%_layoutAxis_#1  := Config_layoutAxis_#1
	View_#%m%_#%v%_layoutAxis_#2  := Config_layoutAxis_#2
	View_#%m%_#%v%_layoutAxis_#3  := Config_layoutAxis_#3
    View_#%m%_#%v%_layoutGapWidth := Config_layoutGapWidth
	View_#%m%_#%v%_layoutMFact    := Config_layoutMFactor
	View_#%m%_#%v%_layoutMSplit   := 1
	View_#%m%_#%v%_layoutSymbol   := Config_layoutSymbol_#1
	View_#%m%_#%v%_wndIds         := ""
}

View_activateWindow(d) {
	Local aWndId, i, j, v, wndId, wndId0, wndIds
	Log_dbg_msg(1, "View_activateWindow(" . d . ")")
	WinGet, aWndId, ID, A
	Log_dbg_bare(2, "Active Windows ID: " . aWndId)
	v := Monitor_#%Manager_aMonitor%_aView_#1
	Log_dbg_bare(2, "View (" . v . ") wndIds: " . View_#%Manager_aMonitor%_#%v%_wndIds)
	StringTrimRight, wndIds, View_#%Manager_aMonitor%_#%v%_wndIds, 1
	StringSplit, wndId, wndIds, `;
	Log_dbg_bare(2, "wndId count: " . wndId0)
	If (wndId0 > 1) {
		Loop, % wndId0
			If (wndId%A_Index% = aWndId) {
				i := A_Index
				Break
			}
		Log_dbg_bare(2, "Current wndId index: " . i)
		j := Manager_loop(i, d, 1, wndId0)
		Log_dbg_bare(2, "Next wndId index: " . j)
		wndId := wndId%j%
		WinSet, AlwaysOnTop, On, ahk_id %wndId%
		WinSet, AlwaysOnTop, Off, ahk_id %wndId%
		If Manager_#%aWndId%_isFloating
			WinSet, Bottom, , ahk_id %aWndId%
		Manager_winActivate(wndId)
	}
}

View_updateLayout(m, v) {
	Local fn, l, wndIds
	l := View_#%m%_#%v%_layout_#1
	fn := Config_layoutFunction_#%l%
	View_updateLayout_%fn%(m, v)
}

View_addWnd(m, v, wndId) {
	Local l, msplit, i, wndIds, n
	
	l := View_#%m%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% = "tile") And ((Config_newWndPosition = "masterBottom") Or (Config_newWndPosition = "stackTop")) {
		n := View_getTiledWndIds(m, v, wndIds)
		msplit := View_#%m%_#%v%_layoutMSplit
		If ( msplit = 1 And Config_newWndPosition="masterBottom" ) {
			View_#%m%_#%v%_wndIds := wndId ";" . View_#%m%_#%v%_wndIds
		}
		Else If ( (Config_newWndPosition="masterBottom" And n < msplit) Or (Config_newWndPosition="stackTop" And n <= msplit) ) {
			View_#%m%_#%v%_wndIds .= wndId ";"
		}
		Else {
			If (Config_newWndPosition="masterBottom")
				i := msplit - 1
			Else
				i := msplit
			StringSplit, wndId, wndIds, `;
			search  := wndId%i% ";"
			replace := search wndId ";"
			StringReplace, View_#%m%_#%v%_wndIds, View_#%m%_#%v%_wndIds, %search%, %replace%
		}
	}
	Else If (Config_newWndPosition = "bottom")
		View_#%m%_#%v%_wndIds .= wndId ";"
	Else
		View_#%m%_#%v%_wndIds := wndId ";" View_#%m%_#%v%_wndIds
}

View_arrange(m, v) {
	Local fn, l, wndIds
	
	l := View_#%m%_#%v%_layout_#1
	fn := Config_layoutFunction_#%l%
	View_getTiledWndIds(m, v, wndIds)
	View_arrange_%fn%(m, v, wndIds)
	View_updateLayout(m, v)
	Bar_updateLayout(m)
}

View_getTiledWndIds(m, v, ByRef tiledWndIds) {
	Local n, wndIds
	
	StringTrimRight, wndIds, View_#%m%_#%v%_wndIds, 1
	Loop, PARSE, wndIds, `;
	{
		If Not Manager_#%A_LoopField%_isFloating And WinExist("ahk_id " A_LoopField) {
			n += 1
			tiledWndIds .= A_LoopField ";"
		}
	}
	
	Return, n
}

View_updateLayout_(m, v)
{
	View_#%m%_#%v%_layoutSymbol := "><>"
}

View_arrange_(m, v)
{
	; Place-holder
}

View_updateLayout_monocle(m, v)
{
	Local wndIds, wndId, wndId0
	StringTrimRight, wndIds, View_#%m%_#%v%_wndIds, 1
	StringSplit, wndId, wndIds, `;
	View_#%m%_#%v%_layoutSymbol := "[" wndId0 "]"
}

View_arrange_monocle(m, v, wndIds) {
	Local wndId0, gw
	
	gw := View_#%m%_#%v%_layoutGapWidth
	
	StringTrimRight, wndIds, wndIds, 1
	StringSplit, wndId, wndIds, `;
	Loop, % wndId0
	   Manager_winMove(wndId%A_Index%, Monitor_#%m%_x + gw, Monitor_#%m%_y + gw, Monitor_#%m%_width - 2*gw, Monitor_#%m%_height - 2*gw)
}

View_rotateLayoutAxis(i, d) {
	Local f, l, v
	
	v := Monitor_#%Manager_aMonitor%_aView_#1
	l := View_#%Manager_aMonitor%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% = "tile") And (i = 1 Or i = 2 Or i = 3) {
		If (i = 1) {
			If (d = +2)
				View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i% *= -1
			Else {
				f := View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i% / Abs(View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i%)
				View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i% := f * Manager_loop(Abs(View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i%), d, 1, 2)
			}
		} Else
			View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i% := Manager_loop(View_#%Manager_aMonitor%_#%v%_layoutAxis_#%i%, d, 1, 3)
		View_arrange(Manager_aMonitor, v)
	}
}

View_setGapWidth(d) {
	Local l, v, w
	
	v := Monitor_#%Manager_aMonitor%_aView_#1
	l := View_#%Manager_aMonitor%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% = "tile") {
        If (d < 0)
            d := Floor(d / 2) * 2
        Else
            d := Ceil(d / 2) * 2
        w := View_#%Manager_aMonitor%_#%v%_layoutGapWidth + d
		If (w >= 0 And w < Monitor_#%Manager_aMonitor%_height And w < Monitor_#%Manager_aMonitor%_width) {
			View_#%Manager_aMonitor%_#%v%_layoutGapWidth := w
			View_arrange(Manager_aMonitor, v)
		}
	}
}

View_setLayout(l) {
	Local v
	
	v := Monitor_#%Manager_aMonitor%_aView_#1
	If (l = -1)
		l := View_#%Manager_aMonitor%_#%v%_layout_#2
	If (l = ">")
		l := Manager_loop(View_#%Manager_aMonitor%_#%v%_layout_#1, +1, 1, Config_layoutCount)
	If (l > 0) And (l <= Config_layoutCount) {
		If Not (l = View_#%Manager_aMonitor%_#%v%_layout_#1) {
			View_#%Manager_aMonitor%_#%v%_layout_#2 := View_#%Manager_aMonitor%_#%v%_layout_#1
			View_#%Manager_aMonitor%_#%v%_layout_#1 := l
		}
		View_arrange(Manager_aMonitor, v)
	}
}

View_setMFactor(d) {
	Local l, mfact, v
	
	v := Monitor_#%Manager_aMonitor%_aView_#1
	l := View_#%Manager_aMonitor%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% = "tile") {
		mfact := 0
		If (d >= 1.05)
			mfact := d
		Else
			mfact := View_#%Manager_aMonitor%_#%v%_layoutMFact + d
		If (mfact >= 0.05 And mfact <= 0.95) {
			View_#%Manager_aMonitor%_#%v%_layoutMFact := mfact
			View_arrange(Manager_aMonitor, v)
		}
	}
}

View_setMSplit(d) {
	Local l, n, v, wndIds
	
	v := Monitor_#%Manager_aMonitor%_aView_#1
	l := View_#%Manager_aMonitor%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% = "tile") {
		n := View_getTiledWndIds(Manager_aMonitor, v, wndIds)
		View_#%Manager_aMonitor%_#%v%_layoutMSplit := Manager_loop(View_#%Manager_aMonitor%_#%v%_layoutMSplit, d, 1, n)
		View_arrange(Manager_aMonitor, v)
	}
}

View_shuffleWindow(d) {
	Local aWndHeight, aWndId, aWndWidth, aWndX, aWndY, i, j, l, search, v, wndId0, wndIds
	
	WinGet, aWndId, ID, A
	v := Monitor_#%Manager_aMonitor%_aView_#1
	l := View_#%Manager_aMonitor%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% = "tile" And InStr(Manager_managedWndIds, aWndId ";")) {
		View_getTiledWndIds(Manager_aMonitor, v, wndIds)
		StringTrimRight, wndIds, wndIds, 1
		StringSplit, wndId, wndIds, `;
		If (wndId0 > 1) {
			Loop, % wndId0
				If (wndId%A_Index% = aWndId) {
					i := A_Index
					Break
				}
			If (d = 0 And i = 1)
				j := 2
			Else
				j := Manager_loop(i, d, 1, wndId0)
			If (j > 0 And j <= wndId0) {
				If (j = i) {
					StringReplace, View_#%Manager_aMonitor%_#%v%_wndIds, View_#%Manager_aMonitor%_#%v%_wndIds, %aWndId%`;, 
					View_#%Manager_aMonitor%_#%v%_wndIds := aWndId ";" View_#%Manager_aMonitor%_#%v%_wndIds
				} Else {
					search := wndId%j%
					StringReplace, View_#%Manager_aMonitor%_#%v%_wndIds, View_#%Manager_aMonitor%_#%v%_wndIds, %aWndId%, SEARCH
					StringReplace, View_#%Manager_aMonitor%_#%v%_wndIds, View_#%Manager_aMonitor%_#%v%_wndIds, %search%, %aWndId%
					StringReplace, View_#%Manager_aMonitor%_#%v%_wndIds, View_#%Manager_aMonitor%_#%v%_wndIds, SEARCH, %search%
				}
				View_arrange(Manager_aMonitor, v)
				
				If Config_mouseFollowsFocus {
					WinGetPos, aWndX, aWndY, aWndWidth, aWndHeight, ahk_id %aWndId%
					DllCall("SetCursorPos", "Int", Round(aWndX + aWndWidth / 2), "Int", Round(aWndY + aWndHeight / 2))
				}
			}
		}
	}
}

View_updateLayout_tile(m, v) {
	Local axis1, axis2, axis3, msplit, sym1, sym3, master_div, master_dim, master_sym, stack_sym
	
	; Main axis
	; 1 - vertical divider, master left
	; 2 - horizontal divider, master top
	; -1 - vertical divider, master right
	; -2 - horizontal divider, master bottom
	axis1  := View_#%m%_#%v%_layoutAxis_#1
	; Master axis
	; 1 - vertical divider
	; 2 - horizontal divider
	; 3 - monocle
	axis2  := View_#%m%_#%v%_layoutAxis_#2
	; Stack axis
	; 1 - vertical divider
	; 2 - horizontal divider
	; 3 - monocle
	axis3  := View_#%m%_#%v%_layoutAxis_#3
	msplit := View_#%m%_#%v%_layoutMSplit
	
	If ( Abs(axis1) = 1 )
		master_div := "|"
	Else
		master_div := "="
	
	If ( axis2 = 1 ) {
		master_sym := "|"
		master_dim := "" . msplit . "x1"
	}
	Else If ( axis2 = 2 ) {
		master_sym := "-"
		master_dim := "1x" . msplit
	}
	Else 
		master_sym := "[" . msplit . "]"
	
	If ( axis3 = 1 )
		stack_sym := "|"
	Else If ( axis3 = 2 )
		stack_sym := "-"
	Else
		stack_sym := "o"
	
	If ( axis1 > 0 )
		View_#%m%_#%v%_layoutSymbol := master_dim . master_sym . master_div . stack_sym
	Else
		View_#%m%_#%v%_layoutSymbol := stack_sym . master_div . master_sym . master_dim
}

View_arrange_tile(m, v, wndIds) {
	Local axis1, axis2, axis3, gapW, gapW_2, h1, h2, i, mfact, msplit, n1, n2, w1, w2, wndId0, x1, x2, y1, y2, oriented
	
	StringTrimRight, wndIds, wndIds, 1
	StringSplit, wndId, wndIds, `;
	Log_dbg_msg(1, "View_arrange_tile: (" . wndId0 . ") " . wndIds)
	If (wndId0 = 0)
		Return

	axis1  := Abs(View_#%m%_#%v%_layoutAxis_#1)
	axis2  := View_#%m%_#%v%_layoutAxis_#2
	axis3  := View_#%m%_#%v%_layoutAxis_#3
	oriented := View_#%m%_#%v%_layoutAxis_#1 > 0
	gapW   := View_#%m%_#%v%_layoutGapWidth
	gapW_2 := gapW/2
	mfact  := View_#%m%_#%v%_layoutMFact
	msplit := View_#%m%_#%v%_layoutMSplit

	If (msplit > wndId0) {
		msplit := wndId0
	}
	
	; master and stack area
	h1 := Monitor_#%m%_height - gapW
	h2 := h1
	w1 := Monitor_#%m%_width - gapW
	w2 := w1
	x1 := Monitor_#%m%_x + gapW_2
	x2 := x1
	y1 := Monitor_#%m%_y + gapW_2
	y2 := y1
	If (wndId0 > msplit) {
		If (axis1 = 1) {
			w1 *= mfact
			w2 -= w1
			If (Not oriented)
				x1 += w2
			Else
				x2 += w1
		} Else If (axis1 = 2) {
			h1 *= mfact
			h2 -= h1
			If (Not oriented)
				y1 += h2
			Else
				y2 += h1
		}
	}
	
	; master
	If (axis2 != 1 Or w1 / msplit < 161)
		n1 := w1
	Else
		n1 := w1/msplit
	If (axis2 != 2 Or h1 / msplit < Bar_height)
		n2 := h1
	Else
		n2 := h1/msplit
	Loop, % msplit {
		Manager_winMove(wndId%A_Index%, x1 + gapW_2, y1 + gapW_2, n1 - gapW, n2 - gapW)
		If (n1 < w1)
			x1 += n1
		If (n2 < h1)
			y1 += n2
	}
	
	; stack
	If (wndId0 > msplit) {
		If (axis3 != 1 Or w2 / (wndId0 - msplit) < 161)
			n1 := w2
		Else
			n1 := w2/(wndId0 - msplit)
		If (axis3 != 2 Or h2 / (wndId0 - msplit) < Bar_height)
			n2 := h2
		Else
			n2 := h2/(wndId0 - msplit)
		Loop, % wndId0 - msplit {
			i := msplit + A_Index
			Manager_winMove(wndId%i%, x2 + gapW_2, y2 + gapW_2, n1 - gapW, n2 - gapW)
			If (n1 < w2)
				x2 += n1
			If (n2 < h2)
				y2 += n2
		}
	}
}

View_toggleFloating() {
	Local aWndId, l, v
	
	WinGet, aWndId, ID, A
	v := Monitor_#%Manager_aMonitor%_aView_#1
	l := View_#%Manager_aMonitor%_#%v%_layout_#1
	If (Config_layoutFunction_#%l% And InStr(Manager_managedWndIds, aWndId ";")) {
		Manager_#%aWndId%_isFloating := Not Manager_#%aWndId%_isFloating
		View_arrange(Manager_aMonitor, v)
		Bar_updateTitle()
	}
}
