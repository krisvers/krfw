package krfw_vulkan

import "base:runtime"
import "core:dynlib"

import "../../krfw"
import vk "vendor:vulkan"

/* instance function pointer management */
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

/* instance management */
Instance :: struct {
    instance:   vk.Instance,
    using _:    InstanceFunctions,
}

/* device function pointer management */
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

/* device management */
Device :: struct {
    physical:   vk.PhysicalDevice,
    logical:    vk.Device,
    using _:    DeviceFunctions,
}

/* queue management */
QueueType :: enum u32 {
    General = 0,
    Graphics = 1,
    Transfer = 2,
    Compute = 3,
    Present = 4,
    
    Invalid = 31,
}

QueueTypeMask :: bit_set[QueueType; u32]

Queue :: struct {
    queue:          vk.Queue,
    family:         u32,
    index:          u32,
    intendedTypes:  QueueTypeMask,
    supportedTypes: QueueTypeMask,
    commandPool:    CommandPool,
}

SubmitInfoWait :: struct {
    semaphore:      vk.Semaphore,
    dstStageMask:   vk.PipelineStageFlags,
}

/* packet */
ProcPacketAddSyncObjects :: #type proc "c" (renderer: ^Renderer, submitInfoWaitCount: u32, submitInfoWait: [^]SubmitInfoWait, signalCount: u32, signals: [^]vk.Semaphore)

Packet :: struct {
    renderer:   ^Renderer,
    instance:   ^Instance,
    device:     ^Device,

    addSyncObjects: ProcPacketAddSyncObjects,
}

/* pass implementation */
Pass :: struct {
    /* inherited components */
    #subtype ipass: krfw.IPass,
    using _:        PassVTable,
}

ProcPassExecute :: #type proc "c" (this: ^Pass, packet: ^Packet) -> b32

PassVTable :: struct {
    execute: ProcPassExecute,
}

/* wsi management (surface, swapchain and backbuffers) */
WSI :: struct {
    window:     krfw.Window,

    setting:    krfw.WSISetting,
    surface:    vk.SurfaceKHR,
}

/* fence pool */
FencePool :: struct {
    using _: FencePoolVTable,

    /* members */
    _renderer:              ^Renderer,
    _fences:                [dynamic]vk.Fence,
    _unusedFenceIndices:    [dynamic]u32,

    _isInternal: b32,
}

ProcFencePoolDestroy    :: #type proc "c" (this: ^FencePool)
ProcFencePoolAcquire    :: #type proc "c" (this: ^FencePool, signaled := b32(false)) -> vk.Fence
ProcFencePoolRelease    :: #type proc "c" (this: ^FencePool, fence: vk.Fence)

FencePoolVTable :: struct {
    destroy: ProcFencePoolDestroy,
    acquire: ProcFencePoolAcquire,
    release: ProcFencePoolRelease,
}

/* semaphore pool */
SemaphorePool :: struct {
    using _: SemaphorePoolVTable,

    /* members */
    _renderer:                  ^Renderer,
    _semaphores:                [dynamic]vk.Semaphore,
    _unusedSemaphoreIndices:    [dynamic]u32,

    _isInternal: b32,
}

ProcSemaphorePoolDestroy    :: #type proc "c" (this: ^SemaphorePool)
ProcSemaphorePoolAcquire    :: #type proc "c" (this: ^SemaphorePool) -> vk.Semaphore
ProcSemaphorePoolRelease    :: #type proc "c" (this: ^SemaphorePool, fence: vk.Semaphore)

SemaphorePoolVTable :: struct {
    destroy: ProcSemaphorePoolDestroy,
    acquire: ProcSemaphorePoolAcquire,
    release: ProcSemaphorePoolRelease,
}

/* command pool */
CommandPool :: struct {
    using _: CommandPoolVTable,

    /* members */
    _renderer:      ^Renderer,
    _queue:         ^Queue,
    _fencePool:     ^FencePool,
    _commandPool:   vk.CommandPool,

    _commandBuffers:                [dynamic]vk.CommandBuffer,
    _unusedCommandBufferIndices:    [dynamic]u32,

    _isInternal: b32,
}

