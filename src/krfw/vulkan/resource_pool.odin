#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"
import "vma"

VkResourcePoolData :: struct {
    _refCount:      u64,
    _ctx:           ^runtime.Context,

    _device:        ^VkDevice,
    _pool:          vma.Pool,

    _isInternal:    b32,
}

VkResourcePoolIBase :: struct {
    interface:  kom.IBase,
    base:       ^VkResourcePool,
}

VkResourcePoolIChild :: struct {
    interface:  kom.IChild,
    base:       ^VkResourcePool,
}

VkResourcePoolIVkResourcePool :: struct {
    interface:  IVkResourcePool,
    base:       ^VkResourcePool,
}

VkResourcePool :: struct {
    using _:            VkResourcePoolData,

    ibase:              VkResourcePoolIBase,
    ichild:             VkResourcePoolIChild,
    ivkresourcepool:    VkResourcePoolIVkResourcePool,
}

/* IBase */
VkResourcePool_retain :: proc "c" (this: ^VkResourcePool) -> u64 {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._refCount += 1

    return this._refCount
}

VkResourcePool_release :: proc "c" (this: ^VkResourcePool) -> u64 {
    if this == nil || this._ctx == nil {
        return
    }

    context = this._ctx^
    this._refCount -= 1
    if this._refCount != 0 {
        return this._refCount
    }

    device := this._device
    renderer := device._renderer

    if this._isInternal {
        if renderer._performingDestruction {
            return
        }
        
        _log(renderer, .Warning, "Can't destroy this resource pool as it is internally managed by the renderer")
        this._refCount = 1
        return this._refCount
    }

    vma.destroy_pool(renderer._vma, this._pool)
    delete(this)

    return 0
}

VkResourcePool_queryInterface :: proc "c" (this: ^VkResourcePool, #by_ptr id: kom.IID) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    switch id {
        case kom.IBase_IID:
            return &this.ibase
        case kom.IChild_IID:
            return &this.ichild
        case IVkResourcePool_IID:
            return &this.ivkresourcepool
        case:
            break
    }

    return nil
}

/* IChild */
VkResourcePool_getParent :: proc "c" (this: ^VkResourcePool) -> ^kom.IBase {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    device := this._device
    return &device.ibase
}

/* IVkResourcePool */
VkResourcePool_createBuffer :: proc "c" (this: ^VkResourcePool, createInfo: ^vk.BufferCreateInfo, allocationCreateInfo: ^vma.Allocation_Create_Info) -> ^IVkBuffer {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    
    pool := this._pool
    device := this._device
    renderer := device._renderer

    if createInfo == nil {
        _log(renderer, .Error, "Can't create buffer: invalid pointer to VkBufferCreateInfo")
        return nil
    }

    if allocationCreateInfo == nil {
        _log(renderer, .Error, "Can't create image: invalid pointer to VmaAllocationCreateInfo")
        return nil
    }

    ai := allocationCreateInfo^
    ai.pool = pool

    vkBuffer: vk.Buffer
    allocation: vma.Allocation
    if vma.create_buffer(renderer._vma, createInfo^, ai, &vkBuffer, &allocation, nil) != .SUCCESS {
        _log(renderer, .Error, "Failed to create and allocate buffer")
        return nil
    }
    
    buffer := new(VkBuffer)
    /* TODO: instantiate buffer */

    return buffer
}

VkResourcePool_createImage :: proc "c" (this: ^VkResourcePool, createInfo: ^vk.ImageCreateInfo, allocationCreateInfo: ^vma.Allocation_Create_Info) -> ^IVkImage {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    
    pool := this._pool
    device := this._device
    renderer := device._renderer

    if createInfo == nil {
        _log(renderer, .Error, "Can't create image: invalid pointer to VkImageCreateInfo")
        return nil
    }

    if allocationCreateInfo == nil {
        _log(renderer, .Error, "Can't create image: invalid pointer to VmaAllocationCreateInfo")
        return nil
    }

    ai := allocationCreateInfo^
    ai.pool = pool

    vkImage: vk.Image
    allocation: vma.Allocation
    if vma.create_image(renderer._vma, createInfo^, ai, &vkImage, &allocation, nil) != .SUCCESS {
        _log(renderer, .Error, "Failed to create and allocate buffer")
        return nil
    }

    image := new(VkImage)

    image^ = {
        _refCount       = 1,
        _ctx            = this._ctx,

        _resourcePool   = this,
        _allocation     = allocation,

        _isPersistent   = .Mapped in allocationCreateInfo.flags,
        _isBackbuffer   = false,

        _image          = vkImage,
        _layout         = .UNDEFINED,

        ibase
    }

    return image
}