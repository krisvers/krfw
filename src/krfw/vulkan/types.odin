package krfw_vulkan

import "base:runtime"
import "core:dynlib"

import "../kom"
import "../../krfw"

import vk "vendor:vulkan"
import "vma"

/* general types */
QueueType :: enum u32 {
    General     = 0,
    Graphics    = 1,
    Transfer    = 2,
    Compute     = 3,
    Present     = 4,
    
    Invalid     = 31,
}

QueueTypeMask :: bit_set[QueueType; u32]

SubmitInfoWait :: struct {
    semaphore:      vk.Semaphore,
    dstStageMask:   vk.PipelineStageFlags,
}

BackbufferAcquisitionSyncValues :: enum u32 {
    Fence = 0,
    Semaphore = 1,
}

BackbufferAcquisitionSync :: bit_set[BackbufferAcquisitionSyncValues; u32]

BackbufferInfo :: struct {
    index:          u32,
    image:          ^IVkImage,
    imageView:      vk.ImageView,

    surfaceFormat:  vk.SurfaceFormatKHR,
    extent:         vk.Extent2D,
    layerCount:     u32,
    
    fence:          vk.Fence,
    semaphore:      vk.Semaphore,
}

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

/* IVkInstance (239cfaf2-7025-470c-9b34-4121b0885182) */
ProcIVkInstanceGetVulkanInstance :: #type proc "c" (this: ^IVkInstance) -> vk.Instance

IVkInstance_IID :: kom.IID {
    0x23, 0x9c, 0xfa, 0xf2,
    0x70, 0x25,
    0x47, 0x0c,
    0x9b, 0x34,
    0x41, 0x21, 0xb0, 0x88, 0x51, 0x82
}

IVkInstance :: struct {
    using ichild:       kom.IChild,

    getVulkanInstance:  ProcIVkInstanceGetVulkanInstance,

    using functions:    InstanceFunctions,
}

/* IVkDevice (5b54190d-3d86-4dc7-a8c9-a45278684b4a) */
ProcIVkDeviceGetVulkanPhysicalDevice    :: #type proc "c" (this: ^IVkDevice) -> vk.PhysicalDevice
ProcIVkDeviceGetVulkanLogicalDevice     :: #type proc "c" (this: ^IVkDevice) -> vk.Device

IVkDevice_IID :: kom.IID {
    0x5b, 0x54, 0x19, 0x0d,
    0x3d, 0x86,
    0x4d, 0xc7,
    0xa8, 0xc9,
    0xa4, 0x52, 0x78, 0x68, 0x4b, 0x4a
}

IVkDevice :: struct {
    using ichild:               kom.IChild,

    getVulkanPhysicalDevice:    ProcIVkDeviceGetVulkanPhysicalDevice,
    getVulkanLogicalDevice:     ProcIVkDeviceGetVulkanLogicalDevice,

    using functions:            DeviceFunctions,
}

/* IVkFence (52ebaf79-574e-4f68-8e49-c7f5da819f9e) */
ProcIVkFenceGetVulkanFence :: #type proc "c" (this: ^IVkFence) -> vk.Fence

IVkFence_IID :: kom.IID {
    0x52, 0xeb, 0xaf, 0x79,
    0x57, 0x4e,
    0x4f, 0x68,
    0x8e, 0x49,
    0xc7, 0xf5, 0xda, 0x81, 0x9f, 0x9e
}

IVkFence :: struct {
    using ichild:   kom.IChild,

    getVulkanFence: ProcIVkFenceGetVulkanFence,
}

/* IVkFencePool (3d84f39b-d915-4285-b347-3a5deb9a4a73) */
ProcIVkFencePoolAcquireFence :: #type proc "c" (this: ^IVkFencePool, signaled := b32(false)) -> ^IVkFence

IVkFencePool_IID :: kom.IID {
    0x3d, 0x84, 0xf3, 0x9b,
    0xd9, 0x15,
    0x42, 0x85,
    0xb3, 0x47,
    0x3a, 0x5d, 0xeb, 0x9a, 0x4a, 0x73
}

