#+build darwin
package krfw_vulkan

import ns "core:sys/darwin/Foundation"
import ca "vendor:darwin/QuartzCore"

_getCAMetalLayerFromNSWindow :: proc(nsWindow: rawptr) -> ^ca.MetalLayer {
    window := (^ns.Window)(nsWindow)

    layer := ca.MetalLayer.layer()
    window->contentView()->setLayer(layer)

    return layer
}