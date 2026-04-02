package demo

import krfw "krfw"
import krfw_vk "krfw/vulkan"

main :: proc() {
    krfw_vk.loadInstanceFunctions(nil, nil, nil)
}