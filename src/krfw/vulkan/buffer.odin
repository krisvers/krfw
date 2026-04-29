#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"
import "vma"

VkBufferData :: struct {
    _refCount:      u64,
    _ctx:           ^runtime.Context,

    _resourcePool:  ^VkResourcePool,
    _allocation:    vma.Allocation,

    _isPersistent:  b32,
    _isInternal:    b32,

    _buffer:        vk.Buffer,
}

VkBufferIBase :: struct {
    interface:  kom.IBase,
    base:       ^VkBuffer,
}

VkBufferIChild :: struct {
    interface:  kom.IChild,
    base:       ^VkBuffer,
}

VkBufferIVkResource :: struct {
    interface:  IVkResource,
    base:       ^VkBuffer,
}

VkBufferIVkBuffer :: struct {
    interface:  IVkBuffer,
    base:       ^VkBuffer,
}

VkBuffer :: struct {
    using _:        VkBufferData,

    ibase:          VkBufferIBase,
    ichild:         VkBufferIChild,
    ivkresource:    VkBufferIVkResource,
    ivkbuffer:       VkBufferIVkBuffer,
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
    device := pool._device
    instance := device._instance
    renderer := instance._renderer

    if this._isBackbuffer && !renderer._performingDestruction {
        log(renderer, .Warning, "Can't fully release buffer: is internal (likely a double release or a missing retain)")
        this._refCount = 1
        return max(u64)
    }

    assert(this._allocation != nil)
    vma.destroy_buffer(renderer._vma, this._buffer, this._allocation)

    delete(this)
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
VkBuffer_getAllocationInfo :: proc "c" (this: ^VkBuffer, allocationInfo: ^vma.Allocation_Info) -> b32 {
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

/* IVkBuffer */
VkBuffer_getVulkanBuffer :: proc "c" (this: ^VkBuffer) -> vk.Buffer {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    return this._buffer
}

/* IBase interface wrapper */
VkBuffer_IBase_retain :: proc "c" (this: ^VkBufferIBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkBuffer_retain(this.base)
}

VkBuffer_IBase_release :: proc "c" (this: ^VkBufferIBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkBuffer_release(this.base)
}

VkBuffer_IBase_queryInterface :: proc "c" (this: ^VkBufferIBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_queryInterface(this.base, id)
}

/* IChild interface wrapper */
VkBuffer_IChild_retain :: proc "c" (this: ^VkBufferIChild) -> u64 {
    if this == nil {
        return 0
    }

    return VkBuffer_retain(this.base)
}

VkBuffer_IChild_release :: proc "c" (this: ^VkBufferIChild) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkBuffer_release(this.base)
}

VkBuffer_IChild_queryInterface :: proc "c" (this: ^VkBufferIChild, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_queryInterface(this.base, id)
}

VkBuffer_IChild_getParent :: proc "c" (this: ^VkBufferIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkBuffer_getParent(this.base)
}

/* IVkResource interface wrapper */
VkBuffer_IVkResource_retain :: proc "c" (this: ^VkBufferIVkResource) -> u64 {
    if this == nil {
        return 0
    }

    return VkBuffer_retain(this.base)
}

VkBuffer_IVkResource_release :: proc "c" (this: ^VkBufferIVkResource) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkBuffer_release(this.base)
}

VkBuffer_IVkResource_queryInterface :: proc "c" (this: ^VkBufferIVkResource, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_queryInterface(this.base, id)
}

VkBuffer_IVkResource_getParent :: proc "c" (this: ^VkBufferIVkResource) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkBuffer_getParent(this.base)
}

VkBuffer_IVkResource_getAllocationInfo :: proc "c" (this: ^VkBufferIVkResource, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_getAllocationInfo(this.base, allocationInfo)
}

VkBuffer_IVkResource_mapResource :: proc "c" (this: ^VkBufferIVkResource) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_mapResource(this.base)
}

VkBuffer_IVkResource_unmapResource :: proc "c" (this: ^VkBufferIVkResource) {
    if this == nil {
        return
    }

    VkBuffer_unmapResource(this.base)
}

VkBuffer_IVkResource_flush :: proc "c" (this: ^VkBufferIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_flush(this.base, offset, size)
}

VkBuffer_IVkResource_invalidate :: proc "c" (this: ^VkBufferIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_invalidate(this.base, offset, size)
}


/* IVkResource interface wrapper */
VkBuffer_IVkBuffer_retain :: proc "c" (this: ^VkBufferIVkBuffer) -> u64 {
    if this == nil {
        return 0
    }

    return VkBuffer_retain(this.base)
}

VkBuffer_IVkBuffer_release :: proc "c" (this: ^VkBufferIVkBuffer) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkBuffer_release(this.base)
}

VkBuffer_IVkBuffer_queryInterface :: proc "c" (this: ^VkBufferIVkBuffer, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_queryInterface(this.base, id)
}

VkBuffer_IVkBuffer_getParent :: proc "c" (this: ^VkBufferIVkBuffer) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkBuffer_getParent(this.base)
}

VkBuffer_IVkBuffer_getAllocationInfo :: proc "c" (this: ^VkBufferIVkBuffer, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_getAllocationInfo(this.base, allocationInfo)
}

VkBuffer_IVkBuffer_mapResource :: proc "c" (this: ^VkBufferIVkBuffer) -> rawptr {
    if this == nil {
        return nil
    }

    return VkBuffer_mapResource(this.base)
}

VkBuffer_IVkBuffer_unmapResource :: proc "c" (this: ^VkBufferIVkBuffer) {
    if this == nil {
        return
    }

    VkBuffer_unmapResource(this.base)
}

VkBuffer_IVkBuffer_flush :: proc "c" (this: ^VkBufferIVkBuffer, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_flush(this.base, offset, size)
}

VkBuffer_IVkBuffer_invalidate :: proc "c" (this: ^VkBufferIVkBuffer, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkBuffer_invalidate(this.base, offset, size)
}

VkBuffer_IVkBuffer_getVulkanBuffer :: proc "c" (this: ^VkBufferIVkBuffer) -> vk.Buffer {
    if this == nil {
        return 0
    }

    return VkBuffer_getVulkanBuffer(this.base)
}