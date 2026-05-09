#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"
import "vma"

VkBufferData :: struct {
    _refCount:          u64,
    _ctx:               ^runtime.Context,

    _resourcePool:      ^VkResourcePool,
    _allocation:        vma.Allocation,
    _aliasOffset:       vk.DeviceSize,

    _isPersistent:      b32,
    _isInternal:        b32,
    _isConcurrent:      b32,

    _buffer:            vk.Buffer,
    _lastStageFlags:    vk.PipelineStageFlags,
    _lastAccessMask:    vk.AccessFlags,
    _lastQueueOwner:    ^IVkQueue,
}

VkBufferIBase :: struct {
    base:       ^VkBuffer,
    interface:  kom.IBase,
}

VkBufferIChild :: struct {
    base:       ^VkBuffer,
    interface:  kom.IChild,
}

VkBufferIVkResource :: struct {
    base:       ^VkBuffer,
    interface:  IVkResource,
}

VkBufferIVkBuffer :: struct {
    base:       ^VkBuffer,
    interface:  IVkBuffer,
}

VkBuffer :: struct {
    using _:        VkBufferData,

    ibase:          VkBufferIBase,
    ichild:         VkBufferIChild,
    ivkresource:    VkBufferIVkResource,
    ivkbuffer:      VkBufferIVkBuffer,
}

/* initializer */
VkBuffer_new :: proc(pool: ^VkResourcePool, allocation: vma.Allocation, vkBuffer: vk.Buffer, isPersistent: b32, isInternal := b32(false), isConcurrent := b32(false), aliasOffset := max(vk.DeviceSize)) {
    buffer := new(VkBuffer)

    buffer^ = {
        _refCount       = 1,
        _ctx            = this._ctx,

        _resourcePool   = pool,
        _allocation     = allocation,
        _aliasOffset    = aliasOffset,

        _isPersistent   = isPersistent,
        _isBackbuffer   = isBackbuffer,
        _isConcurrent   = isConcurrent,

        _buffer         = vkBuffer,

        ibase           = {
            base        = buffer,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkBuffer_IBase_retain),
                release         = kom.ProcIBaseRelease(VkBuffer_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkBuffer_IBase_queryInterface),
            },
        },

        ichild          = {
            base        = buffer,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkBuffer_IBase_retain),
                release         = kom.ProcIBaseRelease(VkBuffer_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkBuffer_IBase_queryInterface),

                /* IChild */
                getParent       = kom.ProcIChildGetParent(VkBuffer_IChild_getParent),
            },
        },

        ivkresource     = {
            base        = buffer,
            interface   = {
                /* IBase */
                retain                  = kom.ProcIBaseRetain(VkBuffer_IBase_retain),
                release                 = kom.ProcIBaseRelease(VkBuffer_IBase_release),
                queryInterface          = kom.ProcIBaseQueryInterface(VkBuffer_IBase_queryInterface),

                /* IChild */
                getParent               = kom.ProcIChildGetParent(VkBuffer_IChild_getParent),
            
                /* IVkResource */
                getVmaAllocationInfo    = ProcIVkResourceGetVmaAllocationInfo(VkBuffer_IVkResource_getVmaAllocationInfo),
                getVmaAllocation        = ProcIVkResourceGetVmaAllocationInfo(VkBuffer_IVkResource_getVmaAllocation),
                mapResource             = ProcIVkResourceMapResource(VkBuffer_IVkResource_mapResource),
                unmapResource           = ProcIVkResourceUnmapResource(VkBuffer_IVkResource_unmapResource),
                flush                   = ProcIVkResourceFlush(VkBuffer_IVkResource_flush),
                invalidate              = ProcIVkResourceInvalidate(VkBuffer_IVkResource_invalidate),
                isSharedConcurrent      = ProcIVkResourceIsSharedConcurrent(VkBuffer_IVkResource_isSharedConcurrent),
                getLastStageFlags       = ProcIVkResourceGetLastStageFlags(VkBuffer_IVkResource_getLastStageFlags),
                setLastStageFlags       = ProcIVkResourceSetLastStageFlags(VkBuffer_IVkResource_setLastStageFlags),
                getLastAccessMask       = ProcIVkResourceGetLastAccessMask(VkBuffer_IVkResource_getLastAccessMask),
                setLastAccessMask       = ProcIVkResourceSetLastAccessMask(VkBuffer_IVkResource_setLastAccessMask),
                getLastQueueOwnership   = ProcIVkResourceGetLastQueueOwnership(VkBuffer_IVkResource_getLastQueueOwnership),
                setLastQueueOwnership   = ProcIVkResourceSetLastQueueOwnership(VkBuffer_IVkResource_setLastQueueOwnership),
            },
        },

        ivkimage        = {
            base        = buffer,
            interface   = {
                /* IBase */
                retain                  = kom.ProcIBaseRetain(VkBuffer_IBase_retain),
                release                 = kom.ProcIBaseRelease(VkBuffer_IBase_release),
                queryInterface          = kom.ProcIBaseQueryInterface(VkBuffer_IBase_queryInterface),

                /* IChild */
                getParent               = kom.ProcIChildGetParent(VkBuffer_IChild_getParent),
                
                /* IVkResource */
                getVmaAllocationInfo    = ProcIVkResourceGetVmaAllocationInfo(VkBuffer_IVkResource_getVmaAllocationInfo),
                getVmaAllocation        = ProcIVkResourceGetVmaAllocationInfo(VkBuffer_IVkResource_getVmaAllocation),
                mapResource             = ProcIVkResourceMapResource(VkBuffer_IVkResource_mapResource),
                unmapResource           = ProcIVkResourceUnmapResource(VkBuffer_IVkResource_unmapResource),
                flush                   = ProcIVkResourceFlush(VkBuffer_IVkResource_flush),
                invalidate              = ProcIVkResourceInvalidate(VkBuffer_IVkResource_invalidate),
                isSharedConcurrent      = ProcIVkResourceIsSharedConcurrent(VkBuffer_IVkResource_isSharedConcurrent),
                getLastStageFlags       = ProcIVkResourceGetLastStageFlags(VkBuffer_IVkResource_getLastStageFlags),
                setLastStageFlags       = ProcIVkResourceSetLastStageFlags(VkBuffer_IVkResource_setLastStageFlags),
                getLastAccessMask       = ProcIVkResourceGetLastAccessMask(VkBuffer_IVkResource_getLastAccessMask),
                setLastAccessMask       = ProcIVkResourceSetLastAccessMask(VkBuffer_IVkResource_setLastAccessMask),
                getLastQueueOwnership   = ProcIVkResourceGetLastQueueOwnership(VkBuffer_IVkResource_getLastQueueOwnership),
                setLastQueueOwnership   = ProcIVkResourceSetLastQueueOwnership(VkBuffer_IVkResource_setLastQueueOwnership),

                /* IVkBuffer */
                getVulkanBuffer          = ProcIVkBufferGetVulkanBuffer(VkBuffer_IVkBuffer_getVulkanBuffer),
                getLayout               = ProcIVkBufferGetLayout(VkBuffer_IVkBuffer_getLayout),
                setLayout               = ProcIVkBufferSetLayout(VkBuffer_IVkBuffer_setLayout),
            },
        },
    }
}

