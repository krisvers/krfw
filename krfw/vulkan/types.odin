package krfw_vulkan

import "../../krfw"
import vk "vendor:vulkan"

InstanceKHRFunctions :: struct {
    surface: InstanceSurfaceKHRFunctionPointers,
}

InstanceEXTFunctions :: struct {
    debugUtils: InstanceDebugUtilsEXTFunctionPointers,
}

InstanceFunctions :: struct {
    using _: InstanceFunctionPointers,
    khr: InstanceKHRFunctions,
    ext: InstanceEXTFunctions,
}

Instance :: struct {
    instance: vk.Instance,
    using _: InstanceFunctions,
}

DeviceKHRFunctions :: struct {
    swapchain: DeviceSwapchainKHRFunctionPointers,
    dynamicRendering: DeviceDynamicRenderingKHRFunctionPointers,
}

DeviceEXTFunctions :: struct {

}

DeviceFunctions :: struct {
    using _: DeviceFunctionPointers,
    khr: DeviceKHRFunctions,
    ext: DeviceEXTFunctions,
}

Device :: struct {
    device: vk.Device,
    using _: DeviceFunctions,
}

Packet :: struct {
    instance: ^Instance,
    device: ^Device,

}

Pass :: struct #raw_union {
    #subtype ipass: krfw.IPass,
    execute: proc "c" (this: ^Pass, packet: ^Packet) -> b32,
}

Renderer :: struct #raw_union {
    #subtype irenderer: krfw.IRenderer,
}