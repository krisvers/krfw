#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"
import "vma"

VkResourcePoolData :: struct {
    _refCount:      u64,
    _ctx:           ^runtime.Context,

    _renderer:      ^VkRenderer,
    _pool:          vma.Pool,

    _isInternal:    b32,
}

VkResourcePoolIBase :: struct {
    base:       ^VkResourcePool,
    interface:  kom.IBase,
}

VkResourcePoolIChild :: struct {
    base:       ^VkResourcePool,
    interface:  kom.IChild,
}

VkResourcePoolIVkResourcePool :: struct {
    base:       ^VkResourcePool,
    interface:  IVkResourcePool,
}

VkResourcePool :: struct {
    using _:            VkResourcePoolData,

    ibase:              VkResourcePoolIBase,
    ichild:             VkResourcePoolIChild,
    ivkresourcepool:    VkResourcePoolIVkResourcePool,
}

/* initializer */
VkResourcePool_new :: proc(renderer: ^VkRenderer, pool: vma.Pool, isInternal := b32(false)) -> ^VkResourcePool {
    resourcePool := new(VkResourcePool)

    resourcePool^ = {
        _refCount       = 1,
        _ctx            = &renderer._ctx,

        _renderer       = renderer,
        _pool           = pool,

        _isInternal     = isInternal,

        ibase           = {
            base        = resourcePool,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkResourcePool_IBase_retain),
                release         = kom.ProcIBaseRelease(VkResourcePool_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkResourcePool_IBase_queryInterface),
            },
        },
    
        ichild          = {
            base        = resourcePool,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkResourcePool_IBase_retain),
                release         = kom.ProcIBaseRelease(VkResourcePool_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkResourcePool_IBase_queryInterface),
                
                /* IChild */
                getParent       = kom.ProcIChildGetParent(VkResourcePool_IChild_getParent),
            },
        },

        ivkresourcepool = {
            base        = resourcePool,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkResourcePool_IBase_retain),
                release         = kom.ProcIBaseRelease(VkResourcePool_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkResourcePool_IBase_queryInterface),
            
                /* IChild */
                getParent       = kom.ProcIChildGetParent(VkResourcePool_IChild_getParent),

                /* IVkResourcePool */
                createBuffer    = ProcIVkResourcePoolCreateBuffer(VkResourcePool_IVkResourcePool_createBuffer),
                createImage     = ProcIVkResourcePoolCreateImage(VkResourcePool_IVkResourcePool_createImage),
            },
        },
    }

    return resourcePool
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
        return max(u64)
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

    free(this)
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

    renderer := this._renderer
    return &renderer.ibase
}

/* IVkResourcePool */
VkResourcePool_getVmaPool :: proc "c" (this: ^VkResourcePool) -> vma.Pool {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    return this._pool
}

VkResourcePool_createBuffer :: proc "c" (this: ^VkResourcePool, #by_ptr createInfo: vk.BufferCreateInfo, #by_ptr allocationCreateInfo: vma.Allocation_Create_Info) -> ^IVkBuffer {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    
    pool := this._pool
    renderer := this._renderer

    ai := allocationCreateInfo
    ai.pool = pool

    vkBuffer: vk.Buffer
    allocation: vma.Allocation
    if vma.create_buffer(renderer._vma, createInfo, ai, &vkBuffer, &allocation, nil) != .SUCCESS {
        _log(renderer, .Error, "Failed to create and allocate buffer")
        return nil
    }
    
    return &VkBuffer_new(this, allocation, vkBuffer, .Mapped in allocationCreateInfo.flags, isConcurrent = (createInfo.sharingMode == .CONCURRENT)).ivkbuffer
}

VkResourcePool_createImage :: proc "c" (this: ^VkResourcePool, #by_ptr createInfo: vk.ImageCreateInfo, #by_ptr allocationCreateInfo: vma.Allocation_Create_Info) -> ^IVkImage {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    
    pool := this._pool
    device := this._device
    renderer := device._renderer

    ai := allocationCreateInfo
    ai.pool = pool

    vkImage: vk.Image
    allocation: vma.Allocation
    if vma.create_image(renderer._vma, createInfo, ai, &vkImage, &allocation, nil) != .SUCCESS {
        _log(renderer, .Error, "Failed to create and allocate image")
        return nil
    }

    return &VkImage_new(this, allocation, vkImage, .Mapped in allocationCreateInfo.flags, isConcurrent = (createInfo.sharingMode == .CONCURRENT)).ivkimage
}