ProcCommandPoolDestroy  :: #type proc "c" (this: ^CommandPool)
ProcCommandPoolGetQueue :: #type proc "c" (this: ^CommandPool) -> ^Queue
ProcCommandPoolAcquire  :: #type proc "c" (this: ^CommandPool, bundle := b32(false)) -> vk.CommandBuffer
ProcCommandPoolSubmit   :: #type proc "c" (this: ^CommandPool, commandBuffer: vk.CommandBuffer, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore) -> vk.Fence
ProcCommandPoolRelease  :: #type proc "c" (this: ^CommandPool, commandBuffer: vk.CommandBuffer, fence: vk.Fence)

CommandPoolVTable :: struct {
    destroy:    ProcCommandPoolDestroy,
    getQueue:   ProcCommandPoolGetQueue,
    acquire:    ProcCommandPoolAcquire,
    submit:     ProcCommandPoolSubmit,
    release:    ProcCommandPoolRelease,
}

/* internal use only */
_RendererBuffers :: struct {
    _debugLoggerBuffer: [2048]u8,
    _driverPreference:  [vk.MAX_DRIVER_NAME_SIZE]u8,
}

/* renderer backend */
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
    using _buffers:             ^_RendererBuffers,

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
    _queues:    []Queue,

    _generalQueue:  ^Queue,
    _presentQueue:  ^Queue,
    _graphicsQueue: ^Queue,
    _transferQueue: ^Queue,
    _computeQueue:  ^Queue,

    /* pools */
    _defaultFencePool:      FencePool,
    _defaultSemaphorePool:  SemaphorePool,

    /* other state */
    _performingDestruction: b32,
}

/* Renderer pre-init functions */
ProcRendererLoadVulkanLoaderOdin    :: #type proc "c" (this: ^Renderer, path: string) -> b32
ProcRendererLoadVulkanLoader        :: #type proc "c" (this: ^Renderer, len: u32, path: cstring) -> b32
ProcRendererLoadVulkanLoaderUTF32   :: #type proc "c" (this: ^Renderer, len: u32, path: [^]rune) -> b32
ProcRendererSetDriverPreferenceOdin :: #type proc "c" (this: ^Renderer, driver: string)
ProcRendererSetDriverPreference     :: #type proc "c" (this: ^Renderer, len: u32, driver: cstring)
ProcRendererSetAllocator            :: #type proc "c" (this: ^Renderer, allocator: ^vk.AllocationCallbacks)

/* Renderer Vulkan interface functions */
ProcRendererCreateFencePool     :: #type proc "c" (this: ^Renderer, fencePool: ^FencePool) -> b32
ProcRendererCreateSemaphorePool :: #type proc "c" (this: ^Renderer, semaphorePool: ^SemaphorePool) -> b32
ProcRendererCreateCommandPool   :: #type proc "c" (this: ^Renderer, commandPool: ^CommandPool, fencePool: ^FencePool, queue: ^Queue) -> b32

ProcRendererGetDefaultFencePool     :: #type proc "c" (this: ^Renderer) -> ^FencePool
ProcRendererGetDefaultSemaphorePool :: #type proc "c" (this: ^Renderer) -> ^SemaphorePool
ProcRendererGetDefaultCommandPool   :: #type proc "c" (this: ^Renderer, queueType: QueueType) -> ^CommandPool

RendererVTable :: struct {
    /* pre-init */
    loadVulkanLoaderOdin:       ProcRendererLoadVulkanLoaderOdin,
    loadVulkanLoader:           ProcRendererLoadVulkanLoader,
    loadVulkanLoaderUnicode:    ProcRendererLoadVulkanLoaderUTF32,
    setDriverPreferenceOdin:    ProcRendererSetDriverPreferenceOdin,
    setDriverPreference:        ProcRendererSetDriverPreference,
    setAllocator:               ProcRendererSetAllocator,

    /* Vulkan interface */
    createFencePool:            ProcRendererCreateFencePool,
    createSemaphorePool:        ProcRendererCreateSemaphorePool,
    createCommandPool:          ProcRendererCreateCommandPool,

    getDefaultFencePool:        ProcRendererGetDefaultFencePool,
    getDefaultSemaphorePool:    ProcRendererGetDefaultSemaphorePool,
    getDefaultCommandPool:      ProcRendererGetDefaultCommandPool,
}