#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"
import "vma"

VkImageData :: struct {
    _refCount:          u64,
    _ctx:               ^runtime.Context,

    _resourcePool:      ^VkResourcePool,
    _allocation:        vma.Allocation,
    _aliasOffset:       vk.DeviceSize,

    _isPersistent:      b32,
    _isBackbuffer:      b32,
    _isConcurrent:      b32,

    _image:             vk.Image,
    _layout:            vk.ImageLayout,
    _lastStageFlags:    vk.PipelineStageFlags,
    _lastAccessMask:    vk.AccessFlags,
    _lastQueueOwner:    ^IVkQueue,
}

VkImageIBase :: struct {
    base:       ^VkImage,
    interface:  kom.IBase,
}

VkImageIChild :: struct {
    base:       ^VkImage,
    interface:  kom.IChild,
}

VkImageIVkResource :: struct {
    base:       ^VkImage,
    interface:  IVkResource,
}

VkImageIVkImage :: struct {
    base:       ^VkImage,
    interface:  IVkImage,
}

VkImage :: struct {
    using _:        VkImageData,

    ibase:          VkImageIBase,
    ichild:         VkImageIChild,
    ivkresource:    VkImageIVkResource,
    ivkimage:       VkImageIVkImage,
}

/* initializer */
VkImage_new :: proc(pool: ^VkResourcePool, allocation: vma.Allocation, vkImage: vk.Image, isPersistent: b32, isBackbuffer := b32(false), isConcurrent := b32(false), aliasOffset := max(vk.DeviceSize)) -> ^VkImage {
    image := new(VkImage)

    image^ = {
        _refCount       = 1,
        _ctx            = this._ctx,

        _resourcePool   = this,
        _allocation     = allocation,
        _aliasOffset    = aliasOffset,

        _isPersistent   = isPersistent,
        _isBackbuffer   = isBackbuffer,
        _isConcurrent   = isConcurrent,

        _image          = vkImage,
        _layout         = .UNDEFINED,

        ibase           = {
            base        = image,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkImage_IBase_retain),
                release         = kom.ProcIBaseRelease(VkImage_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkImage_IBase_queryInterface),
            },
        },

        ichild          = {
            base        = image,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkImage_IBase_retain),
                release         = kom.ProcIBaseRelease(VkImage_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkImage_IBase_queryInterface),

                /* IChild */
                getParent       = kom.ProcIChildGetParent(VkImage_IChild_getParent),
            },
        },

        ivkresource     = {
            base        = image,
            interface   = {
                /* IBase */
                retain                  = kom.ProcIBaseRetain(VkImage_IBase_retain),
                release                 = kom.ProcIBaseRelease(VkImage_IBase_release),
                queryInterface          = kom.ProcIBaseQueryInterface(VkImage_IBase_queryInterface),

                /* IChild */
                getParent               = kom.ProcIChildGetParent(VkImage_IChild_getParent),
                
                /* IVkResource */
                getVmaAllocationInfo    = ProcIVkResourceGetVmaAllocationInfo(VkImage_IVkResource_getVmaAllocationInfo),
                getVmaAllocation        = ProcIVkResourceGetVmaAllocationInfo(VkImage_IVkResource_getVmaAllocation),
                mapResource             = ProcIVkResourceMapResource(VkImage_IVkResource_mapResource),
                unmapResource           = ProcIVkResourceUnmapResource(VkImage_IVkResource_unmapResource),
                flush                   = ProcIVkResourceFlush(VkImage_IVkResource_flush),
                invalidate              = ProcIVkResourceInvalidate(VkImage_IVkResource_invalidate),
                isSharedConcurrent      = ProcIVkResourceIsSharedConcurrent(VkImage_IVkResource_isSharedConcurrent),
                getLastStageFlags       = ProcIVkResourceGetLastStageFlags(VkImage_IVkResource_getLastStageFlags),
                setLastStageFlags       = ProcIVkResourceSetLastStageFlags(VkImage_IVkResource_setLastStageFlags),
                getLastAccessMask       = ProcIVkResourceGetLastAccessMask(VkImage_IVkResource_getLastAccessMask),
                setLastAccessMask       = ProcIVkResourceSetLastAccessMask(VkImage_IVkResource_setLastAccessMask),
                getLastQueueOwnership   = ProcIVkResourceGetLastQueueOwnership(VkImage_IVkResource_getLastQueueOwnership),
                setLastQueueOwnership   = ProcIVkResourceSetLastQueueOwnership(VkImage_IVkResource_setLastQueueOwnership),
            },
        },

        ivkimage        = {
            base        = image,
            interface   = {
                /* IBase */
                retain                  = kom.ProcIBaseRetain(VkImage_IBase_retain),
                release                 = kom.ProcIBaseRelease(VkImage_IBase_release),
                queryInterface          = kom.ProcIBaseQueryInterface(VkImage_IBase_queryInterface),

                /* IChild */
                getParent               = kom.ProcIChildGetParent(VkImage_IChild_getParent),
                
                /* IVkResource */
                getVmaAllocationInfo    = ProcIVkResourceGetVmaAllocationInfo(VkImage_IVkResource_getVmaAllocationInfo),
                getVmaAllocation        = ProcIVkResourceGetVmaAllocationInfo(VkImage_IVkResource_getVmaAllocation),
                mapResource             = ProcIVkResourceMapResource(VkImage_IVkResource_mapResource),
                unmapResource           = ProcIVkResourceUnmapResource(VkImage_IVkResource_unmapResource),
                flush                   = ProcIVkResourceFlush(VkImage_IVkResource_flush),
                invalidate              = ProcIVkResourceInvalidate(VkImage_IVkResource_invalidate),
                isSharedConcurrent      = ProcIVkResourceIsSharedConcurrent(VkImage_IVkResource_isSharedConcurrent),
                getLastStageFlags       = ProcIVkResourceGetLastStageFlags(VkImage_IVkResource_getLastStageFlags),
                setLastStageFlags       = ProcIVkResourceSetLastStageFlags(VkImage_IVkResource_setLastStageFlags),
                getLastAccessMask       = ProcIVkResourceGetLastAccessMask(VkImage_IVkResource_getLastAccessMask),
                setLastAccessMask       = ProcIVkResourceSetLastAccessMask(VkImage_IVkResource_setLastAccessMask),
                getLastQueueOwnership   = ProcIVkResourceGetLastQueueOwnership(VkImage_IVkResource_getLastQueueOwnership),
                setLastQueueOwnership   = ProcIVkResourceSetLastQueueOwnership(VkImage_IVkResource_setLastQueueOwnership),

                /* IVkImage */
                getVulkanImage          = ProcIVkImageGetVulkanImage(VkImage_IVkImage_getVulkanImage),
                getLayout               = ProcIVkImageGetLayout(VkImage_IVkImage_getLayout),
                setLayout               = ProcIVkImageSetLayout(VkImage_IVkImage_setLayout),
            },
        },
    }

    return image
}