/* IBase */
VkBuffer_retain :: proc "c" (this: ^VkBuffer) -> u64 {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._refCount += 1

    return this._refCount
}

VkBuffer_release :: proc "c" (this: ^VkBuffer) -> u64 {
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
        log(renderer, .Warning, "Can't fully release buffer: is internal (likely a double release or a missing retain)")
        this._refCount = 1
        return max(u64)
    }

    assert(this._allocation != nil)
    vma.destroy_buffer(renderer._vma, this._buffer, this._allocation)

    free(this)
    return 0
}

VkBuffer_queryInterface :: proc "c" (this: ^VkBuffer, #by_ptr id: kom.IID) -> rawptr {
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
        case IVkBuffer_IID:
            return &this.ivkbuffer
        case:
            break
    }

    return nil
}

/* IChild */
VkBuffer_getParent :: proc "c" (this: ^VkBuffer) -> ^kom.IBase {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    pool := this._resourcePool
    return &pool.ibase
}

/* IVkResource */
VkBuffer_getVmaAllocationInfo :: proc "c" (this: ^VkBuffer, allocationInfo: ^vma.Allocation_Info) -> b32 {
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

VkBuffer_getVmaAllocation :: proc "c" (this: ^VkBuffer) -> vma.Allocation {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    return this._allocation
}

VkBuffer_mapResource :: proc "c" (this: ^VkBuffer) -> rawptr {
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
        log(renderer, .Error, "Failed to map buffer memory")
        return nil
    }

    return data
}

VkBuffer_unmapResource :: proc "c" (this: ^VkBuffer) {
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

VkBuffer_flush :: proc "c" (this: ^VkBuffer, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer
    
    if this._isBackbuffer {
        log(renderer, .Error, "Can't flush buffer resource: is managed internally")
        return false
    }

    if vma.flush_allocation(renderer._vma, this._allocation, offset, size) != .SUCCESS {
        log(renderer, .Error, "Failed to flush buffer resource")
        return false
    }

    return true
}

VkBuffer_invalidate :: proc "c" (this: ^VkBuffer, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := pool._device
    instance := device._instance
    renderer := instance._renderer
    
    if this._isBackbuffer {
        log(renderer, .Error, "Can't invalidate buffer resource: is managed internally")
        return false
    }

    if vma.invalidate_allocation(renderer._vma, this._allocation, offset, size) != .SUCCESS {
        log(renderer, .Error, "Failed to invalidate buffer resource")
        return false
    }

    return true
}

VkBuffer_isSharedConcurrent :: proc "c" (this: ^VkBuffer) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^
    return this._isConcurrent
}

VkBuffer_getLastStageFlags :: proc "c" (this: ^VkBuffer) -> vk.PipelineStageFlags {
    if this == nil || this._ctx == nil {
        return {}
    }

    context = this._ctx^
    return this._lastStageFlags
}

