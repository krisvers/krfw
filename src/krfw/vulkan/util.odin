#+private
package krfw_vulkan

import "base:runtime"

import "core:fmt"

import "../../krfw"
import vk "vendor:vulkan"

logManual :: proc(this: ^VkRenderer, severity: krfw.DebugSeverity, message: cstring, origin: cstring) {
    assert(this != nil)

    context = this._ctx
    if this._debugLogger == nil {
        return
    }

    if severity < this._debugLoggerLowestSeverity {
        return
    }
    
    this._debugLogger(severity, u32(len(origin)), origin, u32(len(message)), message)
}

logAuto :: proc(this: ^VkRenderer, severity: krfw.DebugSeverity, format: string, args: ..any, loc := #caller_location) {
    assert(this != nil)

    context = this._ctx

    origin := fmt.ctprintf("%s():%d", loc.procedure, loc.line)
    defer delete(origin, context.temp_allocator)

    message := fmt.ctprintf(format, ..args)
    defer delete(message, context.temp_allocator)

    _logManual(this, severity, message, origin)
}

logAutoExplicitOrigin :: proc(this: ^VkRenderer, severity: krfw.DebugSeverity, origin: cstring, format: string, args: ..any) {
    assert(this != nil)

    context = this._ctx

    message := fmt.ctprintf(format, ..args)
    defer delete(message, context.temp_allocator)

    _logManual(this, severity, message, origin)
}

log :: proc{ logManual, logAuto }

