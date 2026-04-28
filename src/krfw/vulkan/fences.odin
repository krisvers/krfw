/* FencePool implementation */
FencePool_destroy :: proc "c" (this: ^FencePool) {
    if this == nil || this._renderer == nil {
        return
    }

    context = this._renderer._ctx

    if this._isInternal && !this._renderer._performingDestruction {
        _log(this._renderer, .Error, "Can't destroy this fence pool as it is internally managed by the renderer")
        return
    }

    if len(this._fences) != 0 {
        if this._renderer._device.waitForFences(this._renderer._device.logical, u32(len(this._fences)), &this._fences[0], true, max(u64)) != .SUCCESS {
            _log(this._renderer, .Warning, "Failed to wait for all fences to be signaled when destroying fence pool; attempting wait device")

            if this._renderer._device.deviceWaitIdle(this._renderer._device.logical) != .SUCCESS {
                _log(this._renderer, .Warning, "Failed to wait for device to idle when destroying fence pool; ignoring failure")
            }
        }

        for fence in this._fences {
            this._renderer._device.destroyFence(this._renderer._device.logical, fence, this._renderer._allocator)
        }
    }

    delete(this._unusedFenceIndices)
    delete(this._fences)
}

FencePool_acquire :: proc "c" (this: ^FencePool, signaled := b32(false)) -> vk.Fence {
    if this == nil || this._renderer == nil {
        return 0
    }
    
    context = this._renderer._ctx

    if len(this._unusedFenceIndices) == 0 || signaled {
        ci := vk.FenceCreateInfo {
            sType = .FENCE_CREATE_INFO,
            flags = signaled ? { .SIGNALED } : {},
        }

        fence: vk.Fence
        if this._renderer._device.createFence(this._renderer._device.logical, &ci, this._renderer._allocator, &fence) != .SUCCESS {
            _log(this._renderer, .Error, "Failed to create Vulkan fence")
            return 0
        }

        append(&this._fences, fence)
        return fence
    }

    unusedFenceIndex := pop(&this._unusedFenceIndices)
    fence := this._fences[unusedFenceIndex]

    if this._renderer._device.resetFences(this._renderer._device.logical, 1, &fence) != .SUCCESS {
        _log(this._renderer, .Error, "Failed to reset Vulkan fence")
        return 0
    }

    return fence
}

FencePool_release :: proc "c" (this: ^FencePool, fence: vk.Fence) {
    if this == nil || this._renderer == nil {
        return
    }
    
    context = this._renderer._ctx

    for i in 0..<len(this._fences) {
        if fence == this._fences[i] {
            for u in this._unusedFenceIndices {
                if u == u32(i) {
                    _log(this._renderer, .Warning, "Can't release fence: provided fence has already been released and is unused")
                    return
                }
            }

            inject_at(&this._unusedFenceIndices, 0, u32(i))
            return
        }
    }

    _log(this._renderer, .Warning, "Can't release fence: provided fence not found in this pool")
}