#include "vulkan/vulkan_core.h"
#include <iostream>
#include <format>
#include <limits>
#include <unordered_map>
#include <vector>
#include <sstream>
#include <functional>

#define VK_ONLY_EXPORTED_PROTOTYPES
#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>
#include <vulkan/vulkan.h>

#include "kvk.h"

#ifdef KRFW_IMGUI
#include "imgui.h"
#include "imgui_impl_vulkan.h"
#endif

#define KRFW_ERR(msg_) throw std::runtime_error(msg_)
#define KRFW_VK_ERR(vkresult_, msg_) if (vkresult_ != VK_SUCCESS) { KRFW_ERR(msg_); }

namespace krfw {

struct Queue {
    VkQueue queue = {};
    uint32_t familyIndex;
    uint32_t queueIndex;

    static Queue& invalid() {
        static Queue q = { nullptr };
        return q;
    }
};

class FencePool {
private:
    VkDevice _device = {};

    std::vector<uint32_t> _unusedFences;
    std::vector<VkFence> _fences;

    friend class Renderer;

    void destroy() {
        if (_device == nullptr) {
            return;
        }

        if (!_fences.empty()) {
            vkWaitForFences(_device, static_cast<uint32_t>(_fences.size()), _fences.data(), true, std::numeric_limits<uint64_t>::max());

            for (uint32_t i = 0; i < _fences.size(); ++i) {
                vkDestroyFence(_device, _fences[i], nullptr);
            }
        }
    }

public:
    FencePool(VkDevice device) : _device(device) {}

    VkFence acquireFence(bool signaled) {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call acquireFence on invalid reference FencePool");
        }

        VkFenceCreateInfo ci = {
            .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .flags = signaled ? VK_FENCE_CREATE_SIGNALED_BIT : static_cast<VkFlags>(0),
        };

        VkFence fence;
        KRFW_VK_ERR(vkCreateFence(_device, &ci, nullptr, &fence), "Failed to create VkFence");

        _fences.push_back(fence);
        return fence;
    }

    void releaseFence(VkFence fence) {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call releaseFence on invalid reference FencePool");
        }

        for (uint32_t i = 0; i < _fences.size(); ++i) {
            if (fence == _fences[i]) {
                _unusedFences.push_back(i);
                return;
            }
        }
    }

    static FencePool& invalid() {
        static FencePool fp = FencePool(nullptr);
        return fp;
    }
};

class SemaphorePool {
private:
    VkDevice _device = {};

    std::vector<uint32_t> _unusedSemaphores;
    std::vector<VkSemaphore> _semaphores;

    friend class Renderer;

    void destroy() {
        if (_device == nullptr) {
            return;
        }

        vkDeviceWaitIdle(_device);
        for (uint32_t i = 0; i < _semaphores.size(); ++i) {
            vkDestroySemaphore(_device, _semaphores[i], nullptr);
        }
    }

public:
    SemaphorePool(VkDevice device) : _device(device) {}

    VkSemaphore acquireSemaphore() {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call acquireSemaphore on invalid reference SemaphorePool");
        }

        VkSemaphoreCreateInfo ci = {
            .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        };

        VkSemaphore semaphore;
        KRFW_VK_ERR(vkCreateSemaphore(_device, &ci, nullptr, &semaphore), "Failed to create VkSemaphore");

        _semaphores.push_back(semaphore);
        return semaphore;
    }

    void releaseSemaphore(VkSemaphore semaphore) {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call releaseSemaphore on invalid reference SemaphorePool");
        }

        for (uint32_t i = 0; i < _semaphores.size(); ++i) {
            if (semaphore == _semaphores[i]) {
                _unusedSemaphores.push_back(i);
                return;
            }
        }
    }

    static SemaphorePool& invalid() {
        static SemaphorePool sp = SemaphorePool(nullptr);
        return sp;
    }
};

struct SubmitInfoWait {
    VkSemaphore semaphore = {};
    VkPipelineStageFlags dstStageMask;
};

