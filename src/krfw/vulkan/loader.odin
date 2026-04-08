package krfw_vulkan

import vk "vendor:vulkan"

GlobalFunctionPointers :: struct {
    getInstanceProcAddr:                    vk.ProcGetInstanceProcAddr,
    createInstance:                         vk.ProcCreateInstance,
    enumerateInstanceExtensionProperties:   vk.ProcEnumerateInstanceExtensionProperties,
    enumerateInstanceLayerProperties:       vk.ProcEnumerateInstanceLayerProperties,
    enumerateInstanceVersion:               vk.ProcEnumerateInstanceVersion,
}

loadVulkanGlobalFunctions :: proc "c" (getInstanceProcAddr: vk.ProcGetInstanceProcAddr, functions: ^GlobalFunctionPointers) -> b32 {
    if getInstanceProcAddr == nil || functions == nil {
        return false
    }

    functions.getInstanceProcAddr = getInstanceProcAddr
    functions.createInstance = vk.ProcCreateInstance(getInstanceProcAddr(nil, "vkCreateInstance"))
    if functions.createInstance == nil {
        return false
    }

    functions.enumerateInstanceExtensionProperties = vk.ProcEnumerateInstanceExtensionProperties(getInstanceProcAddr(nil, "vkEnumerateInstanceExtensionProperties"))
    if functions.enumerateInstanceExtensionProperties == nil {
        return false
    }

    functions.enumerateInstanceLayerProperties = vk.ProcEnumerateInstanceLayerProperties(getInstanceProcAddr(nil, "vkEnumerateInstanceLayerProperties"))
    if functions.enumerateInstanceLayerProperties == nil {
        return false
    }

    functions.enumerateInstanceVersion = vk.ProcEnumerateInstanceVersion(getInstanceProcAddr(nil, "vkEnumerateInstanceVersion"))
    if functions.enumerateInstanceVersion == nil {
        return false
    }

    return true
}

InstanceFunctionPointers :: struct {
    getInstanceProcAddr:                    vk.ProcGetInstanceProcAddr,
    getDeviceProcAddr:                      vk.ProcGetDeviceProcAddr,
    destroyInstance:                        vk.ProcDestroyInstance,
    enumeratePhysicalDevices:               vk.ProcEnumeratePhysicalDevices,
    enumerateDeviceExtensionProperties:     vk.ProcEnumerateDeviceExtensionProperties,
    enumerateDeviceLayerProperties:         vk.ProcEnumerateDeviceLayerProperties,
    getPhysicalDeviceFeatures:              vk.ProcGetPhysicalDeviceFeatures,
    getPhysicalDeviceFormatProperties:      vk.ProcGetPhysicalDeviceFormatProperties,
    getPhysicalDeviceImageFormatProperties: vk.ProcGetPhysicalDeviceImageFormatProperties,
    getPhysicalDeviceProperties:            vk.ProcGetPhysicalDeviceProperties,
    getPhysicalDeviceQueueFamilyProperties: vk.ProcGetPhysicalDeviceQueueFamilyProperties,
    getPhysicalDeviceMemoryProperties:      vk.ProcGetPhysicalDeviceMemoryProperties,
    createDevice:                           vk.ProcCreateDevice,
}

