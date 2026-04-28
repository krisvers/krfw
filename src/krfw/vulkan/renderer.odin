#+private
package krfw_vulkan

import "base:runtime"

import "core:fmt"
import "core:mem"
import "core:dynlib"
import "core:strings"
import "core:unicode/utf8"

import "../kom"
import "../../krfw"
import vk "vendor:vulkan"
import "vma"

VERSION_PATCH_VULKAN :: 0

/* for VK_KHR_dynamic_rendering and Vulkan 1.1/1.2 features */
REQUIRED_VULKAN_VERSION_VARIANT :: 0
REQUIRED_VULKAN_VERSION_MAJOR   :: 1
REQUIRED_VULKAN_VERSION_MINOR   :: 2
REQUIRED_VULKAN_VERSION_PATCH   :: 197

VK_MAKE_API_VERSION :: proc(variant: u32, major: u32, minor: u32, patch: u32) -> u32 {
    return (variant << 29) | (major << 22) | (minor << 12) | (patch)
}

VK_API_VERSION_VARIANT :: proc(version: u32) -> u32 {
    return (version >> 29) & 0x7
}

VK_API_VERSION_MAJOR :: proc(version: u32) -> u32 {
    return (version >> 22) & 0x7f
}

VK_API_VERSION_MINOR :: proc(version: u32) -> u32 {
    return (version >> 12) & 0x3ff
}

VK_API_VERSION_PATCH :: proc(version: u32) -> u32 {
    return version & 0xfff
}