IVkFencePool :: struct {
    using ichild:   kom.IChild,

    acquireFence:   ProcIVkFencePoolAcquireFence,
}

/* IVkSemaphore (90c8a8fc-9cd6-4fae-a1b9-a233cdba7a0e) */
ProcIVkSemaphoreGetVulkanSemaphore :: #type proc "c" (this: ^IVkSemaphore) -> vk.Semaphore

IVkSemaphore_IID :: kom.IID {
    0x90, 0xc8, 0xa8, 0xfc,
    0x9c, 0xd6,
    0x4f, 0xae,
    0xa1, 0xb9,
    0xa2, 0x33, 0xcd, 0xba, 0x7a, 0x0e
}

IVkSemaphore :: struct {
    using ichild:       kom.IChild,

    getVulkanSemaphore: ProcIVkSemaphoreGetVulkanSemaphore,
}

/* IVkSemaphorePool (9666ab06-9679-49ed-82c3-e01ba213d76e) */
ProcIVkSemaphorePoolAcquireSemaphore :: #type proc "c" (this: ^IVkSemaphorePool) -> ^IVkSemaphore

IVkSemaphorePool_IID :: kom.IID {
    0x96, 0x66, 0xab, 0x06,
    0x96, 0x79,
    0x49, 0xed,
    0x82, 0xc3,
    0xe0, 0x1b, 0xa2, 0x13, 0xd7, 0x6e
}

IVkSemaphorePool :: struct {
    using ichild:       kom.IChild,

    acquireSemaphore:   ProcIVkSemaphorePoolAcquireSemaphore,
}

/* IVkQueue (302fc103-8440-4160-b500-51b2bd9626ab) */
ProcIVkQueueCreateCommandPool       :: #type proc "c" (this: ^IVkQueue, fencePool: ^IVkFencePool) -> ^IVkCommandPool
ProcIVkQueueGetDefaultCommandPool   :: #type proc "c" (this: ^IVkQueue) -> ^IVkCommandPool
ProcIVkQueueGetVulkanQueue          :: #type proc "c" (this: ^IVkQueue) -> vk.Queue
ProcIVkQueueGetFamily               :: #type proc "c" (this: ^IVkQueue) -> u32
ProcIVkQueueGetIndex                :: #type proc "c" (this: ^IVkQueue) -> u32
ProcIVkQueueGetIntendedTypes        :: #type proc "c" (this: ^IVkQueue) -> QueueTypeMask
ProcIVkQueueGetSupportedTypes       :: #type proc "c" (this: ^IVkQueue) -> QueueTypeMask

IVkQueue_IID :: kom.IID {
    0x30, 0x2f, 0xc1, 0x03,
    0x84, 0x40,
    0x41, 0x60,
    0xb5, 0x00,
    0x51, 0xb2, 0xbd, 0x96, 0x26, 0xab
}

IVkQueue :: struct {
    using ichild:           kom.IChild,

    createCommandPool:      ProcIVkQueueCreateCommandPool,
    getDefaultCommandPool:  ProcIVkQueueGetDefaultCommandPool,
    getVulkanQueue:         ProcIVkQueueGetVulkanQueue,
    getFamily:              ProcIVkQueueGetFamily,
    getIndex:               ProcIVkQueueGetIndex,
    getIntendedTypes:       ProcIVkQueueGetIntendedTypes,
    getSupportedTypes:      ProcIVkQueueGetSupportedTypes,
}

/* IVkCommandPool (efb61d2b-7518-4d73-b513-49215772b010) */
ProcIVkCommandPoolGetQueue              :: #type proc "c" (this: ^IVkCommandPool) -> ^IVkQueue
ProcIVkCommandPoolAcquireCommandBuffer  :: #type proc "c" (this: ^IVkCommandPool, bundle := b32(false)) -> ^IVkCommandBuffer

