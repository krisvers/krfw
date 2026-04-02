package demo

import "core:fmt"

import krfw "krfw"
import krfw_vk "krfw/vulkan"

main :: proc() {
    renderer: krfw_vk.Renderer
    krfw_vk.instantiateRenderer(&renderer)

    pRenderer: ^krfw_vk.Renderer

    if !pRenderer->init(true) {
        panic("Failed to initialize renderer")
    }



    pRenderer->destroy()
}