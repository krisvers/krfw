package krfw_vulkan

import "base:runtime"
import "../../krfw"

@(export, link_name="krfwVkCreateRenderer")
createRenderer :: proc "c" () -> ^krfw.IRenderer {
    context = runtime.default_context()

    renderer := new(VkRenderer)
    renderer^ = {
        data = {
            _refCount   = 1,
            _ctx        = context,
            _library    = VULKAN_LOADER_DEFAULT_HANDLE,
        },

        ibase = {
            interface = {
                retain          = kom.ProcIBaseRetain(VkRenderer_IBase_retain),
                release         = kom.ProcIBaseRelease(VkRenderer_IBase_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkRenderer_IBase_queryInterface),
            },

            base = renderer,
        },

        irenderer = {
            interface = {
                retain          = kom.ProcIBaseRetain(VkRenderer_IRenderer_retain),
                release         = kom.ProcIBaseRelease(VkRenderer_IRenderer_release),
                queryInterface  = kom.ProcIBaseQueryInterface(VkRenderer_IRenderer_queryInterface),
                
                setDebugLogger  = krfw.ProcIRendererSetDebugLogger(VkRenderer_IRenderer_setDebugLogger),
                init            = krfw.ProcIRendererInit(VkRenderer_IRenderer_init),
                createWSI       = krfw.ProcIRendererCreateWSI(VkRenderer_IRenderer_createWSI),
                destroyWSI      = krfw.ProcIRendererDestroyWSI(VkRenderer_IRenderer_destroyWSI),
                executePasses   = krfw.ProcIRendererExecutePasses(VkRenderer_IRenderer_executePasses),
            },

            base = renderer,
        },

        ivkrenderer = {
            interface = {
                retain                  = kom.ProcIBaseRetain(VkRenderer_IVkRenderer_retain),
                release                 = kom.ProcIBaseRelease(VkRenderer_IVkRenderer_release),
                queryInterface          = kom.ProcIBaseQueryInterface(VkRenderer_IVkRenderer_queryInterface),
                
                setDebugLogger          = krfw.ProcIRendererSetDebugLogger(VkRenderer_IVkRenderer_setDebugLogger),
                init                    = krfw.ProcIRendererInit(VkRenderer_IVkRenderer_init),
                createWSI               = krfw.ProcIRendererCreateWSI(VkRenderer_IVkRenderer_createWSI),
                destroyWSI              = krfw.ProcIRendererDestroyWSI(VkRenderer_IVkRenderer_destroyWSI),
                executePasses           = krfw.ProcIRendererExecutePasses(VkRenderer_IVkRenderer_executePasses),
                
                loadVulkanLoaderOdin    = ProcIVkRendererLoadVulkanLoaderOdin(VkRenderer_IVkRenderer_loadVulkanLoaderOdin),
                loadVulkanLoader        = ProcIVkRendererLoadVulkanLoader(VkRenderer_IVkRenderer_loadVulkanLoader),
                loadVulkanLoaderUnicode = ProcIVkRendererLoadVulkanLoaderUnicode(VkRenderer_IVkRenderer_loadVulkanLoaderUnicode),
                setDriverPreferenceOdin = ProcIVkRendererSetDriverPreferenceOdin(VkRenderer_IVkRenderer_setDriverPreferenceOdin),
                setDriverPreference     = ProcIVkRendererSetDriverPreference(VkRenderer_IVkRenderer_setDriverPreference),
                setAllocator            = ProcIVkRendererSetAllocator(VkRenderer_IVkRenderer_setAllocator),
                createFencePool         = ProcIVkRendererCreateFencePool(VkRenderer_IVkRenderer_createFencePool),
                createSemaphorePool     = ProcIVkRendererCreateSemaphorePool(VkRenderer_IVkRenderer_createSemaphorePool),
                createCommandPool       = ProcIVkRendererCreateCommandPool(VkRenderer_IVkRenderer_createCommandPool),
                createResourcePool      = ProcIVkRendererCreateResourcePool(VkRenderer_IVkRenderer_createResourcePool),
                getDefaultFencePool     = ProcIVkRendererGetDefaultFencePool(VkRenderer_IVkRenderer_getDefaultFencePool),
                getDefaultSemaphorePool = ProcIVkRendererGetDefaultSemaphorePool(VkRenderer_IVkRenderer_getDefaultSemaphorePool),
                getDefaultCommandPool   = ProcIVkRendererGetDefaultCommandPool(VkRenderer_IVkRenderer_getDefaultCommandPool),
                getDefaultResourcePool  = ProcIVkRendererGetDefaultResourcePool(VkRenderer_IVkRenderer_getDefaultResourcePool),
                getAllocator            = ProcIVkRendererGetAllocator(VkRenderer_IVkRenderer_getAllocator),
                getInstance             = ProcIVkRendererGetInstance(VkRenderer_IVkRenderer_getInstance),
                getDevice               = ProcIVkRendererGetDevice(VkRenderer_IVkRenderer_getDevice),
            },

            base = renderer,
        },
    }

    return renderer
}