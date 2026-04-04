#+private
package krfw_vulkan

import "base:runtime"

import "core:fmt"
import "core:mem"
import "core:dynlib"
import "core:strings"
import "core:unicode/utf8"

import "../../krfw"
import vk "vendor:vulkan"

when ODIN_OS == .Windows {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "vulkan-1.dll"
    }
} else when ODIN_OS == .Linux {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "libvulkan.so",
        "libvulkan-1.so",
        "libvulkan.so.1",
    }
} else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "libvulkan.so.1.4",
        "libvulkan.so.1.3",
        "libvulkan.so.1.2",
        "libvulkan.so.1.1",
        "libvulkan.so.1.0",
        "libvulkan.so.1",
        "libvulkan.so",
        "libvulkan-1.so",
    }
} else when ODIN_OS == .Darwin {
    /* equivalent to macOS <dlfcn.h> RTLD_DEFAULT = ((void*) -2) (adapted from https://github.com/karl-zylinski/karl2d/blob/master/platform_mac_glue_gl.odin#L91) */
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(~uintptr(0) - 1)
    
    /* (adapted from https://github.com/libsdl-org/SDL/blob/main/src/video/cocoa/SDL_cocoavulkan.m#L38) */
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "@executable_path/../Frameworks/libMoltenVK.dylib",
        "vulkan.framework/vulkan",
        "libvulkan.1.dylib",
        "libvulkan.dylib",
        "MoltenVK.framework/MoltenVK",
        "libMoltenVK.dylib"
    }
} else {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {}
}

RENDERER := Renderer {
    /* inherited functions */
    setDebugLogger  = krfw.ProcIRendererSetDebugLogger(setDebugLogger),
    init            = krfw.ProcIRendererInit(init),
    destroy         = krfw.ProcIRendererDestroy(destroy),
    createWSI       = krfw.ProcIRendererCreateWSI(createWSI),
    destroyWSI      = krfw.ProcIRendererDestroyWSI(destroyWSI),
    executePasses   = krfw.ProcIRendererExecutePasses(executePasses),

    /* custom functions */
    loadVulkanLoaderOdin    = loadVulkanLoaderOdin,
    loadVulkanLoader        = loadVulkanLoader,
    loadVulkanLoaderUnicode = loadVulkanLoaderUnicode,

    _ctx            = runtime.default_context(),
    _library        = VULKAN_LOADER_DEFAULT_HANDLE,
}

_logManual :: proc(this: ^Renderer, severity: krfw.DebugSeverity, message: string, origin: string) {
    assert(this != nil)

    context = this._ctx
    if this._debugLogger == nil {
        return
    }

    if severity < this._debugLoggerLowestSeverity {
        return
    }
    
    nextAvailableResidentOffset := 0
    originCString := cstring(nil)
    originResident := nextAvailableResidentOffset + len(origin) < len(this._debugLoggerBuffer)
    if originResident {
        originCString = cstring(&this._debugLoggerBuffer[nextAvailableResidentOffset])
        mem.copy_non_overlapping(&this._debugLoggerBuffer[nextAvailableResidentOffset], raw_data(origin), len(origin))
        this._debugLoggerBuffer[nextAvailableResidentOffset + len(origin)] = 0
        nextAvailableResidentOffset += len(origin) + 1
    } else {
        originCString = strings.clone_to_cstring(origin, context.temp_allocator)
    }

    messageCString := cstring(nil)
    messageResident := nextAvailableResidentOffset + len(message) < len(this._debugLoggerBuffer)
    if messageResident {
        messageCString = cstring(&this._debugLoggerBuffer[nextAvailableResidentOffset])
        mem.copy_non_overlapping(&this._debugLoggerBuffer[nextAvailableResidentOffset], raw_data(message), len(message))
        this._debugLoggerBuffer[nextAvailableResidentOffset + len(message)] = 0
        nextAvailableResidentOffset += len(message) + 1
    } else {
        messageCString = strings.clone_to_cstring(message, context.temp_allocator)
    }

    this._debugLogger(severity, u32(len(origin)), originCString, u32(len(message)), messageCString)

    if !messageResident {
        delete(messageCString, context.temp_allocator)
    }

    if !originResident {
        delete(originCString, context.temp_allocator)
    }
}

_logAuto :: proc(this: ^Renderer, severity: krfw.DebugSeverity, format: string, args: ..any, loc := #caller_location) {
    assert(this != nil)

    context = this._ctx

    origin := fmt.tprintf("%s():%d", loc.procedure, loc.line)
    defer delete(origin, context.temp_allocator)

    message := fmt.tprintf(format, ..args)
    defer delete(message, context.temp_allocator)

    _logManual(this, severity, message, origin)
}