when ODIN_OS == .Windows {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "vulkan-1.dll"
    }
} else when ODIN_OS == .Linux {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "libvulkan.so.1",
        "libvulkan.so",
        "libvulkan-1.so",
    }
} else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {
    VULKAN_LOADER_DEFAULT_HANDLE := dynlib.Library(nil)
    VULKAN_LOADER_DEFAULT_PATHS := []string {
        "libvulkan.so.1",
        "libvulkan.so",
        "libvulkan.so.1.4",
        "libvulkan.so.1.3",
        "libvulkan.so.1.2",
        "libvulkan.so.1.1",
        "libvulkan.so.1.0",
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

VkQueuedWindowData :: struct {
    window:     krfw.Window,
    setting:    krfw.WSISetting,
}

VkRendererData :: struct {
    _refCount:          u64,

    _debugLogger:               krfw.ProcDebugLogger,
    _debugLoggerLowestSeverity: krfw.DebugSeverity,
    _ctx:                       runtime.Context,
    _library:                   dynlib.Library,
    _allocator:                 ^vk.AllocationCallbacks,
    _globalFunctions:           GlobalFunctionPointers,
    _driverPreferenceBuffer:    [vk.MAX_DRIVER_NAME_SIZE]u8,

    /* pre-init, destroyed at the end of init */
    _areWindowsQueued:  bool,
    _queuedWindows:     [dynamic]VulkanQueuedWindowData,

    /* init members */
    _headless:          bool,
    _debug:             bool,
    _instance:          Instance,
    _device:            Device,
    _vma:               vma.Allocator,
    _backbufferPools:   map[krfw.Window]BackbufferPool,

    /* note: queues may be aliases of one another */
    _queues:    []Queue,

    _generalQueue:  ^Queue,
    _presentQueue:  ^Queue,
    _graphicsQueue: ^Queue,
    _transferQueue: ^Queue,
    _computeQueue:  ^Queue,

    /* pools */
    _defaultFencePool:      FencePool,
    _defaultSemaphorePool:  SemaphorePool,
    _defaultResourcePool:   ResourcePool,

    /* other state */
    _performingDestruction: b32,
}

VkRendererIBase :: struct {
    interface:  IBase,
    base:       ^VkRenderer,
}

VkRendererIRenderer :: struct {
    interface:  IRenderer,
    base:       ^VkRenderer,
}

VkRendererIVkRenderer :: struct {
    interface:  IVkRenderer,
    base:       ^VkRenderer,
}

VkRenderer :: struct {
    data:           VkRendererData,

    ibase:          VkRendererIBase,
    irenderer:      VkRendererIRenderer,
    ivkrenderer:    VkRendererIVkRenderer,
}

/* IRenderer */
VkRenderer_setDebugLogger :: proc "c" (this: ^VkRenderer, logger: krfw.ProcDebugLogger, lowestSeverity := krfw.DebugSeverity.Warning) {
    if this == nil {
        return
    }

    context = this._ctx

    this._debugLogger = logger
    this._debugLoggerLowestSeverity = lowestSeverity
}

VkRenderer_init :: proc "c" (this: ^Renderer, lowPower := b32(false), headless := b32(false), debug := b32(false)) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    /* setup containers */
    if this._buffers == nil {
        this._buffers = new(_RendererBuffers)
    }

    this._headless = bool(headless)
    this._debug = bool(debug)
    this._backbufferPools = make(map[krfw.Window]BackbufferPool)

    /* load Vulkan loader */
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

    /* determine support for extensions and create instance */
    appInfo := vk.ApplicationInfo {
        sType = .APPLICATION_INFO,
        pApplicationName = "krfw",
        applicationVersion = VK_MAKE_API_VERSION(0, krfw.VERSION_MAJOR, krfw.VERSION_MINOR, VERSION_PATCH_VULKAN),
        pEngineName = "krfw",
        engineVersion = VK_MAKE_API_VERSION(0, krfw.VERSION_MAJOR, krfw.VERSION_MINOR, VERSION_PATCH_VULKAN),
        apiVersion = VK_MAKE_API_VERSION(REQUIRED_VULKAN_VERSION_VARIANT, REQUIRED_VULKAN_VERSION_MAJOR, REQUIRED_VULKAN_VERSION_MINOR, REQUIRED_VULKAN_VERSION_PATCH),
    }

    debugUtilsMessengerCI := vk.DebugUtilsMessengerCreateInfoEXT {
        sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
        messageSeverity = { .VERBOSE, .INFO, .WARNING, .ERROR },
        messageType = { .GENERAL, .PERFORMANCE, .VALIDATION },
        pfnUserCallback = proc "system" (severity: vk.DebugUtilsMessageSeverityFlagsEXT, types: vk.DebugUtilsMessageTypeFlagsEXT, data: ^vk.DebugUtilsMessengerCallbackDataEXT, userData: rawptr) -> b32 {
            this := (^Renderer)(userData)
            if this == nil {
                return false
            }

            context = this._ctx

            krfwSeverity: krfw.DebugSeverity
            if .VERBOSE in severity {
                krfwSeverity = .Verbose
            } else if .INFO in severity {
                krfwSeverity = .Info
            } else if .WARNING in severity {
                krfwSeverity = .Warning
            } else if .ERROR in severity {
                krfwSeverity = .Error
            }

            if .GENERAL in types {
                krfwSeverity = .Verbose
            }

            if .VALIDATION in types && krfwSeverity == .Info {
                krfwSeverity = .Verbose
            }

            _logAutoExplicitOrigin(this, krfwSeverity, "vk::???():???", "(FORWARDING VULKAN DEBUG MESSAGE): [%s] %s", types, data.pMessage)
            return false
        },
        pUserData = rawptr(this),
    }

    debugReportCallbackCI := vk.DebugReportCallbackCreateInfoEXT {
        sType = .DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
        flags = { .ERROR, .WARNING, .PERFORMANCE_WARNING },
        pfnCallback = proc "system" (flags: vk.DebugReportFlagsEXT, objectType: vk.DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, layerPrefix: cstring, message: cstring, userData: rawptr) -> b32 {
            this := (^Renderer)(userData)
            if this == nil {
                return false
            }

            context = this._ctx

            _logAutoExplicitOrigin(this, .Verbose, "vk::???():???", "(FORWARDING VULKAN DEBUG REPORT): [%s] (%s %v %v) (%s: %x) %s", flags, layerPrefix, location, messageCode, objectType, object, message)
            return false
        },
        pUserData = rawptr(this),
    }

    availableInstanceLayerPropertiesCount: u32
    if this._globalFunctions.enumerateInstanceLayerProperties(&availableInstanceLayerPropertiesCount, nil) != .SUCCESS {
        _log(this, .Error, "Failed to enumerate Vulkan instance layers")
        return false
    }

    availableInstanceLayerProperties := make([]vk.LayerProperties, availableInstanceLayerPropertiesCount)
    defer delete(availableInstanceLayerProperties)

    if this._globalFunctions.enumerateInstanceLayerProperties(&availableInstanceLayerPropertiesCount, &availableInstanceLayerProperties[0]) != .SUCCESS {
        _log(this, .Error, "Failed to enumerate Vulkan instance layers")
        return false
    }

    availableInstanceExtensionPropertiesCount: u32
    if this._globalFunctions.enumerateInstanceExtensionProperties(nil, &availableInstanceExtensionPropertiesCount, nil) != .SUCCESS {
        _log(this, .Error, "Failed to enumerate Vulkan instance extensions")
        return false
    }

    availableInstanceExtensionProperties := make([]vk.ExtensionProperties, availableInstanceExtensionPropertiesCount)
    defer delete(availableInstanceExtensionProperties)

    if this._globalFunctions.enumerateInstanceExtensionProperties(nil, &availableInstanceExtensionPropertiesCount, &availableInstanceExtensionProperties[0]) != .SUCCESS {
        _log(this, .Error, "Failed to enumerate Vulkan instance extensions")
        return false
    }

    enabledInstanceLayers := make([dynamic]cstring)
    defer delete(enabledInstanceLayers)

    enabledInstanceExtensions := make([dynamic]cstring)
    defer delete(enabledInstanceExtensions)

    if this._debug {
        for &layerProperties in availableInstanceLayerProperties {
            if strings.compare(string(cstring(&layerProperties.layerName[0])), "VK_LAYER_KHRONOS_validation") == 0 {
                _log(this, .Verbose, "Enabling instance layer %s", cstring(&layerProperties.layerName[0]))
                append(&enabledInstanceLayers, cstring(&layerProperties.layerName[0]))
            }
        }
    }

    flags: vk.InstanceCreateFlags
    next := rawptr(nil)

    foundPortabilityEnumerationKHR := false
    foundDebugUtilsEXT := false
    foundSurfaceKHR, foundGetSurfaceCapabilities2KHR, foundSurfaceMaintenace1EXT, foundPlatformSpecificSurfaceExtension: bool

    for &extensionProperties in availableInstanceExtensionProperties {
        _log(this, .Verbose, "Interview instance extension %s (specification version: %d)", cstring(&extensionProperties.extensionName[0]), extensionProperties.specVersion)\

        if this._debug {
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_debug_utils") == 0 {
                /* extension was advertised twice (sometimes happens with Renderdoc??) */
                if foundDebugUtilsEXT {
                    continue
                }

                foundDebugUtilsEXT = true

                debugUtilsMessengerCI.pNext = next
                next = &debugUtilsMessengerCI

                _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_debug_report") == 0 {
                debugReportCallbackCI.pNext = next
                next = &debugReportCallbackCI

                _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
            }
        }

        if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_surface") == 0 {
            foundSurfaceKHR = true

            if !this._headless {
                _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
            }
        } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_surface_maintenance1") == 0 {
            foundSurfaceMaintenace1EXT = true

            if !this._headless {
                _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
            }
        } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_get_surface_capabilities2") == 0 {
            foundGetSurfaceCapabilities2KHR = true

            if !this._headless {
                _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
            }
        } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_portability_enumeration") == 0 {
            foundPortabilityEnumerationKHR = true
            
            when ODIN_OS == .Darwin {
                flags |= { .ENUMERATE_PORTABILITY_KHR }

                _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
            }
        }

        when ODIN_OS == .Windows {
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_win32_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            }
        } else when ODIN_OS == .Linux {
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_xlib_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_xcb_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_wayland_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            }
        } else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_xlib_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_xcb_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            }
        } else when ODIN_OS == .Darwin {
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_metal_surface") == 0 {
                foundPlatformSpecificSurfaceExtension = true

                if !this._headless {
                    _log(this, .Verbose, "Enabling instance extension %s", cstring(&extensionProperties.extensionName[0]))
                    append(&enabledInstanceExtensions, cstring(&extensionProperties.extensionName[0]))
                }
            }
        }
    }

    if !this._headless && !foundSurfaceKHR {
        _log(this, .Fatal, "Failed to find Vulkan extension VK_KHR_surface required for non-headless renderers")
        return false
    }

    if !this._headless && !foundSurfaceMaintenace1EXT {
        _log(this, .Fatal, "Failed to find Vulkan extension VK_EXT_surface_maintenance1 required for non-headless renderers")
        return false
    }

    if !this._headless && !foundSurfaceMaintenace1EXT {
        _log(this, .Fatal, "Failed to find Vulkan extension VK_KHR_get_surface_capabilities2 required for non-headless renderers")
        return false
    }

    if !this._headless && !foundPlatformSpecificSurfaceExtension {
        _log(this, .Fatal, "Failed to find Vulkan platform specific surface extension required for non-headless renderers")
        return false
    }
    
    when ODIN_OS == .Darwin {
        if !foundPortabilityEnumerationKHR {
            _log(this, .Fatal, "Failed to find Vulkan extension VK_KHR_portability_enumeration required for Vulkan compatiblity with Apple devices")
            return false
        }
    }

    instanceCI := vk.InstanceCreateInfo {
        sType = .INSTANCE_CREATE_INFO,
        pNext = next,
        flags = flags,
        pApplicationInfo = &appInfo,
        enabledLayerCount = u32(len(enabledInstanceLayers)),
        ppEnabledLayerNames = len(enabledInstanceLayers) == 0 ? nil : &enabledInstanceLayers[0],
        enabledExtensionCount = u32(len(enabledInstanceExtensions)),
        ppEnabledExtensionNames = len(enabledInstanceExtensions) == 0 ? nil : &enabledInstanceExtensions[0],
    }

    /* load instance function pointers */
    if this._globalFunctions.createInstance(&instanceCI, this._allocator, &this._instance.instance) != .SUCCESS {
        _log(this, .Fatal, "Failed to create Vulkan instance")
        return false
    }
    
    if !loadVulkanInstanceFunctions(this._instance.instance, this._globalFunctions.getInstanceProcAddr, &this._instance.instanceFunctionPointers) {
        _log(this, .Fatal, "Failed to load Vulkan instance functions")
        return false
    }

    if !loadVulkanInstance11Functions(this._instance.instance, this._globalFunctions.getInstanceProcAddr, &this._instance.instance11FunctionPointers) {
        _log(this, .Fatal, "Failed to load Vulkan 1.1 instance functions")
        return false
    }
    
    if !this._headless {
        if !loadVulkanInstanceSurfaceKHRFunctions(this._instance.instance, this._globalFunctions.getInstanceProcAddr, &this._instance.khr.surface) {
            _log(this, .Fatal, "Failed to load Vulkan instance functions for VK_KHR_surface")
            return false
        }
    }

    if this._debug && foundDebugUtilsEXT {
        if !loadVulkanInstanceDebugUtilsEXTFunctions(this._instance.instance, this._globalFunctions.getInstanceProcAddr, &this._instance.ext.debugUtils) {
            _log(this, .Fatal, "Failed to load Vulkan instance functions for VK_EXT_debug_utils")
            return false
        }
    }

    /* create queued windows if necessary */
    if this._areWindowsQueued {
        for &w in this._queuedWindows {
            if !this->createWSI(&w.window, w.setting) {
                _log(this, .Fatal, "Failed to create queued window WSI")
                return false
            }
        }

        delete(this._queuedWindows)
        this._areWindowsQueued = false
    }

    /* physical device acquisition */
    availablePhysicalDeviceCount: u32
    if this._instance.enumeratePhysicalDevices(this._instance.instance, &availablePhysicalDeviceCount, nil) != .SUCCESS {
        _log(this, .Fatal, "Failed to enumerate Vulkan physical devices")
        return false
    }

    availablePhysicalDevices := make([]vk.PhysicalDevice, availablePhysicalDeviceCount)
    defer delete(availablePhysicalDevices)

    if this._instance.enumeratePhysicalDevices(this._instance.instance, &availablePhysicalDeviceCount, &availablePhysicalDevices[0]) != .SUCCESS {
        _log(this, .Fatal, "Failed to enumerate Vulkan physical devices")
        return false
    }

    viablePhysicalDevice:                   vk.PhysicalDevice
    viablePhysicalDeviceProperties:         vk.PhysicalDeviceProperties
    viablePhysicalDeviceTotalPrivateMemory: vk.DeviceSize
    viablePhysicalDeviceTotalSharedMemory:  vk.DeviceSize
    viablePhysicalDeviceSupportScore:       int
    viablePhysicalDeviceDriverPreferred:    bool

    availablePhysicalDeviceExtensionPropeties := make([dynamic]vk.ExtensionProperties)
    defer delete(availablePhysicalDeviceExtensionPropeties)

    for &pd in availablePhysicalDevices {
        properties12 := vk.PhysicalDeviceVulkan12Properties {
            sType = .PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES
        }

        properties2 := vk.PhysicalDeviceProperties2 {
            sType = .PHYSICAL_DEVICE_PROPERTIES_2,
            pNext = &properties12,
        }

        this._instance.getPhysicalDeviceProperties2(pd, &properties2)

        _log(this, .Verbose, "Interviewing physical device %s (%s) (API version: %d.%d.%d) with driver %s (version: %d)", cstring(&properties2.properties.deviceName[0]), properties2.properties.deviceType, VK_API_VERSION_MAJOR(properties2.properties.apiVersion), VK_API_VERSION_MINOR(properties2.properties.apiVersion), VK_API_VERSION_PATCH(properties2.properties.apiVersion), cstring(&properties12.driverName[0]), properties2.properties.driverVersion)

        availablePhysicalDeviceExtensionPropertiesCount: u32
        if this._instance.enumerateDeviceExtensionProperties(pd, nil, &availablePhysicalDeviceExtensionPropertiesCount, nil) != .SUCCESS {
            _log(this, .Error, "Failed to enumerate physical device %s extensions; continuing to next device", cstring(&properties2.properties.deviceName[0]))
            continue
        }
        
        resize(&availablePhysicalDeviceExtensionPropeties, availablePhysicalDeviceExtensionPropertiesCount)
        if this._instance.enumerateDeviceExtensionProperties(pd, nil, &availablePhysicalDeviceExtensionPropertiesCount, &availablePhysicalDeviceExtensionPropeties[0]) != .SUCCESS {
            _log(this, .Error, "Failed to enumerate physical device %s extensions; continuing to next device", cstring(&properties2.properties.deviceName[0]))
            continue
        }

        supportScore := int(0)
        if properties12.shaderUniformBufferArrayNonUniformIndexingNative {
            supportScore += 5
        }
        
        if properties12.shaderSampledImageArrayNonUniformIndexingNative {
            supportScore += 10
        }
        
        if properties12.shaderStorageBufferArrayNonUniformIndexingNative {
            supportScore += 10
        }
        
        if properties12.shaderStorageImageArrayNonUniformIndexingNative {
            supportScore += 10
        }

        if properties12.shaderInputAttachmentArrayNonUniformIndexingNative {
            supportScore += 2
        }

        foundPortabilitySubsetKHR: bool
        foundDynamicRenderingKHR: bool
        foundSwapchainKHR, foundSwapchainMaintenance1EXT: bool

        for &extensionProperties in availablePhysicalDeviceExtensionPropeties {
            _log(this, .Verbose, "Interview physical device %s extension %s (specification version: %d)", cstring(&properties2.properties.deviceName[0]), cstring(&extensionProperties.extensionName[0]), extensionProperties.specVersion)
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_swapchain") == 0 {
                foundSwapchainKHR = true
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_swapchain_maintenance1") == 0 {
                foundSwapchainMaintenance1EXT = true
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_dynamic_rendering") == 0 {
                foundDynamicRenderingKHR = true
                
                if !headless {
                    supportScore += 40
                }
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_portability_subset") == 0 {
                foundPortabilitySubsetKHR = true
            }
        }

        when ODIN_OS == .Darwin {
            if !foundPortabilitySubsetKHR {
                _log(this, .Verbose, "Physical device %s lacks VK_KHR_portability_subset which is required for Apple device compatibility", cstring(&properties2.properties.deviceName[0]))
                continue
            }
        }

        if !headless {
            if !foundSwapchainKHR {
                _log(this, .Verbose, "Physical device %s lacks VK_KHR_swapchain; incompatible with non-headless renderer", cstring(&properties2.properties.deviceName[0]))
                continue
            } else if !foundSwapchainMaintenance1EXT {
                _log(this, .Verbose, "Physical device %s lacks VK_EXT_swapchain_maintenance1; incompatible with non-headless renderer", cstring(&properties2.properties.deviceName[0]))
                continue
            }
            
            if !foundDynamicRenderingKHR {
                _log(this, .Verbose, "Physical device %s lacks VK_KHR_dynamic_rendering (which is recommended)", cstring(&properties2.properties.deviceName[0]))
            }
        }

        features12 := vk.PhysicalDeviceVulkan12Features {
            sType = .PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
        }
        
        features2 := vk.PhysicalDeviceFeatures2 {
            sType = .PHYSICAL_DEVICE_FEATURES_2,
            pNext = &features12,
        }

        this._instance.getPhysicalDeviceFeatures2(pd, &features2)

        if !features2.features.shaderUniformBufferArrayDynamicIndexing {
            _log(this, .Verbose, "Physical device %s lacks uniform buffer array dynamic indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 15
        }

        if !features2.features.shaderSampledImageArrayDynamicIndexing {
            _log(this, .Verbose, "Physical device %s lacks sampled image array dynamic indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 20
        }

        if !features2.features.shaderStorageImageArrayDynamicIndexing {
            _log(this, .Verbose, "Physical device %s lacks storage image array dynamic indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 20
        }

        if !features2.features.shaderStorageBufferArrayDynamicIndexing {
            _log(this, .Verbose, "Physical device %s lacks storage buffer array dynamic indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 20
        }

        if !features12.shaderUniformBufferArrayNonUniformIndexing {
            _log(this, .Verbose, "Physical device %s lacks uniform buffer array non-uniform indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 5
        }

        if !features12.shaderSampledImageArrayNonUniformIndexing {
            _log(this, .Verbose, "Physical device %s lacks sampled image array non-uniform indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 10
        }

        if !features12.shaderStorageImageArrayNonUniformIndexing {
            _log(this, .Verbose, "Physical device %s lacks storage image array non-uniform indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 10
        }

        if !features12.shaderStorageBufferArrayNonUniformIndexing {
            _log(this, .Verbose, "Physical device %s lacks storage buffer array non-uniform indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 10
        }

        if !features12.shaderInputAttachmentArrayNonUniformIndexing {
            _log(this, .Verbose, "Physical device %s lacks input attachment array non-uniform indexing", cstring(&properties2.properties.deviceName[0]))
            supportScore -= 2
        }

        memoryProperties: vk.PhysicalDeviceMemoryProperties
        this._instance.getPhysicalDeviceMemoryProperties(pd, &memoryProperties)

        totalPrivateMemory, totalSharedMemory: vk.DeviceSize
        for i in 0..<memoryProperties.memoryTypeCount {
            if .DEVICE_LOCAL in memoryProperties.memoryTypes[i].propertyFlags {
                totalPrivateMemory += memoryProperties.memoryHeaps[i].size
            } else if .HOST_VISIBLE in memoryProperties.memoryTypes[i].propertyFlags {
                totalSharedMemory += memoryProperties.memoryHeaps[i].size
            }
        }

        driverPreferred := false
        if this._buffers != nil && this._driverPreference[0] != 0 {
            if strings.compare(string(cstring(&this._driverPreference[0])), string(cstring(&properties12.driverName[0]))) == 0 {
                driverPreferred = true
            }
        }

        if viablePhysicalDevice == nil {
            viablePhysicalDevice = pd
            viablePhysicalDeviceProperties = properties2.properties
            viablePhysicalDeviceTotalPrivateMemory = totalPrivateMemory
            viablePhysicalDeviceTotalSharedMemory = totalSharedMemory
            viablePhysicalDeviceSupportScore = supportScore
            viablePhysicalDeviceDriverPreferred = driverPreferred
            continue
        }

        if !viablePhysicalDeviceDriverPreferred && driverPreferred {
            _log(this, .Verbose, "Prefer physical device %s over previously viable physical device %s", cstring(&properties2.properties.deviceName[0]), cstring(&viablePhysicalDeviceProperties.deviceName[0]))
            viablePhysicalDevice = pd
            viablePhysicalDeviceProperties = properties2.properties
            viablePhysicalDeviceTotalPrivateMemory = totalPrivateMemory
            viablePhysicalDeviceTotalSharedMemory = totalSharedMemory
            viablePhysicalDeviceSupportScore = supportScore
            viablePhysicalDeviceDriverPreferred = driverPreferred
            continue
        } else if viablePhysicalDeviceDriverPreferred && !driverPreferred {
            continue
        }

        goalDeviceType: vk.PhysicalDeviceType
        if lowPower {
            goalDeviceType = .INTEGRATED_GPU
        } else {
            goalDeviceType = .DISCRETE_GPU
        }
        
        if properties2.properties.deviceType == goalDeviceType && viablePhysicalDeviceProperties.deviceType != goalDeviceType {
            _log(this, .Verbose, "Prefer physical device %s over previously viable physical device %s", cstring(&properties2.properties.deviceName[0]), cstring(&viablePhysicalDeviceProperties.deviceName[0]))
            viablePhysicalDevice = pd
            viablePhysicalDeviceProperties = properties2.properties
            viablePhysicalDeviceTotalPrivateMemory = totalPrivateMemory
            viablePhysicalDeviceTotalSharedMemory = totalSharedMemory
            viablePhysicalDeviceSupportScore = supportScore
            viablePhysicalDeviceDriverPreferred = driverPreferred
            continue
        }

        if properties2.properties.deviceType != goalDeviceType && viablePhysicalDeviceProperties.deviceType == goalDeviceType {
            continue
        }

        if supportScore > viablePhysicalDeviceSupportScore {
            _log(this, .Verbose, "Prefer physical device %s over previously viable physical device %s", cstring(&properties2.properties.deviceName[0]), cstring(&viablePhysicalDeviceProperties.deviceName[0]))
            viablePhysicalDevice = pd
            viablePhysicalDeviceProperties = properties2.properties
            viablePhysicalDeviceTotalPrivateMemory = totalPrivateMemory
            viablePhysicalDeviceTotalSharedMemory = totalSharedMemory
            viablePhysicalDeviceSupportScore = supportScore
            viablePhysicalDeviceDriverPreferred = driverPreferred
            continue
        }

        if totalPrivateMemory > viablePhysicalDeviceTotalPrivateMemory {
            _log(this, .Verbose, "Prefer physical device %s over previously viable physical device %s", cstring(&properties2.properties.deviceName[0]), cstring(&viablePhysicalDeviceProperties.deviceName[0]))
            viablePhysicalDevice = pd
            viablePhysicalDeviceProperties = properties2.properties
            viablePhysicalDeviceTotalPrivateMemory = totalPrivateMemory
            viablePhysicalDeviceTotalSharedMemory = totalSharedMemory
            viablePhysicalDeviceSupportScore = supportScore
            viablePhysicalDeviceDriverPreferred = driverPreferred
            continue
        }
    }

    if viablePhysicalDevice == nil {
        _log(this, .Fatal, "No suitable physical device found")
        return false
    }

    _log(this, .Verbose, "Selected physical device %s", cstring(&viablePhysicalDeviceProperties.deviceName[0]))
    
    /* logical device creation */
    availablePhysicalDeviceExtensionPropertiesCount: u32
    if this._instance.enumerateDeviceExtensionProperties(viablePhysicalDevice, nil, &availablePhysicalDeviceExtensionPropertiesCount, nil) != .SUCCESS {
        _log(this, .Fatal, "Failed to enumerate over chosen physical device extensions")
        return false
    }
    
    resize(&availablePhysicalDeviceExtensionPropeties, availablePhysicalDeviceExtensionPropertiesCount)
    if this._instance.enumerateDeviceExtensionProperties(viablePhysicalDevice, nil, &availablePhysicalDeviceExtensionPropertiesCount, &availablePhysicalDeviceExtensionPropeties[0]) != .SUCCESS {
        _log(this, .Fatal, "Failed to enumerate over chosen physical device extensions")
        return false
    }

    next = nil

    enabledDeviceExtensions := make([dynamic]cstring)
    defer delete(enabledDeviceExtensions)

    dynamicRenderingFeatures := vk.PhysicalDeviceDynamicRenderingFeaturesKHR {
        sType = .PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES_KHR,
        dynamicRendering = true,
    }

    swapchainMaintenance1Features := vk.PhysicalDeviceSwapchainMaintenance1FeaturesEXT {
        sType = .PHYSICAL_DEVICE_SWAPCHAIN_MAINTENANCE_1_FEATURES_EXT,
        swapchainMaintenance1 = true,
    }

    pageableDeviceLocalMemoryFeatures := vk.PhysicalDevicePageableDeviceLocalMemoryFeaturesEXT {
        sType = .PHYSICAL_DEVICE_PAGEABLE_DEVICE_LOCAL_MEMORY_FEATURES_EXT,
        pageableDeviceLocalMemory = true,
    }

    memoryPriorityFeatures := vk.PhysicalDeviceMemoryPriorityFeaturesEXT {
        sType = .PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT,
        memoryPriority = true,
    }

    for &extensionProperties in availablePhysicalDeviceExtensionPropeties {
        if !headless {
            if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_swapchain") == 0 {
                append(&enabledDeviceExtensions, cstring(&extensionProperties.extensionName[0]))
            } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_swapchain_maintenance1") == 0 {
                swapchainMaintenance1Features.pNext = next
                next = &swapchainMaintenance1Features

                append(&enabledDeviceExtensions, cstring(&extensionProperties.extensionName[0]))
            }
        }

        if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_dynamic_rendering") == 0 {
            dynamicRenderingFeatures.pNext = next
            next = &dynamicRenderingFeatures

            append(&enabledDeviceExtensions, cstring(&extensionProperties.extensionName[0]))
        } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_memory_priority") == 0 {
            memoryPriorityFeatures.pNext = next
            next = &memoryPriorityFeatures

            append(&enabledDeviceExtensions, cstring(&extensionProperties.extensionName[0]))
        } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_EXT_pageable_device_local_memory") == 0 {
            pageableDeviceLocalMemoryFeatures.pNext = next
            next = &pageableDeviceLocalMemoryFeatures

            append(&enabledDeviceExtensions, cstring(&extensionProperties.extensionName[0]))
        } else if strings.compare(string(cstring(&extensionProperties.extensionName[0])), "VK_KHR_portability_subset") == 0 {
            append(&enabledDeviceExtensions, cstring(&extensionProperties.extensionName[0]))
        }
    }

    physicalDeviceQueueFamilyPropertiesCount: u32
    this._instance.getPhysicalDeviceQueueFamilyProperties(viablePhysicalDevice, &physicalDeviceQueueFamilyPropertiesCount, nil)

    physicalDeviceQueueFamilyProperties := make([]vk.QueueFamilyProperties, physicalDeviceQueueFamilyPropertiesCount)
    this._instance.getPhysicalDeviceQueueFamilyProperties(viablePhysicalDevice, &physicalDeviceQueueFamilyPropertiesCount, &physicalDeviceQueueFamilyProperties[0])

    preferredGeneralQueueFamily := max(u32)
    preferredPresentQueueFamily := max(u32)
    preferredGraphicsQueueFamily := max(u32)
    preferredTransferQueueFamily := max(u32)
    preferredComputeQueueFamily := max(u32)

    preferredGeneralScore := min(int)
    preferredPresentScore := min(int)
    preferredGraphicsScore := min(int)
    preferredTransferScore := min(int)
    preferredComputeScore := min(int)

    for i in 0..<u32(len(physicalDeviceQueueFamilyProperties)) {
        queueProperties := &physicalDeviceQueueFamilyProperties[i]
        generalScore, presentScore, graphicsScore, transferScore, computeScore: int
        if .GRAPHICS in queueProperties.queueFlags {
            generalScore += 1
            graphicsScore += 1
            transferScore -= 1
            computeScore -= 1
        }

        if .COMPUTE in queueProperties.queueFlags {
            generalScore += 1
            graphicsScore -= 1
            transferScore -= 1
            computeScore += 1
        }

        if .TRANSFER in queueProperties.queueFlags {
            generalScore += 1
            graphicsScore -= 1
            transferScore += 1
            computeScore -= 1
        }

        if !this._headless {
            for _, pool in this._backbufferPools {
                supported: b32
                if this._instance.khr.surface.getPhysicalDeviceSurfaceSupport(viablePhysicalDevice, i, pool._surface, &supported) != .SUCCESS {
                    _log(this, .Fatal, "Failed to get Vulkan physical device surface support for queued window")
                    return false
                }

                presentScore += supported ? 1 : 0
            }
        }

        if generalScore > preferredGeneralScore {
            preferredGeneralScore = generalScore
            preferredGeneralQueueFamily = i
        }

        if presentScore > preferredPresentScore {
            preferredPresentScore = presentScore
            preferredPresentQueueFamily = i
        }

        if graphicsScore > preferredGraphicsScore {
            preferredGraphicsScore = graphicsScore
            preferredGraphicsQueueFamily = i
        }

        if transferScore > preferredTransferScore {
            preferredTransferScore = transferScore
            preferredTransferQueueFamily = i
        }

        if computeScore > preferredComputeScore {
            preferredComputeScore = computeScore
            preferredComputeQueueFamily = i
        }
    }

    if preferredGeneralQueueFamily == max(u32) {
        preferredGeneralQueueFamily = 0
    }

    if preferredPresentQueueFamily == max(u32) {
        preferredPresentQueueFamily = preferredGeneralQueueFamily
    }

    if preferredGraphicsQueueFamily == max(u32) {
        preferredGraphicsQueueFamily = preferredGeneralQueueFamily
    }

    if preferredTransferQueueFamily == max(u32) {
        preferredTransferQueueFamily = preferredGeneralQueueFamily
    }

    if preferredComputeQueueFamily == max(u32) {
        preferredComputeQueueFamily = preferredGeneralQueueFamily
    }

    queuePriorities := []f32 { 1.0, 1.0, 1.0, 1.0, 1.0 }
    deviceQueueCIs := make([dynamic]vk.DeviceQueueCreateInfo)
    defer delete(deviceQueueCIs)

    deviceQueueIntendedTypes := make([dynamic]QueueTypeMask)
    defer delete(deviceQueueIntendedTypes)

    addDeviceQueueCI := proc(queueFamilyProperties: []vk.QueueFamilyProperties, deviceQueueCIs: ^[dynamic]vk.DeviceQueueCreateInfo, deviceQueueIntendedTypes: ^[dynamic]QueueTypeMask, queuePriorities: [^]f32, family: u32, intendedType: QueueType, uniqueQueueCount: ^u32) -> u32 {
        for i in 0..<len(deviceQueueCIs) {
            ci := &deviceQueueCIs[i]
            if ci.queueFamilyIndex == family {
                deviceQueueIntendedTypes[i] |= { intendedType }
                if ci.queueCount + 1 < queueFamilyProperties[ci.queueFamilyIndex].queueCount {
                    ci.queueCount += 1
                    return ci.queueCount - 1
                } else {
                    return 0
                }
            }
        }

        uniqueQueueCount^ += 1
        append(deviceQueueCIs, vk.DeviceQueueCreateInfo {
            sType = .DEVICE_QUEUE_CREATE_INFO,
            queueFamilyIndex = family,
            queueCount = 1,
            pQueuePriorities = queuePriorities,
        })

        append(deviceQueueIntendedTypes, QueueTypeMask { intendedType })
        return 0
    }

    uniqueQueueCount := u32(0)
    generalQueueIndex := addDeviceQueueCI(physicalDeviceQueueFamilyProperties, &deviceQueueCIs, &deviceQueueIntendedTypes, &queuePriorities[0], preferredGeneralQueueFamily, .General, &uniqueQueueCount)
    presentQueueIndex := addDeviceQueueCI(physicalDeviceQueueFamilyProperties, &deviceQueueCIs, &deviceQueueIntendedTypes, &queuePriorities[0], preferredPresentQueueFamily, .Present, &uniqueQueueCount)
    graphicsQueueIndex := addDeviceQueueCI(physicalDeviceQueueFamilyProperties, &deviceQueueCIs, &deviceQueueIntendedTypes, &queuePriorities[0], preferredGraphicsQueueFamily, .Graphics, &uniqueQueueCount)
    transferQueueIndex := addDeviceQueueCI(physicalDeviceQueueFamilyProperties, &deviceQueueCIs, &deviceQueueIntendedTypes, &queuePriorities[0], preferredTransferQueueFamily, .Transfer, &uniqueQueueCount)
    computeQueueIndex := addDeviceQueueCI(physicalDeviceQueueFamilyProperties, &deviceQueueCIs, &deviceQueueIntendedTypes, &queuePriorities[0], preferredComputeQueueFamily, .Compute, &uniqueQueueCount)

    this._queues = make([]Queue, uniqueQueueCount)
    {
        currentCI := u32(0)
        currentQueue := u32(0)
        for i in 0..<len(this._queues) {
            queueFlags := physicalDeviceQueueFamilyProperties[deviceQueueCIs[currentCI].queueFamilyIndex].queueFlags
            supportedTypes: QueueTypeMask
            if .GRAPHICS in queueFlags {
                supportedTypes |= { .Graphics }
            } else if .TRANSFER in queueFlags {
                supportedTypes |= { .Transfer }
            } else if .COMPUTE in queueFlags {
                supportedTypes |= { .Compute }
            }

            this._queues[i] = {
                family = deviceQueueCIs[currentCI].queueFamilyIndex,
                index = 0,
                intendedTypes = deviceQueueIntendedTypes[i],
                supportedTypes = supportedTypes,
            }

            currentQueue += 1
            if currentQueue >= deviceQueueCIs[currentCI].queueCount {
                currentQueue = 0
                currentCI += 1
            }
        }
    }

    availablePhysicalDeviceFeatures: vk.PhysicalDeviceFeatures
    this._instance.getPhysicalDeviceFeatures(viablePhysicalDevice, &availablePhysicalDeviceFeatures)

    enabledFeatures := vk.PhysicalDeviceFeatures {
        shaderUniformBufferArrayDynamicIndexing = availablePhysicalDeviceFeatures.shaderUniformBufferArrayDynamicIndexing,
        shaderSampledImageArrayDynamicIndexing = availablePhysicalDeviceFeatures.shaderSampledImageArrayDynamicIndexing,
        shaderStorageBufferArrayDynamicIndexing = availablePhysicalDeviceFeatures.shaderStorageBufferArrayDynamicIndexing,
        shaderStorageImageArrayDynamicIndexing = availablePhysicalDeviceFeatures.shaderStorageImageArrayDynamicIndexing,
    }

    deviceCI := vk.DeviceCreateInfo {
        sType = .DEVICE_CREATE_INFO,
        pNext = next,
        flags = {},
        queueCreateInfoCount = u32(len(deviceQueueCIs)),
        pQueueCreateInfos = &deviceQueueCIs[0],
        enabledLayerCount = 0,
        ppEnabledLayerNames = nil,
        enabledExtensionCount = u32(len(enabledDeviceExtensions)),
        ppEnabledExtensionNames = len(enabledDeviceExtensions) == 0 ? nil : &enabledDeviceExtensions[0],
        pEnabledFeatures = &enabledFeatures,
    }

    this._device.physical = viablePhysicalDevice
    if this._instance.createDevice(this._device.physical, &deviceCI, this._allocator, &this._device.logical) != .SUCCESS {
        _log(this, .Fatal, "Failed to create Vulkan logical device using physical device %s", cstring(&viablePhysicalDeviceProperties.deviceName[0]))
        return false
    }

    /* loading logical device function pointers */
    if !loadVulkanDeviceFunctions(this._device.logical, this._instance.getDeviceProcAddr, &this._device.deviceFunctionPointers) {
        _log(this, .Fatal, "Failed to load Vulkan logical device function pointers")
        return false
    }

    if !loadVulkanDevice11Functions(this._device.logical, this._instance.getDeviceProcAddr, &this._device.device11FunctionsPointers) {
        _log(this, .Fatal, "Failed to load Vulkan 1.1 logical device function pointers")
        return false
    }

    if !loadVulkanDevice12Functions(this._device.logical, this._instance.getDeviceProcAddr, &this._device.device12FunctionsPointers) {
        _log(this, .Fatal, "Failed to load Vulkan 1.2 logical device function pointers")
        return false
    }

    if !loadVulkanDeviceSwapchainKHRFunctions(this._device.logical, this._instance.getDeviceProcAddr, &this._device.khr.swapchain) && !headless {
        _log(this, .Fatal, "Failed to load Vulkan swapchain function pointers required for non-headless mode")
        return false
    }

    if !loadVulkanDeviceDynamicRenderingKHRFunctions(this._device.logical, this._instance.getDeviceProcAddr, &this._device.khr.dynamicRendering) {
        _log(this, .Warning, "Failed to load Vulkan dynamic rendering function pointers which is recommended for use")
    }

    /* get queues and setup command pools */
    for &queue in this._queues {
        this._device.getDeviceQueue(this._device.logical, queue.family, queue.index, &queue.queue)

        if .General in queue.intendedTypes {
            this._generalQueue = &queue
        }

        if .Present in queue.intendedTypes {
            this._presentQueue = &queue
        }

        if .Graphics in queue.intendedTypes {
            this._graphicsQueue = &queue
        }

        if .Transfer in queue.intendedTypes {
            this._transferQueue = &queue
        }

        if .Compute in queue.intendedTypes {
            this._computeQueue = &queue
        }

        if !this->createCommandPool(&queue.commandPool, &this._defaultFencePool, &queue) {
            _log(this, .Fatal, "Failed to create internal command pool")
            return false
        }

        queue.commandPool._isInternal = true
    }

    /* setup pools */
    if !this->createFencePool(&this._defaultFencePool) {
        _log(this, .Fatal, "Failed to create internal default fence pool")
        return false
    }

    this._defaultFencePool._isInternal = true

    if !this->createSemaphorePool(&this._defaultSemaphorePool) {
        _log(this, .Fatal, "Failed to create internal default semaphore pool")
        return false
    }
    
    this._defaultSemaphorePool._isInternal = true

    /* finish initializing any queued windows */
    for w in this._backbufferPools {
        window := w
        if !_Renderer_finishCreateWSI(this, &window) {
            _log(this, .Fatal, "Failed to finish creating WSI")
            return false
        }
    }

    
    if vma.create_allocator({
        flags                           = ((memoryPriorityFeatures.pNext != nil || deviceCI.pNext == &memoryPriorityFeatures) ? { .Ext_Memory_Priority } : {}),
        physical_device                 = this._device.physical,
        device                          = this._device.logical,
        preferred_large_heap_block_size = 0,    /* default to 256 MiB */
        allocation_callbacks            = this._allocator,
        vulkan_functions                = &{
            get_instance_proc_addr          = this._globalFunctions.getInstanceProcAddr,
            get_device_proc_addr            = this._instance.getDeviceProcAddr,
        },
        instance                        = this._instance.instance,
        vulkan_api_version              = appInfo.apiVersion,
    }, &this._vma) != .SUCCESS {
        _log(this, .Fatal, "Failed to create VMA allocator")
        return false
    }

    this._defaultResourcePool = {
        destroy         = ResourcePool_destroy,
        createBuffer    = ResourcePool_createBuffer,
        createImage     = ResourcePool_createImage,

        _renderer       = this,
        _pool           = nil,

        _isInternal     = true,
    }

    return true
}

VkRenderer_destroy :: proc "c" (this: ^Renderer) {
    if this == nil {
        return
    }

    context = this._ctx

    this._performingDestruction = true
    if this._device.logical != nil {
        if this._device.deviceWaitIdle != nil {
            this._device.deviceWaitIdle(this._device.logical)
        }

        if this._vma != nil {
            vma.destroy_allocator(this._vma)
        }

        for &queue in this._queues {
            queue.commandPool->destroy()
        }

        delete(this._queues)
        
        this._defaultSemaphorePool->destroy()
        this._defaultFencePool->destroy()
    }

    for _, pool in this._backbufferPools {
        this._instance.khr.surface.destroySurface(this._instance.instance, pool._surface, this._allocator)
    }

    if this._device.logical != nil {
        if this._device.destroyDevice != nil {
            this._device.destroyDevice(this._device.logical, this._allocator)
        }
    }

    if this._instance.instance != nil {
        if this._instance.destroyInstance != nil {
            this._instance.destroyInstance(this._instance.instance, this._allocator)
        }
    }
    
    if this._library != nil && this._library != VULKAN_LOADER_DEFAULT_HANDLE {
        dynlib.unload_library(this._library)
    }

    /* cleanup containers */
    delete(this._backbufferPools)

    if this._buffers != nil {
        free(this._buffers)
    }
}

/* internal function */
_Renderer_finishCreateWSI :: proc(this: ^Renderer, window: ^krfw.Window) -> b32 {
    if this._device.logical == nil {
        return true
    }

    backbufferPool := &this._backbufferPools[window^]

    capabilities: vk.SurfaceCapabilitiesKHR
    if this._instance.khr.surface.getPhysicalDeviceSurfaceCapabilities(this._device.physical, backbufferPool._surface, &capabilities) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan physical device surface capabilities")
        return false
    }

    surfaceFormatCount: u32
    if this._instance.khr.surface.getPhysicalDeviceSurfaceFormats(this._device.physical, backbufferPool._surface, &surfaceFormatCount, nil) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan list of compatible surface formats")
        return false
    }

    surfaceFormats := make([]vk.SurfaceFormatKHR, surfaceFormatCount)
    defer delete(surfaceFormats)

    if this._instance.khr.surface.getPhysicalDeviceSurfaceFormats(this._device.physical, backbufferPool._surface, &surfaceFormatCount, &surfaceFormats[0]) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan list of compatible surface formats")
        return false
    }

    presentModeCount: u32
    if this._instance.khr.surface.getPhysicalDeviceSurfacePresentModes(this._device.physical, backbufferPool._surface, &presentModeCount, nil) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan list of compatible present modes")
        return false
    }

    presentModes := make([]vk.PresentModeKHR, presentModeCount)
    defer delete(presentModes)

    if this._instance.khr.surface.getPhysicalDeviceSurfacePresentModes(this._device.physical, backbufferPool._surface, &presentModeCount, &presentModes[0]) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan list of compatible present modes")
        return false
    }

    preferredSurfaceFormat := u32(0)
    preferredSurfaceFormatScore := min(int)
    for i in 0..<surfaceFormatCount {
        score := 0
        #partial switch surfaceFormats[i].format {
            case .R8G8B8A8_SRGB:
                score += 20
            case .B8G8R8A8_SRGB:
                score += 15
            case .R8G8B8_SRGB:
                score += 12
            case .B8G8R8_SRGB:
                score += 11
            case .R8G8B8A8_UNORM:
                score += 10
            case .B8G8R8A8_UNORM:
                score += 5
            case:
                break
        }
        
        #partial switch surfaceFormats[i].colorSpace {
            case .SRGB_NONLINEAR:
                score += 20
            case .EXTENDED_SRGB_NONLINEAR_EXT:
                score += 5
            case:
                break
        }

        if score > preferredSurfaceFormatScore {
            preferredSurfaceFormat = i
            preferredSurfaceFormatScore = score
        }
    }

    mailboxScore        := 20
    fifoRelaxedScore    := 15
    fifoScore           := 10
    immediateScore      := 5

    #partial switch backbufferPool._setting {
        case .Immediate:
            immediateScore += 20
        case .VSync:
            fifoRelaxedScore += 15
            fifoScore += 15
        case:
            break
    }

    preferredPresentMode := u32(0)
    preferredPresentModeScore := min(int)
    for i in 0..<presentModeCount {
        score := 0

        #partial switch presentModes[i] {
            case .MAILBOX:
                score += mailboxScore
            case .FIFO_RELAXED:
                score += fifoRelaxedScore
            case .FIFO:
                score += fifoScore
            case .IMMEDIATE:
                score += immediateScore
            case:
                break
        }

        if score > preferredPresentModeScore {
            preferredPresentMode = i
            preferredPresentModeScore = score
        }
    }

    ci := vk.SwapchainCreateInfoKHR {
        sType = .SWAPCHAIN_CREATE_INFO_KHR,
        surface = backbufferPool._surface,
        minImageCount = min(capabilities.maxImageCount, max(capabilities.minImageCount, 3)),
        imageFormat = surfaceFormats[preferredSurfaceFormat].format,
        imageColorSpace = surfaceFormats[preferredSurfaceFormat].colorSpace,
        imageExtent = capabilities.currentExtent,
        imageArrayLayers = 1,
        imageUsage = { .TRANSFER_SRC, .TRANSFER_DST, .COLOR_ATTACHMENT },
        imageSharingMode = .EXCLUSIVE,
        queueFamilyIndexCount = 1,
        pQueueFamilyIndices = &this._presentQueue.family,
        preTransform = { .IDENTITY },
        compositeAlpha = { .OPAQUE },
        presentMode = presentModes[preferredPresentMode],
    }

    if this._device.khr.swapchain.createSwapchain(this._device.logical, &ci, this._allocator, &backbufferPool._swapchain) != .SUCCESS {
        _log(this, .Error, "Failed to create Vulkan swapchain")
        return false
    }

    backbufferCount: u32
    if this._device.khr.swapchain.getSwapchainImages(this._device.logical, backbufferPool._swapchain, &backbufferCount, nil) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan swapchain images")
        return false
    }

    backbufferPool._backbuffers = make([]Backbuffer, backbufferCount)
    backbufferImages := make([]vk.Image, backbufferCount)
    defer delete(backbufferImages)

    if this._device.khr.swapchain.getSwapchainImages(this._device.logical, backbufferPool._swapchain, &backbufferCount, &backbufferImages[0]) != .SUCCESS {
        _log(this, .Error, "Failed to get Vulkan swapchain images")
        return false
    }

    for i in 0..<backbufferCount {
        ci := vk.ImageViewCreateInfo {
            sType = .IMAGE_VIEW_CREATE_INFO,
            image = backbufferImages[i],
            viewType = .D2,
            format = surfaceFormats[preferredSurfaceFormat].format,
            components = {
                r = .IDENTITY,
                g = .IDENTITY,
                b = .IDENTITY,
                a = .IDENTITY,
            },
            subresourceRange = {
                aspectMask = { .COLOR },
                baseMipLevel = 0,
                levelCount = 1,
                baseArrayLayer = 0,
                layerCount = 1,
            }
        }

        view: vk.ImageView
        if this._device.createImageView(this._device.logical, &ci, this._allocator, &view) != .SUCCESS {
            _log(this, .Error, "Failed to create Vulkan image view for backbuffer {}", i)
            return false
        }
        
        backbufferPool._backbuffers[i] = {
            index = i,
            image = {
                destroy             = ProcIResourceDestroy(Image_destroy),
                getAllocationInfo   = IResource_getAllocationInfo,
                mapResource         = IResource_mapResource,
                unmapResource       = IResource_unmapResource,
                flush               = IResource_flush,
                invalidate          = IResource_invalidate,

                getVulkanImage      = Image_getVulkanImage,
                getLayout           = Image_getLayout,
                setLayout           = Image_setLayout,

                _pool               = &this._defaultResourcePool,
                _allocation         = nil,

                _isPersistent       = false,
                _isBackbuffer       = true,

                _image              = backbufferImages[i],
                _layout             = .UNDEFINED
            },
            imageView = view,

            surfaceFormat = surfaceFormats[preferredSurfaceFormat],
            extent = capabilities.currentExtent,
            layerCount = 1,

            fence = 0,
            semaphore = 0,
        }
    }

    backbufferPool._fencePool = &this._defaultFencePool
    backbufferPool._semaphorePool = &this._defaultSemaphorePool
    return true
}

