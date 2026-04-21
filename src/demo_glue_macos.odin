#+build darwin
package demo

import "krfw"
import "vendor:sdl3"

getKRFWWindow :: proc(window: ^sdl3.Window) -> krfw.Window {
    when ODIN_OS == .Windows {
        return {
            nativeWindowHandle = krfw.NativeWindowHandle(sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_COCOA_WINDOW_POINTER, nil)),
            nativeWindowType = .Cocoa,
        }
    }
}