class CommandPool {
private:
    VkDevice _device = {};
    VkCommandPool _commandPool = {};

    Queue* _queue;
    FencePool* _fencePool;

    std::vector<uint32_t> _unusedCommandBuffers;
    std::vector<VkCommandBuffer> _commandBuffers;

    friend class Renderer;

    void destroy() {
        if (_device == nullptr) {
            return;
        }

        vkQueueWaitIdle(_queue->queue);
        vkDestroyCommandPool(_device, _commandPool, nullptr);
    }

public:
    CommandPool(VkDevice device, Queue& queue, FencePool& fencePool) : _device(device), _queue(&queue), _fencePool(&fencePool) {
        if (_device == nullptr) {
            return;
        }

        VkCommandPoolCreateInfo ci = {
            .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
            .queueFamilyIndex = queue.familyIndex,
        };

        KRFW_VK_ERR(vkCreateCommandPool(_device, &ci, nullptr, &_commandPool), "Failed to create VkCommandPool for command grouping");
    }

    VkCommandBuffer acquireCommandBuffer() {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call acquireCommandBuffer on invalid reference CommandPool");
        }

        VkCommandBuffer commandBuffer;
        if (!_unusedCommandBuffers.empty()) {
            uint32_t cb = _unusedCommandBuffers[_unusedCommandBuffers.size() - 1];
            _unusedCommandBuffers.resize(_unusedCommandBuffers.size() - 1);
            commandBuffer = _commandBuffers[cb];
        } else {
            VkCommandBufferAllocateInfo ai = {
                .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .commandPool = _commandPool,
                .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandBufferCount = 1,
            };

            KRFW_VK_ERR(vkAllocateCommandBuffers(_device, &ai, &commandBuffer), "Failed to allocate new VkCommandBuffer");
            _commandBuffers.push_back(commandBuffer);
        }

        return commandBuffer;
    }

    void releaseCommandBuffer(VkCommandBuffer commandBuffer) {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call acquireCommandBuffer on invalid reference CommandPool");
        }

        uint32_t index;
        for (index = 0; index < _commandBuffers.size(); ++index) {
            if (_commandBuffers[index] == commandBuffer) {
                break;
            }
        }

        if (index == _commandBuffers.size()) {
            KRFW_ERR("Provided command buffer is not a child of this CommandPool");
        }

        vkResetCommandBuffer(commandBuffer, VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT);
        _unusedCommandBuffers.push_back(index);
    }

    VkFence submitCommandBuffer(VkCommandBuffer commandBuffer, std::vector<SubmitInfoWait> const& waits, std::vector<VkSemaphore> const& signals) {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call submitCommandBuffer on invalid reference CommandPool");
        }

        uint32_t cb;
        for (cb = 0; cb < _commandBuffers.size(); ++cb) {
            if (_commandBuffers[cb] == commandBuffer) {
                break;
            }
        }

        if (cb == _commandBuffers.size()) {
            KRFW_ERR("Provided VkCommandBuffer does not exist in this pool");
        }

        std::vector<VkSemaphore> waitSemaphores(waits.size());
        std::vector<VkPipelineStageFlags> waitDstStageMasks(waits.size());
        for (uint32_t i = 0; i < waits.size(); ++i) {
            waitSemaphores[i] = waits[i].semaphore;
            waitDstStageMasks[i] = waits[i].dstStageMask;
        }

        VkFence fence = _fencePool->acquireFence(false);
        
        VkSubmitInfo si = {
            .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .waitSemaphoreCount = static_cast<uint32_t>(waits.size()),
            .pWaitSemaphores = waitSemaphores.data(),
            .pWaitDstStageMask = waitDstStageMasks.data(),
            .commandBufferCount = 1,
            .pCommandBuffers = &commandBuffer,
            .signalSemaphoreCount = static_cast<uint32_t>(signals.size()),
            .pSignalSemaphores = signals.data(),
        };

        KRFW_VK_ERR(vkQueueSubmit(_queue->queue, 1, &si, fence), "Failed to submit VkQueue");
        return fence;
    }

    void releaseSubmitFence(VkFence fence) {
        if (_device == nullptr) {
            KRFW_ERR("Attempted to call releaseSubmitFence on invalid reference CommandPool");
        }

        _fencePool->releaseFence(fence);
    }

    static CommandPool& invalid() {
        static CommandPool cp = CommandPool(nullptr, Queue::invalid(), FencePool::invalid());
        return cp;
    }
};