VkBuffer_setLastStageFlags :: proc "c" (this: ^VkBuffer, stages: vk.PipelineStageFlags) {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^
    this._lastStageFlags = stages
}

VkBuffer_getLastAccessMask :: proc "c" (this: ^VkBuffer) -> vk.AccessFlags {
    if this == nil || this._ctx == nil {
        return {}
    }

    context = this._ctx^
    return this._lastAccessMask
}

VkBuffer_setLastAccessMask :: proc "c" (this: ^VkBuffer, access: vk.AccessFlags) {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^
    this._lastAccessMask = access
}

VkBuffer_getLastQueueOwnership :: proc "c" (this: ^VkBuffer) -> ^IVkQueue {
    if this == nil || this._ctx == nil {
        return {}
    }

    context = this._ctx^
    return this._lastQueueOwner
}

VkBuffer_setLastQueueOwnership :: proc "c" (this: ^VkBuffer, queue: ^IVkQueue) {
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

/* IVkBuffer */
VkBuffer_getVulkanBuffer :: proc "c" (this: ^VkBuffer) -> vk.Buffer {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    return this._buffer
}

/* IBase interface wrapper */
VkBuffer_IBase_retain :: proc "c" (this: ^kom.IBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkBuffer_retain(getBaseFromInterface(this))
}

VkBuffer_IBase_release :: proc "c" (this: ^kom.IBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkBuffer_release(getBaseFromInterface(this))
}

VkBuffer_IBase_queryInterface :: proc "c" (this: ^kom.IBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_queryInterface(getBaseFromInterface(this), id)
}

/* IChild interface wrapper */
VkBuffer_IChild_getParent :: proc "c" (this: ^VkBufferIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkBuffer_getParent(getBaseFromInterface(this))
}

/* IVkResource interface wrapper */
VkBuffer_IVkResource_getVmaAllocationInfo :: proc "c" (this: ^VkBufferIVkResource, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_getVmaAllocationInfo(getBaseFromInterface(this), allocationInfo)
}

VkBuffer_IVkResource_getVmaAllocation :: proc "c" (this: ^VkBufferIVkResource) -> vma.Allocation {
    if this == nil {
        return nil
    }

    return VkBuffer_getVmaAllocation(getBaseFromInterface(this))
}

VkBuffer_IVkResource_mapResource :: proc "c" (this: ^VkBufferIVkResource) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_mapResource(getBaseFromInterface(this))
}

VkBuffer_IVkResource_unmapResource :: proc "c" (this: ^VkBufferIVkResource) {
    if this == nil {
        return
    }

    VkBuffer_unmapResource(getBaseFromInterface(this))
}

VkBuffer_IVkResource_flush :: proc "c" (this: ^VkBufferIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_flush(getBaseFromInterface(this), offset, size)
}

VkBuffer_IVkResource_invalidate :: proc "c" (this: ^VkBufferIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_invalidate(getBaseFromInterface(this), offset, size)
}

VkBuffer_IVkResource_isSharedConcurrent :: proc "c" (this: ^VkBufferIVkResource) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_isSharedConcurrent(getBaseFromInterface(this))
}

VkBuffer_IVkResource_getLastStageFlags :: proc "c" (this: ^VkBufferIVkResource) -> vk.PipelineStageFlags {
    if this == nil {
        return {}
    }

    return VkBuffer_getLastStageFlags(getBaseFromInterface(this))
}

VkBuffer_IVkResource_setLastStageFlags :: proc "c" (this: ^VkBufferIVkResource, stages: vk.PipelineStageFlags) {
    if this == nil {
        return
    }

    VkBuffer_setLastStageFlags(getBaseFromInterface(this), stages)
}

VkBuffer_IVkResource_getLastAccessMask :: proc "c" (this: ^VkBufferIVkResource) -> vk.AccessMask {
    if this == nil {
        return {}
    }

    return VkBuffer_getLastAccessMask(getBaseFromInterface(this))
}

VkBuffer_IVkResource_setLastAccessMask :: proc "c" (this: ^VkBufferIVkResource, access: vk.AccessMask) {
    if this == nil {
        return
    }

    VkBuffer_setLastAccessMask(getBaseFromInterface(this), access)
}

VkBuffer_IVkResource_getLastQueueOwnership :: proc "c" (this: ^VkBufferIVkResource) -> ^IVkQueue {
    if this == nil {
        return nil
    }

    return VkBuffer_getLastQueueOwnership(getBaseFromInterface(this))
}

VkBuffer_IVkResource_setLastQueueOwnership :: proc "c" (this: ^VkBufferIVkResource, queue: ^IVkQueue) {
    if this == nil {
        return
    }

    VkBuffer_setLastQueueOwnership(getBaseFromInterface(this), queue)
}

/* IVkBuffer interface wrapper */
VkBuffer_IVkBuffer_getVulkanBuffer :: proc "c" (this: ^VkBufferIVkBuffer) -> vk.Buffer {
    if this == nil {
        return 0
    }

    return VkBuffer_getVulkanBuffer(getBaseFromInterface(this))
}