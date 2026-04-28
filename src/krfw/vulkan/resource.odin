/* ResourcePool implementation */
ResourcePool_destroy :: proc "c" (this: ^ResourcePool) {
    if this == nil || this._renderer == nil {
        return
    }

    context = this._renderer._ctx

    if this._isInternal {
        if this._renderer._performingDestruction {
            return
        }
        
        _log(this._renderer, .Error, "Can't destroy this resource pool as it is internally managed by the renderer")
        return
    }

    vma.destroy_pool(this._renderer._vma, this._pool)
    this._pool = nil
}

ResourcePool_createBuffer :: proc "c" (this: ^ResourcePool, buffer: ^Buffer, createInfo: ^vk.BufferCreateInfo, allocationCreateInfo: ^vma.Allocation_Create_Info) -> b32 {
    if this == nil || this._renderer == nil {
        return false
    }

    context = this._renderer._ctx

    if buffer == nil {
        _log(this._renderer, .Error, "Can't create buffer: invalid pointer to Buffer")
        return false
    }

    if createInfo == nil {
        _log(this._renderer, .Error, "Can't create buffer: invalid pointer to VkBufferCreateInfo")
        return false
    }

    if allocationCreateInfo == nil {
        _log(this._renderer, .Error, "Can't create image: invalid pointer to VmaAllocationCreateInfo")
        return false
    }

    ai := allocationCreateInfo^
    ai.pool = this._pool

    vkBuffer: vk.Buffer
    allocation: vma.Allocation
    if vma.create_buffer(this._renderer._vma, createInfo^, ai, &vkBuffer, &allocation, nil) != .SUCCESS {
        _log(this._renderer, .Error, "Failed to create and allocate buffer")
        return false
    }

    buffer^ = {
        destroy             = ProcIResourceDestroy(Buffer_destroy),
        getAllocationInfo   = IResource_getAllocationInfo,
        mapResource         = IResource_mapResource,
        unmapResource       = IResource_unmapResource,
        flush               = IResource_flush,
        invalidate          = IResource_invalidate,
        getVulkanBuffer     = Buffer_getVulkanBuffer,

        _pool               = this,
        _allocation         = allocation,
        _buffer             = vkBuffer,

        _isPersistent       = .Mapped in allocationCreateInfo.flags,
    }

    return true
}

ResourcePool_createImage :: proc "c" (this: ^ResourcePool, image: ^Image, createInfo: ^vk.ImageCreateInfo, allocationCreateInfo: ^vma.Allocation_Create_Info) -> b32 {
    if this == nil || this._renderer == nil {
        return false
    }

    context = this._renderer._ctx

    if image == nil {
        _log(this._renderer, .Error, "Can't create image: invalid pointer to Image")
        return false
    }

    if createInfo == nil {
        _log(this._renderer, .Error, "Can't create image: invalid pointer to VkImageCreateInfo")
        return false
    }

    if allocationCreateInfo == nil {
        _log(this._renderer, .Error, "Can't create image: invalid pointer to VmaAllocationCreateInfo")
        return false
    }

    ai := allocationCreateInfo^
    ai.pool = this._pool

    vkImage: vk.Image
    allocation: vma.Allocation
    if vma.create_image(this._renderer._vma, createInfo^, ai, &vkImage, &allocation, nil) != .SUCCESS {
        _log(this._renderer, .Error, "Failed to create and allocate buffer")
        return false
    }

    image^ = {
        destroy             = ProcIResourceDestroy(Image_destroy),
        getAllocationInfo   = IResource_getAllocationInfo,
        getVulkanImage      = Image_getVulkanImage,

        _pool               = this,
        _allocation         = allocation,
        _image              = vkImage,
        _layout             = .UNDEFINED,

        _isPersistent       = .Mapped in allocationCreateInfo.flags,
    }

    return true
}

/* IResource implementation */
IResource_getAllocationInfo :: proc "c" (this: ^IResource, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return false
    }

    context = this._pool._renderer._ctx

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Failed to get allocation info for resource: resource is invalid")
        return false
    }

    vma.get_allocation_info(this._pool._renderer._vma, this._allocation, allocationInfo)
    return true
}

IResource_mapResource :: proc "c" (this: ^IResource) -> rawptr {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return nil
    }

    context = this._pool._renderer._ctx

    if this._isBackbuffer {
        _log(this._pool._renderer, .Error, "Can't map resource: resource is a backbuffer")
        return nil
    }

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't map resource: resource is invalid")
        return nil
    }

    if this._isPersistent {
        allocationInfo: vma.Allocation_Info
        vma.get_allocation_info(this._pool._renderer._vma, this._allocation, &allocationInfo)

        return allocationInfo.mapped_data
    }

    mapped: rawptr
    if vma.map_memory(this._pool._renderer._vma, this._allocation, &mapped) != .SUCCESS {
        _log(this._pool._renderer, .Error, "Failed to map memory for resource")
        return nil
    }

    return mapped
}

IResource_unmapResource :: proc "c" (this: ^IResource) {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return
    }

    context = this._pool._renderer._ctx

    if this._isBackbuffer {
        _log(this._pool._renderer, .Error, "Can't unmap resource: resource is a backbuffer")
        return
    }

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't unmap resource: resource is invalid")
        return
    }

    if this._isPersistent {
        return
    }

    vma.unmap_memory(this._pool._renderer._vma, this._allocation)
    this._allocation = nil
}

IResource_flush :: proc "c" (this: ^IResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return false
    }

    context = this._pool._renderer._ctx

    if this._isBackbuffer {
        _log(this._pool._renderer, .Error, "Can't flush resource: resource is a backbuffer")
        return false
    }

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't flush resource: resource is invalid")
        return false
    }

    if vma.flush_allocation(this._pool._renderer._vma, this._allocation, offset, size) != .SUCCESS {
        _log(this._pool._renderer, .Error, "Failed to flush resource")
        return false
    }

    return true
}

IResource_invalidate :: proc "c" (this: ^IResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return false
    }

    context = this._pool._renderer._ctx

    if this._isBackbuffer {
        _log(this._pool._renderer, .Error, "Can't invalidate resource: resource is a backbuffer")
        return false
    }

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't invalidate resource: resource is invalid")
        return false
    }

    if vma.invalidate_allocation(this._pool._renderer._vma, this._allocation, offset, size) != .SUCCESS {
        _log(this._pool._renderer, .Error, "Failed to invalidate resource")
        return false
    }

    return true
}