/* IBase */
VkImage_retain :: proc "c" (this: ^VkImage) -> u64 {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._refCount += 1

    return this._refCount
}

VkImage_release :: proc "c" (this: ^VkImage) -> u64 {
    if this == nil || this._ctx == nil {
        return max(u64)
    }

    context = this._ctx^
    this._refCount -= 1
    if this._refCount != 0 {
        return this._refCount
    }

    pool := this._resourcePool
    renderer := pool._renderer

    if this._isBackbuffer && !renderer._performingDestruction {
        log(renderer, .Warning, "Can't fully release image: is internal backbuffer (likely a double release or a missing retain)")
        this._refCount = 1
        return max(u64)
    }

    assert(this._allocation != nil)
    vma.destroy_image(renderer._vma, this._image, this._allocation)

    free(this)
    return 0
}

VkImage_queryInterface :: proc "c" (this: ^VkImage, #by_ptr id: kom.IID) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    switch id {
        case kom.IBase_IID:
            return &this.ibase
        case kom.IChild_IID:
            return &this.ichild
        case IVkResource_IID:
            return &this.ivkresource
        case IVkImage_IID:
            return &this.ivkimage
        case:
            break
    }

    return nil
}

/* IChild */
VkImage_getParent :: proc "c" (this: ^VkImage) -> ^kom.IBase {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    pool := this._resourcePool
    return &pool.ibase
}

