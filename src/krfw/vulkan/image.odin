#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"
import "vma"

VkImageData :: struct {
    _refCount:      u64,
    _ctx:           ^runtime.Context,

    _resourcePool:  ^VkResourcePool,
    _allocation:    vma.Allocation,

    _isPersistent:  bool,
    _isBackbuffer:  bool,

    _image:         vk.Image,
    _layout:        vk.ImageLayout,
}

VkImageIBase :: struct {
    interface:  kom.IBase,
    base:       ^VkImage,
}

VkImageIChild :: struct {
    interface:  kom.IChild,
    base:       ^VkImage,
}

VkImageIVkResource :: struct {
    interface:  IVkResource,
    base:       ^VkImage,
}

VkImageIVkImage :: struct {
    interface:  IVkImage,
    base:       ^VkImage,
}

VkImage :: struct {
    using _:        VkImageData,

    ibase:          VkImageIBase,
    ichild:         VkImageIChild,
    ivkresource:    VkImageIVkResource,
    ivkimage:       VkImageIVkImage,
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
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)

    if this._isBackbuffer && !renderer.base._performingDestruction {
        log(renderer.base, .Warning, "Can't fully release image: is internal backbuffer (likely a double release or a missing retain)")
        this._refCount = 1
        return max(u64)
    }

    assert(this._allocation != nil)
    vma.destroy_image(renderer.base._vma, this._image, this._allocation)

    delete(this)
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
    assert(pool != nil)

    return &pool.ibase
}

/* IVkResource */
VkImage_getAllocationInfo :: proc "c" (this: ^VkImage, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)
    assert(allocationInfo != nil)

    vma.get_allocation_info(renderer.base._vma, this._allocation, allocationInfo)
    return true
}

VkImage_mapResource :: proc "c" (this: ^VkImage) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    pool := this._resourcePool
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)

    allocationInfo: vma.Allocation_Info
    vma.get_allocation_info(renderer.base._vma, this._allocation, &allocationInfo)

    if this._isPersistent {
        return allocationInfo.mapped_data
    }

    data: rawptr
    if vma.map_memory(renderer.base._vma, this._allocation, &data) != .SUCCESS {
        log(renderer.base, .Error, "Failed to map image memory")
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
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)
    
    if this._isPersistent {
        return
    }

    vma.unmap_memory(renderer.base._vma, this._allocation)
}

VkImage_flush :: proc "c" (this: ^VkImage, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil || this._ctx == nil {
        return false
    }

    context = this._ctx^

    pool := this._resourcePool
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)
    
    if this._isBackbuffer {
        log(renderer.base, .Error, "Can't flush image resource: is internally-managed backbuffer")
        return false
    }

    if vma.flush_allocation(renderer.base._vma, this._allocation, offset, size) != .SUCCESS {
        log(renderer.base, .Error, "Failed to flush image resource")
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
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)
    
    if this._isBackbuffer {
        log(renderer.base, .Error, "Can't invalidate image resource: is internally-managed backbuffer")
        return false
    }

    if vma.invalidate_allocation(renderer.base._vma, this._allocation, offset, size) != .SUCCESS {
        log(renderer.base, .Error, "Failed to invalidate image resource")
        return false
    }

    return true
}

/* IVkImage */
VkImage_getVulkanImage :: proc "c" (this: ^VkImage) -> vk.Image {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^

    pool := this._resourcePool
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)

    return this._image
}

VkImage_getLayout :: proc "c" (this: ^VkImage) -> vk.ImageLayout {
    if this == nil || this._ctx == nil {
        return .UNDEFINED
    }

    context = this._ctx^

    pool := this._resourcePool
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)

    return this._layout
}

VkImage_setLayout :: proc "c" (this: ^VkImage, layout: vk.ImageLayout) {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^

    pool := this._resourcePool
    device := kom.getParent(&pool.ichild, IVkDevice_IID, IVkDevice)
    assert(device != nil)

    renderer := kom.queryInterface(device, IVkRenderer_IID, VkRendererIVkRenderer)
    assert(renderer != nil)

    this._layout = layout
}

/* IBase interface wrapper */
VkImage_IBase_retain :: proc "c" (this: ^VkImageIBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkImage_retain(this.base)
}

VkImage_IBase_release :: proc "c" (this: ^VkImageIBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkImage_release(this.base)
}

