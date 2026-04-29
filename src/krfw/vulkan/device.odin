#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"

VkDeviceData :: struct {
    _refCount:      u64,
    _ctx:           ^runtime.Context,

    _instance:      ^VkInstance,

    _physical:      vk.PhysicalDevice,
    _logical:       vk.Device,
}

VkDeviceIBase :: struct {
    interface:  kom.IBase,
    base:       ^VkDevice,
}

VkDeviceIChild :: struct {
    interface:  kom.IChild,
    base:       ^VkDevice,
}

VkDeviceIVkDevice :: struct {
    interface:  IVkDevice,
    base:       ^VkDevice,
}

VkDevice :: struct {
    using _:        VkDeviceData,

    ibase:          VkDeviceIBase,
    ichild:         VkDeviceIChild,
    ivkdevice:      VkDeviceIVkDevice,
}

/* IBase */
VkDevice_retain :: proc "c" (this: ^VkDevice) -> u64 {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._refCount += 1

    return this._refCount
}

VkDevice_release :: proc "c" (this: ^VkDevice) -> u64 {
    if this == nil || this._ctx == nil {
        return max(u64)
    }

    context = this._ctx^
    this._refCount -= 1
    if this._refCount != 0 {
        return this._refCount
    }

    instance := this._instance
    renderer := instance._renderer
    if !renderer._performingDestruction {
        log(renderer, .Warning, "Can't fully release device: is internally managed")
        this._refCount = 1
        return max(u64)
    }

    this.ivkdevice.interface.destroyDevice(this._logical, renderer._allocator)
    delete(this)

    return 0
}

VkDevice_queryInterface :: proc "c" (this: ^VkDevice, #by_ptr id: kom.IID) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    switch id {
        case kom.IBase_IID:
            return &this.ibase
        case kom.IChild_IID:
            return &this.ichild
        case IVkDevice_IID:
            return &this.ivkdevice
        case:
            break
    }

    return nil
}

/* IChild */
VkDevice_getParent :: proc "c" (this: ^VkDevice) -> ^kom.IBase {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    instance := this._instance
    return &instance.ibase
}

/* IVkDevice */
VkDevice_getVulkanPhysicalDevice :: proc "c" (this: ^VkDevice) -> vk.PhysicalDevice {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    return this._physical
}

VkDevice_getVulkanLogicalDevice :: proc "c" (this: ^VkDevice) -> vk.Device {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    return this._logical
}

/* IBase interface wrapper */
VkDevice_IBase_retain :: proc "c" (this: ^VkDeviceIBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkDevice_retain(this.base)
}

VkDevice_IBase_release :: proc "c" (this: ^VkDeviceIBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkDevice_release(this.base)
}

VkDevice_IBase_queryInterface :: proc "c" (this: ^VkDeviceIBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkDevice_queryInterface(this.base, id)
}

/* IChild interface wrapper */
VkDevice_IChild_retain :: proc "c" (this: ^VkDeviceIChild) -> u64 {
    if this == nil {
        return 0
    }

    return VkDevice_retain(this.base)
}

VkDevice_IChild_release :: proc "c" (this: ^VkDeviceIChild) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkDevice_release(this.base)
}

VkDevice_IChild_queryInterface :: proc "c" (this: ^VkDeviceIChild, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkDevice_queryInterface(this.base, id)
}

VkDevice_IChild_getParent :: proc "c" (this: ^VkDeviceIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkDevice_getParent(this.base)
}

/* IVkDevice interface wrapper */
VkDevice_IVkDevice_retain :: proc "c" (this: ^VkDeviceIVkDevice) -> u64 {
    if this == nil {
        return 0
    }

    return VkDevice_retain(this.base)
}

VkDevice_IVkDevice_release :: proc "c" (this: ^VkDeviceIVkDevice) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkDevice_release(this.base)
}

VkDevice_IVkDevice_queryInterface :: proc "c" (this: ^VkDeviceIVkDevice, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkDevice_queryInterface(this.base, id)
}

VkDevice_IVkDevice_getParent :: proc "c" (this: ^VkDeviceIVkDevice) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkDevice_getParent(this.base)
}

VkDevice_IVkDevice_getVulkanPhysicalDevice :: proc "c" (this: ^VkDeviceIVkDevice) -> vk.PhysicalDevice {
    if this == nil {
        return 0
    }

    return VkDevice_getVulkanPhysicalDevice(this.base)
}

VkDevice_IVkDevice_getVulkanLogicalDevice :: proc "c" (this: ^VkDeviceIVkDevice) -> vk.Device {
    if this == nil {
        return 0
    }

    return VkDevice_getVulkanLogicalDevice(this.base)
}