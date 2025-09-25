#Requires AutoHotkey v2.0
; SwapScreens.ahk  (AutoHotkey v2)
; Hotkey: Ctrl+Alt+S → 把兩個螢幕上的視窗等比例互換

myHotkey := "^!s"
Hotkey(myHotkey, (*) => SwapAllWindowsBetweenTwoMonitors())

SwapAllWindowsBetweenTwoMonitors() {
    if (MonitorGetCount() != 2) {
        MsgBox "偵測到的顯示器數量不是 2。此腳本僅支援兩螢幕交換。"
        return
    }

    MonitorGetWorkArea(1, &l1, &t1, &r1, &b1)
    MonitorGetWorkArea(2, &l2, &t2, &r2, &b2)
    srcA := {L:l1, T:t1, R:r1, B:b1, W:(r1-l1), H:(b1-t1)}
    srcB := {L:l2, T:t2, R:r2, B:b2, W:(r2-l2), H:(b2-t2)}

    for hwnd in WinGetList() {
        ; 排除不適合移動的視窗
        try {
            if (WinGetMinMax(hwnd) = -1)  ; 最小化
                continue
            if !WinGetTitle(hwnd)         ; 無標題（多為系統/工具）
                continue
            if !IsWindowVisible(hwnd)     ; 不可見
                continue
            if (WinGetExStyle(hwnd) & 0x00000080) ; WS_EX_TOOLWINDOW
                continue
        } catch Any as e {
            continue
        }

        ; 取得座標（若失敗，略過）
        try {
            WinGetPos(&x, &y, &w, &h, hwnd)
        } catch Any as e {
            continue
        }

        cx := x + w/2
        cy := y + h/2

        if PointInRect(cx, cy, srcA) {
            MoveWindowProportional(hwnd, x, y, w, h, srcA, srcB)
        } else if PointInRect(cx, cy, srcB) {
            MoveWindowProportional(hwnd, x, y, w, h, srcB, srcA)
        } else if PointInRect(x, y, srcA) {
            MoveWindowProportional(hwnd, x, y, w, h, srcA, srcB)
        } else if PointInRect(x, y, srcB) {
            MoveWindowProportional(hwnd, x, y, w, h, srcB, srcA)
        }
    }
}

MoveWindowProportional(hwnd, x, y, w, h, src, dst) {
    state := WinGetMinMax(hwnd) ; 1=Maximized, 0=Normal
    if (state = 1)
        WinRestore hwnd

    nx := dst.L + Round((x - src.L) * dst.W / src.W)
    ny := dst.T + Round((y - src.T) * dst.H / src.H)
    nw := Max(50, Round(w * dst.W / src.W))
    nh := Max(50, Round(h * dst.H / src.H))

    try {
        WinMove nx, ny, nw, nh, hwnd
    } catch Any as e {
        return
    }
    if (state = 1)
        WinMaximize hwnd
}

PointInRect(x, y, r) => (x >= r.L && x <= r.R && y >= r.T && y <= r.B)

IsWindowVisible(hwnd) {
    try {
        ; WS_VISIBLE = 0x10000000
        return (WinGetStyle(hwnd) & 0x10000000) != 0
    } catch Any as e {
        return false
    }
}
