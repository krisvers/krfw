#+private
package krfw_vulkan

import "base:runtime"

import "core:dynlib"

import "core:strings"
import "core:unicode/utf8"

import "../../krfw"
import vk "vendor:vulkan"

import win32 "core:sys/windows"

RENDERER := Renderer {
    init            = krfw.ProcIRendererInit(init),
    destroy         = krfw.ProcIRendererDestroy(destroy),
    createWSI       = krfw.ProcIRendererCreateWSI(createWSI),
    destroyWSI      = krfw.ProcIRendererDestroyWSI(destroyWSI),
    executePasses   = krfw.ProcIRendererExecutePasses(executePasses),

    setVulkanLoaderPath         = setVulkanLoaderPath,
    setVulkanLoaderPathUnicode  = setVulkanLoaderPathUnicode,

    _ctx            = runtime.default_context(),
    _libraryPath    = "",
}

_log :: proc(this: ^Renderer, severity: krfw.DebugSeverity, origin: string, message: string) {
    if this._debugLogger == nil {
        return
    }

    originCString := strings.clone_to_cstring(origin, context.temp_allocator)
    defer delete(originCString, context.temp_allocator)

    messageCString := strings.clone_to_cstring(message, context.temp_allocator)
    defer delete(messageCString, context.temp_allocator)

    this._debugLogger(severity, u32(len(origin)), originCString, u32(len(message)), messageCString)
}

setDebugLogger :: proc "c" (this: ^Renderer, logger: krfw.ProcDebugLogger) {
    this._debugLogger = logger
}

setVulkanLoaderPath :: proc "c" (this: ^Renderer, len: u32, path: [^]u8) {
    context = this._ctx
    if this._library != nil {
        panic("Cannot set Vulkan loader path: library already loaded")
    }

    this._libraryPath = strings.string_from_ptr(path, int(len))
}

setVulkanLoaderPathUnicode :: proc "c" (this: ^Renderer, len: u32, path: [^]rune) {
    context = this._ctx
    if this._library != nil {
        panic("Cannot set Vulkan loader path: library already loaded")
    }

    this._libraryPath = utf8.runes_to_string(path[:len])
}

init :: proc "c" (this: ^Renderer, debug := b32(false)) -> b32 {
    context = this._ctx
    library, ok := dynlib.load_library(this._libraryPath)
    if !ok {
        return false
    }
    
    this._instance.getInstanceProcAddr;
    return false
}

destroy :: proc "c" (this: ^Renderer) {
    context = this._ctx
    delete(this._libraryPath)
}

createWSI :: proc "c" (this: ^Renderer, window: ^krfw.Window, setting := krfw.WSISetting.DontCare) -> krfw.WSIHandle {
    context = this._ctx
    return krfw.WSI_HANDLE_INVALID
}

destroyWSI :: proc "c" (this: ^Renderer, handle: krfw.WSIHandle) {
    context = this._ctx
    
}

executePasses :: proc "c" (this: ^Renderer, passCount: u32, passes: [^]^krfw.IPass, wsiHandle := krfw.WSI_HANDLE_INVALID) -> b32 {
    context = this._ctx
    return false
}