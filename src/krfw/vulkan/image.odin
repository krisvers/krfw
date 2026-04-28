
/* Image implementation */
Image_destroy :: proc "c" (this: ^Image) {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return
    }

    context = this._pool._renderer._ctx

    if this._isBackbuffer {
        _log(this._pool._renderer, .Error, "Can't destroy image: is internally managed backbuffer")
        return
    }

    if this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't destroy image: resource is invalid (likely a double-free)")
        return
    }

    vma.destroy_image(this._pool._renderer._vma, this._image, this._allocation)
    this._image = 0
    this._allocation = nil
}

Image_getVulkanImage :: proc "c" (this: ^Image) -> vk.Image {
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return 0
    }

    context = this._pool._renderer._ctx

    if !this._isBackbuffer && this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't get Vulkan image: resource is invalid")
        return 0
    }

    return this._image
}

Image_getLayout :: proc "c" (this: ^Image) -> vk.ImageLayout {    
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return .UNDEFINED
    }

    context = this._pool._renderer._ctx

    if !this._isBackbuffer && this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't get image layout: resource is invalid")
        return .UNDEFINED
    }

    return this._layout
}

Image_setLayout :: proc "c" (this: ^Image, layout: vk.ImageLayout) {    
    if this == nil || this._pool == nil || this._pool._renderer == nil {
        return
    }

    context = this._pool._renderer._ctx

    if !this._isBackbuffer && this._allocation == nil {
        _log(this._pool._renderer, .Error, "Can't set image layout: resource is invalid")
        return
    }

    this._layout = layout
}