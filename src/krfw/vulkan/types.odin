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
    using instanceFunctionPointers:     InstanceFunctionPointers,
    using instance11FunctionPointers:   Instance11FunctionPointers,
    khr:                                InstanceKHRFunctions,
    ext:                                InstanceEXTFunctions,
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
    using deviceFunctionPointers:       DeviceFunctionPointers,
    using device11FunctionsPointers:    Device11FunctionPointers,
    using device12FunctionsPointers:    Device12FunctionPointers,
    khr:                                DeviceKHRFunctions,
    ext:                                DeviceEXTFunctions,
}

Device :: struct {
    physical:   vk.PhysicalDevice,
    logical:    vk.Device,
    using _:    DeviceFunctions,
}

Queue :: struct {
    queue:  vk.Queue,
    family: u32,
    index:  u32,
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

RendererBuffers :: struct {
    _debugLoggerBuffer: [2048]u8,
    _driverPreference:  [vk.MAX_DRIVER_NAME_SIZE]u8,
}

WSI :: struct {
    window:     krfw.Window,

    setting:    krfw.WSISetting,
    surface:    vk.SurfaceKHR,
}

Renderer :: struct {
    /* inherited components */
    using irenderer:    krfw.IRenderer,
    using _:            RendererVTable,

    /* pre-init members */
    _debugLogger:               krfw.ProcDebugLogger,
    _debugLoggerLowestSeverity: krfw.DebugSeverity,
    _ctx:                       runtime.Context,
    _library:                   dynlib.Library,
    _globalFunctions:           GlobalFunctionPointers,
    using _buffers:             ^RendererBuffers,

    /* pre-init, destroyed at the end of init */
    _areWindowsQueued:  bool,
    _queuedWindows:     [dynamic]WSI,

    /* init members */
    _headless:  bool,
    _debug:     bool,
    _allocator: ^vk.AllocationCallbacks,
    _instance:  Instance,
    _wsis:      map[krfw.Window]WSI,
    _device:    Device,

    /* note: queues may be aliases of one another */
    _generalQueue:  Queue,
    _presentQueue:  Queue,
    _graphicsQueue: Queue,
    _transferQueue: Queue,
    _computeQueue:  Queue,
}

/* pre-init functions */
ProcRendererLoadVulkanLoaderOdin    :: #type proc "c" (this: ^Renderer, path: string) -> b32
ProcRendererLoadVulkanLoader        :: #type proc "c" (this: ^Renderer, len: u32, path: cstring) -> b32
ProcRendererLoadVulkanLoaderUTF32   :: #type proc "c" (this: ^Renderer, len: u32, path: [^]rune) -> b32

ProcRendererSetDriverPreferenceOdin :: #type proc "c" (this: ^Renderer, driver: string)
ProcRendererSetDriverPreference     :: #type proc "c" (this: ^Renderer, len: u32, driver: cstring)

ProcRendererSetAllocator            :: #type proc "c" (this: ^Renderer, allocator: ^vk.AllocationCallbacks)

RendererVTable :: struct {
    loadVulkanLoaderOdin:       ProcRendererLoadVulkanLoaderOdin,
    loadVulkanLoader:           ProcRendererLoadVulkanLoader,
    loadVulkanLoaderUnicode:    ProcRendererLoadVulkanLoaderUTF32,

    setDriverPreferenceOdin:    ProcRendererSetDriverPreferenceOdin,
    setDriverPreference:        ProcRendererSetDriverPreference,

    setAllocator:               ProcRendererSetAllocator,
}