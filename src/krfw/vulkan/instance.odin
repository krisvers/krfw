#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"

VkInstanceData :: struct {
    _refCount:      u64,
    _ctx:           ^runtime.Context,

    _renderer:      ^VkRenderer,

    _instance:      vk.Instance,
}

VkInstanceIBase :: struct {
    interface:  kom.IBase,
    base:       ^VkInstance,
}

VkInstanceIChild :: struct {
    interface:  kom.IChild,
    base:       ^VkInstance,
}

VkInstanceIVkInstance :: struct {
    interface:  IVkInstance,
    base:       ^VkInstance,
}

VkInstance :: struct {
    using _:        VkInstanceData,

    ibase:          VkInstanceIBase,
    ichild:         VkInstanceIChild,
    ivkinstance:    VkInstanceIVkInstance,
}

/* IBase */
VkInstance_retain :: proc "c" (this: ^VkInstance) -> u64 {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._refCount += 1

    return this._refCount
}

VkInstance_release :: proc "c" (this: ^VkInstance) -> u64 {
    if this == nil || this._ctx == nil {
        return max(u64)
    }

    context = this._ctx^
    this._refCount -= 1
    if this._refCount != 0 {
        return this._refCount
    }

    renderer := this._renderer
    if !renderer._performingDestruction {
        log(renderer, .Warning, "Can't fully release instance: is internally managed")
        this._refCount = 1
        return max(u64)
    }

    this.ivkinstance.interface.destroyInstance(this._instance, renderer._allocator)
    delete(this)

    return 0
}

VkInstance_queryInterface :: proc "c" (this: ^VkInstance, #by_ptr id: kom.IID) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    switch id {
        case kom.IBase_IID:
            return &this.ibase
        case kom.IChild_IID:
            return &this.ichild
        case IVkInstance_IID:
            return &this.ivkinstance
        case:
            break
    }

    return nil
}

/* IChild */
VkInstance_getParent :: proc "c" (this: ^VkInstance) -> ^kom.IBase {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    renderer := this._renderer
    return &renderer.ibase
}

/* IVkInstance */
VkInstance_getVulkanInstance :: proc "c" (this: ^VkInstance) -> vk.Instance {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    return this._instance
}

/* IBase interface wrapper */
VkInstance_IBase_retain :: proc "c" (this: ^VkInstanceIBase) -> u64 {
    if this == nil {
        return 0
    }

    return VkInstance_retain(this.base)
}

VkInstance_IBase_release :: proc "c" (this: ^VkInstanceIBase) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkInstance_release(this.base)
}

VkInstance_IBase_queryInterface :: proc "c" (this: ^VkInstanceIBase, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkInstance_queryInterface(this.base, id)
}

/* IChild interface wrapper */
VkInstance_IChild_retain :: proc "c" (this: ^VkInstanceIChild) -> u64 {
    if this == nil {
        return 0
    }

    return VkInstance_retain(this.base)
}

VkInstance_IChild_release :: proc "c" (this: ^VkInstanceIChild) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkInstance_release(this.base)
}

VkInstance_IChild_queryInterface :: proc "c" (this: ^VkInstanceIChild, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkInstance_queryInterface(this.base, id)
}

VkInstance_IChild_getParent :: proc "c" (this: ^VkInstanceIChild) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkInstance_getParent(this.base)
}

/* IVkInstance interface wrapper */
VkInstance_IVkInstance_retain :: proc "c" (this: ^VkInstanceIVkInstance) -> u64 {
    if this == nil {
        return 0
    }

    return VkInstance_retain(this.base)
}

VkInstance_IVkInstance_release :: proc "c" (this: ^VkInstanceIVkInstance) -> u64 {
    if this == nil {
        return max(u64)
    }

    return VkInstance_release(this.base)
}

VkInstance_IVkInstance_queryInterface :: proc "c" (this: ^VkInstanceIVkInstance, #by_ptr id: kom.IID) -> rawptr {
    if this == nil {
        return nil
    }

    return VkInstance_queryInterface(this.base, id)
}

VkInstance_IVkInstance_getParent :: proc "c" (this: ^VkInstanceIVkInstance) -> ^kom.IBase {
    if this == nil {
        return nil
    }

    return VkInstance_getParent(this.base)
}

VkInstance_IVkInstance_getVulkanInstance :: proc "c" (this: ^VkInstanceIVkInstance) -> vk.Instance {
    if this == nil {
        return 0
    }

    return VkInstance_getVulkanInstance(this.base)
}