IVkCommandPool_IID :: kom.IID {
    0xef, 0xb6, 0x1d, 0x2b,
    0x75, 0x18,
    0x4d, 0x73,
    0xb5, 0x13,
    0x49, 0x21, 0x57, 0x72, 0xb0, 0x10
}

IVkCommandPool :: struct {
    using ichild:           kom.IChild,
    
    getQueue:               ProcIVkCommandPoolGetQueue,
    acquireCommandBuffer:   ProcIVkCommandPoolAcquireCommandBuffer,
}

/* IVkCommandBuffer (f760d942-c36b-4cdb-91dd-f2e562b6df4e) */
ProcIVkCommandBufferGetPool           :: #type proc "c" (this: ^IVkCommandBuffer) -> ^IVkCommandPool
ProcIVkCommandBufferBegin             :: #type proc "c" (this: ^IVkCommandBuffer, #by_ptr beginInfo: vk.CommandBufferBeginInfo) -> vk.CommandBuffer
ProcIVkCommandBufferEnd               :: #type proc "c" (this: ^IVkCommandBuffer) -> b32
ProcIVkCommandBufferSubmitAndRelease  :: #type proc "c" (this: ^IVkCommandBuffer, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore) -> ^IVkFence

IVkCommandBuffer_IID :: kom.IID {
    0xf7, 0x60, 0xd9, 0x42,
    0xc3, 0x6b,
    0x4c, 0xdb,
    0x91, 0xdd,
    0xf2, 0xe5, 0x62, 0xb6, 0xdf, 0x4e
}

IVkCommandBuffer :: struct {
    using ichild:       kom.IChild,

    getPool:            ProcIVkCommandBufferGetPool,
    begin:              ProcIVkCommandBufferBegin,
    end:                ProcIVkCommandBufferEnd,
    submitAndRelease:   ProcIVkCommandBufferSubmitAndRelease,
}

/* IVkBackbufferPool (f7a75b5c-4943-414f-8337-8145aa22aeb8) */
ProcIVkBackbufferPoolAcquireBackbuffer :: #type proc "c" (this: ^IVkBackbufferPool, sync: BackbufferAcquisitionSync) -> ^IVkBackbuffer

IVkBackbufferPool_IID :: kom.IID {
    0xf7, 0xa7, 0x5b, 0x5c,
    0x49, 0x43,
    0x41, 0x4f,
    0x83, 0x37,
    0x81, 0x45, 0xaa, 0x22, 0xae, 0xb8
}

IVkBackbufferPool :: struct {
    using ichild:       kom.IChild,

    acquireBackbuffer:  ProcIVkBackbufferPoolAcquireBackbuffer,
}

/* IVkBackbuffer (ec08813c-84d7-48b2-97f9-fb31e53f9037) */
ProcIVkBackbufferGetInfo              :: #type proc "c" (this: ^IVkBackbuffer, info: ^BackbufferInfo)
ProcIVkBackbufferGetLastStageFlags    :: #type proc "c" (this: ^IVkBackbuffer) -> vk.PipelineStageFlags
ProcIVkBackbufferSetLastStageFlags    :: #type proc "c" (this: ^IVkBackbuffer, stages: vk.PipelineStageFlags)

IVkBackbuffer_IID :: kom.IID {
    0xec, 0x08, 0x81, 0x3c,
    0x84, 0xd7,
    0x48, 0xb2,
    0x97, 0xf9,
    0xfb, 0x31, 0xe5, 0x3f, 0x90, 0x37
}

IVkBackbuffer :: struct {
    using ichild:       kom.IChild,

    getInfo:            ProcIVkBackbufferGetInfo,
    getLastStageFlags:  ProcIVkBackbufferGetLastStageFlags,
    setLastStageFlags:  ProcIVkBackbufferSetLastStageFlags,
}