struct Backbuffer {
    uint32_t index;

    VkImage image = {};
    VkImageView imageView = {};

    VkSurfaceFormatKHR surfaceFormat;
    VkExtent2D extent;
    uint32_t layerCount;

    VkFence fence = {};
    VkSemaphore semaphore = {};
};

class BackbufferPool {
private:
    VkSurfaceKHR _surface = {};
    bool _preferImmediate;

    VkDevice _device = {};
    VkSwapchainKHR _swapchain = {};
    kvk::SwapchainPreference _swapchainPreference;
    VkExtent2D _lastKnownExtent;

    std::vector<VkImage> _backbuffers;
    std::vector<VkImageView> _backbufferViews;

    FencePool* _fencePool;
    SemaphorePool* _semaphorePool;

    friend class Renderer;

public:
    BackbufferPool() {}

    BackbufferPool(FencePool& fencePool, SemaphorePool& semaphorePool, VkSurfaceKHR surface, bool preferImmediate) : _surface(surface), _preferImmediate(preferImmediate), _fencePool(&fencePool), _semaphorePool(&semaphorePool) {}

    Backbuffer acquireBackbuffer() {
        Backbuffer backbuffer = {};
        if (_fencePool != &FencePool::invalid()) {
            backbuffer.fence = _fencePool->acquireFence(false);
        }
        
        if (_semaphorePool != &SemaphorePool::invalid()) {
            backbuffer.semaphore = _semaphorePool->acquireSemaphore();
        }

        PFN_vkAcquireNextImageKHR vkAcquireNextImageKHR = reinterpret_cast<PFN_vkAcquireNextImageKHR>(vkGetDeviceProcAddr(_device, "vkAcquireNextImageKHR"));
        VkResult result = vkAcquireNextImageKHR(_device, _swapchain, std::numeric_limits<uint64_t>::max(), backbuffer.semaphore, backbuffer.fence, &backbuffer.index);
        if (result != VK_SUCCESS) {
            throw std::runtime_error("Failed to acquire next image for BackbuferPool");
        }

        backbuffer.image = _backbuffers[backbuffer.index];
        backbuffer.imageView = _backbufferViews[backbuffer.index];
        backbuffer.surfaceFormat = _swapchainPreference.vk_surface_format;
        backbuffer.extent = _lastKnownExtent;
        backbuffer.layerCount = _swapchainPreference.layer_count;
        return backbuffer;
    }

    void releaseBackbuffer(Backbuffer& backbuffer) {
        if (backbuffer.fence != VK_NULL_HANDLE) {
            _fencePool->releaseFence(backbuffer.fence);
        }

        if (backbuffer.semaphore != VK_NULL_HANDLE) {
            _semaphorePool->releaseSemaphore(backbuffer.semaphore);
        }
    }
};

struct RenderPoolPacket {
    VkInstance instance;
    VkDevice device;
    VkPhysicalDevice physicalDevice;

    FencePool& fencePool;
    SemaphorePool& semaphorePool;

    VkCommandBuffer commandBuffer;

    Queue const& queue;
};

struct RenderPoolBackbufferPacket {
    Backbuffer backbuffer;
    VkImageLayout lastLayout;
    VkPipelineStageFlags lastStage;
};

class IRenderPool {
public:
    virtual bool requiresBackbuffer() = 0;
    virtual bool execute(RenderPoolPacket const& packet, RenderPoolBackbufferPacket* backbufferPacket, std::vector<SubmitInfoWait>& waits, std::vector<VkSemaphore>& signals) = 0;
};

