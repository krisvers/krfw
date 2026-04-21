package krfw_vulkan

import "base:runtime"
import "core:dynlib"

import "../../krfw"
import vk "vendor:vulkan"
import "vma"

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
    General     = 0,
    Graphics    = 1,
    Transfer    = 2,
    Compute     = 3,
    Present     = 4,
    
    Invalid     = 31,
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

SubmitInfoWait :: struct {
    semaphore:      vk.Semaphore,
    dstStageMask:   vk.PipelineStageFlags,
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

/* backbuffer pool */
Backbuffer :: struct {
    index:          u32,
    image:          vk.Image,
    imageView:      vk.ImageView,

    surfaceFormat:  vk.SurfaceFormatKHR,
    extent:         vk.Extent2D,
    layerCount:     u32,
    
    fence:          vk.Fence,
    semaphore:      vk.Semaphore,
}

BackbufferPoolAcquisitionModeValues :: enum u32 {
    Fence = 0,
    Semaphore = 1,
}

BackbufferPoolAcquisitionMode :: bit_set[BackbufferPoolAcquisitionModeValues; u32]

BackbufferPool :: struct {
    using _: BackbufferPoolVTable,

    _renderer:      ^Renderer,
    _window:        krfw.Window,
    _setting:       krfw.WSISetting,
    _surface:       vk.SurfaceKHR,

    _swapchain:     vk.SwapchainKHR,
    _fencePool:     ^FencePool,
    _semaphorePool: ^SemaphorePool,
    _backbuffers:   []Backbuffer,
}

ProcBackbufferPoolAcquire :: #type proc "c" (this: ^BackbufferPool, mode: BackbufferPoolAcquisitionMode) -> ^Backbuffer
ProcBackbufferPoolRelease :: #type proc "c" (this: ^BackbufferPool, backbuffer: ^Backbuffer)

BackbufferPoolVTable :: struct {
    acquire: ProcBackbufferPoolAcquire,
    release: ProcBackbufferPoolRelease,
}

/* packet */
BackbufferPacket :: struct {
    backbuffer: ^Backbuffer,
    lastStage:  vk.PipelineStageFlags,
    lastLayout: vk.ImageLayout,
}

Packet :: struct {
    using _: PacketVTable,

    renderer:           ^Renderer,
    queue:              ^Queue,
    commandPool:        ^CommandPool,
    commandBuffer:      vk.CommandBuffer,
    backbufferPacket:   ^BackbufferPacket,

    _submitInfoWaits:   ^[dynamic]SubmitInfoWait,
    _signalSemaphores:  ^[dynamic]vk.Semaphore,
}

ProcPacketAddSyncObjects :: #type proc "c" (this: ^Packet, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore)

PacketVTable :: struct {
    addSyncObjects: ProcPacketAddSyncObjects,
}

/* pass implementation */
Pass :: struct {
    /* inherited components */
    using ipass:    krfw.IPass,
    using _:        PassVTable,
}

ProcPassExecute :: #type proc "c" (this: ^Pass, packet: ^Packet) -> b32

PassVTable :: struct {
    execute: ProcPassExecute,
}

/* internal use only */
_RendererBuffers :: struct {
    _driverPreference:  [vk.MAX_DRIVER_NAME_SIZE]u8,
}

_QueuedWindow :: struct {
    window:     krfw.Window,
    setting:    krfw.WSISetting,
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
    _allocator:                 ^vk.AllocationCallbacks,
    _globalFunctions:           GlobalFunctionPointers,
    using _buffers:             ^_RendererBuffers,

    /* pre-init, destroyed at the end of init */
    _areWindowsQueued:  bool,
    _queuedWindows:     [dynamic]_QueuedWindow,

    /* init members */
    _headless:          bool,
    _debug:             bool,
    _instance:          Instance,
    _device:            Device,
    _vma:               vma.Allocator,
    _backbufferPools:   map[krfw.Window]BackbufferPool,

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

ProcRendererGetAllocator    :: #type proc "c" (this: ^Renderer) -> ^vk.AllocationCallbacks
ProcRendererGetInstance     :: #type proc "c" (this: ^Renderer) -> ^Instance
ProcRendererGetDevice       :: #type proc "c" (this: ^Renderer) -> ^Device

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

    getAllocator:               ProcRendererGetAllocator,
    getInstance:                ProcRendererGetInstance,
    getDevice:                  ProcRendererGetDevice,
}