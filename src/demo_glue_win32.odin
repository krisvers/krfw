#+build windows
package demo

import "krfw"
import "vendor:sdl3"
import win32 "core:sys/windows"

getKRFWWindow :: proc(window: ^sdl3.Window) -> krfw.Window {
    return {
        nativeWindowHandle = krfw.NativeWindowHandle(sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WIN32_HWND_POINTER, nil)),
        nativeDisplayHandle = krfw.NativeDisplayHandle(win32.GetModuleHandleA(nil)),
        nativeWindowType = .Win32,
    }
}