class Renderer {
private:
    bool _debug;

    VkInstance _instance = {};
    VkPhysicalDevice _physicalDevice = {};
    VkDevice _device = {};

    FencePool _fencePool;
    SemaphorePool _semaphorePool;

    Queue _graphicsQueue;
    CommandPool _graphicsCommandPool;

    std::vector<IRenderPool*> _renderPools;

    void _initInstance() {
        KRFW_VK_ERR(
            kvk::create_instance({
                .app_name = "kgc Standalone",
                .app_version = VK_MAKE_API_VERSION(0, 0, 9, 0),
                .vk_version = VK_MAKE_API_VERSION(0, 1, 2, 197),
                .vk_layers = {},
                .vk_extensions = {
                    VK_KHR_GET_SURFACE_CAPABILITIES_2_EXTENSION_NAME,
                    VK_EXT_SURFACE_MAINTENANCE_1_EXTENSION_NAME
                },
                .presets = {
                    .recommended = true,
                    .enable_surfaces = true,
                    .enable_platform_specific_surfaces = true,
                    .enable_validation_layers = _debug,
                    .enable_debug_utils = _debug,

                    .debug_messenger_callback = [](VkDebugUtilsMessageSeverityFlagBitsEXT severity, VkDebugUtilsMessageTypeFlagsEXT types, const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, void* pUserData) -> VkBool32 {
                        const char* severity_strings[4] = {
                            "VERBOSE",
                            "INFO",
                            "WARNING",
                            "KRFW_ERROR",
                        };
                    
                        const char* type_strings[4] = {
                            "GENERAL",
                            "VALIDATION",
                            "PERFORMANCE",
                            "DEVICE_ADDRESS_BINDING_EXT",
                        };
                    
                        uint32_t severity_index = 0;
                        uint32_t severity_shifted = static_cast<uint32_t>(severity);
                        for (severity_index = 0; severity_index < 4; ++severity_index) {
                            if (severity_shifted == 1) {
                                break;
                            }
                        
                            severity_shifted >>= 4;
                        }
                    
                        std::cout << "[vk] (" << severity_strings[severity_index];
                        for (uint32_t i = 0; i < 4; ++i) {
                            if ((types & (1 << i)) != 0) {
                                std::cout << ", " << type_strings[i];
                            }
                        }

                        std::cout << "): " << pCallbackData->pMessage << std::endl;
                        return false;
                    },
                }
            }, _instance),
            "Failed to create VkInstance using kvk"
        );
    }

    void _cleanupInstance() {
        if (_instance != VK_NULL_HANDLE) {
            vkDestroyInstance(_instance, nullptr);
        }
    }