/* IVkPacket (65a6b753-34f9-46a0-ab14-1238c3ae3018) */
ProcIVkPacketGetCommandBuffer :: #type proc "c" (this: ^IVkPacket) -> ^IVkCommandBuffer
ProcIVkPacketGetBackbuffer    :: #type proc "c" (this: ^IVkPacket) -> ^IVkBackbuffer
ProcIVkPacketAddSyncObjects   :: #type proc "c" (this: ^IVkPacket, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore)

IVkPacket_IID :: kom.IID {
    0x65, 0xa6, 0xb7, 0x53,
    0x34, 0xf9,
    0x46, 0xa0,
    0xab, 0x14,
    0x12, 0x38, 0xc3, 0xae, 0x30, 0x18
}

IVkPacket :: struct {
    using ichild:       kom.IChild,

    getCommandBuffer:   ProcIVkPacketGetCommandBuffer,
    getBackbuffer:      ProcIVkPacketGetBackbuffer,
    addSyncObjects:     ProcIVkPacketAddSyncObjects,
}

/* IVkPass (22a77ffd-a263-4a6c-ba4f-5adcd4b8eee1) */
ProcIVkPassExecute :: #type proc "c" (this: ^IVkPass, packet: ^IVkPacket) -> b32

IVkPass_IID :: kom.IID {
    0x22, 0xa7, 0x7f, 0xfd,
    0xa2, 0x63,
    0x4a, 0x6c,
    0xba, 0x4f,
    0x5a, 0xdc, 0xd4, 0xb8, 0xee, 0xe1
}

IVkPass :: struct {
    using IVkPass:    krfw.IVkPass,

    execute:        ProcIVkPassExecute,
}

/* IVkResourcePool (eff18254-eefd-4823-899e-40e62fc64035) */
ProcIVkResourcePoolCreateBuffer   :: #type proc "c" (this: ^IVkResourcePool, buffer: ^Buffer, createInfo: ^vk.BufferCreateInfo, allocationCreateInfo: ^vma.Allocation_Create_Info) -> b32
ProcIVkResourcePoolCreateImage    :: #type proc "c" (this: ^IVkResourcePool, image: ^Image, createInfo: ^vk.ImageCreateInfo, allocationCreateInfo: ^vma.Allocation_Create_Info) -> b32

IVkResourcePool_IID :: kom.IID {
    0xef, 0xf1, 0x82, 0x54,
    0xee, 0xfd,
    0x48, 0x23,
    0x89, 0x9e,
    0x40, 0xe6, 0x2f, 0xc6, 0x40, 0x35
}

IVkResourcePool :: struct {
    using ichild:   kom.IChild,

    createBuffer:   ProcIVkResourcePoolCreateBuffer,
    createImage:    ProcIVkResourcePoolCreateImage,
}

/* IVkResource (21f3ce42-4de9-4326-9ebb-1e761e05d37b) */
ProcIVkResourceGetAllocationInfo  :: #type proc "c" (this: ^IVkResource, allocationInfo: ^vma.Allocation_Info) -> b32
ProcIVkResourceMapResource        :: #type proc "c" (this: ^IVkResource) -> rawptr
ProcIVkResourceUnmapResource      :: #type proc "c" (this: ^IVkResource)
ProcIVkResourceFlush              :: #type proc "c" (this: ^IVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32
ProcIVkResourceInvalidate         :: #type proc "c" (this: ^IVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32

IVkResource_IID :: kom.IID {
    0x21, 0xf3, 0xce, 0x42,
    0x4d, 0xe9,
    0x43, 0x26,
    0x9e, 0xbb,
    0x1e, 0x76, 0x1e, 0x05, 0xd3, 0x7b
}

IVkResource :: struct {
    using ichild:       kom.IChild,

    getAllocationInfo:  ProcIVkResourceGetAllocationInfo,
    mapResource:        ProcIVkResourceMapResource,
    unmapResource:      ProcIVkResourceUnmapResource,
    flush:              ProcIVkResourceFlush,
    invalidate:         ProcIVkResourceInvalidate,
}