VkRenderer_createWSI :: proc "c" (this: ^Renderer, window: ^krfw.Window, setting := krfw.WSISetting.DontCare) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._instance.instance == nil {
        if !this._areWindowsQueued {
            this._areWindowsQueued = true
            this._queuedWindows = make([dynamic]_QueuedWindow)
        }

        append(&this._queuedWindows, _QueuedWindow {
            window = window^,
            setting = setting,
        })

        return true
    }

    if this._headless {
        _log(this, .Warning, "Attempting to create a WSI with a headless renderer might fail")
    }

    surface := _createSurface(this, window)
    if surface == 0 {
        _log(this, .Fatal, "Failed to create Vulkan surface for window")
        return false
    }

    this._backbufferPools[window^] = {
        acquire = BackbufferPool_acquire,
        release = BackbufferPool_release,

        _renderer   = this,
        _window     = window^,
        _setting    = setting,
        _surface    = surface,
    }

    return _Renderer_finishCreateWSI(this, window)
}

VkRenderer_destroyWSI :: proc "c" (this: ^Renderer, window: ^krfw.Window) {
    if this == nil {
        return
    }

    context = this._ctx

    backbufferPool, ok := this._backbufferPools[window^]
    if !ok {
        _log(this, .Warning, "Can't destroy WSI: provided window does not have an associated WSI")
        return
    }
    
    if this._device.logical != nil {
        if this._device.deviceWaitIdle != nil {
            this._device.deviceWaitIdle(this._device.logical)
        }

        if backbufferPool._swapchain != 0 {
            if this._device.destroyImageView != nil {
                for backbuffer in backbufferPool._backbuffers {
                    if backbuffer.imageView != 0 {
                        this._device.destroyImageView(this._device.logical, backbuffer.imageView, this._allocator)
                    }
                }
            }

            if this._device.khr.swapchain.destroySwapchain != nil {
                this._device.khr.swapchain.destroySwapchain(this._device.logical, backbufferPool._swapchain, this._allocator)
            }

            delete(backbufferPool._backbuffers)
        }
    }

    if this._instance.khr.surface.destroySurface != nil {
        this._instance.khr.surface.destroySurface(this._instance.instance, backbufferPool._surface, this._allocator)
    }

    delete_key(&this._backbufferPools, window^)
}

