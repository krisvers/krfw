#+private
package krfw_vulkan

import "base:runtime"

import vk "vendor:vulkan"

import "../kom"

VkCommandPoolData :: struct {
    _refCount:          u64,
    _ctx:               ^runtime.Context,

    _queue:             ^VkQueue,
    _commandPool:       vk.CommandPool,
    _fencePool:         ^IVkFencePool,

    _commandBuffers:    [dynamic]^VkCommandBuffer,
    _unusedIndices:     [dynamic]u32,

    _isInternal:        b32,
}

VkCommandPoolIBase :: struct {
    base:       ^VkCommandPool,
    interface:  kom.IBase,
}

VkCommandPoolIChild :: struct {
    base:       ^VkCommandPool,
    interface:  kom.IChild,
}

VkCommandPoolIVkCommandPool :: struct {
    base:       ^VkComandPool,
    interface:  IVkCommandPool,
}

VkCommandPool :: struct {
    using _:        VkCommandPoolData,

    ibase:          VkCommandPoolIBase,
    ichild:         VkCommandPoolIChild,
    ivkcommandpool: VkCommandPoolIVkCommandPool,
}

/* initializer */
VkCommandPool_new :: proc(queue: ^VkQueue, vkCommandPool: vk.CommandPool, fencePool: ^IVkFencePool, isInternal := b32(false)) -> ^VkCommandPool {
    commandPool := new(VkCommandPool)

    commandPool^ = {
        _refCount       = 1,
        _ctx            = queue._ctx,

        _queue          = queue,
        _commandPool    = vkCommandPool,
        _fencePool      = fencePool,

        _commandBuffers = make([dynamic]vk.CommandBuffers),
        _unsuedIndices  = make([dynamic]u32),

        _isInternal     = isInternal,

        ibase           = {
            base        = commandPool,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkCommandPool_IBase_retain),
                release         = kom.ProcIBaseRetain(VkCommandPool_IBase_release),
                queryInterface  = kom.ProcIBaseRetain(VkCommandPool_IBase_queryInterface),
            },
        },

        ichild          = {
            base        = commandPool,
            interface   = {
                /* IBase */
                retain          = kom.ProcIBaseRetain(VkCommandPool_IBase_retain),
                release         = kom.ProcIBaseRetain(VkCommandPool_IBase_release),
                queryInterface  = kom.ProcIBaseRetain(VkCommandPool_IBase_queryInterface),

                /* IChild */
                getParent       = kom.ProcIChildGetParent(VkCommandPool_IChild_getParent),
            },
        },

        ivkcommandpool  = {
            base        = commandPool,
            interface   = {
                /* IBase */
                retain                  = kom.ProcIBaseRetain(VkCommandPool_IBase_retain),
                release                 = kom.ProcIBaseRetain(VkCommandPool_IBase_release),
                queryInterface          = kom.ProcIBaseRetain(VkCommandPool_IBase_queryInterface),

                /* IChild */
                getParent               = kom.ProcIChildGetParent(VkCommandPool_IChild_getParent),

                /* IVkCommandPool */
                getVulkanCommandPool    = ProcIVkCommandPoolGetVulkanCommandPool(VkCommandPool_IVkCommandPool_getVulkanCommandPool),
                acquireCommandBuffer    = ProcIVkCommandPoolAcquireCommandBuffer(VkCommandPool_IVkCommandPool_acquireCommandBuffer),
                submitCommandBuffers    = ProcIVkCommandPoolSubmitCommandBuffers(VkCommandPool_IVkCommandPool_submitCommandBuffers),
            },
        },
    }

    return commandPool
}

/* IBase */
VkCommandPool_retain :: proc "c" (this: ^VkCommandPool) -> u64 {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    this._refCount += 1

    return this._refCount
}

VkCommandPool_release :: proc "c" (this: ^VkCommandPool) -> u64 {
    if this == nil || this._ctx == nil {
        return max(u64)
    }

    context = this._ctx^
    this._refCount -= 1
    if this._refCount != 0 {
        return this._refCount
    }

    pool := this._resourcePool
    renderer := pool._renderer
    device := renderer._device

    if this._isInternal && !renderer._performingDestruction {
        log(renderer, .Warning, "Can't fully release command pool: is internal (likely a double release or a missing retain)")
        this._refCount = 1
        return max(u64)
    }

    device.ivkdevice.deviceWaitIdle(device._logical)
    device.ivkdevice.destroyCommandPool(device._logical, this._commandPool, renderer._allocator)

    delete(this._commandBuffers)
    delete(this._unusedIndices)

    free(this)
    return 0
}

VkCommandPool_queryInterface :: proc "c" (this: ^VkCommandPool, #by_ptr id: kom.IID) -> rawptr {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
    switch id {
        case kom.IBase_IID:
            return &this.ibase
        case kom.IChild_IID:
            return &this.ichild
        case IVkCommandPool_IID:
            return &this.ivkcommandpool
        case:
            break
    }

    return nil
}

/* IChild */
VkCommandPool_getParent :: proc "c" (this: ^VkCommandPool) -> ^kom.IBase {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    queue := this._queue
    return &queue.ibase
}

/* IVkCommandPool */
VkCommandPool_getVulkanCommandPool :: proc "c" (this: ^IVkCommandPool) -> vk.CommandPool {
    if this == nil || this._ctx == nil {
        return 0
    }

    context = this._ctx^
    return this._commandPool
}

VkCommandPool_acquireCommandBuffer :: proc "c" (this: ^IVkCommandPool, bundle := b32(false)) -> ^IVkCommandBuffer {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^

    /* NOTE: implement VkCommandBuffer first */

    /*
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
    */
}

VkCommandPool_submitCommandBuffers :: proc "c" (this: ^IVkCommandPool, commandBufferCount: u32, commandBuffers: [^]^IVkCommandBuffer, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore) -> ^IVkFence {
    if this == nil || this._ctx == nil {
        return nil
    }

    context = this._ctx^
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