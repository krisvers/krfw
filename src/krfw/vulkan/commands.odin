/* CommandPool implementation */
CommandPool_destroy :: proc "c" (this: ^CommandPool) {
    if this == nil || this._renderer == nil {
        return
    }

    context = this._renderer._ctx

    if this._isInternal && !this._renderer._performingDestruction {
        _log(this._renderer, .Error, "Can't destroy this command pool as it is internally managed by the renderer")
        return
    }

    if len(this._commandBuffers) != 0 {
        if this._renderer._device.queueWaitIdle(this._queue.queue) != .SUCCESS {
            _log(this._renderer, .Warning, "Failed to wait queue when destroying command pool; attempting wait device")

            if this._renderer._device.deviceWaitIdle(this._renderer._device.logical) != .SUCCESS {
                _log(this._renderer, .Warning, "Failed to wait for device to idle when destroying command pool; ignoring failure")
            }
        }
    }

    this._renderer._device.destroyCommandPool(this._renderer._device.logical, this._commandPool, this._renderer._allocator)

    delete(this._unusedCommandBufferIndices)
    delete(this._commandBuffers)
}

CommandPool_getQueue :: proc "c" (this: ^CommandPool) -> ^Queue {
    if this == nil || this._renderer == nil {
        return nil
    }

    context = this._renderer._ctx

    return this._queue
}

CommandPool_acquire :: proc "c" (this: ^CommandPool, bundle := b32(false)) -> vk.CommandBuffer {
    if this == nil || this._renderer == nil {
        return nil
    }

    context = this._renderer._ctx

    if len(this._unusedCommandBufferIndices) == 0 {
        ai := vk.CommandBufferAllocateInfo {
            sType = .COMMAND_BUFFER_ALLOCATE_INFO,
            commandPool = this._commandPool,
            level = bundle ? .SECONDARY : .PRIMARY,
            commandBufferCount = 1,
        }

        commandBuffer: vk.CommandBuffer
        if this._renderer._device.allocateCommandBuffers(this._renderer._device.logical, &ai, &commandBuffer) != .SUCCESS {
            _log(this._renderer, .Error, "Failed to allocate Vulkan command buffer")
            return nil
        }

        append(&this._commandBuffers, commandBuffer)
        return commandBuffer
    }

    unusedCommandBufferIndex := pop(&this._unusedCommandBufferIndices)
    commandBuffer := this._commandBuffers[unusedCommandBufferIndex]

    return commandBuffer
}

CommandPool_submit :: proc "c" (this: ^CommandPool, commandBuffer: vk.CommandBuffer, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore) -> vk.Fence {
    if this == nil || this._renderer == nil {
        return 0
    }

    context = this._renderer._ctx

    found := false
    for cb in this._commandBuffers {
        if cb == commandBuffer {
            found = true
            break
        }
    }

    if !found {
        _log(this._renderer, .Error, "Can't submit command buffer: provided command buffer not found in this pool")
        return 0
    }

    waitSemaphores := make([]vk.Semaphore, submitInfoWaitCount)
    defer delete(waitSemaphores)

    waitDstStageMasks := make([]vk.PipelineStageFlags, submitInfoWaitCount)
    defer delete(waitDstStageMasks)

    for i in 0..<submitInfoWaitCount {
        waitSemaphores[i] = submitInfoWaits[i].semaphore
        waitDstStageMasks[i] = submitInfoWaits[i].dstStageMask
    }

    fence := this._fencePool->acquire()
    if fence == 0 {
        _log(this._renderer, .Error, "Can't submit command buffer: failed to acquire submission fence")
        return 0
    }

    cb := commandBuffer
    si := vk.SubmitInfo {
        sType = .SUBMIT_INFO,
        waitSemaphoreCount = submitInfoWaitCount,
        pWaitSemaphores = submitInfoWaitCount == 0 ? nil : &waitSemaphores[0],
        pWaitDstStageMask = submitInfoWaitCount == 0 ? nil : &waitDstStageMasks[0],
        commandBufferCount = 1,
        pCommandBuffers = &cb,
        signalSemaphoreCount = signalSemaphoreCount,
        pSignalSemaphores = signalSemaphores,
    }

    if this._renderer._device.queueSubmit(this._queue.queue, 1, &si, fence) != .SUCCESS {
        _log(this._renderer, .Error, "Failed to submit Vulkan queue")
        return 0
    }

    return fence
}

CommandPool_release :: proc "c" (this: ^CommandPool, commandBuffer: vk.CommandBuffer, fence: vk.Fence) {
    if this == nil || this._renderer == nil {
        return
    }

    context = this._renderer._ctx

    if commandBuffer == nil {
        if fence == 0 {
            return
        }

        this._fencePool->release(fence)
        return
    }

    for i in 0..<len(this._commandBuffers) {
        if commandBuffer == this._commandBuffers[i] {
            for u in this._unusedCommandBufferIndices {
                if u == u32(i) {
                    _log(this._renderer, .Warning, "Can't release command buffer: provided command buffer has already been released and is unused")
                    return
                }
            }

            inject_at(&this._unusedCommandBufferIndices, 0, u32(i))
            if fence != 0 {
                this._fencePool->release(fence)
            }

            return
        }
    }

    _log(this._renderer, .Warning, "Can't release command buffer: provided command buffer not found in this pool")
}