    void _initDevice() {
        VkPhysicalDeviceSwapchainMaintenance1FeaturesEXT swapchainMaintenance1Features = {
            .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SWAPCHAIN_MAINTENANCE_1_FEATURES_EXT,
            .swapchainMaintenance1 = true,
        };

        VkPhysicalDeviceVulkan12Features vk12Features = {
            .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
            .pNext = &swapchainMaintenance1Features,
            .shaderStorageBufferArrayNonUniformIndexing = true,
            .shaderStorageImageArrayNonUniformIndexing = true,
        };

        VkSurfaceKHR surfaceToBeCompatibleWith = VK_NULL_HANDLE;
        if (!_backbufferPools.empty()) {
            surfaceToBeCompatibleWith = _backbufferPools.begin()->second._surface;
        }

        std::vector<kvk::DeviceQueueReturn> deviceQueueReturns;
        KRFW_VK_ERR(kvk::create_device(_instance, {
            .vk_pnext = &vk12Features,
            .vk_extensions = { VK_EXT_SWAPCHAIN_MAINTENANCE_1_EXTENSION_NAME },
            .physical_device_query = {
                .minimum_vk_version = VK_MAKE_API_VERSION(0, 1, 2, 197),
                .excluded_device_types = kvk::PhysicalDeviceTypeFlags::CPU | kvk::PhysicalDeviceTypeFlags::VIRTUAL_GPU | kvk::PhysicalDeviceTypeFlags::OTHER,
                .minimum_features = {
                    .shaderStorageBufferArrayDynamicIndexing = true,
                    .shaderStorageImageArrayDynamicIndexing = true,
                },
                .minimum_limits = {},
                .required_extensions = {},
                .minimum_format_properties = {
                    {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .minimum_properties = {
                            .optimalTilingFeatures = VK_FORMAT_FEATURE_TRANSFER_SRC_BIT | VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT,
                        },
                    },
                    {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .minimum_properties = {
                            .optimalTilingFeatures = VK_FORMAT_FEATURE_TRANSFER_SRC_BIT | VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT,
                        },
                    },
                },
                .minimum_image_format_properties = {},
                .minimum_memory_properties = {
                    .memoryTypeCount = 1,
                    .memoryTypes = {
                        {
                            .propertyFlags = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                        },
                        {
                            .propertyFlags = VK_MEMORY_PROPERTY_HOST_COHERENT_BIT | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                        },
                    },
                },
                .required_queues = {
                    {
                        .properties = {
                            .queueFlags = VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_TRANSFER_BIT,
                            .queueCount = 1,
                        },
                        .surface_support = surfaceToBeCompatibleWith,
                        .priorities = {
                            1.0f,
                        },
                    }
                }
            },
            .presets = {
                .recommended = true,
                .enable_swapchain = true,
                .enable_dynamic_rendering = true,
                .enable_maintenance1 = true,
            },
        }, _physicalDevice, _device, deviceQueueReturns), "Failed to create VkDevice using kvk");

        _graphicsQueue = {
            .queue = deviceQueueReturns[0].vk_queue,
            .familyIndex = deviceQueueReturns[0].family_index,
            .queueIndex = deviceQueueReturns[0].queue_index,
        };
    }

    void _cleanupDevice() {
        if (_device != VK_NULL_HANDLE) {
            vkDestroyDevice(_device, nullptr);
        }
    }

    std::unordered_map<SDL_Window*, BackbufferPool> _backbufferPools;

    void _cleanupWSI() {
        for (auto const& p : _backbufferPools) {
            for (uint32_t i = 0; i < p.second._swapchainPreference.image_count; ++i) {
                if (p.second._backbufferViews[i] != VK_NULL_HANDLE) {
                    vkDestroyImageView(_device, p.second._backbufferViews[i], nullptr);
                }
            }

            if (p.second._swapchain != VK_NULL_HANDLE) {
                PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR = reinterpret_cast<PFN_vkDestroySwapchainKHR>(vkGetDeviceProcAddr(_device, "vkDestroySwapchainKHR"));
                vkDestroySwapchainKHR(_device, p.second._swapchain, nullptr);
            }

            PFN_vkDestroySurfaceKHR vkDestroySurfaceKHR = reinterpret_cast<PFN_vkDestroySurfaceKHR>(vkGetInstanceProcAddr(_instance, "vkDestroySurfaceKHR"));
            vkDestroySurfaceKHR(_instance, p.second._surface, nullptr);
        }
    }

