package demo

import "base:runtime"

import "core:fmt"

import krfw "krfw"
import krfw_vk "krfw/vulkan"

import "vendor:sdl3"

main :: proc() {
    if !sdl3.Init({ .VIDEO }) {
        panic("SDL3 Init")
    }

    window := sdl3.CreateWindow("krfw demo", 800, 600, {})
    if window == nil {
        panic("SDL3 window creation")
    }

    renderer: krfw_vk.Renderer
    krfw_vk.instantiateRenderer(&renderer)

    renderer->setDebugLogger(proc "c" (severity: krfw.DebugSeverity, originLen: u32, origin: cstring, messageLen: u32, message: cstring) {
        context = runtime.default_context()
        fmt.printfln("[%s] (%s): %s", severity, origin, message)
    }, krfw.DebugSeverity.Verbose)

    if !renderer->createWSI(&{
        nativeWindowHandle = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_COCOA_WINDOW_POINTER, nil),
        nativeWindowType = .Cocoa,
    }, .Mailbox) {
        panic("Renderer create WSI")
    }

    if !renderer->init(debug = true) {
        panic("Failed to initialize renderer")
    }

    fencePool := renderer->getDefaultFencePool()

    running := true
    for running {
        event: sdl3.Event
        for sdl3.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    running = false
            }
        }
    }

    renderer->destroyWSI(&{
        nativeWindowHandle = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_COCOA_WINDOW_POINTER, nil),
        nativeWindowType = .Cocoa,
    })

    renderer->destroy()
}