VkRenderer_executePasses :: proc "c" (this: ^Renderer, passCount: u32, passes: [^]^Pass, window: ^krfw.Window) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't execute passes: renderer not fully initialized yet")
        return false
    }

    /* NOTE: this function assumes present queue and general queues are aliases (which is bad) */
    /* TODO: add queue-specific things */
    commandBuffer := this._generalQueue.commandPool->acquire()
    if commandBuffer == nil {
        _log(this, .Error, "Failed to acquire command buffer")
        return false
    }

    bi := vk.CommandBufferBeginInfo {
        sType = .COMMAND_BUFFER_BEGIN_INFO,
    }

    if this._device.beginCommandBuffer(commandBuffer, &bi) != .SUCCESS {
        _log(this, .Error, "Failed to begin command buffer")
        return false
    }

    backbufferPool := (^BackbufferPool)(nil)
    if window != nil {
        if window^ not_in this._backbufferPools {
            if !this->createWSI(window, .DontCare) {
                _log(this, .Error, "Failed to auto-create WSI for provided window")
                return false
            }
        }

        backbufferPool = &this._backbufferPools[window^]
    }

    backbufferPacket := BackbufferPacket {
        backbuffer = nil,
        lastStage = { .TRANSFER },
    }

    submitInfoWaits := make([dynamic]SubmitInfoWait)
    defer delete(submitInfoWaits)

    signalSemaphores := make([dynamic]vk.Semaphore)
    defer delete(signalSemaphores)

    furthestBackbufferStage := vk.PipelineStageFlags { .TOP_OF_PIPE }

    for pass in passes[:passCount] {
        if pass->requiresBackbuffer() {
            if window == nil {
                _log(this, .Warning, "Provided pass requires backbuffer, but no window provided; this is likely to cause problems")
            } else if backbufferPacket.backbuffer == nil {
                backbufferPacket.backbuffer = backbufferPool->acquire({ .Semaphore })
                if backbufferPacket.backbuffer == nil {
                    _log(this, .Error, "Failed to acquire backbuffer for pass execution")
                    return false
                }
            }
        }

        packet := Packet {
            addSyncObjects = proc "c" (this: ^Packet, submitInfoWaitCount: u32, submitInfoWaits: [^]SubmitInfoWait, signalSemaphoreCount: u32, signalSemaphores: [^]vk.Semaphore) {
                context = this.renderer._ctx

                if submitInfoWaits != nil {
                    for wait in submitInfoWaits[:submitInfoWaitCount] {
                        append(this._submitInfoWaits, wait)
                    }
                }

                if signalSemaphores != nil {
                    for semaphore in signalSemaphores[:signalSemaphoreCount] {
                        append(this._signalSemaphores, semaphore)
                    }
                }
            },

            renderer            = this,
            queue               = this._generalQueue,
            commandPool         = &this._generalQueue.commandPool,
            commandBuffer       = commandBuffer,
            backbufferPacket    = backbufferPacket.backbuffer == nil ? nil : &backbufferPacket,

            _submitInfoWaits    = &submitInfoWaits,
            _signalSemaphores   = &signalSemaphores,
        }

        if !pass->execute(&packet) {
            _log(this, .Error, "Pass execution failure")
        }

        if backbufferPacket.lastStage > furthestBackbufferStage {
            furthestBackbufferStage = backbufferPacket.lastStage
        }
    }

    if backbufferPacket.backbuffer != nil {
        backbufferToPresentBarrier := vk.ImageMemoryBarrier {
            sType = .IMAGE_MEMORY_BARRIER,
            srcAccessMask = {},
            dstAccessMask = { .TRANSFER_READ },
            oldLayout = backbufferPacket.backbuffer.image->getLayout(),
            newLayout = .PRESENT_SRC_KHR,
            srcQueueFamilyIndex = this._generalQueue.family,
            dstQueueFamilyIndex = this._generalQueue.family,
            image = backbufferPacket.backbuffer.image->getVulkanImage(),
            subresourceRange = {
                aspectMask =  {.COLOR },
                baseMipLevel = 0,
                levelCount = 1,
                baseArrayLayer = 0,
                layerCount = backbufferPacket.backbuffer.layerCount,
            }
        }

        this._device.cmdPipelineBarrier(commandBuffer,
            backbufferPacket.lastStage,
            { .TRANSFER }, {},
            0, nil,
            0, nil,
            1, &backbufferToPresentBarrier
        )

        backbufferPacket.backbuffer.image->setLayout(.PRESENT_SRC_KHR)
    }

    if this._device.endCommandBuffer(commandBuffer) != .SUCCESS {
        _log(this, .Error, "Failed to end command buffer")
        return false
    }

    backbufferFinishedSemaphore: vk.Semaphore
    if backbufferPacket.backbuffer != nil {
        append(&submitInfoWaits, SubmitInfoWait {
            semaphore = backbufferPacket.backbuffer.semaphore,
            dstStageMask = furthestBackbufferStage,
        })

        backbufferFinishedSemaphore = this._defaultSemaphorePool->acquire()
        if backbufferFinishedSemaphore == 0 {
            _log(this, .Error, "Failed to acquire semaphore for backbuffer completion")
            return false
        }

        append(&signalSemaphores, backbufferFinishedSemaphore)
    }

    submissionFence := this._generalQueue.commandPool->submit(commandBuffer, u32(len(submitInfoWaits)), &submitInfoWaits[0], u32(len(signalSemaphores)), &signalSemaphores[0])
    if submissionFence == 0 {
        _log(this, .Error, "Failed to submit command buffer")
        return false
    }

    waitFences := make([dynamic]vk.Fence, 1)
    defer delete(waitFences)

    waitFences[0] = submissionFence
    
    presentationFinishedFence: vk.Fence
    if backbufferPacket.backbuffer != nil {
        presentationFinishedFence = this._defaultFencePool->acquire()

        spfi := vk.SwapchainPresentFenceInfoEXT {
            sType = .SWAPCHAIN_PRESENT_FENCE_INFO_EXT,
            swapchainCount = 1,
            pFences = &presentationFinishedFence,
        }

        pi := vk.PresentInfoKHR {
            sType = .PRESENT_INFO_KHR,
            pNext = &spfi,
            waitSemaphoreCount = 1,
            pWaitSemaphores = &backbufferFinishedSemaphore,
            swapchainCount = 1,
            pSwapchains = &backbufferPool._swapchain,
            pImageIndices = &backbufferPacket.backbuffer.index,
        }

        if this._device.khr.swapchain.queuePresent(this._generalQueue.queue, &pi) != .SUCCESS {
            _log(this, .Error, "Failed to present")
            return false
        }

        append(&waitFences, presentationFinishedFence)
    }

    this._device.waitForFences(this._device.logical, u32(len(waitFences)), &waitFences[0], true, max(u64))

    this._generalQueue.commandPool->release(commandBuffer, submissionFence)
    if backbufferPacket.backbuffer != nil {
        this._defaultFencePool->release(presentationFinishedFence)
        this._defaultSemaphorePool->release(backbufferFinishedSemaphore)
        backbufferPool->release(backbufferPacket.backbuffer)
    }

    return true
}