_log :: proc{ _logManual, _logAuto }

setDebugLogger :: proc "c" (this: ^Renderer, logger: krfw.ProcDebugLogger, lowestSeverity := krfw.DebugSeverity.Warning) {
    if this == nil {
        return
    }

    context = this._ctx
    this._debugLogger = logger
    this._debugLoggerLowestSeverity = lowestSeverity
}

loadVulkanLoaderOdin :: proc "c" (this: ^Renderer, path: string) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx
    if this._library != nil && this._library != VULKAN_LOADER_DEFAULT_HANDLE {
        _log(this, krfw.DebugSeverity.Warning, "Cannot load Vulkan loader with new path: library already loaded")
        return false
    }

    library, ok := dynlib.load_library(path)
    if !ok {
        _log(this, krfw.DebugSeverity.Error, "Failed to load Vulkan loader using custom path")
        return false
    }

    this._library = library
    return true
}

loadVulkanLoader :: proc "c" (this: ^Renderer, len: u32, path: [^]u8) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    pathString := strings.string_from_ptr(path, int(len))
    return loadVulkanLoaderOdin(this, pathString)
}

loadVulkanLoaderUnicode :: proc "c" (this: ^Renderer, len: u32, path: [^]rune) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    pathString := utf8.runes_to_string(path[:len], context.temp_allocator)
    defer delete(pathString, context.temp_allocator)

    return loadVulkanLoaderOdin(this, pathString)
}

init :: proc "c" (this: ^Renderer, debug := b32(false)) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._library != nil {
        p, ok := dynlib.symbol_address(this._library, "vkGetInstanceProcAddr")
        if ok {
            this._instance.getInstanceProcAddr = vk.ProcGetInstanceProcAddr(p)
            _log(this, krfw.DebugSeverity.Verbose, "Using pre-provided Vulkan library for loading")
        }
    }

    for i in 0..<len(VULKAN_LOADER_DEFAULT_PATHS) {
        _logAuto(this, krfw.DebugSeverity.Verbose, "Attempting to load default library %d: \"%s\"", i, VULKAN_LOADER_DEFAULT_PATHS[i])
        library, ok := dynlib.load_library(VULKAN_LOADER_DEFAULT_PATHS[i])
        if !ok {
            continue
        }
        
        _log(this, krfw.DebugSeverity.Verbose, "Default library %d: \"%s\" loaded library successfully", i, VULKAN_LOADER_DEFAULT_PATHS[i])

        p: rawptr
        p, ok = dynlib.symbol_address(library, "vkGetInstanceProcAddr")
        if !ok {
            dynlib.unload_library(library)
            continue
        }

        _log(this, krfw.DebugSeverity.Verbose, "Default library %d: \"%s\" loaded vkGetInstanceProcAddr successfully", i, VULKAN_LOADER_DEFAULT_PATHS[i])
        
        this._library = library
        this._globalFunctions.getInstanceProcAddr = vk.ProcGetInstanceProcAddr(p)
        break
    }

    if this._globalFunctions.getInstanceProcAddr == nil {
        _log(this, krfw.DebugSeverity.Fatal, "Failed to load Vulkan loader from list of candidate paths")
        return false
    }

    if !loadVulkanGlobalFunctions(this._globalFunctions.getInstanceProcAddr, &this._globalFunctions) {
        _log(this, krfw.DebugSeverity.Fatal, "Failed to load Vulkan global function pointers")
        return false
    }
    
    return true
}

destroy :: proc "c" (this: ^Renderer) {
    if this == nil {
        return
    }

    context = this._ctx
    
    if this._library != nil && this._library != VULKAN_LOADER_DEFAULT_HANDLE {
        dynlib.unload_library(this._library)
    }
}

createWSI :: proc "c" (this: ^Renderer, window: ^krfw.Window, setting := krfw.WSISetting.DontCare) -> krfw.WSIHandle {
    if this == nil {
        return krfw.WSI_HANDLE_INVALID
    }

    context = this._ctx
    return krfw.WSI_HANDLE_INVALID
}

destroyWSI :: proc "c" (this: ^Renderer, handle: krfw.WSIHandle) {
    if this == nil {
        return
    }

    context = this._ctx
    
}

executePasses :: proc "c" (this: ^Renderer, passCount: u32, passes: [^]^krfw.IPass, wsiHandle := krfw.WSI_HANDLE_INVALID) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx
    return false
}