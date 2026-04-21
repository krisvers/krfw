#+build linux, freebsd, openbsd
package demo

import "krfw"
import "vendor:sdl3"

getKRFWWindow :: proc(window: ^sdl3.Window) -> krfw.Window {
    #panic("todo")
    return {}
}