/* IVkBuffer (701057d1-4a04-4ea0-9fcb-e5a516b27586) */
ProcIVkBufferGetVulkanBuffer :: #type proc "c" (this: ^IVkBuffer) -> vk.Buffer

IVkBuffer_IID :: kom.IID {
    0x70, 0x10, 0x57, 0xd1,
    0x4a, 0x04,
    0x4e, 0xa0,
    0x9f, 0xcb,
    0xe5, 0xa5, 0x16, 0xb2, 0x75, 0x86
}

IVkBuffer :: struct {
    using IVkResource:    IVkResource,

    getVulkanBuffer:    ProcIVkBufferGetVulkanBuffer,
}

/* IVkImage (93be4bbe-1ea8-4cf1-9b9e-c43d715c0f6c) */
ProcIVkImageGetVulkanImage  :: #type proc "c" (this: ^IVkImage) -> vk.Image
ProcIVkImageGetLayout       :: #type proc "c" (this: ^IVkImage) -> vk.ImageLayout
ProcIVkImageSetLayout       :: #type proc "c" (this: ^IVkImage, layout: vk.ImageLayout)

IVkImage_IID :: kom.IID {
    0x93, 0xbe, 0x4b, 0xbe,
    0x1e, 0xa8,
    0x4c, 0xf1,
    0x9b, 0x9e,
    0xc4, 0x3d, 0x71, 0x5c, 0x0f, 0x6c
}

IVkImage :: struct {
    using IVkResource:    IVkResource,
    
    getVulkanImage:     ProcIVkImageGetVulkanImage,
    getLayout:          ProcIVkImageGetLayout,
    setLayout:          ProcIVkImageSetLayout,
}

/* IVkShaderCompiler (6d6d95bc-7155-4085-bfb5-1a3597bc58c0) */
ProcIVkShaderCompilerCompile :: #type proc "c" (this: ^IVkShaderCompiler, stages: vk.ShaderStageFlags, entryPoint: cstring, source: cstring) -> ^Shader

IVkShaderCompiler_IID :: kom.IID {
    0x6d, 0x6d, 0x95, 0xbc,
    0x71, 0x55,
    0x40, 0x85,
    0xbf, 0xb5,
    0x1a, 0x35, 0x97, 0xbc, 0x58, 0xc0
}

IVkShaderCompiler :: struct {
    using ichild:   kom.IChild,

    compile:        ProcIVkShaderCompilerCompile,
}

/* IVkShader (49d91fc8-93e2-4c77-9d18-b34d97edd384) */
ProcIVkShaderGetVulkanShaderModule    :: #type proc "c" (this: ^IVkShader) -> vk.ShaderModule
ProcIVkShaderGetEntryPoint            :: #type proc "c" (this: ^IVkShader) -> cstring
ProcIVkShaderGetStages                :: #type proc "c" (this: ^IVkShader) -> vk.ShaderStageFlags

IVkShader_IID :: kom.IID {
    0x49, 0xd9, 0x1f, 0xc8,
    0x93, 0xe2,
    0x4c, 0x77,
    0x9d, 0x18,
    0xb3, 0x4d, 0x97, 0xed, 0xd3, 0x84
}

IVkShader :: struct {
    using ichild:           kom.IChild,

    getVulkanShaderModule:  ProcIVkShaderGetVulkanShaderModule,
    getEntryPoint:          ProcIVkShaderGetEntryPoint,
    getStages:              ProcIVkShaderGetStages,
}

/* IVkRenderer (08131508-5abc-42a3-a2f6-c1f6f42d24fd) */
ProcIVkRendererLoadVulkanLoaderOdin     :: #type proc "c" (this: ^IVkRenderer, path: string) -> b32
ProcIVkRendererLoadVulkanLoader         :: #type proc "c" (this: ^IVkRenderer, len: u32, path: cstring) -> b32
ProcIVkRendererLoadVulkanLoaderUTF32    :: #type proc "c" (this: ^IVkRenderer, len: u32, path: [^]rune) -> b32
ProcIVkRendererSetDriverPreferenceOdin  :: #type proc "c" (this: ^IVkRenderer, driver: string)
ProcIVkRendererSetDriverPreference      :: #type proc "c" (this: ^IVkRenderer, len: u32, driver: cstring)
ProcIVkRendererSetAllocator             :: #type proc "c" (this: ^IVkRenderer, allocator: ^vk.AllocationCallbacks)