/* Vulkan helper functions */
_createSurface :: proc "c" (this: ^VkRenderer, window: ^krfw.Window) -> vk.SurfaceKHR {
    if this == nil || window == nil {
        return 0
    }

    context = this._ctx

    if this._headless {
        _log(this, .Warning, "Called Vulkan backend internal _createSurface with a headless VkRenderer; surface support is not likely to be enabled")
    }

    surface: vk.SurfaceKHR
    when ODIN_OS == .Windows {
        if window.nativeWindowType != .Win32 {
            _log(this, .Error, "Called Vulkan backend internal _createSurface with invalid window: not a Win32 window")
            return 0
        }

        createWin32SurfaceKHR := vk.ProcCreateWin32SurfaceKHR(this._instance.getInstanceProcAddr(this._instance.instance, "vkCreateWin32SurfaceKHR"))
        if createWin32SurfaceKHR == nil {
            _log(this, .Error, "Failed to load vkCreateWin32SurfaceKHR required for creating a Vulkan surface")
            return 0
        }

        ci := vk.Win32SurfaceCreateInfoKHR {
            sType = .WIN32_SURFACE_CREATE_INFO_KHR,
            hinstance = vk.HINSTANCE(window.nativeDisplayHandle),
            hwnd = vk.HWND(window.nativeWindowHandle),
        }

        if createWin32SurfaceKHR(this._instance.instance, &ci, this._allocator, &surface) != .SUCCESS {
            _log(this, .Error, "Failed to create a Vulkan surface with vkCreateWin32SurfaceKHR")
            return 0
        }
    } else when ODIN_OS == .Linux {
        #partial switch window.nativeWindowType {
            case .Xlib:
                createXlibSurfaceKHR := vk.ProcCreateXlibSurfaceKHR(this._instance.getInstanceProcAddr(this._instance.instance, "vkCreateXlibSurfaceKHR"))
                if createXlibSurfaceKHR == nil {
                    _log(this, .Error, "Failed to load vkCreateXlibSurfaceKHR required for creating a Vulkan surface")
                    return 0
                }

                ci := vk.XlibSurfaceCreateInfoKHR {
                    sType = .XLIB_SURFACE_CREATE_INFO_KHR,
                    dpy = (^vk.XlibDisplay)(window.nativeDisplayHandle),
                    window = (vk.XlibWindow)(window.nativeWindowHandle),
                }

                if createXlibSurfaceKHR(this._instance.instance, &ci, this._allocator, &surface) != .SUCCESS {
                    _log(this, .Error, "Failed to create a Vulkan surface with vkCreateXlibSurfaceKHR")
                    return 0
                }
            case .Xcb:
                createXcbSurfaceKHR := vk.ProcCreateXcbSurfaceKHR(this._instance.getInstanceProcAddr(this._instance.instance, "vkCreateXcbSurfaceKHR"))
                if createXcbSurfaceKHR == nil {
                    _log(this, .Error, "Failed to load vkCreateXcbSurfaceKHR required for creating a Vulkan surface")
                    return 0
                }

                ci := vk.XcbSurfaceCreateInfoKHR {
                    sType = .XCB_SURFACE_CREATE_INFO_KHR,
                    connection = (^vk.xcb_connection_t)(window.nativeDisplayHandle),
                    window = (vk.xcb_window_t)(window.nativeWindowHandle),
                }

                if createXcbSurfaceKHR(this._instance.instance, &ci, this._allocator, &surface) != .SUCCESS {
                    _log(this, .Error, "Failed to create a Vulkan surface with vkCreateXcbSurfaceKHR")
                    return 0
                }
            case .Wayland:
                createWaylandSurfaceKHR := vk.ProcCreateWaylandSurfaceKHR(this._instance.getInstanceProcAddr(this._instance.instance, "vkCreateWaylandSurfaceKHR"))
                if createWaylandSurfaceKHR == nil {
                    _log(this, .Error, "Failed to load vkCreateWaylandSurfaceKHR required for creating a Vulkan surface")
                    return 0
                }

                ci := vk.WaylandSurfaceCreateInfoKHR {
                    sType = .WAYLAND_SURFACE_CREATE_INFO_KHR,
                    display = (^vk.wl_display)(window.nativeDisplayHandle),
                    surface = (^vk.wl_surface)(window.nativeWindowHandle),
                }

                if createWaylandSurfaceKHR(this._instance.instance, &ci, this._allocator, &surface) != .SUCCESS {
                    _log(this, .Error, "Failed to create a Vulkan surface with vkCreateWaylandSurfaceKHR")
                    return 0
                }
            case:
                _log(this, .Error, "Called Vulkan backend internal _createSurface with invalid window: not a Xlib, Xcb or Wayland window")
                return 0
        }
    } else when ODIN_OS == .Darwin {
        #partial switch window.nativeWindowType {
            case .Metal:
                createMetalSurfaceEXT := vk.ProcCreateMetalSurfaceEXT(this._instance.getInstanceProcAddr(this._instance.instance, "vkCreateMetalSurfaceEXT"))
                if createMetalSurfaceEXT == nil {
                    _log(this, .Error, "Failed to load vkCreateMetalSurfaceEXT required for creating a Vulkan surface")
                    return 0
                }

                layer := (^vk.CAMetalLayer)(window.nativeWindowHandle)
                if layer == nil {
                    _log(this, .Error, "Called Vulkan backend internal _createSurface with invalid window: Metal layer is nil")
                    return 0
                }

                ci := vk.MetalSurfaceCreateInfoEXT {
                    sType = .METAL_SURFACE_CREATE_INFO_EXT,
                    pLayer = layer,
                }

                if createMetalSurfaceEXT(this._instance.instance, &ci, this._allocator, &surface) != .SUCCESS {
                    _log(this, .Error, "Failed to create a Vulkan surface with vkCreateMetalSurfaceEXT")
                    return 0
                }
            case .Cocoa:
                createMetalSurfaceEXT := vk.ProcCreateMetalSurfaceEXT(this._instance.getInstanceProcAddr(this._instance.instance, "vkCreateMetalSurfaceEXT"))
                if createMetalSurfaceEXT == nil {
                    _log(this, .Error, "Failed to load vkCreateMetalSurfaceEXT required for creating a Vulkan surface")
                    return 0
                }

                layer := (^vk.CAMetalLayer)(_getCAMetalLayerFromNSWindow(window.nativeWindowHandle))
                if layer == nil {
                    _log(this, .Error, "Called Vulkan backend internal _createSurface with invalid window: Metal layer derived from window is nil")
                    return 0
                }

                ci := vk.MetalSurfaceCreateInfoEXT {
                    sType = .METAL_SURFACE_CREATE_INFO_EXT,
                    pLayer = layer,
                }

                if createMetalSurfaceEXT(this._instance.instance, &ci, this._allocator, &surface) != .SUCCESS {
                    _log(this, .Error, "Failed to create a Vulkan surface with vkCreateMetalSurfaceEXT")
                    return 0
                }
            case:
                _log(this, .Error, "Called Vulkan backend internal _createSurface with invalid window: not a Metal or Cocoa window")
                return 0
        }
    }

    return surface
}