/* IVkRenderer */
VkRenderer_loadVulkanLoaderOdin :: proc "c" (this: ^Renderer, path: string) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._library != nil && this._library != VULKAN_LOADER_DEFAULT_HANDLE {
        _log(this, krfw.DebugSeverity.Warning, "Can't load Vulkan loader with new path: library already loaded")
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

VkRenderer_loadVulkanLoader :: proc "c" (this: ^Renderer, len: u32, path: cstring) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    pathString := strings.string_from_ptr(transmute([^]u8)path, int(len))
    return Renderer_loadVulkanLoaderOdin(this, pathString)
}

VkRenderer_loadVulkanLoaderUnicode :: proc "c" (this: ^Renderer, len: u32, path: [^]rune) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    pathString := utf8.runes_to_string(path[:len], context.temp_allocator)
    defer delete(pathString, context.temp_allocator)

    return Renderer_loadVulkanLoaderOdin(this, pathString)
}

VkRenderer_setDriverPreferenceOdin :: proc "c" (this: ^Renderer, driver: string) {
    if this == nil {
        return
    }

    context = this._ctx

    if this._buffers == nil {
        this._buffers = new(_RendererBuffers)
    }

    if len(driver) >= vk.MAX_DRIVER_NAME_SIZE {
        _log(this, .Warning, "Driver preference name (%v bytes) is longer than possible actual driver name (%v bytes); truncating driver preference name", len(driver), vk.MAX_DRIVER_NAME_SIZE)
    }

    mem.copy_non_overlapping(&this._driverPreference[0], raw_data(driver), min(len(driver), 4095))
    this._driverPreference[min(len(driver), 4095) + 1] = 0
}