loadVulkanInstanceFunctions :: proc "c" (instance: vk.Instance, getInstanceProcAddr: vk.ProcGetInstanceProcAddr, functions: ^InstanceFunctionPointers) -> b32 {
    if instance == nil || getInstanceProcAddr == nil || functions == nil {
        return false
    }

    functions.getInstanceProcAddr = getInstanceProcAddr
    functions.getDeviceProcAddr = vk.ProcGetDeviceProcAddr(getInstanceProcAddr(instance, "vkGetDeviceProcAddr"))
    if functions.getDeviceProcAddr == nil {
        return false
    }

    functions.destroyInstance = vk.ProcDestroyInstance(getInstanceProcAddr(instance, "vkDestroyInstance"))
    if functions.destroyInstance == nil {
        return false
    }

    functions.enumeratePhysicalDevices = vk.ProcEnumeratePhysicalDevices(getInstanceProcAddr(instance, "vkEnumeratePhysicalDevices"))
    if functions.enumeratePhysicalDevices == nil {
        return false
    }

    functions.enumerateDeviceExtensionProperties = vk.ProcEnumerateDeviceExtensionProperties(getInstanceProcAddr(instance, "vkEnumerateDeviceExtensionProperties"))
    if functions.enumerateDeviceExtensionProperties == nil {
        return false
    }

    functions.enumerateDeviceLayerProperties = vk.ProcEnumerateDeviceLayerProperties(getInstanceProcAddr(instance, "vkEnumerateDeviceLayerProperties"))
    if functions.enumerateDeviceLayerProperties == nil {
        return false
    }

    functions.getPhysicalDeviceFeatures = vk.ProcGetPhysicalDeviceFeatures(getInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures"))
    if functions.getPhysicalDeviceFeatures == nil {
        return false
    }

    functions.getPhysicalDeviceFormatProperties = vk.ProcGetPhysicalDeviceFormatProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties"))
    if functions.getPhysicalDeviceFormatProperties == nil {
        return false
    }

    functions.getPhysicalDeviceImageFormatProperties = vk.ProcGetPhysicalDeviceImageFormatProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties"))
    if functions.getPhysicalDeviceImageFormatProperties == nil {
        return false
    }

    functions.getPhysicalDeviceProperties = vk.ProcGetPhysicalDeviceProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties"))
    if functions.getPhysicalDeviceProperties == nil {
        return false
    }

    functions.getPhysicalDeviceQueueFamilyProperties = vk.ProcGetPhysicalDeviceQueueFamilyProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties"))
    if functions.getPhysicalDeviceQueueFamilyProperties == nil {
        return false
    }

    functions.getPhysicalDeviceMemoryProperties = vk.ProcGetPhysicalDeviceMemoryProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties"))
    if functions.getPhysicalDeviceMemoryProperties == nil {
        return false
    }

    functions.createDevice = vk.ProcCreateDevice(getInstanceProcAddr(instance, "vkCreateDevice"))
    if functions.createDevice == nil {
        return false
    }
    
    return true
}

Instance11FunctionPointers :: struct {
    enumerateInstanceVersion:                       vk.ProcEnumerateInstanceVersion,
    enumeratePhysicalDeviceGroups:                  vk.ProcEnumeratePhysicalDeviceGroups,
    getPhysicalDeviceExternalBufferProperties:      vk.ProcGetPhysicalDeviceExternalBufferProperties,
    getPhysicalDeviceExternalFenceProperties:       vk.ProcGetPhysicalDeviceExternalFenceProperties,
    getPhysicalDeviceExternalSemaphoreProperties:   vk.ProcGetPhysicalDeviceExternalSemaphoreProperties,
    getPhysicalDeviceFeatures2:                     vk.ProcGetPhysicalDeviceFeatures2,
    getPhysicalDeviceFormatProperties2:             vk.ProcGetPhysicalDeviceFormatProperties2,
    getPhysicalDeviceImageFormatProperties2:        vk.ProcGetPhysicalDeviceImageFormatProperties2,
    getPhysicalDeviceMemoryProperties2:             vk.ProcGetPhysicalDeviceMemoryProperties2,
    getPhysicalDeviceProperties2:                   vk.ProcGetPhysicalDeviceProperties2,
    getPhysicalDeviceQueueFamilyProperties2:        vk.ProcGetPhysicalDeviceQueueFamilyProperties2,
    getPhysicalDeviceSparseImageFormatProperties2:  vk.ProcGetPhysicalDeviceSparseImageFormatProperties2,
}

loadVulkanInstance11Functions :: proc "c" (instance: vk.Instance, getInstanceProcAddr: vk.ProcGetInstanceProcAddr, functions: ^Instance11FunctionPointers) -> b32 {
    if instance == nil || getInstanceProcAddr == nil || functions == nil {
        return false
    }

    functions.enumerateInstanceVersion = vk.ProcEnumerateInstanceVersion(getInstanceProcAddr(instance, "vkEnumerateInstanceVersion"))
    if functions.enumerateInstanceVersion == nil {
        return false
    }

    functions.enumeratePhysicalDeviceGroups = vk.ProcEnumeratePhysicalDeviceGroups(getInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroups"))
    if functions.enumeratePhysicalDeviceGroups == nil {
        return false
    }

    functions.getPhysicalDeviceExternalBufferProperties = vk.ProcGetPhysicalDeviceExternalBufferProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferProperties"))
    if functions.getPhysicalDeviceExternalBufferProperties == nil {
        return false
    }

    functions.getPhysicalDeviceExternalFenceProperties = vk.ProcGetPhysicalDeviceExternalFenceProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFenceProperties"))
    if functions.getPhysicalDeviceExternalFenceProperties == nil {
        return false
    }

    functions.getPhysicalDeviceExternalSemaphoreProperties = vk.ProcGetPhysicalDeviceExternalSemaphoreProperties(getInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphoreProperties"))
    if functions.getPhysicalDeviceExternalSemaphoreProperties == nil {
        return false
    }

    functions.getPhysicalDeviceFeatures2 = vk.ProcGetPhysicalDeviceFeatures2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2"))
    if functions.getPhysicalDeviceFeatures2 == nil {
        return false
    }

    functions.getPhysicalDeviceFormatProperties2 = vk.ProcGetPhysicalDeviceFormatProperties2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2"))
    if functions.getPhysicalDeviceFormatProperties2 == nil {
        return false
    }

    functions.getPhysicalDeviceImageFormatProperties2 = vk.ProcGetPhysicalDeviceImageFormatProperties2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2"))
    if functions.getPhysicalDeviceImageFormatProperties2 == nil {
        return false
    }

    functions.getPhysicalDeviceMemoryProperties2 = vk.ProcGetPhysicalDeviceMemoryProperties2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2"))
    if functions.getPhysicalDeviceMemoryProperties2 == nil {
        return false
    }

    functions.getPhysicalDeviceProperties2 = vk.ProcGetPhysicalDeviceProperties2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2"))
    if functions.getPhysicalDeviceProperties2 == nil {
        return false
    }

    functions.getPhysicalDeviceQueueFamilyProperties2 = vk.ProcGetPhysicalDeviceQueueFamilyProperties2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2"))
    if functions.getPhysicalDeviceQueueFamilyProperties2 == nil {
        return false
    }

    functions.getPhysicalDeviceSparseImageFormatProperties2 = vk.ProcGetPhysicalDeviceSparseImageFormatProperties2(getInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2"))
    if functions.getPhysicalDeviceSparseImageFormatProperties2 == nil {
        return false
    }

    return true
}

InstanceSurfaceKHRFunctionPointers :: struct {
    destroySurface:                         vk.ProcDestroySurfaceKHR,
    getPhysicalDeviceSurfaceSupport:        vk.ProcGetPhysicalDeviceSurfaceSupportKHR,
    getPhysicalDeviceSurfaceCapabilities:   vk.ProcGetPhysicalDeviceSurfaceCapabilitiesKHR,
    getPhysicalDeviceSurfaceFormats:        vk.ProcGetPhysicalDeviceSurfaceFormatsKHR,
    getPhysicalDeviceSurfacePresentModes:   vk.ProcGetPhysicalDeviceSurfacePresentModesKHR,
}

loadVulkanInstanceSurfaceKHRFunctions :: proc "c" (instance: vk.Instance, getInstanceProcAddr: vk.ProcGetInstanceProcAddr, functions: ^InstanceSurfaceKHRFunctionPointers) -> b32 {
    if instance == nil || getInstanceProcAddr == nil || functions == nil {
        return false
    }

    functions.destroySurface = vk.ProcDestroySurfaceKHR(getInstanceProcAddr(instance, "vkDestroySurfaceKHR"))
    if functions.destroySurface == nil {
        return false
    }

    functions.getPhysicalDeviceSurfaceSupport = vk.ProcGetPhysicalDeviceSurfaceSupportKHR(getInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR"))
    if functions.getPhysicalDeviceSurfaceSupport == nil {
        return false
    }

    functions.getPhysicalDeviceSurfaceCapabilities = vk.ProcGetPhysicalDeviceSurfaceCapabilitiesKHR(getInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"))
    if functions.getPhysicalDeviceSurfaceCapabilities == nil {
        return false
    }

    functions.getPhysicalDeviceSurfaceFormats = vk.ProcGetPhysicalDeviceSurfaceFormatsKHR(getInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR"))
    if functions.getPhysicalDeviceSurfaceFormats == nil {
        return false
    }

    functions.getPhysicalDeviceSurfacePresentModes = vk.ProcGetPhysicalDeviceSurfacePresentModesKHR(getInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR"))
    if functions.getPhysicalDeviceSurfacePresentModes == nil {
        return false
    }

    return true
}

InstanceDebugUtilsEXTFunctionPointers :: struct {
    setDebugUtilsObjectName:    vk.ProcSetDebugUtilsObjectNameEXT,
    setDebugUtilsObjectTag:     vk.ProcSetDebugUtilsObjectTagEXT,
    queueBeginDebugUtilsLabel:  vk.ProcQueueBeginDebugUtilsLabelEXT,
    queueEndDebugUtilsLabel:    vk.ProcQueueEndDebugUtilsLabelEXT,
    queueInsertDebugUtilsLabel: vk.ProcQueueInsertDebugUtilsLabelEXT,
    cmdBeginDebugUtilsLabel:    vk.ProcCmdBeginDebugUtilsLabelEXT,
    cmdEndDebugUtilsLabel:      vk.ProcCmdEndDebugUtilsLabelEXT,
    cmdInsertDebugUtilsLabel:   vk.ProcCmdInsertDebugUtilsLabelEXT,
    createDebugUtilsMessenger:  vk.ProcCreateDebugUtilsMessengerEXT,
    destroyDebugUtilsMessenger: vk.ProcDestroyDebugUtilsMessengerEXT,
    submitDebugUtilsMessage:    vk.ProcSubmitDebugUtilsMessageEXT,
}

loadVulkanInstanceDebugUtilsEXTFunctions :: proc "c" (instance: vk.Instance, getInstanceProcAddr: vk.ProcGetInstanceProcAddr, functions: ^InstanceDebugUtilsEXTFunctionPointers) -> b32 {
    if instance == nil || getInstanceProcAddr == nil || functions == nil {
        return false
    }

    functions.setDebugUtilsObjectName = vk.ProcSetDebugUtilsObjectNameEXT(getInstanceProcAddr(instance, "vkSetDebugUtilsObjectNameEXT"))
    if functions.setDebugUtilsObjectName == nil {
        return false
    }

    functions.setDebugUtilsObjectTag = vk.ProcSetDebugUtilsObjectTagEXT(getInstanceProcAddr(instance, "vkSetDebugUtilsObjectTagEXT"))
    if functions.setDebugUtilsObjectTag == nil {
        return false
    }

    functions.queueBeginDebugUtilsLabel = vk.ProcQueueBeginDebugUtilsLabelEXT(getInstanceProcAddr(instance, "vkQueueBeginDebugUtilsLabelEXT"))
    if functions.queueBeginDebugUtilsLabel == nil {
        return false
    }

    functions.queueEndDebugUtilsLabel = vk.ProcQueueEndDebugUtilsLabelEXT(getInstanceProcAddr(instance, "vkQueueEndDebugUtilsLabelEXT"))
    if functions.queueEndDebugUtilsLabel == nil {
        return false
    }

    functions.queueInsertDebugUtilsLabel = vk.ProcQueueInsertDebugUtilsLabelEXT(getInstanceProcAddr(instance, "vkQueueInsertDebugUtilsLabelEXT"))
    if functions.queueInsertDebugUtilsLabel == nil {
        return false
    }

    functions.cmdBeginDebugUtilsLabel = vk.ProcCmdBeginDebugUtilsLabelEXT(getInstanceProcAddr(instance, "vkCmdBeginDebugUtilsLabelEXT"))
    if functions.cmdBeginDebugUtilsLabel == nil {
        return false
    }

    functions.cmdEndDebugUtilsLabel = vk.ProcCmdEndDebugUtilsLabelEXT(getInstanceProcAddr(instance, "vkCmdEndDebugUtilsLabelEXT"))
    if functions.cmdEndDebugUtilsLabel == nil {
        return false
    }

    functions.cmdInsertDebugUtilsLabel = vk.ProcCmdInsertDebugUtilsLabelEXT(getInstanceProcAddr(instance, "vkCmdInsertDebugUtilsLabelEXT"))
    if functions.cmdInsertDebugUtilsLabel == nil {
        return false
    }

    functions.createDebugUtilsMessenger = vk.ProcCreateDebugUtilsMessengerEXT(getInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT"))
    if functions.createDebugUtilsMessenger == nil {
        return false
    }

    functions.destroyDebugUtilsMessenger = vk.ProcDestroyDebugUtilsMessengerEXT(getInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT"))
    if functions.destroyDebugUtilsMessenger == nil {
        return false
    }

    functions.submitDebugUtilsMessage = vk.ProcSubmitDebugUtilsMessageEXT(getInstanceProcAddr(instance, "vkSubmitDebugUtilsMessageEXT"))
    if functions.submitDebugUtilsMessage == nil {
        return false
    }

    return true
}

DeviceFunctionPointers :: struct {
    destroyDevice:                      vk.ProcDestroyDevice,
    getDeviceQueue:                     vk.ProcGetDeviceQueue,
    queueSubmit:                        vk.ProcQueueSubmit,
    queueWaitIdle:                      vk.ProcQueueWaitIdle,
    deviceWaitIdle:                     vk.ProcDeviceWaitIdle,
    allocateMemory:                     vk.ProcAllocateMemory,
    freeMemory:                         vk.ProcFreeMemory,
    mapMemory:                          vk.ProcMapMemory,
    unmapMemory:                        vk.ProcUnmapMemory,
    flushMappedMemoryRanges:            vk.ProcFlushMappedMemoryRanges,
    invalidateMappedMemoryRanges:       vk.ProcInvalidateMappedMemoryRanges,
    getDeviceMemoryCommitment:          vk.ProcGetDeviceMemoryCommitment,
    bindBufferMemory:                   vk.ProcBindBufferMemory,
    bindImageMemory:                    vk.ProcBindImageMemory,
    getBufferMemoryRequirements:        vk.ProcGetBufferMemoryRequirements,
    getImageMemoryRequirements:         vk.ProcGetImageMemoryRequirements,
    getImageSparseMemoryRequirements:   vk.ProcGetImageSparseMemoryRequirements,
    queueBindSparse:                    vk.ProcQueueBindSparse,
    createFence:                        vk.ProcCreateFence,
    destroyFence:                       vk.ProcDestroyFence,
    resetFences:                        vk.ProcResetFences,
    getFenceStatus:                     vk.ProcGetFenceStatus,
    waitForFences:                      vk.ProcWaitForFences,
    createSemaphore:                    vk.ProcCreateSemaphore,
    destroySemaphore:                   vk.ProcDestroySemaphore,
    createQueryPool:                    vk.ProcCreateQueryPool,
    destroyQueryPool:                   vk.ProcDestroyQueryPool,
    getQueryPoolResults:                vk.ProcGetQueryPoolResults,
    createBuffer:                       vk.ProcCreateBuffer,
    destroyBuffer:                      vk.ProcDestroyBuffer,
    createImage:                        vk.ProcCreateImage,
    destroyImage:                       vk.ProcDestroyImage,
    getImageSubresourceLayout:          vk.ProcGetImageSubresourceLayout,
    createImageView:                    vk.ProcCreateImageView,
    destroyImageView:                   vk.ProcDestroyImageView,
    createCommandPool:                  vk.ProcCreateCommandPool,
    destroyCommandPool:                 vk.ProcDestroyCommandPool,
    resetCommandPool:                   vk.ProcResetCommandPool,
    allocateCommandBuffers:             vk.ProcAllocateCommandBuffers,
    freeCommandBuffers:                 vk.ProcFreeCommandBuffers,
    beginCommandBuffer:                 vk.ProcBeginCommandBuffer,
    endCommandBuffer:                   vk.ProcEndCommandBuffer,
    resetCommandBuffer:                 vk.ProcResetCommandBuffer,
    cmdCopyBuffer:                      vk.ProcCmdCopyBuffer,
    cmdCopyImage:                       vk.ProcCmdCopyImage,
    cmdCopyBufferToImage:               vk.ProcCmdCopyBufferToImage,
    cmdCopyImageToBuffer:               vk.ProcCmdCopyImageToBuffer,
    cmdUpdateBuffer:                    vk.ProcCmdUpdateBuffer,
    cmdFillBuffer:                      vk.ProcCmdFillBuffer,
    cmdPipelineBarrier:                 vk.ProcCmdPipelineBarrier,
    cmdBeginQuery:                      vk.ProcCmdBeginQuery,
    cmdEndQuery:                        vk.ProcCmdEndQuery,
    cmdResetQueryPool:                  vk.ProcCmdResetQueryPool,
    cmdWriteTimestamp:                  vk.ProcCmdWriteTimestamp,
    cmdCopyQueryPoolResults:            vk.ProcCmdCopyQueryPoolResults,
    cmdExecuteCommands:                 vk.ProcCmdExecuteCommands,
    createEvent:                        vk.ProcCreateEvent,
    destroyEvent:                       vk.ProcDestroyEvent,
    getEventStatus:                     vk.ProcGetEventStatus,
    setEvent:                           vk.ProcSetEvent,
    resetEvent:                         vk.ProcResetEvent,
    createBufferView:                   vk.ProcCreateBufferView,
    destroyBufferView:                  vk.ProcDestroyBufferView,
    createShaderModule:                 vk.ProcCreateShaderModule,
    destroyShaderModule:                vk.ProcDestroyShaderModule,
    createPipelineCache:                vk.ProcCreatePipelineCache,
    destroyPipelineCache:               vk.ProcDestroyPipelineCache,
    getPipelineCacheData:               vk.ProcGetPipelineCacheData,
    mergePipelineCaches:                vk.ProcMergePipelineCaches,
    createComputePipelines:             vk.ProcCreateComputePipelines,
    destroyPipeline:                    vk.ProcDestroyPipeline,
    createPipelineLayout:               vk.ProcCreatePipelineLayout,
    destroyPipelineLayout:              vk.ProcDestroyPipelineLayout,
    createSampler:                      vk.ProcCreateSampler,
    destroySampler:                     vk.ProcDestroySampler,
    createDescriptorSetLayout:          vk.ProcCreateDescriptorSetLayout,
    destroyDescriptorSetLayout:         vk.ProcDestroyDescriptorSetLayout,
    createDescriptorPool:               vk.ProcCreateDescriptorPool,
    destroyDescriptorPool:              vk.ProcDestroyDescriptorPool,
    resetDescriptorPool:                vk.ProcResetDescriptorPool,
    allocateDescriptorSets:             vk.ProcAllocateDescriptorSets,
    freeDescriptorSets:                 vk.ProcFreeDescriptorSets,
    updateDescriptorSets:               vk.ProcUpdateDescriptorSets,
    cmdBindPipeline:                    vk.ProcCmdBindPipeline,
    cmdBindDescriptorSets:              vk.ProcCmdBindDescriptorSets,
    cmdClearColorImage:                 vk.ProcCmdClearColorImage,
    cmdDispatch:                        vk.ProcCmdDispatch,
    cmdDispatchIndirect:                vk.ProcCmdDispatchIndirect,
    cmdSetEvent:                        vk.ProcCmdSetEvent,
    cmdResetEvent:                      vk.ProcCmdResetEvent,
    cmdWaitEvents:                      vk.ProcCmdWaitEvents,
    cmdPushConstants:                   vk.ProcCmdPushConstants,
    createGraphicsPipelines:            vk.ProcCreateGraphicsPipelines,
    createFramebuffer:                  vk.ProcCreateFramebuffer,
    destroyFramebuffer:                 vk.ProcDestroyFramebuffer,
    createRenderPass:                   vk.ProcCreateRenderPass,
    destroyRenderPass:                  vk.ProcDestroyRenderPass,
    getRenderAreaGranularity:           vk.ProcGetRenderAreaGranularity,
    cmdSetViewport:                     vk.ProcCmdSetViewport,
    cmdSetScissor:                      vk.ProcCmdSetScissor,
    cmdSetLineWidth:                    vk.ProcCmdSetLineWidth,
    cmdSetDepthBias:                    vk.ProcCmdSetDepthBias,
    cmdSetBlendConstants:               vk.ProcCmdSetBlendConstants,
    cmdSetDepthBounds:                  vk.ProcCmdSetDepthBounds,
    cmdSetStencilCompareMask:           vk.ProcCmdSetStencilCompareMask,
    cmdSetStencilWriteMask:             vk.ProcCmdSetStencilWriteMask,
    cmdSetStencilReference:             vk.ProcCmdSetStencilReference,
    cmdBindIndexBuffer:                 vk.ProcCmdBindIndexBuffer,
    cmdBindVertexBuffers:               vk.ProcCmdBindVertexBuffers,
    cmdDraw:                            vk.ProcCmdDraw,
    cmdDrawIndexed:                     vk.ProcCmdDrawIndexed,
    cmdDrawIndirect:                    vk.ProcCmdDrawIndirect,
    cmdDrawIndexedIndirect:             vk.ProcCmdDrawIndexedIndirect,
    cmdBlitImage:                       vk.ProcCmdBlitImage,
    cmdClearDepthStencilImage:          vk.ProcCmdClearDepthStencilImage,
    cmdClearAttachments:                vk.ProcCmdClearAttachments,
    cmdResolveImage:                    vk.ProcCmdResolveImage,
    cmdBeginRenderPass:                 vk.ProcCmdBeginRenderPass,
    cmdNextSubpass:                     vk.ProcCmdNextSubpass,
    cmdEndRenderPass:                   vk.ProcCmdEndRenderPass,
}

loadVulkanDeviceFunctions :: proc "c" (device: vk.Device, getDeviceProcAddr: vk.ProcGetDeviceProcAddr, functions: ^DeviceFunctionPointers) -> b32 {
    if device == nil || getDeviceProcAddr == nil || functions == nil {
        return false
    }

    functions.destroyDevice = vk.ProcDestroyDevice(getDeviceProcAddr(device, "vkDestroyDevice"))
    if functions.destroyDevice == nil {
        return false
    }

    functions.getDeviceQueue = vk.ProcGetDeviceQueue(getDeviceProcAddr(device, "vkGetDeviceQueue"))
    if functions.getDeviceQueue == nil {
        return false
    }

    functions.queueSubmit = vk.ProcQueueSubmit(getDeviceProcAddr(device, "vkQueueSubmit"))
    if functions.queueSubmit == nil {
        return false
    }

    functions.queueWaitIdle = vk.ProcQueueWaitIdle(getDeviceProcAddr(device, "vkQueueWaitIdle"))
    if functions.queueWaitIdle == nil {
        return false
    }

    functions.deviceWaitIdle = vk.ProcDeviceWaitIdle(getDeviceProcAddr(device, "vkDeviceWaitIdle"))
    if functions.deviceWaitIdle == nil {
        return false
    }

    functions.allocateMemory = vk.ProcAllocateMemory(getDeviceProcAddr(device, "vkAllocateMemory"))
    if functions.allocateMemory == nil {
        return false
    }

    functions.freeMemory = vk.ProcFreeMemory(getDeviceProcAddr(device, "vkFreeMemory"))
    if functions.freeMemory == nil {
        return false
    }

    functions.mapMemory = vk.ProcMapMemory(getDeviceProcAddr(device, "vkMapMemory"))
    if functions.mapMemory == nil {
        return false
    }

    functions.unmapMemory = vk.ProcUnmapMemory(getDeviceProcAddr(device, "vkUnmapMemory"))
    if functions.unmapMemory == nil {
        return false
    }

    functions.flushMappedMemoryRanges = vk.ProcFlushMappedMemoryRanges(getDeviceProcAddr(device, "vkFlushMappedMemoryRanges"))
    if functions.flushMappedMemoryRanges == nil {
        return false
    }

    functions.invalidateMappedMemoryRanges = vk.ProcInvalidateMappedMemoryRanges(getDeviceProcAddr(device, "vkInvalidateMappedMemoryRanges"))
    if functions.invalidateMappedMemoryRanges == nil {
        return false
    }

    functions.getDeviceMemoryCommitment = vk.ProcGetDeviceMemoryCommitment(getDeviceProcAddr(device, "vkGetDeviceMemoryCommitment"))
    if functions.getDeviceMemoryCommitment == nil {
        return false
    }

    functions.bindBufferMemory = vk.ProcBindBufferMemory(getDeviceProcAddr(device, "vkBindBufferMemory"))
    if functions.bindBufferMemory == nil {
        return false
    }

    functions.bindImageMemory = vk.ProcBindImageMemory(getDeviceProcAddr(device, "vkBindImageMemory"))
    if functions.bindImageMemory == nil {
        return false
    }

    functions.getBufferMemoryRequirements = vk.ProcGetBufferMemoryRequirements(getDeviceProcAddr(device, "vkGetBufferMemoryRequirements"))
    if functions.getBufferMemoryRequirements == nil {
        return false
    }

    functions.getImageMemoryRequirements = vk.ProcGetImageMemoryRequirements(getDeviceProcAddr(device, "vkGetImageMemoryRequirements"))
    if functions.getImageMemoryRequirements == nil {
        return false
    }

    functions.getImageSparseMemoryRequirements = vk.ProcGetImageSparseMemoryRequirements(getDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements"))
    if functions.getImageSparseMemoryRequirements == nil {
        return false
    }

    functions.queueBindSparse = vk.ProcQueueBindSparse(getDeviceProcAddr(device, "vkQueueBindSparse"))
    if functions.queueBindSparse == nil {
        return false
    }

    functions.createFence = vk.ProcCreateFence(getDeviceProcAddr(device, "vkCreateFence"))
    if functions.createFence == nil {
        return false
    }

    functions.destroyFence = vk.ProcDestroyFence(getDeviceProcAddr(device, "vkDestroyFence"))
    if functions.destroyFence == nil {
        return false
    }

    functions.resetFences = vk.ProcResetFences(getDeviceProcAddr(device, "vkResetFences"))
    if functions.resetFences == nil {
        return false
    }

    functions.getFenceStatus = vk.ProcGetFenceStatus(getDeviceProcAddr(device, "vkGetFenceStatus"))
    if functions.getFenceStatus == nil {
        return false
    }

    functions.waitForFences = vk.ProcWaitForFences(getDeviceProcAddr(device, "vkWaitForFences"))
    if functions.waitForFences == nil {
        return false
    }

    functions.createSemaphore = vk.ProcCreateSemaphore(getDeviceProcAddr(device, "vkCreateSemaphore"))
    if functions.createSemaphore == nil {
        return false
    }

    functions.destroySemaphore = vk.ProcDestroySemaphore(getDeviceProcAddr(device, "vkDestroySemaphore"))
    if functions.destroySemaphore == nil {
        return false
    }

    functions.createQueryPool = vk.ProcCreateQueryPool(getDeviceProcAddr(device, "vkCreateQueryPool"))
    if functions.createQueryPool == nil {
        return false
    }

    functions.destroyQueryPool = vk.ProcDestroyQueryPool(getDeviceProcAddr(device, "vkDestroyQueryPool"))
    if functions.destroyQueryPool == nil {
        return false
    }

    functions.getQueryPoolResults = vk.ProcGetQueryPoolResults(getDeviceProcAddr(device, "vkGetQueryPoolResults"))
    if functions.getQueryPoolResults == nil {
        return false
    }

    functions.createBuffer = vk.ProcCreateBuffer(getDeviceProcAddr(device, "vkCreateBuffer"))
    if functions.createBuffer == nil {
        return false
    }

    functions.destroyBuffer = vk.ProcDestroyBuffer(getDeviceProcAddr(device, "vkDestroyBuffer"))
    if functions.destroyBuffer == nil {
        return false
    }

    functions.createImage = vk.ProcCreateImage(getDeviceProcAddr(device, "vkCreateImage"))
    if functions.createImage == nil {
        return false
    }

    functions.destroyImage = vk.ProcDestroyImage(getDeviceProcAddr(device, "vkDestroyImage"))
    if functions.destroyImage == nil {
        return false
    }

    functions.getImageSubresourceLayout = vk.ProcGetImageSubresourceLayout(getDeviceProcAddr(device, "vkGetImageSubresourceLayout"))
    if functions.getImageSubresourceLayout == nil {
        return false
    }

    functions.createImageView = vk.ProcCreateImageView(getDeviceProcAddr(device, "vkCreateImageView"))
    if functions.createImageView == nil {
        return false
    }

    functions.destroyImageView = vk.ProcDestroyImageView(getDeviceProcAddr(device, "vkDestroyImageView"))
    if functions.destroyImageView == nil {
        return false
    }

    functions.createCommandPool = vk.ProcCreateCommandPool(getDeviceProcAddr(device, "vkCreateCommandPool"))
    if functions.createCommandPool == nil {
        return false
    }

    functions.destroyCommandPool = vk.ProcDestroyCommandPool(getDeviceProcAddr(device, "vkDestroyCommandPool"))
    if functions.destroyCommandPool == nil {
        return false
    }

    functions.resetCommandPool = vk.ProcResetCommandPool(getDeviceProcAddr(device, "vkResetCommandPool"))
    if functions.resetCommandPool == nil {
        return false
    }

    functions.allocateCommandBuffers = vk.ProcAllocateCommandBuffers(getDeviceProcAddr(device, "vkAllocateCommandBuffers"))
    if functions.allocateCommandBuffers == nil {
        return false
    }

    functions.freeCommandBuffers = vk.ProcFreeCommandBuffers(getDeviceProcAddr(device, "vkFreeCommandBuffers"))
    if functions.freeCommandBuffers == nil {
        return false
    }

    functions.beginCommandBuffer = vk.ProcBeginCommandBuffer(getDeviceProcAddr(device, "vkBeginCommandBuffer"))
    if functions.beginCommandBuffer == nil {
        return false
    }

    functions.endCommandBuffer = vk.ProcEndCommandBuffer(getDeviceProcAddr(device, "vkEndCommandBuffer"))
    if functions.endCommandBuffer == nil {
        return false
    }

    functions.resetCommandBuffer = vk.ProcResetCommandBuffer(getDeviceProcAddr(device, "vkResetCommandBuffer"))
    if functions.resetCommandBuffer == nil {
        return false
    }

    functions.cmdCopyBuffer = vk.ProcCmdCopyBuffer(getDeviceProcAddr(device, "vkCmdCopyBuffer"))
    if functions.cmdCopyBuffer == nil {
        return false
    }

    functions.cmdCopyImage = vk.ProcCmdCopyImage(getDeviceProcAddr(device, "vkCmdCopyImage"))
    if functions.cmdCopyImage == nil {
        return false
    }

    functions.cmdCopyBufferToImage = vk.ProcCmdCopyBufferToImage(getDeviceProcAddr(device, "vkCmdCopyBufferToImage"))
    if functions.cmdCopyBufferToImage == nil {
        return false
    }

    functions.cmdCopyImageToBuffer = vk.ProcCmdCopyImageToBuffer(getDeviceProcAddr(device, "vkCmdCopyImageToBuffer"))
    if functions.cmdCopyImageToBuffer == nil {
        return false
    }

    functions.cmdUpdateBuffer = vk.ProcCmdUpdateBuffer(getDeviceProcAddr(device, "vkCmdUpdateBuffer"))
    if functions.cmdUpdateBuffer == nil {
        return false
    }

    functions.cmdFillBuffer = vk.ProcCmdFillBuffer(getDeviceProcAddr(device, "vkCmdFillBuffer"))
    if functions.cmdFillBuffer == nil {
        return false
    }

    functions.cmdPipelineBarrier = vk.ProcCmdPipelineBarrier(getDeviceProcAddr(device, "vkCmdPipelineBarrier"))
    if functions.cmdPipelineBarrier == nil {
        return false
    }

    functions.cmdBeginQuery = vk.ProcCmdBeginQuery(getDeviceProcAddr(device, "vkCmdBeginQuery"))
    if functions.cmdBeginQuery == nil {
        return false
    }

    functions.cmdEndQuery = vk.ProcCmdEndQuery(getDeviceProcAddr(device, "vkCmdEndQuery"))
    if functions.cmdEndQuery == nil {
        return false
    }

    functions.cmdResetQueryPool = vk.ProcCmdResetQueryPool(getDeviceProcAddr(device, "vkCmdResetQueryPool"))
    if functions.cmdResetQueryPool == nil {
        return false
    }

    functions.cmdWriteTimestamp = vk.ProcCmdWriteTimestamp(getDeviceProcAddr(device, "vkCmdWriteTimestamp"))
    if functions.cmdWriteTimestamp == nil {
        return false
    }

    functions.cmdCopyQueryPoolResults = vk.ProcCmdCopyQueryPoolResults(getDeviceProcAddr(device, "vkCmdCopyQueryPoolResults"))
    if functions.cmdCopyQueryPoolResults == nil {
        return false
    }

    functions.cmdExecuteCommands = vk.ProcCmdExecuteCommands(getDeviceProcAddr(device, "vkCmdExecuteCommands"))
    if functions.cmdExecuteCommands == nil {
        return false
    }

    functions.createEvent = vk.ProcCreateEvent(getDeviceProcAddr(device, "vkCreateEvent"))
    if functions.createEvent == nil {
        return false
    }

    functions.destroyEvent = vk.ProcDestroyEvent(getDeviceProcAddr(device, "vkDestroyEvent"))
    if functions.destroyEvent == nil {
        return false
    }

    functions.getEventStatus = vk.ProcGetEventStatus(getDeviceProcAddr(device, "vkGetEventStatus"))
    if functions.getEventStatus == nil {
        return false
    }

    functions.setEvent = vk.ProcSetEvent(getDeviceProcAddr(device, "vkSetEvent"))
    if functions.setEvent == nil {
        return false
    }

    functions.resetEvent = vk.ProcResetEvent(getDeviceProcAddr(device, "vkResetEvent"))
    if functions.resetEvent == nil {
        return false
    }

    functions.createBufferView = vk.ProcCreateBufferView(getDeviceProcAddr(device, "vkCreateBufferView"))
    if functions.createBufferView == nil {
        return false
    }

    functions.destroyBufferView = vk.ProcDestroyBufferView(getDeviceProcAddr(device, "vkDestroyBufferView"))
    if functions.destroyBufferView == nil {
        return false
    }

    functions.createShaderModule = vk.ProcCreateShaderModule(getDeviceProcAddr(device, "vkCreateShaderModule"))
    if functions.createShaderModule == nil {
        return false
    }

    functions.destroyShaderModule = vk.ProcDestroyShaderModule(getDeviceProcAddr(device, "vkDestroyShaderModule"))
    if functions.destroyShaderModule == nil {
        return false
    }

    functions.createPipelineCache = vk.ProcCreatePipelineCache(getDeviceProcAddr(device, "vkCreatePipelineCache"))
    if functions.createPipelineCache == nil {
        return false
    }

    functions.destroyPipelineCache = vk.ProcDestroyPipelineCache(getDeviceProcAddr(device, "vkDestroyPipelineCache"))
    if functions.destroyPipelineCache == nil {
        return false
    }

    functions.getPipelineCacheData = vk.ProcGetPipelineCacheData(getDeviceProcAddr(device, "vkGetPipelineCacheData"))
    if functions.getPipelineCacheData == nil {
        return false
    }

    functions.mergePipelineCaches = vk.ProcMergePipelineCaches(getDeviceProcAddr(device, "vkMergePipelineCaches"))
    if functions.mergePipelineCaches == nil {
        return false
    }

    functions.createComputePipelines = vk.ProcCreateComputePipelines(getDeviceProcAddr(device, "vkCreateComputePipelines"))
    if functions.createComputePipelines == nil {
        return false
    }

    functions.destroyPipeline = vk.ProcDestroyPipeline(getDeviceProcAddr(device, "vkDestroyPipeline"))
    if functions.destroyPipeline == nil {
        return false
    }

    functions.createPipelineLayout = vk.ProcCreatePipelineLayout(getDeviceProcAddr(device, "vkCreatePipelineLayout"))
    if functions.createPipelineLayout == nil {
        return false
    }

    functions.destroyPipelineLayout = vk.ProcDestroyPipelineLayout(getDeviceProcAddr(device, "vkDestroyPipelineLayout"))
    if functions.destroyPipelineLayout == nil {
        return false
    }

    functions.createSampler = vk.ProcCreateSampler(getDeviceProcAddr(device, "vkCreateSampler"))
    if functions.createSampler == nil {
        return false
    }

    functions.destroySampler = vk.ProcDestroySampler(getDeviceProcAddr(device, "vkDestroySampler"))
    if functions.destroySampler == nil {
        return false
    }

    functions.createDescriptorSetLayout = vk.ProcCreateDescriptorSetLayout(getDeviceProcAddr(device, "vkCreateDescriptorSetLayout"))
    if functions.createDescriptorSetLayout == nil {
        return false
    }

    functions.destroyDescriptorSetLayout = vk.ProcDestroyDescriptorSetLayout(getDeviceProcAddr(device, "vkDestroyDescriptorSetLayout"))
    if functions.destroyDescriptorSetLayout == nil {
        return false
    }

    functions.createDescriptorPool = vk.ProcCreateDescriptorPool(getDeviceProcAddr(device, "vkCreateDescriptorPool"))
    if functions.createDescriptorPool == nil {
        return false
    }

    functions.destroyDescriptorPool = vk.ProcDestroyDescriptorPool(getDeviceProcAddr(device, "vkDestroyDescriptorPool"))
    if functions.destroyDescriptorPool == nil {
        return false
    }

    functions.resetDescriptorPool = vk.ProcResetDescriptorPool(getDeviceProcAddr(device, "vkResetDescriptorPool"))
    if functions.resetDescriptorPool == nil {
        return false
    }

    functions.allocateDescriptorSets = vk.ProcAllocateDescriptorSets(getDeviceProcAddr(device, "vkAllocateDescriptorSets"))
    if functions.allocateDescriptorSets == nil {
        return false
    }

    functions.freeDescriptorSets = vk.ProcFreeDescriptorSets(getDeviceProcAddr(device, "vkFreeDescriptorSets"))
    if functions.freeDescriptorSets == nil {
        return false
    }

    functions.updateDescriptorSets = vk.ProcUpdateDescriptorSets(getDeviceProcAddr(device, "vkUpdateDescriptorSets"))
    if functions.updateDescriptorSets == nil {
        return false
    }

    functions.cmdBindPipeline = vk.ProcCmdBindPipeline(getDeviceProcAddr(device, "vkCmdBindPipeline"))
    if functions.cmdBindPipeline == nil {
        return false
    }

    functions.cmdBindDescriptorSets = vk.ProcCmdBindDescriptorSets(getDeviceProcAddr(device, "vkCmdBindDescriptorSets"))
    if functions.cmdBindDescriptorSets == nil {
        return false
    }

    functions.cmdClearColorImage = vk.ProcCmdClearColorImage(getDeviceProcAddr(device, "vkCmdClearColorImage"))
    if functions.cmdClearColorImage == nil {
        return false
    }

    functions.cmdDispatch = vk.ProcCmdDispatch(getDeviceProcAddr(device, "vkCmdDispatch"))
    if functions.cmdDispatch == nil {
        return false
    }

    functions.cmdDispatchIndirect = vk.ProcCmdDispatchIndirect(getDeviceProcAddr(device, "vkCmdDispatchIndirect"))
    if functions.cmdDispatchIndirect == nil {
        return false
    }

    functions.cmdSetEvent = vk.ProcCmdSetEvent(getDeviceProcAddr(device, "vkCmdSetEvent"))
    if functions.cmdSetEvent == nil {
        return false
    }

    functions.cmdResetEvent = vk.ProcCmdResetEvent(getDeviceProcAddr(device, "vkCmdResetEvent"))
    if functions.cmdResetEvent == nil {
        return false
    }

    functions.cmdWaitEvents = vk.ProcCmdWaitEvents(getDeviceProcAddr(device, "vkCmdWaitEvents"))
    if functions.cmdWaitEvents == nil {
        return false
    }

    functions.cmdPushConstants = vk.ProcCmdPushConstants(getDeviceProcAddr(device, "vkCmdPushConstants"))
    if functions.cmdPushConstants == nil {
        return false
    }

    functions.createGraphicsPipelines = vk.ProcCreateGraphicsPipelines(getDeviceProcAddr(device, "vkCreateGraphicsPipelines"))
    if functions.createGraphicsPipelines == nil {
        return false
    }

    functions.createFramebuffer = vk.ProcCreateFramebuffer(getDeviceProcAddr(device, "vkCreateFramebuffer"))
    if functions.createFramebuffer == nil {
        return false
    }

    functions.destroyFramebuffer = vk.ProcDestroyFramebuffer(getDeviceProcAddr(device, "vkDestroyFramebuffer"))
    if functions.destroyFramebuffer == nil {
        return false
    }

    functions.createRenderPass = vk.ProcCreateRenderPass(getDeviceProcAddr(device, "vkCreateRenderPass"))
    if functions.createRenderPass == nil {
        return false
    }

    functions.destroyRenderPass = vk.ProcDestroyRenderPass(getDeviceProcAddr(device, "vkDestroyRenderPass"))
    if functions.destroyRenderPass == nil {
        return false
    }

    functions.getRenderAreaGranularity = vk.ProcGetRenderAreaGranularity(getDeviceProcAddr(device, "vkGetRenderAreaGranularity"))
    if functions.getRenderAreaGranularity == nil {
        return false
    }

    functions.cmdSetViewport = vk.ProcCmdSetViewport(getDeviceProcAddr(device, "vkCmdSetViewport"))
    if functions.cmdSetViewport == nil {
        return false
    }

    functions.cmdSetScissor = vk.ProcCmdSetScissor(getDeviceProcAddr(device, "vkCmdSetScissor"))
    if functions.cmdSetScissor == nil {
        return false
    }

    functions.cmdSetLineWidth = vk.ProcCmdSetLineWidth(getDeviceProcAddr(device, "vkCmdSetLineWidth"))
    if functions.cmdSetLineWidth == nil {
        return false
    }

    functions.cmdSetDepthBias = vk.ProcCmdSetDepthBias(getDeviceProcAddr(device, "vkCmdSetDepthBias"))
    if functions.cmdSetDepthBias == nil {
        return false
    }

    functions.cmdSetBlendConstants = vk.ProcCmdSetBlendConstants(getDeviceProcAddr(device, "vkCmdSetBlendConstants"))
    if functions.cmdSetBlendConstants == nil {
        return false
    }

    functions.cmdSetDepthBounds = vk.ProcCmdSetDepthBounds(getDeviceProcAddr(device, "vkCmdSetDepthBounds"))
    if functions.cmdSetDepthBounds == nil {
        return false
    }

    functions.cmdSetStencilCompareMask = vk.ProcCmdSetStencilCompareMask(getDeviceProcAddr(device, "vkCmdSetStencilCompareMask"))
    if functions.cmdSetStencilCompareMask == nil {
        return false
    }

    functions.cmdSetStencilWriteMask = vk.ProcCmdSetStencilWriteMask(getDeviceProcAddr(device, "vkCmdSetStencilWriteMask"))
    if functions.cmdSetStencilWriteMask == nil {
        return false
    }

    functions.cmdSetStencilReference = vk.ProcCmdSetStencilReference(getDeviceProcAddr(device, "vkCmdSetStencilReference"))
    if functions.cmdSetStencilReference == nil {
        return false
    }

    functions.cmdBindIndexBuffer = vk.ProcCmdBindIndexBuffer(getDeviceProcAddr(device, "vkCmdBindIndexBuffer"))
    if functions.cmdBindIndexBuffer == nil {
        return false
    }

    functions.cmdBindVertexBuffers = vk.ProcCmdBindVertexBuffers(getDeviceProcAddr(device, "vkCmdBindVertexBuffers"))
    if functions.cmdBindVertexBuffers == nil {
        return false
    }

    functions.cmdDraw = vk.ProcCmdDraw(getDeviceProcAddr(device, "vkCmdDraw"))
    if functions.cmdDraw == nil {
        return false
    }

    functions.cmdDrawIndexed = vk.ProcCmdDrawIndexed(getDeviceProcAddr(device, "vkCmdDrawIndexed"))
    if functions.cmdDrawIndexed == nil {
        return false
    }

    functions.cmdDrawIndirect = vk.ProcCmdDrawIndirect(getDeviceProcAddr(device, "vkCmdDrawIndirect"))
    if functions.cmdDrawIndirect == nil {
        return false
    }

    functions.cmdDrawIndexedIndirect = vk.ProcCmdDrawIndexedIndirect(getDeviceProcAddr(device, "vkCmdDrawIndexedIndirect"))
    if functions.cmdDrawIndexedIndirect == nil {
        return false
    }

    functions.cmdBlitImage = vk.ProcCmdBlitImage(getDeviceProcAddr(device, "vkCmdBlitImage"))
    if functions.cmdBlitImage == nil {
        return false
    }

    functions.cmdClearDepthStencilImage = vk.ProcCmdClearDepthStencilImage(getDeviceProcAddr(device, "vkCmdClearDepthStencilImage"))
    if functions.cmdClearDepthStencilImage == nil {
        return false
    }

    functions.cmdClearAttachments = vk.ProcCmdClearAttachments(getDeviceProcAddr(device, "vkCmdClearAttachments"))
    if functions.cmdClearAttachments == nil {
        return false
    }

    functions.cmdResolveImage = vk.ProcCmdResolveImage(getDeviceProcAddr(device, "vkCmdResolveImage"))
    if functions.cmdResolveImage == nil {
        return false
    }

    functions.cmdBeginRenderPass = vk.ProcCmdBeginRenderPass(getDeviceProcAddr(device, "vkCmdBeginRenderPass"))
    if functions.cmdBeginRenderPass == nil {
        return false
    }

    functions.cmdNextSubpass = vk.ProcCmdNextSubpass(getDeviceProcAddr(device, "vkCmdNextSubpass"))
    if functions.cmdNextSubpass == nil {
        return false
    }

    functions.cmdEndRenderPass = vk.ProcCmdEndRenderPass(getDeviceProcAddr(device, "vkCmdEndRenderPass"))
    if functions.cmdEndRenderPass == nil {
        return false
    }

    return true
}

Device11FunctionPointers :: struct {
    bindBufferMemory2:                              vk.ProcBindBufferMemory2,
    bindImageMemory2:                               vk.ProcBindImageMemory2,
    cmdDispatchBase:                                vk.ProcCmdDispatchBase,
    cmdSetDeviceMask:                               vk.ProcCmdSetDeviceMask,
    createDescriptorUpdateTemplate:                 vk.ProcCreateDescriptorUpdateTemplate,
    createSamplerYcbcrConversion:                   vk.ProcCreateSamplerYcbcrConversion,
    destroyDescriptorUpdateTemplate:                vk.ProcDestroyDescriptorUpdateTemplate,
    destroySamplerYcbcrConversion:                  vk.ProcDestroySamplerYcbcrConversion,
    getBufferMemoryRequirements2:                   vk.ProcGetBufferMemoryRequirements2,
    getDescriptorSetLayoutSupport:                  vk.ProcGetDescriptorSetLayoutSupport,
    getDeviceGroupPeerMemoryFeatures:               vk.ProcGetDeviceGroupPeerMemoryFeatures,
    getDeviceQueue2:                                vk.ProcGetDeviceQueue2,
    getImageMemoryRequirements2:                    vk.ProcGetImageMemoryRequirements2,
    getImageSparseMemoryRequirements2:              vk.ProcGetImageSparseMemoryRequirements2,
    trimCommandPool:                                vk.ProcTrimCommandPool,
    updateDescriptorSetWithTemplate:                vk.ProcUpdateDescriptorSetWithTemplate,
}

loadVulkanDevice11Functions :: proc "c" (device: vk.Device, getDeviceProcAddr: vk.ProcGetDeviceProcAddr, functions: ^Device11FunctionPointers) -> b32 {
    if device == nil || getDeviceProcAddr == nil || functions == nil {
        return false
    }

    functions.bindBufferMemory2 = vk.ProcBindBufferMemory2(getDeviceProcAddr(device, "vkBindBufferMemory2"))
    if functions.bindBufferMemory2 == nil {
        return false
    }

    functions.bindImageMemory2 = vk.ProcBindImageMemory2(getDeviceProcAddr(device, "vkBindImageMemory2"))
    if functions.bindImageMemory2 == nil {
        return false
    }

    functions.cmdDispatchBase = vk.ProcCmdDispatchBase(getDeviceProcAddr(device, "vkCmdDispatchBase"))
    if functions.cmdDispatchBase == nil {
        return false
    }

    functions.cmdSetDeviceMask = vk.ProcCmdSetDeviceMask(getDeviceProcAddr(device, "vkCmdSetDeviceMask"))
    if functions.cmdSetDeviceMask == nil {
        return false
    }

    functions.createDescriptorUpdateTemplate = vk.ProcCreateDescriptorUpdateTemplate(getDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplate"))
    if functions.createDescriptorUpdateTemplate == nil {
        return false
    }

    functions.createSamplerYcbcrConversion = vk.ProcCreateSamplerYcbcrConversion(getDeviceProcAddr(device, "vkCreateSamplerYcbcrConversion"))
    if functions.createSamplerYcbcrConversion == nil {
        return false
    }

    functions.destroyDescriptorUpdateTemplate = vk.ProcDestroyDescriptorUpdateTemplate(getDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplate"))
    if functions.destroyDescriptorUpdateTemplate == nil {
        return false
    }

    functions.destroySamplerYcbcrConversion = vk.ProcDestroySamplerYcbcrConversion(getDeviceProcAddr(device, "vkDestroySamplerYcbcrConversion"))
    if functions.destroySamplerYcbcrConversion == nil {
        return false
    }

    functions.getBufferMemoryRequirements2 = vk.ProcGetBufferMemoryRequirements2(getDeviceProcAddr(device, "vkGetBufferMemoryRequirements2"))
    if functions.getBufferMemoryRequirements2 == nil {
        return false
    }

    functions.getDescriptorSetLayoutSupport = vk.ProcGetDescriptorSetLayoutSupport(getDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupport"))
    if functions.getDescriptorSetLayoutSupport == nil {
        return false
    }

    functions.getDeviceGroupPeerMemoryFeatures = vk.ProcGetDeviceGroupPeerMemoryFeatures(getDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeatures"))
    if functions.getDeviceGroupPeerMemoryFeatures == nil {
        return false
    }

    functions.getDeviceQueue2 = vk.ProcGetDeviceQueue2(getDeviceProcAddr(device, "vkGetDeviceQueue2"))
    if functions.getDeviceQueue2 == nil {
        return false
    }

    functions.getImageMemoryRequirements2 = vk.ProcGetImageMemoryRequirements2(getDeviceProcAddr(device, "vkGetImageMemoryRequirements2"))
    if functions.getImageMemoryRequirements2 == nil {
        return false
    }

    functions.getImageSparseMemoryRequirements2 = vk.ProcGetImageSparseMemoryRequirements2(getDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2"))
    if functions.getImageSparseMemoryRequirements2 == nil {
        return false
    }

    functions.trimCommandPool = vk.ProcTrimCommandPool(getDeviceProcAddr(device, "vkTrimCommandPool"))
    if functions.trimCommandPool == nil {
        return false
    }

    functions.updateDescriptorSetWithTemplate = vk.ProcUpdateDescriptorSetWithTemplate(getDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplate"))
    if functions.updateDescriptorSetWithTemplate == nil {
        return false
    }

    return true
}

Device12FunctionPointers :: struct {
    cmdBeginRenderPass2:                    vk.ProcCmdBeginRenderPass2,
    cmdDrawIndexedIndirectCount:            vk.ProcCmdDrawIndexedIndirectCount,
    cmdDrawIndirectCount:                   vk.ProcCmdDrawIndirectCount,
    cmdEndRenderPass2:                      vk.ProcCmdEndRenderPass2,
    cmdNextSubpass2:                        vk.ProcCmdNextSubpass2,
    createRenderPass2:                      vk.ProcCreateRenderPass2,
    getBufferDeviceAddress:                 vk.ProcGetBufferDeviceAddress,
    getBufferOpaqueCaptureAddress:          vk.ProcGetBufferOpaqueCaptureAddress,
    getDeviceMemoryOpaqueCaptureAddress:    vk.ProcGetDeviceMemoryOpaqueCaptureAddress,
    getSemaphoreCounterValue:               vk.ProcGetSemaphoreCounterValue,
    resetQueryPool:                         vk.ProcResetQueryPool,
    signalSemaphore:                        vk.ProcSignalSemaphore,
    waitSemaphores:                         vk.ProcWaitSemaphores,
}

loadVulkanDevice12Functions :: proc "c" (device: vk.Device, getDeviceProcAddr: vk.ProcGetDeviceProcAddr, functions: ^Device12FunctionPointers) -> b32 {
    if device == nil || getDeviceProcAddr == nil || functions == nil {
        return false
    }

    functions.cmdBeginRenderPass2 = vk.ProcCmdBeginRenderPass2(getDeviceProcAddr(device, "vkCmdBeginRenderPass2"))
    if functions.cmdBeginRenderPass2 == nil {
        return false
    }

    functions.cmdDrawIndexedIndirectCount = vk.ProcCmdDrawIndexedIndirectCount(getDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCount"))
    if functions.cmdDrawIndexedIndirectCount == nil {
        return false
    }

    functions.cmdDrawIndirectCount = vk.ProcCmdDrawIndirectCount(getDeviceProcAddr(device, "vkCmdDrawIndirectCount"))
    if functions.cmdDrawIndirectCount == nil {
        return false
    }

    functions.cmdEndRenderPass2 = vk.ProcCmdEndRenderPass2(getDeviceProcAddr(device, "vkCmdEndRenderPass2"))
    if functions.cmdEndRenderPass2 == nil {
        return false
    }

    functions.cmdNextSubpass2 = vk.ProcCmdNextSubpass2(getDeviceProcAddr(device, "vkCmdNextSubpass2"))
    if functions.cmdNextSubpass2 == nil {
        return false
    }

    functions.createRenderPass2 = vk.ProcCreateRenderPass2(getDeviceProcAddr(device, "vkCreateRenderPass2"))
    if functions.createRenderPass2 == nil {
        return false
    }

    functions.getBufferDeviceAddress = vk.ProcGetBufferDeviceAddress(getDeviceProcAddr(device, "vkGetBufferDeviceAddress"))
    if functions.getBufferDeviceAddress == nil {
        return false
    }

    functions.getBufferOpaqueCaptureAddress = vk.ProcGetBufferOpaqueCaptureAddress(getDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddress"))
    if functions.getBufferOpaqueCaptureAddress == nil {
        return false
    }

    functions.getDeviceMemoryOpaqueCaptureAddress = vk.ProcGetDeviceMemoryOpaqueCaptureAddress(getDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddress"))
    if functions.getDeviceMemoryOpaqueCaptureAddress == nil {
        return false
    }

    functions.getSemaphoreCounterValue = vk.ProcGetSemaphoreCounterValue(getDeviceProcAddr(device, "vkGetSemaphoreCounterValue"))
    if functions.getSemaphoreCounterValue == nil {
        return false
    }

    functions.resetQueryPool = vk.ProcResetQueryPool(getDeviceProcAddr(device, "vkResetQueryPool"))
    if functions.resetQueryPool == nil {
        return false
    }

    functions.signalSemaphore = vk.ProcSignalSemaphore(getDeviceProcAddr(device, "vkSignalSemaphore"))
    if functions.signalSemaphore == nil {
        return false
    }

    functions.waitSemaphores = vk.ProcWaitSemaphores(getDeviceProcAddr(device, "vkWaitSemaphores"))
    if functions.waitSemaphores == nil {
        return false
    }

    return true
}

DeviceSwapchainKHRFunctionPointers :: struct {
    createSwapchain:    vk.ProcCreateSwapchainKHR,
    destroySwapchain:   vk.ProcDestroySwapchainKHR,
    getSwapchainImages: vk.ProcGetSwapchainImagesKHR,
    acquireNextImage:   vk.ProcAcquireNextImageKHR,
    queuePresent:       vk.ProcQueuePresentKHR,
}

loadVulkanDeviceSwapchainKHRFunctions :: proc "c" (device: vk.Device, getDeviceProcAddr: vk.ProcGetDeviceProcAddr, functions: ^DeviceSwapchainKHRFunctionPointers) -> b32 {
    if device == nil || getDeviceProcAddr == nil || functions == nil {
        return false
    }

    functions.createSwapchain = vk.ProcCreateSwapchainKHR(getDeviceProcAddr(device, "vkCreateSwapchainKHR"))
    if functions.createSwapchain == nil {
        return false
    }

    functions.destroySwapchain = vk.ProcDestroySwapchainKHR(getDeviceProcAddr(device, "vkDestroySwapchainKHR"))
    if functions.destroySwapchain == nil {
        return false
    }

    functions.getSwapchainImages = vk.ProcGetSwapchainImagesKHR(getDeviceProcAddr(device, "vkGetSwapchainImagesKHR"))
    if functions.getSwapchainImages == nil {
        return false
    }

    functions.acquireNextImage = vk.ProcAcquireNextImageKHR(getDeviceProcAddr(device, "vkAcquireNextImageKHR"))
    if functions.acquireNextImage == nil {
        return false
    }

    functions.queuePresent = vk.ProcQueuePresentKHR(getDeviceProcAddr(device, "vkQueuePresentKHR"))
    if functions.queuePresent == nil {
        return false
    }

    return true
}

DeviceDynamicRenderingKHRFunctionPointers :: struct {
    cmdBeginRendering:  vk.ProcCmdBeginRendering,
    cmdEndRendering:    vk.ProcCmdEndRendering,
}

loadVulkanDeviceDynamicRenderingKHRFunctions :: proc "c" (device: vk.Device, getDeviceProcAddr: vk.ProcGetDeviceProcAddr, functions: ^DeviceDynamicRenderingKHRFunctionPointers) -> b32 {
    if device == nil || getDeviceProcAddr == nil || functions == nil {
        return false
    }

    functions.cmdBeginRendering = vk.ProcCmdBeginRendering(getDeviceProcAddr(device, "vkCmdBeginRenderingKHR"))
    if functions.cmdBeginRendering == nil {
        return false
    }

    functions.cmdEndRendering = vk.ProcCmdEndRendering(getDeviceProcAddr(device, "vkCmdEndRenderingKHR"))
    if functions.cmdEndRendering == nil {
        return false
    }

    return true
}