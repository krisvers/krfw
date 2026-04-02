package krfw_vulkan

import "base:runtime"
import "core:dynlib"

import "../../krfw"
import vk "vendor:vulkan"

InstanceKHRFunctions :: struct {
    surface: InstanceSurfaceKHRFunctionPointers,
}

InstanceEXTFunctions :: struct {
    debugUtils: InstanceDebugUtilsEXTFunctionPointers,
}

InstanceFunctions :: struct {
    using _:    InstanceFunctionPointers,
    khr:        InstanceKHRFunctions,
    ext:        InstanceEXTFunctions,
}

Instance :: struct {
    instance:   vk.Instance,
    using _:    InstanceFunctions,
}

DeviceKHRFunctions :: struct {
    swapchain:          DeviceSwapchainKHRFunctionPointers,
    dynamicRendering:   DeviceDynamicRenderingKHRFunctionPointers,
}

DeviceEXTFunctions :: struct {

}

DeviceFunctions :: struct {
    using _:    DeviceFunctionPointers,
    khr:        DeviceKHRFunctions,
    ext:        DeviceEXTFunctions,
}

Device :: struct {
    physical:   vk.PhysicalDevice,
    logical:    vk.Device,
    using _:    DeviceFunctions,
}

SubmitInfoWait :: struct {
    semaphore:      vk.Semaphore,
    dstStageMask:   vk.PipelineStageFlags,
}

ProcPacketAddSyncObjects :: #type proc "c" (renderer: ^Renderer, submitInfoWaitCount: u32, submitInfoWait: [^]SubmitInfoWait, signalCount: u32, signals: [^]vk.Semaphore)

Packet :: struct {
    renderer:   ^Renderer,
    instance:   ^Instance,
    device:     ^Device,

    addSyncObjects: ProcPacketAddSyncObjects,
}

Pass :: struct {
    /* inherited components */
    #subtype ipass: krfw.IPass,
    using _:        PassVTable,
}

ProcPassExecute :: #type proc "c" (this: ^Pass, packet: ^Packet) -> b32

PassVTable :: struct {
    execute: ProcPassExecute,
}

Renderer :: struct {
    /* inherited components */
    using irenderer:    krfw.IRenderer,
    using _:            RendererVTable,

    /* pre-init members */
    _debugLogger:       krfw.ProcDebugLogger,
    _ctx:               runtime.Context,
    _libraryPath:       string,

    _debug:     bool,
    _library:   dynlib.Library,
    _allocator: ^vk.AllocationCallbacks,
    _instance:  Instance,
    _device:    Device,
}

ProcRendererSetVulkanLoaderPath         :: #type proc "c" (this: ^Renderer, len: u32, path: [^]u8)
ProcRendererSetVulkanLoaderPathUnicode  :: #type proc "c" (this: ^Renderer, len: u32, path: [^]rune)

RendererVTable :: struct {
    setVulkanLoaderPath:        ProcRendererSetVulkanLoaderPath,
    setVulkanLoaderPathUnicode: ProcRendererSetVulkanLoaderPathUnicode,
}