VkImage_IBase_queryInterface :: proc "c" (this: ^VkImageIBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_queryInterface(this.base, id)
}

/* IChild interface wrapper */
VkImage_IChild_retain :: proc "c" (this: ^VkImageIChild) -> u64 {
    if this == nil {
        return 0
    }

    return VkImage_retain(this.base)
}

VkImage_IChild_release :: proc "c" (this: ^VkImageIChild) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkImage_release(this.base)
}

VkImage_IChild_queryInterface :: proc "c" (this: ^VkImageIChild, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_queryInterface(this.base, id)
}

VkImage_IChild_getParent :: proc "c" (this: ^VkImageIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkImage_getParent(this.base)
}

/* IVkResource interface wrapper */
VkImage_IVkResource_retain :: proc "c" (this: ^VkImageIVkResource) -> u64 {
    if this == nil {
        return 0
    }

    return VkImage_retain(this.base)
}

VkImage_IVkResource_release :: proc "c" (this: ^VkImageIVkResource) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkImage_release(this.base)
}

VkImage_IVkResource_queryInterface :: proc "c" (this: ^VkImageIVkResource, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_queryInterface(this.base, id)
}

VkImage_IVkResource_getParent :: proc "c" (this: ^VkImageIVkResource) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkImage_getParent(this.base)
}

VkImage_IVkResource_getAllocationInfo :: proc "c" (this: ^VkImageIVkResource, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_getAllocationInfo(this.base, allocationInfo)
}

VkImage_IVkResource_mapResource :: proc "c" (this: ^VkImageIVkResource) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_mapResource(this.base)
}

VkImage_IVkResource_unmapResource :: proc "c" (this: ^VkImageIVkResource) {
    if this == nil {
        return
    }

    VkImage_unmapResource(this.base)
}

VkImage_IVkResource_flush :: proc "c" (this: ^VkImageIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_flush(this.base, offset, size)
}

VkImage_IVkResource_invalidate :: proc "c" (this: ^VkImageIVkResource, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_invalidate(this.base, offset, size)
}


/* IVkResource interface wrapper */
VkImage_IVkImage_retain :: proc "c" (this: ^VkImageIVkImage) -> u64 {
    if this == nil {
        return 0
    }

    return VkImage_retain(this.base)
}

VkImage_IVkImage_release :: proc "c" (this: ^VkImageIVkImage) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkImage_release(this.base)
}

VkImage_IVkImage_queryInterface :: proc "c" (this: ^VkImageIVkImage, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_queryInterface(this.base, id)
}

VkImage_IVkImage_getParent :: proc "c" (this: ^VkImageIVkImage) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkImage_getParent(this.base)
}

VkImage_IVkImage_getAllocationInfo :: proc "c" (this: ^VkImageIVkImage, allocationInfo: ^vma.Allocation_Info) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_getAllocationInfo(this.base, allocationInfo)
}

VkImage_IVkImage_mapResource :: proc "c" (this: ^VkImageIVkImage) -> rawptr {
    if this == nil {
        return nil
    }

    return VkImage_mapResource(this.base)
}

VkImage_IVkImage_unmapResource :: proc "c" (this: ^VkImageIVkImage) {
    if this == nil {
        return
    }

    VkImage_unmapResource(this.base)
}

VkImage_IVkImage_flush :: proc "c" (this: ^VkImageIVkImage, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_flush(this.base, offset, size)
}

VkImage_IVkImage_invalidate :: proc "c" (this: ^VkImageIVkImage, offset: vk.DeviceSize, size: vk.DeviceSize) -> b32 {
    if this == nil {
        return false
    }

    return VkImage_invalidate(this.base, offset, size)
}

VkImage_IVkImage_getVulkanImage :: proc "c" (this: ^VkImageIVkImage) -> vk.Image {
    if this == nil {
        return 0
    }

    return VkImage_getVulkanImage(this.base)
}

VkImage_IVkImage_getLayout :: proc "c" (this: ^VkImageIVkImage) -> vk.ImageLayout {
    if this == nil {
        return .UNDEFINED
    }

    return VkImage_getLayout(this.base)
}

VkImage_IVkImage_setLayout :: proc "c" (this: ^VkImageIVkImage, layout: vk.ImageLayout) {
    if this == nil {
        return
    }

    VkImage_setLayout(this.base, layout)
}