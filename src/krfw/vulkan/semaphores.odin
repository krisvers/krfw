/* SemaphorePool implementation */
SemaphorePool_destroy :: proc "c" (this: ^SemaphorePool) {
    if this == nil || this._renderer == nil {
        return
    }

    context = this._renderer._ctx

    if this._isInternal && !this._renderer._performingDestruction {
        _log(this._renderer, .Error, "Can't destroy this semaphore pool as it is internally managed by the renderer")
        return
    }

    if len(this._semaphores) != 0 {
        if this._renderer._device.deviceWaitIdle(this._renderer._device.logical) != .SUCCESS {
            _log(this._renderer, .Warning, "Failed to wait for device to idle when destroying semaphore pool; ignoring failure")
        }

        for semaphore in this._semaphores {
            this._renderer._device.destroySemaphore(this._renderer._device.logical, semaphore, this._renderer._allocator)
        }
    }

    delete(this._unusedSemaphoreIndices)
    delete(this._semaphores)
}

SemaphorePool_acquire :: proc "c" (this: ^SemaphorePool) -> vk.Semaphore {
    if this == nil || this._renderer == nil {
        return 0
    }
    
    context = this._renderer._ctx

    if len(this._unusedSemaphoreIndices) == 0 {
        ci := vk.SemaphoreCreateInfo {
            sType = .SEMAPHORE_CREATE_INFO,
        }

        semaphore: vk.Semaphore
        if this._renderer._device.createSemaphore(this._renderer._device.logical, &ci, this._renderer._allocator, &semaphore) != .SUCCESS {
            _log(this._renderer, .Error, "Failed to create Vulkan semaphore")
            return 0
        }

        append(&this._semaphores, semaphore)
        return semaphore
    }

    unusedSemaphoreIndex := pop(&this._unusedSemaphoreIndices)
    semaphore := this._semaphores[unusedSemaphoreIndex]

    return semaphore
}

SemaphorePool_release :: proc "c" (this: ^SemaphorePool, semaphore: vk.Semaphore) {
    if this == nil || this._renderer == nil {
        return
    }
    
    context = this._renderer._ctx

    for i in 0..<len(this._semaphores) {
        if semaphore == this._semaphores[i] {
            for u in this._unusedSemaphoreIndices {
                if u == u32(i) {
                    _log(this._renderer, .Warning, "Can't release semaphore: provided semaphore has already been released and is unused")
                    return
                }
            }

            inject_at(&this._unusedSemaphoreIndices, 0, u32(i))
            return
        }
    }

    _log(this._renderer, .Warning, "Can't release semaphore: provided semaphore not found in this pool")
}