ProcIVkRendererCreateFencePool          :: #type proc "c" (this: ^IVkRenderer) -> ^IVkFencePool
ProcIVkRendererCreateSemaphorePool      :: #type proc "c" (this: ^IVkRenderer) -> ^IVkSemaphorePool
ProcIVkRendererCreateCommandPool        :: #type proc "c" (this: ^IVkRenderer, fencePool: ^FencePool, queue: ^Queue) -> ^IVkCommandPool
ProcIVkRendererCreateResourcePool       :: #type proc "c" (this: ^IVkRenderer, createInfo: ^vma.Pool_Create_Info) -> ^IVkResourcePool

ProcIVkRendererGetDefaultFencePool      :: #type proc "c" (this: ^IVkRenderer) -> ^IVkFencePool
ProcIVkRendererGetDefaultSemaphorePool  :: #type proc "c" (this: ^IVkRenderer) -> ^IVkSemaphorePool
ProcIVkRendererGetDefaultCommandPool    :: #type proc "c" (this: ^IVkRenderer, queueType: QueueType) -> ^IVkCommandPool
ProcIVkRendererGetDefaultResourcePool   :: #type proc "c" (this: ^IVkRenderer) -> ^IVkResourcePool
ProcIVkRendererGetHLSLShaderCompiler    :: #type proc "c" (this: ^IVkRenderer) -> ^IVkShaderCompiler

ProcIVkRendererGetAllocator             :: #type proc "c" (this: ^IVkRenderer) -> ^vk.AllocationCallbacks
ProcIVkRendererGetInstance              :: #type proc "c" (this: ^IVkRenderer) -> ^Instance
ProcIVkRendererGetDevice                :: #type proc "c" (this: ^IVkRenderer) -> ^Device

IVkRenderer_IID :: kom.IID {
    0x08, 0x13, 0x15, 0x08,
    0x5a, 0xbc,
    0x42, 0xa3,
    0xa2, 0xf6,
    0xc1, 0xf6, 0xf4, 0x2d, 0x24, 0xfd
}

IVkRenderer :: struct {
    using irenderer:            krfw.IRenderer,

    loadVulkanLoaderOdin:       ProcIVkRendererLoadVulkanLoaderOdin,
    loadVulkanLoader:           ProcIVkRendererLoadVulkanLoader,
    loadVulkanLoaderUnicode:    ProcIVkRendererLoadVulkanLoaderUTF32,
    setDriverPreferenceOdin:    ProcIVkRendererSetDriverPreferenceOdin,
    setDriverPreference:        ProcIVkRendererSetDriverPreference,
    setAllocator:               ProcIVkRendererSetAllocator,

    createFencePool:            ProcIVkRendererCreateFencePool,
    createSemaphorePool:        ProcIVkRendererCreateSemaphorePool,
    createCommandPool:          ProcIVkRendererCreateCommandPool,
    createResourcePool:         ProcIVkRendererCreateResourcePool,

    getDefaultFencePool:        ProcIVkRendererGetDefaultFencePool,
    getDefaultSemaphorePool:    ProcIVkRendererGetDefaultSemaphorePool,
    getDefaultCommandPool:      ProcIVkRendererGetDefaultCommandPool,
    getDefaultResourcePool:     ProcIVkRendererGetDefaultResourcePool,

    getAllocator:               ProcIVkRendererGetAllocator,
    getInstance:                ProcIVkRendererGetInstance,
    getDevice:                  ProcIVkRendererGetDevice,
}