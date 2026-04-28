
/* Buffer implementation */
Buffer_destroy :: proc "c" (this: ^Buffer) {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return
    }

    context = this._pool._renderer._ctx

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't destroy buffer: resource is invalid (likely a double-free)")
        return
    }

    vma.destroy_buffer(this._pool._renderer._vma, this._buffer, this._allocation)
    this._buffer = 0
    this._allocation = nil
}

Buffer_getVulkanBuffer :: proc "c" (this: ^Buffer) -> vk.Buffer {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return 0
    }

    context = this._pool._renderer._ctx

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't get Vulkan buffer: resource is invalid")
        return 0
    }

    return this._buffer
}