/* IVkResource */
VkImage_getVmaAllocationInfo :: proc "c" (this: ^VkImage, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer

    assert(allocationInfo != nil)
    vma.get_allocation_info(renderer._vma, this._allocation, allocationInfo)
    return true
}

VkImage_getVmaAllocation :: proc "c" (this: ^VkImage) -> vma.Allocation {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    return this._allocation
}

VkImage_mapResource :: proc "c" (this: ^VkImage) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer

    allocationInfo: vma.Allocation_Info
    vma.get_allocation_info(renderer._vma, this._allocation, &allocationInfo)

    if this._isPersistent {
        return allocationInfo.mapped_data
    }

    data: rawptr
    if vma.map_memory(renderer._vma, this._allocation, &data) != .SUCCESS {
        log(renderer, .Error, "Failed to map image memory")
        return nil
    }

    return data
}

VkImage_unmapResource :: proc "c" (this: ^VkImage) {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer
    
    if this._isPersistent {
        return
    }

    vma.unmap_memory(renderer._vma, this._allocation)
}

VkImage_flush :: proc "c" (this: ^VkImage, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer
    
    if this._isBackbuffer {
        log(renderer, .Error, "Can't flush image resource: is internally-managed backbuffer")
        return false
    }

    if vma.flush_allocation(renderer._vma, this._allocation, offset, size) != .SUCCESS {
        log(renderer, .Error, "Failed to flush image resource")
        return false
    }

    return true
}

VkImage_invalidate :: proc "c" (this: ^VkImage, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer
    
    if this._isBackbuffer {
        log(renderer, .Error, "Can't invalidate image resource: is internally-managed backbuffer")
        return false
    }

    if vma.invalidate_allocation(renderer._vma, this._allocation, offset, size) != .SUCCESS {
        log(renderer, .Error, "Failed to invalidate image resource")
        return false
    }

    return true
}

VkImage_isSharedConcurrent :: proc "c" (this: ^VkImage) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^
    return this._isConcurrent
}

VkImage_getLastStageFlags :: proc "c" (this: ^VkImage) -> vk.PipelineStageFlags {
    if this == nil || this._ctx == nil {
        return {}
    }

    context = this._ctx^
    return this._lastStageFlags
}

VkImage_setLastStageFlags :: proc "c" (this: ^VkImage, stages: vk.PipelineStageFlags) {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^
    this._lastStageFlags = stages
}

VkImage_getLastAccessMask :: proc "c" (this: ^VkImage) -> vk.AccessFlags {
    if this == nil || this._ctx == nil {
        return {}
    }

    context = this._ctx^
    return this._lastAccessMask
}

VkImage_setLastAccessMask :: proc "c" (this: ^VkImage, access: vk.AccessFlags) {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^
    this._lastAccessMask = access
}

VkImage_getLastQueueOwnership :: proc "c" (this: ^VkImage) -> ^IVkQueue {
    if this == nil || this._ctx == nil {
        return {}
    }

    context = this._ctx^
    return this._lastQueueOwner
}

VkImage_setLastQueueOwnership :: proc "c" (this: ^VkImage, queue: ^IVkQueue) {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer
    
    /* TODO: check that Queue is valid and child of renderer */

    this._lastQueueOwner = queue
}

/* IVkImage */
VkImage_getVulkanImage :: proc "c" (this: ^VkImage) -> vk.Image {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    return this._image
}

VkImage_getLayout :: proc "c" (this: ^VkImage) -> vk.ImageLayout {
    if this == nil || this._ctx == nil {
        return .UNDEFINED
    }

    context = this._ctx^
    return this._layout
}

VkImage_setLayout :: proc "c" (this: ^VkImage, layout: vk.ImageLayout) {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._layout = layout
}

/* IBase interface wrapper */
VkImage_IBase_retain :: proc "c" (this: ^VkImageIBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkImage_retain(getBaseFromInterface(this))
}

