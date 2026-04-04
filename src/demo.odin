package demo

import "base:runtime"

import "core:fmt"

import krfw "krfw"
import krfw_vk "krfw/vulkan"

main :: proc() {
    renderer: krfw_vk.Renderer
    krfw_vk.instantiateRenderer(&renderer)

    pRenderer := &renderer
    pRenderer->setDebugLogger(proc "c" (severity: krfw.DebugSeverity, originLen: u32, origin: cstring, messageLen: u32, message: cstring) {
        context = runtime.default_context()
        fmt.printfln("[%s] (%s): %s", severity, origin, message)
    }, krfw.DebugSeverity.Verbose)

    if !pRenderer->init(true) {
        panic("Failed to initialize renderer")
    }



    pRenderer->destroy()
}