    void _finishInitWSI() {
        for (auto& p : _backbufferPools) {
            BackbufferPool& backbufferPool = p.second;
            if (backbufferPool._swapchain != VK_NULL_HANDLE) {
                continue;
            }

            backbufferPool._fencePool = &_fencePool;
            backbufferPool._semaphorePool = &_semaphorePool;

            std::vector<kvk::SwapchainPreference> swapchainPreferences = {
                {
                    .image_count = 3,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = backbufferPool._preferImmediate ? VK_PRESENT_MODE_IMMEDIATE_KHR : VK_PRESENT_MODE_MAILBOX_KHR,
                },
                {
                    .image_count = 3,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = backbufferPool._preferImmediate ? VK_PRESENT_MODE_IMMEDIATE_KHR : VK_PRESENT_MODE_MAILBOX_KHR,
                },
                {
                    .image_count = 2,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = backbufferPool._preferImmediate ? VK_PRESENT_MODE_IMMEDIATE_KHR : VK_PRESENT_MODE_MAILBOX_KHR,
                },
                {
                    .image_count = 2,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = backbufferPool._preferImmediate ? VK_PRESENT_MODE_IMMEDIATE_KHR : VK_PRESENT_MODE_MAILBOX_KHR,
                },
                {
                    .image_count = 3,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_RELAXED_KHR,
                },
                {
                    .image_count = 3,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_RELAXED_KHR,
                },
                {
                    .image_count = 2,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_RELAXED_KHR,
                },
                {
                    .image_count = 2,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_RELAXED_KHR,
                },
                {
                    .image_count = 3,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_KHR,
                },
                {
                    .image_count = 3,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_KHR,
                },
                {
                    .image_count = 2,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_R8G8B8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_KHR,
                },
                {
                    .image_count = 2,
                    .layer_count = 1,

                    .vk_surface_format = {
                        .format = VK_FORMAT_B8G8R8A8_SRGB,
                        .colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                    },
                    .vk_present_mode = VK_PRESENT_MODE_FIFO_KHR,
                },
            };

            kvk::SwapchainReturns swapchainReturns = {
                .vk_backbuffers = backbufferPool._backbuffers,
            };

            KRFW_VK_ERR(kvk::create_swapchain(_device, 
                {
                    .vk_physical_device = _physicalDevice,
                    .vk_surface = backbufferPool._surface,

                    .vk_image_usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT,

                    .preferences = swapchainPreferences,

                    .vk_image_sharing_mode = VK_SHARING_MODE_EXCLUSIVE,
                    .vk_queue_family_indices = {},

                    .vk_pre_transform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
                    .vk_composite_alpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
                    .vk_clipped = false,
                },
                swapchainReturns
            ), "Failed to create VkSwapchainKHR using kvk");

            backbufferPool._device = _device;
            backbufferPool._swapchain = swapchainReturns.vk_swapchain;
            backbufferPool._swapchainPreference = swapchainPreferences[swapchainReturns.chosen_preference];
            backbufferPool._lastKnownExtent = swapchainReturns.vk_current_extent;
            backbufferPool._backbufferViews.resize(backbufferPool._swapchainPreference.image_count);

            for (uint32_t i = 0; i < backbufferPool._swapchainPreference.image_count; ++i) {
                VkImageViewCreateInfo viewCI = {
                    .sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
                    .image = backbufferPool._backbuffers[i],
                    .viewType = VK_IMAGE_VIEW_TYPE_2D,
                    .format = backbufferPool._swapchainPreference.vk_surface_format.format,
                    .components = {
                        .r = VK_COMPONENT_SWIZZLE_IDENTITY,
                        .g = VK_COMPONENT_SWIZZLE_IDENTITY,
                        .b = VK_COMPONENT_SWIZZLE_IDENTITY,
                        .a = VK_COMPONENT_SWIZZLE_IDENTITY,
                    },
                    .subresourceRange = {
                        .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
                        .baseMipLevel = 0,
                        .levelCount = 1,
                        .baseArrayLayer = 0,
                        .layerCount = 1,
                    }
                };

                KRFW_VK_ERR(vkCreateImageView(_device, &viewCI, nullptr, &backbufferPool._backbufferViews[i]), "Failed to create image view for backbuffer");
            }
        }
    }

public:
    Renderer(bool debug = false) : _debug(debug), _fencePool(FencePool::invalid()), _semaphorePool(SemaphorePool::invalid()), _graphicsCommandPool(CommandPool::invalid()) {
        _initInstance();
    }