VkRenderer_setDriverPreference :: proc "c" (this: ^Renderer, len: u32, driver: cstring) {
    if this == nil {
        return
    }

    context = this._ctx

    Renderer_setDriverPreferenceOdin(this, strings.string_from_ptr(transmute([^]u8)driver, int(len)))
}

VkRenderer_setAllocator :: proc "c" (this: ^Renderer, allocator: ^vk.AllocationCallbacks) {
    if this == nil {
        return
    }

    context = this._ctx

    this._allocator = allocator
}

VkRenderer_createFencePool :: proc "c" (this: ^Renderer, fencePool: ^FencePool) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't create a fence pool: renderer not fully initialized yet")
        return false
    }

    if fencePool == nil {
        _log(this, .Error, "Can't create a fence pool: invalid pointer to a FencePool")
        return false
    }

    fencePool^ = {
        destroy = FencePool_destroy,
        acquire = FencePool_acquire,
        release = FencePool_release,

        _renderer           = this,
        _fences             = make([dynamic]vk.Fence),
        _unusedFenceIndices = make([dynamic]u32),
    }

    return true
}

VkRenderer_createSemaphorePool :: proc "c" (this: ^Renderer, semaphorePool: ^SemaphorePool) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't create a semaphore pool: renderer not fully initialized yet")
        return false
    }

    if semaphorePool == nil {
        _log(this, .Error, "Can't create a semaphore pool: invalid pointer to a SemaphorePool")
        return false
    }

    semaphorePool^ = {
        destroy = SemaphorePool_destroy,
        acquire = SemaphorePool_acquire,
        release = SemaphorePool_release,

        _renderer               = this,
        _semaphores             = make([dynamic]vk.Semaphore),
        _unusedSemaphoreIndices = make([dynamic]u32),
    }

    return true
}