VkImage_IBase_release :: proc "c" (this: ^VkImageIBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkImage_release(getBaseFromInterface(this))
}

VkImage_IBase_queryInterface :: proc "c" (this: ^VkImageIBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_queryInterface(getBaseFromInterface(this), id)
}

/* IChild interface wrapper */
VkImage_IChild_getParent :: proc "c" (this: ^VkImageIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkImage_getParent(getBaseFromInterface(this))
}

/* IVkResource interface wrapper */
VkImage_IVkResource_getVmaAllocationInfo :: proc "c" (this: ^VkImageIVkResource, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_getVmaAllocationInfo(getBaseFromInterface(this), allocationInfo)
}

VkImage_IVkResource_getVmaAllocation :: proc "c" (this: ^VkImageIVkResource) -> vma.Allocation {
    if this == nil {
        return nil
    }

    return VkImage_getVmaAllocation(getBaseFromInterface(this))
}

VkImage_IVkResource_mapResource :: proc "c" (this: ^VkImageIVkResource) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_mapResource(getBaseFromInterface(this))
}

VkImage_IVkResource_unmapResource :: proc "c" (this: ^VkImageIVkResource) {
    if this == nil {
        return
    }

    VkImage_unmapResource(getBaseFromInterface(this))
}

VkImage_IVkResource_flush :: proc "c" (this: ^VkImageIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_flush(getBaseFromInterface(this), offset, size)
}

VkImage_IVkResource_invalidate :: proc "c" (this: ^VkImageIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_invalidate(getBaseFromInterface(this), offset, size)
}

VkImage_IVkResource_isSharedConcurrent :: proc "c" (this: ^VkImageIVkResource) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_isSharedConcurrent(getBaseFromInterface(this))
}

VkImage_IVkResource_getLastStageFlags :: proc "c" (this: ^VkImageIVkResource) -> vk.PipelineStageFlags {
    if this == nil {
        return {}
    }

    return VkImage_getLastStageFlags(getBaseFromInterface(this))
}

VkImage_IVkResource_setLastStageFlags :: proc "c" (this: ^VkImageIVkResource, stages: vk.PipelineStageFlags) {
    if this == nil {
        return
    }

    VkImage_setLastStageFlags(getBaseFromInterface(this), stages)
}

VkImage_IVkResource_getLastAccessMask :: proc "c" (this: ^VkImageIVkResource) -> vk.AccessMask {
    if this == nil {
        return {}
    }

    return VkImage_getLastAccessMask(getBaseFromInterface(this))
}

VkImage_IVkResource_setLastAccessMask :: proc "c" (this: ^VkImageIVkResource, access: vk.AccessMask) {
    if this == nil {
        return
    }

    VkImage_setLastAccessMask(getBaseFromInterface(this), access)
}

VkImage_IVkResource_getLastQueueOwnership :: proc "c" (this: ^VkImageIVkResource) -> ^IVkQueue {
    if this == nil {
        return nil
    }

    return VkImage_getLastQueueOwnership(getBaseFromInterface(this))
}

VkImage_IVkResource_setLastQueueOwnership :: proc "c" (this: ^VkImageIVkResource, queue: ^IVkQueue) {
    if this == nil {
        return
    }

    VkImage_setLastQueueOwnership(getBaseFromInterface(this), queue)
}

/* IVkImage interface wrapper */
VkImage_IVkImage_getVulkanImage :: proc "c" (this: ^VkImageIVkImage) -> vk.Image {
    if this == nil {
        return 0
    }

    return VkImage_getVulkanImage(getBaseFromInterface(this))
}

VkImage_IVkImage_getLayout :: proc "c" (this: ^VkImageIVkImage) -> vk.ImageLayout {
    if this == nil {
        return .UNDEFINED
    }

    return VkImage_getLayout(getBaseFromInterface(this))
}

VkImage_IVkImage_setLayout :: proc "c" (this: ^VkImageIVkImage, layout: vk.ImageLayout) {
    if this == nil {
        return
    }

    VkImage_setLayout(getBaseFromInterface(this), layout)
}