    void initWSI(SDL_Window* window, bool preferImmediate) {
        if (_backbufferPools.contains(window)) {
            return;
        }

        VkSurfaceKHR surface;
        if (!SDL_Vulkan_CreateSurface(window, _instance, nullptr, &surface)) {
            KRFW_ERR("Failed to create VkSurfaceKHR using SDL3");
        }

        _backbufferPools[window] = BackbufferPool(FencePool::invalid(), SemaphorePool::invalid(), surface, preferImmediate);

        if (_device != VK_NULL_HANDLE) {
            _finishInitWSI();
        }
    }

    void stage2() {
        _initDevice();

        _fencePool = FencePool(_device);
        _semaphorePool = SemaphorePool(_device);
        _graphicsCommandPool = CommandPool(_device, _graphicsQueue, _fencePool);

        _finishInitWSI();
    }

    void executeRenderPools(std::vector<IRenderPool*>& renderPools, SDL_Window* window) {
        VkCommandBuffer commandBuffer = _graphicsCommandPool.acquireCommandBuffer();
        if (window != nullptr && !_backbufferPools.contains(window)) {
            KRFW_ERR("No such window has been registered for renderer");
        }

        VkCommandBufferBeginInfo commandBufferBI = {
            .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        };

        KRFW_VK_ERR(vkBeginCommandBuffer(commandBuffer, &commandBufferBI), "Failed to begin command buffer");

        BackbufferPool* backbufferPool = {};
        Backbuffer backbuffer = {};

        VkPipelineStageFlags furthestBackbufferStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;

        RenderPoolBackbufferPacket backbufferPacket = {};
        backbufferPacket.lastLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        backbufferPacket.lastStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;

        std::vector<SubmitInfoWait> waits;
        std::vector<VkSemaphore> signals;
        for (IRenderPool* pool : renderPools) {
            RenderPoolPacket packet = {
                .instance = _instance,
                .device = _device,
                .physicalDevice = _physicalDevice,
                .fencePool = _fencePool,
                .semaphorePool = _semaphorePool,

                .commandBuffer = commandBuffer,

                .queue = _graphicsQueue,
            };

            backbufferPacket.backbuffer = backbuffer;

            if (pool->requiresBackbuffer() && window != nullptr) {
                if (backbufferPool == nullptr) {
                    backbufferPool = &_backbufferPools[window];
                    backbuffer = backbufferPool->acquireBackbuffer();
                }

                backbufferPacket.backbuffer = backbuffer;
                if (!pool->execute(packet, &backbufferPacket, waits, signals)) {
                    KRFW_ERR("Failed to execute render pool");
                }

                if (backbufferPacket.lastStage > furthestBackbufferStage) {
                    furthestBackbufferStage = backbufferPacket.lastStage;
                }
            } else {
                if (!pool->execute(packet, nullptr, waits, signals)) {
                    KRFW_ERR("Failed to execute render pool");
                }
            }
        }

        /* transition backbuffer for presentation */
        if (backbufferPool != nullptr) {
            VkImageMemoryBarrier backbufferBarrier = {
                .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                .srcAccessMask = {},
                .dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT,
                .oldLayout = backbufferPacket.lastLayout,
                .newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                .srcQueueFamilyIndex = _graphicsQueue.familyIndex,
                .dstQueueFamilyIndex = _graphicsQueue.familyIndex,
                .image = backbuffer.image,
                .subresourceRange = {
                    .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseMipLevel = 0,
                    .levelCount = 1,
                    .baseArrayLayer = 0,
                    .layerCount = backbuffer.layerCount,
                },
            };

            vkCmdPipelineBarrier(commandBuffer,
                backbufferPacket.lastStage, VK_PIPELINE_STAGE_TRANSFER_BIT, 0,
                0, nullptr,
                0, nullptr,
                1, &backbufferBarrier
            );
        }

        KRFW_VK_ERR(vkEndCommandBuffer(commandBuffer), "Failed to end command buffer");

        VkSemaphore backbufferFinishedSemaphore = {};
        if (backbufferPool != nullptr) {
            waits.push_back({
                .semaphore = backbuffer.semaphore,
                .dstStageMask = furthestBackbufferStage,
            });

            backbufferFinishedSemaphore = _semaphorePool.acquireSemaphore();
            signals.push_back(backbufferFinishedSemaphore);
        }

        VkFence submissionFence = _graphicsCommandPool.submitCommandBuffer(commandBuffer, waits, signals);

        VkFence presentationFinishedFence = {};
        std::vector<VkFence> waitFences = { submissionFence };
        if (backbufferPool != nullptr) {
            presentationFinishedFence = _fencePool.acquireFence(false);

            VkSwapchainPresentFenceInfoEXT spfi = {
                .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_FENCE_INFO_EXT,
                .swapchainCount = 1,
                .pFences = &presentationFinishedFence,
            };

            VkPresentInfoKHR pi = {
                .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
                .pNext = &spfi,
                .waitSemaphoreCount = 1,
                .pWaitSemaphores = &backbufferFinishedSemaphore,
                .swapchainCount = 1,
                .pSwapchains = &backbufferPool->_swapchain,
                .pImageIndices = &backbuffer.index,
                .pResults = nullptr,
            };

            PFN_vkQueuePresentKHR vkQueuePresentKHR = reinterpret_cast<PFN_vkQueuePresentKHR>(vkGetDeviceProcAddr(_device, "vkQueuePresentKHR"));
            KRFW_VK_ERR(vkQueuePresentKHR(_graphicsQueue.queue, &pi), "Failed to present backbuffer");
            waitFences.push_back(presentationFinishedFence);
        }

        vkWaitForFences(_device, static_cast<uint32_t>(waitFences.size()), waitFences.data(), true, std::numeric_limits<uint64_t>::max());
        vkResetFences(_device, static_cast<uint32_t>(waitFences.size()), &waitFences[0]);

        _graphicsCommandPool.releaseCommandBuffer(commandBuffer);
        _graphicsCommandPool.releaseSubmitFence(submissionFence);
        if (backbufferPool != nullptr) {
            _fencePool.releaseFence(presentationFinishedFence);
            _semaphorePool.releaseSemaphore(backbufferFinishedSemaphore);
            backbufferPool->releaseBackbuffer(backbuffer);
        }
    }