VkRenderer_createCommandPool :: proc "c" (this: ^Renderer, commandPool: ^CommandPool, fencePool: ^FencePool, queue: ^Queue) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't create a command pool: renderer not fully initialized yet")
        return false
    }

    if commandPool == nil {
        _log(this, .Error, "Can't create a command pool: invalid pointer to a CommandPool")
        return false
    }

    ci := vk.CommandPoolCreateInfo {
        sType = .COMMAND_POOL_CREATE_INFO,
        flags = { .RESET_COMMAND_BUFFER },
        queueFamilyIndex = queue.family,
    }

    cp: vk.CommandPool
    if this._device.createCommandPool(this._device.logical, &ci, this._allocator, &cp) != .SUCCESS {
        _log(this, .Error, "Failed to create Vulkan command pool")
        return false
    }

    commandPool^ = {
        destroy     = CommandPool_destroy,
        getQueue    = CommandPool_getQueue,
        acquire     = CommandPool_acquire,
        submit      = CommandPool_submit,
        release     = CommandPool_release,

        _renderer       = this,
        _queue          = queue,
        _fencePool      = fencePool,
        _commandPool    = cp,

        _commandBuffers             = make([dynamic]vk.CommandBuffer),
        _unusedCommandBufferIndices = make([dynamic]u32),
    }

    return true
}

