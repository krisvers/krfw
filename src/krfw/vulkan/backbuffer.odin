/* BackbufferPool implementation */
BackbufferPool_acquire :: proc "c" (this: ^BackbufferPool, mode: BackbufferPoolAcquisitionMode) -> ^Backbuffer {
    if this == nil || this._renderer == nil {
        return nil
    }

    context = this._renderer._ctx

    if this._swapchain == 0 {
        _log(this._renderer, .Error, "Can't acquire backbuffer: backbuffer pool not fully initialized")
        return nil
    }

    fence := vk.Fence(0)
    if .Fence in mode {
        if this._fencePool == nil {
            _log(this._renderer, .Error, "Fence requested, but this backbuffer pool was not initialized with a fence pool")
            return nil
        }

        fence = this._fencePool->acquire()
        if fence == 0 {
            _log(this._renderer, .Error, "Failed to acquire fence")
            return nil
        }
    }

    semaphore := vk.Semaphore(0)
    if .Semaphore in mode {
        if this._semaphorePool == nil {
            _log(this._renderer, .Error, "Semaphore requested, but this backbuffer pool was not initialized with a semaphore pool")
            return nil
        }

        semaphore = this._semaphorePool->acquire()
        if semaphore == 0 {
            _log(this._renderer, .Error, "Failed to acquire semaphore")
            if fence != 0 {
                this._fencePool->release(fence)
            }

            return nil
        }
    }

    /* TODO: handle swapchain resizing and non-errors but unfavorable conditions/future errors */
    imageIndex: u32
    if this._renderer._device.khr.swapchain.acquireNextImage(this._renderer._device.logical, this._swapchain, max(u64), semaphore, fence, &imageIndex) != .SUCCESS {
        _log(this._renderer, .Error, "Failed to acquire next image for backbuffer pool")
        if fence != 0 {
            this._fencePool->release(fence)
        }
        
        if semaphore != 0 {
            this._semaphorePool->release(semaphore)
        }
        
        return nil
    }

    this._backbuffers[imageIndex].fence = fence
    this._backbuffers[imageIndex].semaphore = semaphore

    return &this._backbuffers[imageIndex]
}

BackbufferPool_release :: proc "c" (this: ^BackbufferPool, backbuffer: ^Backbuffer) {
    if backbuffer.fence != 0 {
        this._fencePool->release(backbuffer.fence)
    }
    
    if backbuffer.semaphore != 0 {
        this._semaphorePool->release(backbuffer.semaphore)
    }
}