VkResourcePool_createAliasedBuffer :: proc "c" (this: ^VkResourcePool, #by_ptr createInfo: vk.BufferCreateInfo, resourceToAlias: ^IVkResource, offset: vk.DeviceSize) -> ^IVkBuffer {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    
    pool := this._pool
    renderer := this._renderer

    if resourceToAlias == nil {
        _log(renderer, .Error, "Can't create aliased buffer: invalid resource to alias")
        return nil
    }

    vkBuffer: vk.Buffer
    if vma.create_aliasing_buffer2(renderer._vma, resourceToAlias->getVmaAllocation(), offset, createInfo, &vkBuffer) != .SUCCESS {
        _log(renderer, .Error, "Failed to create aliased buffer")
        return nil
    }
    
    return &VkBuffer_new(this, resourceToAlias->getVmaAllocation(), vkBuffer, .Mapped in allocationCreateInfo.flags, isConcurrent = (createInfo.sharingMode == .CONCURRENT), aliasOffset = offset).ivkbuffer
}

VkResourcePool_createAliasedImage :: proc "c" (this: ^VkResourcePool, #by_ptr createInfo: vk.ImageCreateInfo, resourceToAlias: ^IVkResource, offset: vk.DeviceSize) -> ^IVkImage {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    
    pool := this._pool
    renderer := this._renderer

    if resourceToAlias == nil {
        _log(renderer, .Error, "Can't create aliased image: invalid resource to alias")
        return nil
    }

    vkImage: vk.Image
    if vma.create_aliasing_image2(renderer._vma, resourceToAlias->getVmaAllocation(), offset, createInfo, &vkImage) != .SUCCESS {
        _log(renderer, .Error, "Failed to create aliased image")
        return nil
    }
    
    return &VkImage_new(this, resourceToAlias->getVmaAllocation(), vkImage, .Mapped in allocationCreateInfo.flags, isConcurrent = (createInfo.sharingMode == .CONCURRENT), aliasOffset = offset).ivkimage
}

/* IBase interface wrapper */
VkResourcePool_IBase_retain :: proc "c" (this: ^VkResourcePoolIBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkResourcePool_retain(getBaseFromInterface(this))
}

VkResourcePool_IBase_release :: proc "c" (this: ^VkResourcePoolIBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkResourcePool_release(getBaseFromInterface(this))
}

VkResourcePool_IBase_queryInterface :: proc "c" (this: ^VkResourcePoolIBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkResourcePool_queryInterface(getBaseFromInterface(this), id)
}

/* IChild interface wrapper */
VkResourcePool_IChild_getParent :: proc "c" (this: ^VkResourcePoolIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkResourcePool_getParent(getBaseFromInterface(this))
}

/* IVkResourcePool interface wrapper */
VkResourcePool_IVkResourcePool_getVmaPool :: proc "c" (this: ^VkResourcePoolIVkResourcePool) -> vma.Pool {
    if this == nil {
        return nil
    }

    return VkResourcePool_getVmaPool(getBaseFromInterface(this))
}

VkResourcePool_IVkResourcePool_createBuffer :: proc "c" (this: ^VkResourcePoolIVkResourcePool, #by_ptr createInfo: vk.BufferCreateInfo, #by_ptr allocationCreateInfo: vma.Allocation_Create_Info) -> ^IVkBuffer {
    if this == nil {
        return nil
    }

    return VkResourcePool_createBuffer(getBaseFromInterface(this), createInfo, allocationCreateInfo)
}

VkResourcePool_IVkResourcePool_createImage :: proc "c" (this: ^VkResourcePoolIVkResourcePool, #by_ptr createInfo: vk.ImageCreateInfo, #by_ptr allocationCreateInfo: vma.Allocation_Create_Info) -> ^IVkImage {
    if this == nil {
        return nil
    }

    return VkResourcePool_createImage(getBaseFromInterface(this), createInfo, allocationCreateInfo)
}

VkResourcePool_IVkResourcePool_createAliasedBuffer :: proc "c" (this: ^VkResourcePoolIVkResourcePool, #by_ptr createInfo: vk.BufferCreateInfo, resourceToAlias: ^IVkResource, offset: vk.DeviceSize) -> ^IVkBuffer {
    if this == nil {
        return nil
    }

    return VkResourcePool_createAliasedBuffer(getBaseFromInterface(this), createInfo, resourceToAlias, offset)
}

VkResourcePool_IVkResourcePool_createAliasedImage :: proc "c" (this: ^VkResourcePoolIVkResourcePool, #by_ptr createInfo: vk.ImageCreateInfo, resourceToAlias: ^IVkResource, offset: vk.DeviceSize) -> ^IVkImage {
    if this == nil {
        return nil
    }

    return VkResourcePool_createAliasedImage(getBaseFromInterface(this), createInfo, resourceToAlias, offset)
}