#ifndef KRFW_VULKAN_H
#define KRFW_VULKAN_H

#include "vulkan/vulkan_core.h"
#ifdef __cplusplus
#warning  "Use krfw_vulkan.hpp for C++ instead"

extern "C" {
#endif

#include "../krfw.h"

#include <vulkan/vulkan.h>
#include <stdint.h>

typedef uint32_t KRFW_Odin_rune;

typedef struct KRFW_Vulkan_GlobalFunctionPointers {
    PFN_vkGetInstanceProcAddr                    getInstanceProcAddr;
    PFN_vkCreateInstance                         createInstance;
    PFN_vkEnumerateInstanceExtensionProperties   enumerateInstanceExtensionProperties;
    PFN_vkEnumerateInstanceLayerProperties       enumerateInstanceLayerProperties;
    PFN_vkEnumerateInstanceVersion               enumerateInstanceVersion;
} KRFW_Vulkan_GlobalFunctionPointers;

typedef struct KRFW_Vulkan_InstanceFunctionPointers {
    PFN_vkGetInstanceProcAddr                    getInstanceProcAddr;
    PFN_vkGetDeviceProcAddr                      getDeviceProcAddr;
    PFN_vkDestroyInstance                        destroyInstance;
    PFN_vkEnumeratePhysicalDevices               enumeratePhysicalDevices;
    PFN_vkEnumerateDeviceExtensionProperties     enumerateDeviceExtensionProperties;
    PFN_vkEnumerateDeviceLayerProperties         enumerateDeviceLayerProperties;
    PFN_vkGetPhysicalDeviceFeatures              getPhysicalDeviceFeatures;
    PFN_vkGetPhysicalDeviceFormatProperties      getPhysicalDeviceFormatProperties;
    PFN_vkGetPhysicalDeviceImageFormatProperties getPhysicalDeviceImageFormatProperties;
    PFN_vkGetPhysicalDeviceProperties            getPhysicalDeviceProperties;
    PFN_vkGetPhysicalDeviceQueueFamilyProperties getPhysicalDeviceQueueFamilyProperties;
    PFN_vkGetPhysicalDeviceMemoryProperties      getPhysicalDeviceMemoryProperties;
    PFN_vkCreateDevice                           createDevice;
} KRFW_Vulkan_InstanceFunctionPointers;

typedef struct KRFW_Vulkan_Instance11FunctionPointers {
    PFN_vkEnumerateInstanceVersion                       enumerateInstanceVersion;
    PFN_vkEnumeratePhysicalDeviceGroups                  enumeratePhysicalDeviceGroups;
    PFN_vkGetPhysicalDeviceExternalBufferProperties      getPhysicalDeviceExternalBufferProperties;
    PFN_vkGetPhysicalDeviceExternalFenceProperties       getPhysicalDeviceExternalFenceProperties;
    PFN_vkGetPhysicalDeviceExternalSemaphoreProperties   getPhysicalDeviceExternalSemaphoreProperties;
    PFN_vkGetPhysicalDeviceFeatures2                     getPhysicalDeviceFeatures2;
    PFN_vkGetPhysicalDeviceFormatProperties2             getPhysicalDeviceFormatProperties2;
    PFN_vkGetPhysicalDeviceImageFormatProperties2        getPhysicalDeviceImageFormatProperties2;
    PFN_vkGetPhysicalDeviceMemoryProperties2             getPhysicalDeviceMemoryProperties2;
    PFN_vkGetPhysicalDeviceProperties2                   getPhysicalDeviceProperties2;
    PFN_vkGetPhysicalDeviceQueueFamilyProperties2        getPhysicalDeviceQueueFamilyProperties2;
    PFN_vkGetPhysicalDeviceSparseImageFormatProperties2  getPhysicalDeviceSparseImageFormatProperties2;
} KRFW_Vulkan_Instance11FunctionPointers;

typedef struct KRFW_Vulkan_InstanceSurfaceKHRFunctionPointers {
    PFN_vkDestroySurfaceKHR                          destroySurface;
    PFN_vkGetPhysicalDeviceSurfaceSupportKHR         getPhysicalDeviceSurfaceSupport;
    PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR    getPhysicalDeviceSurfaceCapabilities;
    PFN_vkGetPhysicalDeviceSurfaceFormatsKHR         getPhysicalDeviceSurfaceFormats;
    PFN_vkGetPhysicalDeviceSurfacePresentModesKHR    getPhysicalDeviceSurfacePresentModes;
} KRFW_Vulkan_InstanceSurfaceKHRFunctionPointers;

typedef struct KRFW_Vulkan_InstanceDebugUtilsEXTFunctionPointers {
    PFN_vkSetDebugUtilsObjectNameEXT    setDebugUtilsObjectName;
    PFN_vkSetDebugUtilsObjectTagEXT     setDebugUtilsObjectTag;
    PFN_vkQueueBeginDebugUtilsLabelEXT  queueBeginDebugUtilsLabel;
    PFN_vkQueueEndDebugUtilsLabelEXT    queueEndDebugUtilsLabel;
    PFN_vkQueueInsertDebugUtilsLabelEXT queueInsertDebugUtilsLabel;
    PFN_vkCmdBeginDebugUtilsLabelEXT    cmdBeginDebugUtilsLabel;
    PFN_vkCmdEndDebugUtilsLabelEXT      cmdEndDebugUtilsLabel;
    PFN_vkCmdInsertDebugUtilsLabelEXT   cmdInsertDebugUtilsLabel;
    PFN_vkCreateDebugUtilsMessengerEXT  createDebugUtilsMessenger;
    PFN_vkDestroyDebugUtilsMessengerEXT destroyDebugUtilsMessenger;
    PFN_vkSubmitDebugUtilsMessageEXT    submitDebugUtilsMessage;
} KRFW_Vulkan_InstanceDebugUtilsEXTFunctionPointers;

typedef struct KRFW_Vulkan_InstanceKHRFunctions {
    KRFW_Vulkan_InstanceSurfaceKHRFunctionPointers surface;
} KRFW_Vulkan_InstanceKHRFunctions;

typedef struct KRFW_Vulkan_InstanceEXTFunctions {
    KRFW_Vulkan_InstanceDebugUtilsEXTFunctionPointers debugUtils;
} KRFW_Vulkan_InstanceEXTFunctions;

typedef struct KRFW_Vulkan_InstanceFunctions {
    /* Vulkan 1.0 */
    PFN_vkGetInstanceProcAddr                    getInstanceProcAddr;
    PFN_vkGetDeviceProcAddr                      getDeviceProcAddr;
    PFN_vkDestroyInstance                        destroyInstance;
    PFN_vkEnumeratePhysicalDevices               enumeratePhysicalDevices;
    PFN_vkEnumerateDeviceExtensionProperties     enumerateDeviceExtensionProperties;
    PFN_vkEnumerateDeviceLayerProperties         enumerateDeviceLayerProperties;
    PFN_vkGetPhysicalDeviceFeatures              getPhysicalDeviceFeatures;
    PFN_vkGetPhysicalDeviceFormatProperties      getPhysicalDeviceFormatProperties;
    PFN_vkGetPhysicalDeviceImageFormatProperties getPhysicalDeviceImageFormatProperties;
    PFN_vkGetPhysicalDeviceProperties            getPhysicalDeviceProperties;
    PFN_vkGetPhysicalDeviceQueueFamilyProperties getPhysicalDeviceQueueFamilyProperties;
    PFN_vkGetPhysicalDeviceMemoryProperties      getPhysicalDeviceMemoryProperties;
    PFN_vkCreateDevice                           createDevice;

    /* Vulkan 1.1*/
    PFN_vkEnumerateInstanceVersion                       enumerateInstanceVersion;
    PFN_vkEnumeratePhysicalDeviceGroups                  enumeratePhysicalDeviceGroups;
    PFN_vkGetPhysicalDeviceExternalBufferProperties      getPhysicalDeviceExternalBufferProperties;
    PFN_vkGetPhysicalDeviceExternalFenceProperties       getPhysicalDeviceExternalFenceProperties;
    PFN_vkGetPhysicalDeviceExternalSemaphoreProperties   getPhysicalDeviceExternalSemaphoreProperties;
    PFN_vkGetPhysicalDeviceFeatures2                     getPhysicalDeviceFeatures2;
    PFN_vkGetPhysicalDeviceFormatProperties2             getPhysicalDeviceFormatProperties2;
    PFN_vkGetPhysicalDeviceImageFormatProperties2        getPhysicalDeviceImageFormatProperties2;
    PFN_vkGetPhysicalDeviceMemoryProperties2             getPhysicalDeviceMemoryProperties2;
    PFN_vkGetPhysicalDeviceProperties2                   getPhysicalDeviceProperties2;
    PFN_vkGetPhysicalDeviceQueueFamilyProperties2        getPhysicalDeviceQueueFamilyProperties2;
    PFN_vkGetPhysicalDeviceSparseImageFormatProperties2  getPhysicalDeviceSparseImageFormatProperties2;

    /* extensions */
    KRFW_Vulkan_InstanceKHRFunctions khr;
    KRFW_Vulkan_InstanceEXTFunctions ext;
} KRFW_Vulkan_InstanceFunctions;

typedef struct KRFW_Vulkan_Instance {
    VkInstance instance;
    KRFW_Vulkan_InstanceFunctions functions;
} KRFW_Vulkan_Instance;

typedef struct KRFW_Vulkan_DeviceFunctionPointers {
    PFN_vkDestroyDevice                      destroyDevice;
    PFN_vkGetDeviceQueue                     getDeviceQueue;
    PFN_vkQueueSubmit                        queueSubmit;
    PFN_vkQueueWaitIdle                      queueWaitIdle;
    PFN_vkDeviceWaitIdle                     deviceWaitIdle;
    PFN_vkAllocateMemory                     allocateMemory;
    PFN_vkFreeMemory                         freeMemory;
    PFN_vkMapMemory                          mapMemory;
    PFN_vkUnmapMemory                        unmapMemory;
    PFN_vkFlushMappedMemoryRanges            flushMappedMemoryRanges;
    PFN_vkInvalidateMappedMemoryRanges       invalidateMappedMemoryRanges;
    PFN_vkGetDeviceMemoryCommitment          getDeviceMemoryCommitment;
    PFN_vkBindBufferMemory                   bindBufferMemory;
    PFN_vkBindImageMemory                    bindImageMemory;
    PFN_vkGetBufferMemoryRequirements        getBufferMemoryRequirements;
    PFN_vkGetImageMemoryRequirements         getImageMemoryRequirements;
    PFN_vkGetImageSparseMemoryRequirements   getImageSparseMemoryRequirements;
    PFN_vkQueueBindSparse                    queueBindSparse;
    PFN_vkCreateFence                        createFence;
    PFN_vkDestroyFence                       destroyFence;
    PFN_vkResetFences                        resetFences;
    PFN_vkGetFenceStatus                     getFenceStatus;
    PFN_vkWaitForFences                      waitForFences;
    PFN_vkCreateSemaphore                    createSemaphore;
    PFN_vkDestroySemaphore                   destroySemaphore;
    PFN_vkCreateQueryPool                    createQueryPool;
    PFN_vkDestroyQueryPool                   destroyQueryPool;
    PFN_vkGetQueryPoolResults                getQueryPoolResults;
    PFN_vkCreateBuffer                       createBuffer;
    PFN_vkDestroyBuffer                      destroyBuffer;
    PFN_vkCreateImage                        createImage;
    PFN_vkDestroyImage                       destroyImage;
    PFN_vkGetImageSubresourceLayout          getImageSubresourceLayout;
    PFN_vkCreateImageView                    createImageView;
    PFN_vkDestroyImageView                   destroyImageView;
    PFN_vkCreateCommandPool                  createCommandPool;
    PFN_vkDestroyCommandPool                 destroyCommandPool;
    PFN_vkResetCommandPool                   resetCommandPool;
    PFN_vkAllocateCommandBuffers             allocateCommandBuffers;
    PFN_vkFreeCommandBuffers                 freeCommandBuffers;
    PFN_vkBeginCommandBuffer                 beginCommandBuffer;
    PFN_vkEndCommandBuffer                   endCommandBuffer;
    PFN_vkResetCommandBuffer                 resetCommandBuffer;
    PFN_vkCmdCopyBuffer                      cmdCopyBuffer;
    PFN_vkCmdCopyImage                       cmdCopyImage;
    PFN_vkCmdCopyBufferToImage               cmdCopyBufferToImage;
    PFN_vkCmdCopyImageToBuffer               cmdCopyImageToBuffer;
    PFN_vkCmdUpdateBuffer                    cmdUpdateBuffer;
    PFN_vkCmdFillBuffer                      cmdFillBuffer;
    PFN_vkCmdPipelineBarrier                 cmdPipelineBarrier;
    PFN_vkCmdBeginQuery                      cmdBeginQuery;
    PFN_vkCmdEndQuery                        cmdEndQuery;
    PFN_vkCmdResetQueryPool                  cmdResetQueryPool;
    PFN_vkCmdWriteTimestamp                  cmdWriteTimestamp;
    PFN_vkCmdCopyQueryPoolResults            cmdCopyQueryPoolResults;
    PFN_vkCmdExecuteCommands                 cmdExecuteCommands;
    PFN_vkCreateEvent                        createEvent;
    PFN_vkDestroyEvent                       destroyEvent;
    PFN_vkGetEventStatus                     getEventStatus;
    PFN_vkSetEvent                           setEvent;
    PFN_vkResetEvent                         resetEvent;
    PFN_vkCreateBufferView                   createBufferView;
    PFN_vkDestroyBufferView                  destroyBufferView;
    PFN_vkCreateShaderModule                 createShaderModule;
    PFN_vkDestroyShaderModule                destroyShaderModule;
    PFN_vkCreatePipelineCache                createPipelineCache;
    PFN_vkDestroyPipelineCache               destroyPipelineCache;
    PFN_vkGetPipelineCacheData               getPipelineCacheData;
    PFN_vkMergePipelineCaches                mergePipelineCaches;
    PFN_vkCreateComputePipelines             createComputePipelines;
    PFN_vkDestroyPipeline                    destroyPipeline;
    PFN_vkCreatePipelineLayout               createPipelineLayout;
    PFN_vkDestroyPipelineLayout              destroyPipelineLayout;
    PFN_vkCreateSampler                      createSampler;
    PFN_vkDestroySampler                     destroySampler;
    PFN_vkCreateDescriptorSetLayout          createDescriptorSetLayout;
    PFN_vkDestroyDescriptorSetLayout         destroyDescriptorSetLayout;
    PFN_vkCreateDescriptorPool               createDescriptorPool;
    PFN_vkDestroyDescriptorPool              destroyDescriptorPool;
    PFN_vkResetDescriptorPool                resetDescriptorPool;
    PFN_vkAllocateDescriptorSets             allocateDescriptorSets;
    PFN_vkFreeDescriptorSets                 freeDescriptorSets;
    PFN_vkUpdateDescriptorSets               updateDescriptorSets;
    PFN_vkCmdBindPipeline                    cmdBindPipeline;
    PFN_vkCmdBindDescriptorSets              cmdBindDescriptorSets;
    PFN_vkCmdClearColorImage                 cmdClearColorImage;
    PFN_vkCmdDispatch                        cmdDispatch;
    PFN_vkCmdDispatchIndirect                cmdDispatchIndirect;
    PFN_vkCmdSetEvent                        cmdSetEvent;
    PFN_vkCmdResetEvent                      cmdResetEvent;
    PFN_vkCmdWaitEvents                      cmdWaitEvents;
    PFN_vkCmdPushConstants                   cmdPushConstants;
    PFN_vkCreateGraphicsPipelines            createGraphicsPipelines;
    PFN_vkCreateFramebuffer                  createFramebuffer;
    PFN_vkDestroyFramebuffer                 destroyFramebuffer;
    PFN_vkCreateRenderPass                   createRenderPass;
    PFN_vkDestroyRenderPass                  destroyRenderPass;
    PFN_vkGetRenderAreaGranularity           getRenderAreaGranularity;
    PFN_vkCmdSetViewport                     cmdSetViewport;
    PFN_vkCmdSetScissor                      cmdSetScissor;
    PFN_vkCmdSetLineWidth                    cmdSetLineWidth;
    PFN_vkCmdSetDepthBias                    cmdSetDepthBias;
    PFN_vkCmdSetBlendConstants               cmdSetBlendConstants;
    PFN_vkCmdSetDepthBounds                  cmdSetDepthBounds;
    PFN_vkCmdSetStencilCompareMask           cmdSetStencilCompareMask;
    PFN_vkCmdSetStencilWriteMask             cmdSetStencilWriteMask;
    PFN_vkCmdSetStencilReference             cmdSetStencilReference;
    PFN_vkCmdBindIndexBuffer                 cmdBindIndexBuffer;
    PFN_vkCmdBindVertexBuffers               cmdBindVertexBuffers;
    PFN_vkCmdDraw                            cmdDraw;
    PFN_vkCmdDrawIndexed                     cmdDrawIndexed;
    PFN_vkCmdDrawIndirect                    cmdDrawIndirect;
    PFN_vkCmdDrawIndexedIndirect             cmdDrawIndexedIndirect;
    PFN_vkCmdBlitImage                       cmdBlitImage;
    PFN_vkCmdClearDepthStencilImage          cmdClearDepthStencilImage;
    PFN_vkCmdClearAttachments                cmdClearAttachments;
    PFN_vkCmdResolveImage                    cmdResolveImage;
    PFN_vkCmdBeginRenderPass                 cmdBeginRenderPass;
    PFN_vkCmdNextSubpass                     cmdNextSubpass;
    PFN_vkCmdEndRenderPass                   cmdEndRenderPass;
} KRFW_Vulkan_DeviceFunctionPointers;

typedef struct KRFW_Vulkan_Device11FunctionPointers {
    PFN_vkBindBufferMemory2                 bindBufferMemory2;
    PFN_vkBindImageMemory2                  bindImageMemory2;
    PFN_vkCmdDispatchBase                   cmdDispatchBase;
    PFN_vkCmdSetDeviceMask                  cmdSetDeviceMask;
    PFN_vkCreateDescriptorUpdateTemplate    createDescriptorUpdateTemplate;
    PFN_vkCreateSamplerYcbcrConversion      createSamplerYcbcrConversion;
    PFN_vkDestroyDescriptorUpdateTemplate   destroyDescriptorUpdateTemplate;
    PFN_vkDestroySamplerYcbcrConversion     destroySamplerYcbcrConversion;
    PFN_vkGetBufferMemoryRequirements2      getBufferMemoryRequirements2;
    PFN_vkGetDescriptorSetLayoutSupport     getDescriptorSetLayoutSupport;
    PFN_vkGetDeviceGroupPeerMemoryFeatures  getDeviceGroupPeerMemoryFeatures;
    PFN_vkGetDeviceQueue2                   getDeviceQueue2;
    PFN_vkGetImageMemoryRequirements2       getImageMemoryRequirements2;
    PFN_vkGetImageSparseMemoryRequirements2 getImageSparseMemoryRequirements2;
    PFN_vkTrimCommandPool                   trimCommandPool;
    PFN_vkUpdateDescriptorSetWithTemplate   updateDescriptorSetWithTemplate;
} KRFW_Vulkan_Device11FunctionPointers;

typedef struct KRFW_Vulkan_Device12FunctionPointers {
    PFN_vkCmdBeginRenderPass2                   cmdBeginRenderPass2;
    PFN_vkCmdDrawIndexedIndirectCount           cmdDrawIndexedIndirectCount;
    PFN_vkCmdDrawIndirectCount                  cmdDrawIndirectCount;
    PFN_vkCmdEndRenderPass2                     cmdEndRenderPass2;
    PFN_vkCmdNextSubpass2                       cmdNextSubpass2;
    PFN_vkCreateRenderPass2                     createRenderPass2;
    PFN_vkGetBufferDeviceAddress                getBufferDeviceAddress;
    PFN_vkGetBufferOpaqueCaptureAddress         getBufferOpaqueCaptureAddress;
    PFN_vkGetDeviceMemoryOpaqueCaptureAddress   getDeviceMemoryOpaqueCaptureAddress;
    PFN_vkGetSemaphoreCounterValue              getSemaphoreCounterValue;
    PFN_vkResetQueryPool                        resetQueryPool;
    PFN_vkSignalSemaphore                       signalSemaphore;
    PFN_vkWaitSemaphores                        waitSemaphores;
} KRFW_Vulkan_Device12FunctionPointers;

typedef struct KRFW_Vulkan_DeviceSwapchainKHRFunctionPointers {
    PFN_vkCreateSwapchainKHR    createSwapchain;
    PFN_vkDestroySwapchainKHR   destroySwapchain;
    PFN_vkGetSwapchainImagesKHR getSwapchainImages;
    PFN_vkAcquireNextImageKHR   acquireNextImage;
    PFN_vkQueuePresentKHR       queuePresent;
} KRFW_Vulkan_DeviceSwapchainKHRFunctionPointers;

typedef struct KRFW_Vulkan_DeviceDynamicRenderingKHRFunctionPointers {
    PFN_vkCmdBeginRendering  cmdBeginRendering;
    PFN_vkCmdEndRendering    cmdEndRendering;
} KRFW_Vulkan_DeviceDynamicRenderingKHRFunctionPointers;

typedef struct KRFW_Vulkan_DeviceKHRFunctions {
    KRFW_Vulkan_DeviceSwapchainKHRFunctionPointers          swapchain;
    KRFW_Vulkan_DeviceDynamicRenderingKHRFunctionPointers   dynamicRendering;
} KRFW_Vulkan_DeviceKHRFunctions;

typedef struct KRFW_Vulkan_DeviceEXTFunctions {

} KRFW_Vulkan_DeviceEXTFunctions;

typedef struct KRFW_Vulkan_DeviceFunctions {
    /* Vulkan 1.0 */
    PFN_vkDestroyDevice                         destroyDevice;
    PFN_vkGetDeviceQueue                        getDeviceQueue;
    PFN_vkQueueSubmit                           queueSubmit;
    PFN_vkQueueWaitIdle                         queueWaitIdle;
    PFN_vkDeviceWaitIdle                        deviceWaitIdle;
    PFN_vkAllocateMemory                        allocateMemory;
    PFN_vkFreeMemory                            freeMemory;
    PFN_vkMapMemory                             mapMemory;
    PFN_vkUnmapMemory                           unmapMemory;
    PFN_vkFlushMappedMemoryRanges               flushMappedMemoryRanges;
    PFN_vkInvalidateMappedMemoryRanges          invalidateMappedMemoryRanges;
    PFN_vkGetDeviceMemoryCommitment             getDeviceMemoryCommitment;
    PFN_vkBindBufferMemory                      bindBufferMemory;
    PFN_vkBindImageMemory                       bindImageMemory;
    PFN_vkGetBufferMemoryRequirements           getBufferMemoryRequirements;
    PFN_vkGetImageMemoryRequirements            getImageMemoryRequirements;
    PFN_vkGetImageSparseMemoryRequirements      getImageSparseMemoryRequirements;
    PFN_vkQueueBindSparse                       queueBindSparse;
    PFN_vkCreateFence                           createFence;
    PFN_vkDestroyFence                          destroyFence;
    PFN_vkResetFences                           resetFences;
    PFN_vkGetFenceStatus                        getFenceStatus;
    PFN_vkWaitForFences                         waitForFences;
    PFN_vkCreateSemaphore                       createSemaphore;
    PFN_vkDestroySemaphore                      destroySemaphore;
    PFN_vkCreateQueryPool                       createQueryPool;
    PFN_vkDestroyQueryPool                      destroyQueryPool;
    PFN_vkGetQueryPoolResults                   getQueryPoolResults;
    PFN_vkCreateBuffer                          createBuffer;
    PFN_vkDestroyBuffer                         destroyBuffer;
    PFN_vkCreateImage                           createImage;
    PFN_vkDestroyImage                          destroyImage;
    PFN_vkGetImageSubresourceLayout             getImageSubresourceLayout;
    PFN_vkCreateImageView                       createImageView;
    PFN_vkDestroyImageView                      destroyImageView;
    PFN_vkCreateCommandPool                     createCommandPool;
    PFN_vkDestroyCommandPool                    destroyCommandPool;
    PFN_vkResetCommandPool                      resetCommandPool;
    PFN_vkAllocateCommandBuffers                allocateCommandBuffers;
    PFN_vkFreeCommandBuffers                    freeCommandBuffers;
    PFN_vkBeginCommandBuffer                    beginCommandBuffer;
    PFN_vkEndCommandBuffer                      endCommandBuffer;
    PFN_vkResetCommandBuffer                    resetCommandBuffer;
    PFN_vkCmdCopyBuffer                         cmdCopyBuffer;
    PFN_vkCmdCopyImage                          cmdCopyImage;
    PFN_vkCmdCopyBufferToImage                  cmdCopyBufferToImage;
    PFN_vkCmdCopyImageToBuffer                  cmdCopyImageToBuffer;
    PFN_vkCmdUpdateBuffer                       cmdUpdateBuffer;
    PFN_vkCmdFillBuffer                         cmdFillBuffer;
    PFN_vkCmdPipelineBarrier                    cmdPipelineBarrier;
    PFN_vkCmdBeginQuery                         cmdBeginQuery;
    PFN_vkCmdEndQuery                           cmdEndQuery;
    PFN_vkCmdResetQueryPool                     cmdResetQueryPool;
    PFN_vkCmdWriteTimestamp                     cmdWriteTimestamp;
    PFN_vkCmdCopyQueryPoolResults               cmdCopyQueryPoolResults;
    PFN_vkCmdExecuteCommands                    cmdExecuteCommands;
    PFN_vkCreateEvent                           createEvent;
    PFN_vkDestroyEvent                          destroyEvent;
    PFN_vkGetEventStatus                        getEventStatus;
    PFN_vkSetEvent                              setEvent;
    PFN_vkResetEvent                            resetEvent;
    PFN_vkCreateBufferView                      createBufferView;
    PFN_vkDestroyBufferView                     destroyBufferView;
    PFN_vkCreateShaderModule                    createShaderModule;
    PFN_vkDestroyShaderModule                   destroyShaderModule;
    PFN_vkCreatePipelineCache                   createPipelineCache;
    PFN_vkDestroyPipelineCache                  destroyPipelineCache;
    PFN_vkGetPipelineCacheData                  getPipelineCacheData;
    PFN_vkMergePipelineCaches                   mergePipelineCaches;
    PFN_vkCreateComputePipelines                createComputePipelines;
    PFN_vkDestroyPipeline                       destroyPipeline;
    PFN_vkCreatePipelineLayout                  createPipelineLayout;
    PFN_vkDestroyPipelineLayout                 destroyPipelineLayout;
    PFN_vkCreateSampler                         createSampler;
    PFN_vkDestroySampler                        destroySampler;
    PFN_vkCreateDescriptorSetLayout             createDescriptorSetLayout;
    PFN_vkDestroyDescriptorSetLayout            destroyDescriptorSetLayout;
    PFN_vkCreateDescriptorPool                  createDescriptorPool;
    PFN_vkDestroyDescriptorPool                 destroyDescriptorPool;
    PFN_vkResetDescriptorPool                   resetDescriptorPool;
    PFN_vkAllocateDescriptorSets                allocateDescriptorSets;
    PFN_vkFreeDescriptorSets                    freeDescriptorSets;
    PFN_vkUpdateDescriptorSets                  updateDescriptorSets;
    PFN_vkCmdBindPipeline                       cmdBindPipeline;
    PFN_vkCmdBindDescriptorSets                 cmdBindDescriptorSets;
    PFN_vkCmdClearColorImage                    cmdClearColorImage;
    PFN_vkCmdDispatch                           cmdDispatch;
    PFN_vkCmdDispatchIndirect                   cmdDispatchIndirect;
    PFN_vkCmdSetEvent                           cmdSetEvent;
    PFN_vkCmdResetEvent                         cmdResetEvent;
    PFN_vkCmdWaitEvents                         cmdWaitEvents;
    PFN_vkCmdPushConstants                      cmdPushConstants;
    PFN_vkCreateGraphicsPipelines               createGraphicsPipelines;
    PFN_vkCreateFramebuffer                     createFramebuffer;
    PFN_vkDestroyFramebuffer                    destroyFramebuffer;
    PFN_vkCreateRenderPass                      createRenderPass;
    PFN_vkDestroyRenderPass                     destroyRenderPass;
    PFN_vkGetRenderAreaGranularity              getRenderAreaGranularity;
    PFN_vkCmdSetViewport                        cmdSetViewport;
    PFN_vkCmdSetScissor                         cmdSetScissor;
    PFN_vkCmdSetLineWidth                       cmdSetLineWidth;
    PFN_vkCmdSetDepthBias                       cmdSetDepthBias;
    PFN_vkCmdSetBlendConstants                  cmdSetBlendConstants;
    PFN_vkCmdSetDepthBounds                     cmdSetDepthBounds;
    PFN_vkCmdSetStencilCompareMask              cmdSetStencilCompareMask;
    PFN_vkCmdSetStencilWriteMask                cmdSetStencilWriteMask;
    PFN_vkCmdSetStencilReference                cmdSetStencilReference;
    PFN_vkCmdBindIndexBuffer                    cmdBindIndexBuffer;
    PFN_vkCmdBindVertexBuffers                  cmdBindVertexBuffers;
    PFN_vkCmdDraw                               cmdDraw;
    PFN_vkCmdDrawIndexed                        cmdDrawIndexed;
    PFN_vkCmdDrawIndirect                       cmdDrawIndirect;
    PFN_vkCmdDrawIndexedIndirect                cmdDrawIndexedIndirect;
    PFN_vkCmdBlitImage                          cmdBlitImage;
    PFN_vkCmdClearDepthStencilImage             cmdClearDepthStencilImage;
    PFN_vkCmdClearAttachments                   cmdClearAttachments;
    PFN_vkCmdResolveImage                       cmdResolveImage;
    PFN_vkCmdBeginRenderPass                    cmdBeginRenderPass;
    PFN_vkCmdNextSubpass                        cmdNextSubpass;
    PFN_vkCmdEndRenderPass                      cmdEndRenderPass;

    /* Vulkan 1.1 */
    PFN_vkBindBufferMemory2                     bindBufferMemory2;
    PFN_vkBindImageMemory2                      bindImageMemory2;
    PFN_vkCmdDispatchBase                       cmdDispatchBase;
    PFN_vkCmdSetDeviceMask                      cmdSetDeviceMask;
    PFN_vkCreateDescriptorUpdateTemplate        createDescriptorUpdateTemplate;
    PFN_vkCreateSamplerYcbcrConversion          createSamplerYcbcrConversion;
    PFN_vkDestroyDescriptorUpdateTemplate       destroyDescriptorUpdateTemplate;
    PFN_vkDestroySamplerYcbcrConversion         destroySamplerYcbcrConversion;
    PFN_vkGetBufferMemoryRequirements2          getBufferMemoryRequirements2;
    PFN_vkGetDescriptorSetLayoutSupport         getDescriptorSetLayoutSupport;
    PFN_vkGetDeviceGroupPeerMemoryFeatures      getDeviceGroupPeerMemoryFeatures;
    PFN_vkGetDeviceQueue2                       getDeviceQueue2;
    PFN_vkGetImageMemoryRequirements2           getImageMemoryRequirements2;
    PFN_vkGetImageSparseMemoryRequirements2     getImageSparseMemoryRequirements2;
    PFN_vkTrimCommandPool                       trimCommandPool;
    PFN_vkUpdateDescriptorSetWithTemplate       updateDescriptorSetWithTemplate;

    /* Vulkan 1.2 */
    PFN_vkCmdBeginRenderPass2                   cmdBeginRenderPass2;
    PFN_vkCmdDrawIndexedIndirectCount           cmdDrawIndexedIndirectCount;
    PFN_vkCmdDrawIndirectCount                  cmdDrawIndirectCount;
    PFN_vkCmdEndRenderPass2                     cmdEndRenderPass2;
    PFN_vkCmdNextSubpass2                       cmdNextSubpass2;
    PFN_vkCreateRenderPass2                     createRenderPass2;
    PFN_vkGetBufferDeviceAddress                getBufferDeviceAddress;
    PFN_vkGetBufferOpaqueCaptureAddress         getBufferOpaqueCaptureAddress;
    PFN_vkGetDeviceMemoryOpaqueCaptureAddress   getDeviceMemoryOpaqueCaptureAddress;
    PFN_vkGetSemaphoreCounterValue              getSemaphoreCounterValue;
    PFN_vkResetQueryPool                        resetQueryPool;
    PFN_vkSignalSemaphore                       signalSemaphore;
    PFN_vkWaitSemaphores                        waitSemaphores;

    /* extensions */
    KRFW_Vulkan_DeviceKHRFunctions  khr;
    KRFW_Vulkan_DeviceEXTFunctions  ext;
} KRFW_Vulkan_DeviceFunctions;

typedef struct KRFW_Vulkan_Device {
    VkPhysicalDevice            physical;
    VkDevice                    logical;
    KRFW_Vulkan_DeviceFunctions functions;
} KRFW_Vulkan_Device;

typedef void    (*KRFW_Vulkan_ProcFencePoolDestroy) (struct KRFW_Vulkan_FencePool* self);
typedef VkFence (*KRFW_Vulkan_ProcFencePoolAcquire) (struct KRFW_Vulkan_FencePool* self, KRFW_bool signaled);
typedef void    (*KRFW_Vulkan_ProcFencePoolRelease) (struct KRFW_Vulkan_FencePool* self, VkFence fence);

typedef struct KRFW_Vulkan_FencePool {
    KRFW_Vulkan_ProcFencePoolDestroy    destroy;
    KRFW_Vulkan_ProcFencePoolAcquire    acquire;
    KRFW_Vulkan_ProcFencePoolRelease    release;

    struct KRFW_Vulkan_Renderer*        _renderer;
    KRFW_Odin_RawDynamicArray           _fences;
    KRFW_Odin_RawDynamicArray           _unusedFenceIndices;

    KRFW_bool                           _isInternal;
} KRFW_Vulkan_FencePool;

typedef void        (*KRFW_Vulkan_ProcSemaphorePoolDestroy) (struct KRFW_Vulkan_SemaphorePool* self);
typedef VkSemaphore (*KRFW_Vulkan_ProcSemaphorePoolAcquire) (struct KRFW_Vulkan_SemaphorePool* self, KRFW_bool signaled);
typedef void        (*KRFW_Vulkan_ProcSemaphorePoolRelease) (struct KRFW_Vulkan_SemaphorePool* self, VkSemaphore semaphore);

typedef struct KRFW_Vulkan_SemaphorePool {
    KRFW_Vulkan_ProcSemaphorePoolDestroy    destroy;
    KRFW_Vulkan_ProcSemaphorePoolAcquire    acquire;
    KRFW_Vulkan_ProcSemaphorePoolRelease    release;

    struct KRFW_Vulkan_Renderer*        _renderer;
    KRFW_Odin_RawDynamicArray           _semaphores;
    KRFW_Odin_RawDynamicArray           _unusedSemaphoreIndices;

    KRFW_bool                           _isInternal;
} KRFW_Vulkan_SemaphorePool;

typedef struct KRFW_Vulkan_SubmitInfoWait {
    VkSemaphore             semaphore;
    VkPipelineStageFlags    dstStageMask;
} KRFW_Vulkan_SubmitInfoWait;

typedef void                        (*KRFW_Vulkan_ProcCommandPoolDestroy)   (struct KRFW_Vulkan_CommandPool* self);
typedef struct KRFW_Vulkan_Queue*   (*KRFW_Vulkan_ProcCommandPoolGetQueue)  (struct KRFW_Vulkan_CommandPool* self);
typedef VkCommandBuffer             (*KRFW_Vulkan_ProcCommandPoolAcquire)   (struct KRFW_Vulkan_CommandPool* self, KRFW_bool bundle);
typedef VkFence                     (*KRFW_Vulkan_ProcCommandPoolSubmit)    (struct KRFW_Vulkan_CommandPool* self, VkCommandBuffer commandBuffer, uint32_t submitInfoWaitCount, const KRFW_Vulkan_SubmitInfoWait* submitInfoWaits, uint32_t signalSemaphoreCount, const VkSemaphore* signalSemaphores);
typedef void                        (*KRFW_Vulkan_ProcCommandPoolRelease)   (struct KRFW_Vulkan_CommandPool* self, VkCommandBuffer commandBuffer, VkFence fence);

typedef struct KRFW_Vulkan_CommandPool {
    KRFW_Vulkan_ProcCommandPoolDestroy  destroy;
    KRFW_Vulkan_ProcCommandPoolGetQueue getQueue;
    KRFW_Vulkan_ProcCommandPoolAcquire  acquire;
    KRFW_Vulkan_ProcCommandPoolSubmit   submit;
    KRFW_Vulkan_ProcCommandPoolRelease  release;

    struct KRFW_Vulkan_Renderer*        _renderer;
    struct KRFW_Vulkan_Queue*           _queue;
    KRFW_Vulkan_FencePool*              _fencePool;
    VkCommandPool                       _commandPool;

    KRFW_Odin_RawDynamicArray           _commandBuffers;
    KRFW_Odin_RawDynamicArray           _unusedCommandBufferIndices;

    KRFW_bool                           _isInternal;
} KRFW_Vulkan_CommandPool;

typedef uint32_t KRFW_Vulkan_QueueType;
enum KRFW_Vulkan_QueueType_Enum {
    KRFW_VULKAN_QUEUE_TYPE_GENERAL  = 0,
    KRFW_VULKAN_QUEUE_TYPE_GRAPHICS = 1,
    KRFW_VULKAN_QUEUE_TYPE_TRANSFER = 2,
    KRFW_VULKAN_QUEUE_TYPE_COMPUTE  = 3,
    KRFW_VULKAN_QUEUE_TYPE_PRESENT  = 4,
    KRFW_VULKAN_QUEUE_TYPE_INVALID  = 31,
};

typedef uint32_t KRFW_Vulkan_QueueTypeMask;

typedef struct KRFW_Vulkan_Queue {
    VkQueue                     queue;
    uint32_t                    family;
    uint32_t                    index;
    KRFW_Vulkan_QueueTypeMask   intendedTypes;
    KRFW_Vulkan_QueueTypeMask   supportedTypes;
    KRFW_Vulkan_CommandPool     commandPool;
} KRFW_Vulkan_Queue;

typedef struct KRFW_Vulkan_Backbuffer {
    uint32_t            index;
    VkImage             image;
    VkImageView         imageView;

    VkSurfaceFormatKHR  surfaceFormat;
    VkExtent2D          extent;
    uint32_t            layerCount;

    VkFence             fence;
    VkSemaphore         semaphore;
} KRFW_Vulkan_Backbuffer;

typedef const KRFW_Vulkan_Backbuffer*   (*KRFW_Vulkan_ProcBackbufferPoolAcquire)    (struct KRFW_Vulkan_BackBufferPool* self);
typedef void                            (*KRFW_Vulkan_ProcBackbufferPoolRelease)    (struct KRFW_Vulkan_BackBufferPool* self, const KRFW_Vulkan_Backbuffer* backbuffer);

typedef struct KRFW_Vulkan_BackbufferPool {
    KRFW_Vulkan_ProcBackbufferPoolAcquire   acquire;
    KRFW_Vulkan_ProcBackbufferPoolRelease   release;

    struct KRFW_Vulkan_Renderer*            _renderer;
    KRFW_Window                             _window;
    KRFW_WSISetting                         _setting;
    VkSurfaceKHR                            _surface;

    VkSwapchainKHR                          _swapchain;
    KRFW_Vulkan_FencePool*                  _fencePool;
    KRFW_Vulkan_SemaphorePool*              _semaphorePool;
    KRFW_Odin_RawSlice                      _backbuffers;
} KRFW_Vulkan_BackbufferPool;

typedef struct KRFW_Vulkan_BackbufferPacket {
    const KRFW_Vulkan_Backbuffer*   backbuffer;
    VkPipelineStageFlags            lastStage;
    VkImageLayout                   lastLayout; 
} KRFW_Vulkan_BackbufferPacket;

typedef void    (*KRFW_Vulkan_ProcPacketAddSyncObjects) (struct KRFW_Vulkan_Packet* self, uint32_t submitInfoWaitCount, const KRFW_Vulkan_SubmitInfoWait* submitInfoWaits, uint32_t signalSemaphoreCount, const VkSemaphore* signalSemaphores);

typedef struct KRFW_Vulkan_Packet {
    KRFW_Vulkan_ProcPacketAddSyncObjects    addSyncObjects;

    struct KRFW_Vulkan_Renderer*            renderer;
    KRFW_Vulkan_Instance*                   instance;
    KRFW_Vulkan_Device*                     device;
    KRFW_Vulkan_Queue*                      queue;
    KRFW_Vulkan_CommandPool*                commandPool;
    VkCommandBuffer                         commandBuffer;
    KRFW_Vulkan_BackbufferPacket*           backbufferPacket;

    KRFW_Odin_RawDynamicArray*              _submitInfoWaits;
    KRFW_Odin_RawDynamicArray*              _signalSemaphores;
} KRFW_Vulkan_Packet;

typedef KRFW_bool   (*KRFW_Vulkan_ProcPassExecute)  (struct KRFW_Vulkan_Pass* self, KRFW_Vulkan_Packet* packet);

typedef struct KRFW_Vulkan_Pass {
    KRFW_ProcIPassInit                  init;
    KRFW_ProcIPassDestroy               destroy;
    KRFW_ProcIPassRequiresBackbuffer    requiresBackbuffer;

    KRFW_Vulkan_ProcPassExecute         execute;
} KRFW_Vulkan_Pass;

typedef struct KRFW_Vulkan_RenderBuffers_ {
    uint8_t _debugLoggerBuffer[2048];
    uint8_t _driverPreference[VK_MAX_DRIVER_NAME_SIZE];
} KRFW_Vulkan_RenderBuffers_;

typedef struct KRFW_Vulkan_QueuedWindow_ {
    KRFW_Window     window;
    KRFW_WSISetting setting;
} KRFW_Vulkan_QueuedWindow_;

typedef KRFW_bool   (*KRFW_Vulkan_ProcRendererLoadVulkanLoaderOdin)     (struct KRFW_Vulkan_Renderer* self, KRFW_Odin_RawString string);
typedef KRFW_bool   (*KRFW_Vulkan_ProcRendererLoadVulkanLoader)         (struct KRFW_Vulkan_Renderer* self, uint32_t len, const char* path);
typedef KRFW_bool   (*KRFW_Vulkan_ProcRendererLoadVulkanLoaderUTF32)    (struct KRFW_Vulkan_Renderer* self, uint32_t len, const KRFW_Odin_rune* path);
typedef void        (*KRFW_Vulkan_ProcRendererSetDriverPreferenceOdin)  (struct KRFW_Vulkan_Renderer* self, KRFW_Odin_RawString driver);
typedef void        (*KRFW_Vulkan_ProcRendererSetDriverPreference)      (struct KRFW_Vulkan_Renderer* self, uint32_t len, const char* driver);
typedef void        (*KRFW_Vulkan_ProcRendererSetAllocator)             (struct KRFW_Vulkan_Renderer* self, const VkAllocationCallbacks* allocator);

typedef KRFW_bool   (*KRFW_Vulkan_ProcRendererCreateFencePool)      (struct KRFW_Vulkan_Renderer* self, KRFW_Vulkan_FencePool* fencePool);
typedef KRFW_bool   (*KRFW_Vulkan_ProcRendererCreateSemaphorePool)  (struct KRFW_Vulkan_Renderer* self, KRFW_Vulkan_SemaphorePool* semaphorePool);
typedef KRFW_bool   (*KRFW_Vulkan_ProcRendererCreateCommandPool)    (struct KRFW_Vulkan_Renderer* self, KRFW_Vulkan_CommandPool* commandPool, KRFW_Vulkan_FencePool* fencePool, KRFW_Vulkan_Queue* queue);

typedef KRFW_Vulkan_FencePool*      (*KRFW_Vulkan_ProcRendererGetDefaultFencePool)      (struct KRFW_Vulkan_Renderer* self);
typedef KRFW_Vulkan_SemaphorePool*  (*KRFW_Vulkan_ProcRendererGetDefaultSemaphorePool)  (struct KRFW_Vulkan_Renderer* self);
typedef KRFW_Vulkan_CommandPool*    (*KRFW_Vulkan_ProcRendererGetDefaultCommandPool)    (struct KRFW_Vulkan_Renderer* self, KRFW_Vulkan_QueueType queueType);

typedef struct KRFW_Vulkan_Renderer {
    /* inherited functions */
    KRFW_ProcIRendererSetDebugLogger    setDebugLogger;
    KRFW_ProcIRendererInit              init;
    KRFW_ProcIRendererDestroy           destroy;
    KRFW_ProcIRendererCreateWSI         createWSI;
    KRFW_ProcIRendererDestroyWSI        destroyWSI;
    KRFW_ProcIRendererExecutePasses     executePasses;

    /* Vulkan backend functions */
    KRFW_Vulkan_ProcRendererLoadVulkanLoaderOdin    loadVulkanLoaderOdin;
    KRFW_Vulkan_ProcRendererLoadVulkanLoader        loadVulkanLoader;
    KRFW_Vulkan_ProcRendererLoadVulkanLoaderUTF32   loadVulkanLoaderUTF32;
    KRFW_Vulkan_ProcRendererSetDriverPreferenceOdin setDriverPreferenceOdin;
    KRFW_Vulkan_ProcRendererSetDriverPreference     setDriverPreference;
    KRFW_Vulkan_ProcRendererSetAllocator            setAllocator;

    KRFW_Vulkan_ProcRendererCreateFencePool         createFencePool;
    KRFW_Vulkan_ProcRendererCreateSemaphorePool     createSemaphorePool;
    KRFW_Vulkan_ProcRendererCreateCommandPool       createCommandPool;

    KRFW_Vulkan_ProcRendererGetDefaultFencePool     getDefaultFencePool;
    KRFW_Vulkan_ProcRendererGetDefaultSemaphorePool getDefaultSemaphorePool;
    KRFW_Vulkan_ProcRendererGetDefaultCommandPool   getDefaultCommandPool;

    /* members */
    KRFW_ProcDebugLogger                _debugLogger;
    KRFW_DebugSeverity                  _debugLoggerLowestSeverity;
    KRFW_Odin_Context                   _ctx;
    void*                               _library;
    KRFW_Vulkan_GlobalFunctionPointers  _globalFunctions;
    void*                               _buffers;

    bool                        _areWindowsQueued;
    KRFW_Odin_RawDynamicArray   _queuedWindows;

    bool                            _headless;
    bool                            _debug;
    const VkAllocationCallbacks*    _allocator;
    KRFW_Vulkan_Instance            _instance;
    KRFW_Vulkan_Device              _device;
    KRFW_Odin_RawMap                _backbufferPools;

    KRFW_Odin_RawSlice  _queues;

    KRFW_Vulkan_Queue*  _generalQueue;
    KRFW_Vulkan_Queue*  _presentQueue;
    KRFW_Vulkan_Queue*  _graphicsQueue;
    KRFW_Vulkan_Queue*  _transferQueue;
    KRFW_Vulkan_Queue*  _computeQueue;

    KRFW_Vulkan_FencePool       _defaultFencePool;
    KRFW_Vulkan_SemaphorePool    _defaultSemaphorePool;

    KRFW_bool   _performingDestruction;
} KRFW_Vulkan_Renderer;

extern void krfwVulkanInstantiateRenderer(KRFW_Vulkan_Renderer* renderer);

#ifdef __cplusplus
}
#endif

#endif