VkRenderer_createResourcePool :: proc "c" (this: ^Renderer, resourcePool: ^ResourcePool, createInfo: ^vma.Pool_Create_Info) -> b32 {
    if this == nil {
        return false
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't create a resource pool: renderer not fully initialized yet")
        return false
    }

    if resourcePool == nil {
        _log(this, .Error, "Can't create a resource pool: invalid pointer to a ResourcePool")
        return false
    }

    if createInfo == nil {
        _log(this, .Error, "Can't create a resource pool: invalid pointer to a create info")
        return false
    }

    pool: vma.Pool
    if vma.create_pool(this._vma, createInfo^, &pool) != .SUCCESS {
        _log(this, .Error, "Failed to create resource pool")
        return false
    }

    resourcePool^ = {
        destroy         = ResourcePool_destroy,
        createBuffer    = ResourcePool_createBuffer,
        createImage     = ResourcePool_createImage,

        _renderer       = this,
        _pool           = pool,
    }
    
    return true
}

VkRenderer_getDefaultFencePool :: proc "c" (this: ^Renderer) -> ^FencePool {
    if this == nil {
        return nil
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't get default fence pool: renderer not fully initialized yet")
        return nil
    }

    return &this._defaultFencePool
}

VkRenderer_getDefaultSemaphorePool :: proc "c" (this: ^Renderer) -> ^SemaphorePool {
    if this == nil {
        return nil
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't get default semaphore pool: renderer not fully initialized yet")
        return nil
    }

    return &this._defaultSemaphorePool
}

VkRenderer_getDefaultCommandPool :: proc "c" (this: ^Renderer, queueType: QueueType) -> ^CommandPool {
    if this == nil {
        return nil
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't get default command pool: renderer not fully initialized yet")
        return nil
    }

    switch queueType {
        case .General:
            return &this._generalQueue.commandPool
        case .Present:
            return &this._presentQueue.commandPool
        case .Graphics:
            return &this._graphicsQueue.commandPool
        case .Transfer:
            return &this._transferQueue.commandPool
        case .Compute:
            return &this._computeQueue.commandPool
        case .Invalid:
            break
    }

    _log(this, .Error, "Can't get default command pool: invalid queue type provided")
    return nil
}

VkRenderer_getDefaultResourcePool :: proc "c" (this: ^Renderer) -> ^ResourcePool {
    if this == nil {
        return nil
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't get default resource pool: renderer not fully initialized yet")
        return nil
    }

    return &this._defaultResourcePool
}

VkRenderer_getAllocator :: proc "c" (this: ^Renderer) -> ^vk.AllocationCallbacks {
    if this == nil {
        return nil
    }

    context = this._ctx

    return this._allocator
}

VkRenderer_getInstance :: proc "c" (this: ^Renderer) -> ^Instance {
    if this == nil {
        return nil
    }

    context = this._ctx

    if this._instance.instance == nil {
        _log(this, .Error, "Can't get instance: renderer not fully initialized yet")
        return nil
    }

    return &this._instance
}

VkRenderer_getDevice :: proc "c" (this: ^Renderer) -> ^Device {
    if this == nil {
        return nil
    }

    context = this._ctx

    if this._device.logical == nil {
        _log(this, .Error, "Can't get device: renderer not fully initialized yet")
        return nil
    }

    return &this._device
}