    #ifdef KRFW_IMGUI
    ImGui_ImplVulkan_InitInfo getImGuiImplVulkanInitInfo(SDL_Window* window) {
        BackbufferPool& chosenPool = _backbufferPools[window];
        return ImGui_ImplVulkan_InitInfo {
            .ApiVersion = VK_MAKE_API_VERSION(0, 1, 2, 197),
            .Instance = _instance,
            .PhysicalDevice = _physicalDevice,
            .Device = _device,
            .QueueFamily = _graphicsQueue.familyIndex,
            .Queue = _graphicsQueue.queue,
            .DescriptorPool = {},
            .DescriptorPoolSize = 1024,
            .MinImageCount = chosenPool._swapchainPreference.image_count,
            .ImageCount = chosenPool._swapchainPreference.image_count,
            .PipelineInfoMain = {
                .RenderPass = {},
                .Subpass = 0,
                .MSAASamples = VK_SAMPLE_COUNT_1_BIT,
                .PipelineRenderingCreateInfo = {
                    .sType = VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO_KHR,
                    .colorAttachmentCount = 1,
                    .pColorAttachmentFormats = &chosenPool._swapchainPreference.vk_surface_format.format,
                    .depthAttachmentFormat = VK_FORMAT_UNDEFINED,
                    .stencilAttachmentFormat = VK_FORMAT_UNDEFINED,
                },
            },
            .UseDynamicRendering = true,
            .Allocator = nullptr,
            .MinAllocationSize = 1024 * 1024,
        };
    }
    #endif

    ~Renderer() {
        if (_device != VK_NULL_HANDLE) {
            vkDeviceWaitIdle(_device);
        }

        _graphicsCommandPool.destroy();

        _cleanupWSI();

        _semaphorePool.destroy();
        _fencePool.destroy();

        _cleanupDevice();
        _cleanupInstance();
    }
};

}