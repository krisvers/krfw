#include "vulkan/vulkan_core.h"
#include <SDL3/SDL.h>
#include <vector>
#include <iostream>

#define IMGUI_IMPL_VULKAN_USE_LOADER
#define IMGUI_IMPL_VULKAN_NO_PROTOTYPES
#include "imgui.h"
#include "imgui_impl_sdl3.h"
#include "imgui_impl_vulkan.h"

#define VK_NO_PROTOTYPES
#include <vulkan/vulkan.h>

#include "krfw/krfw.h"
#include "krfw/vulkan/krfw_vulkan.h"

class ImGuiPass {
public:
    static KRFW_bool init(KRFW_IPass* self) {
        return true;
    }

    static void destroy(KRFW_IPass* self) {

    }

    static KRFW_bool requiresBackbuffer(KRFW_IPass* self) {
        return true;
    }

    static KRFW_bool execute(KRFW_Vulkan_Pass* self, KRFW_Vulkan_Packet* packet) {
        VkImageMemoryBarrier backbufferToColorAttachmentBarrier = {
            .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .srcAccessMask = {},
            .dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            .oldLayout = packet->backbufferPacket->lastLayout,
            .newLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            .srcQueueFamilyIndex = packet->queue->family,
            .dstQueueFamilyIndex = packet->queue->family,
            .image = packet->backbufferPacket->backbuffer->image,
            .subresourceRange = {
                .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = packet->backbufferPacket->backbuffer->layerCount,
            },
        };

        packet->device->functions.cmdPipelineBarrier(packet->commandBuffer,
            packet->backbufferPacket->lastStage,
            VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, {},
            0, nullptr,
            0, nullptr,
            1, &backbufferToColorAttachmentBarrier
        );

        packet->backbufferPacket->lastStage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

        VkRenderingAttachmentInfoKHR backbufferCAI = {
            .sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO_KHR,
            .imageView = packet->backbufferPacket->backbuffer->imageView,
            .imageLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = VK_ATTACHMENT_STORE_OP_STORE,
            .clearValue = {
                .color = {
                    .float32 = { 0.0f, 0.0f, 0.0f, 1.0f },
                },
            },
        };

        VkRenderingInfoKHR ri = {
            .sType = VK_STRUCTURE_TYPE_RENDERING_INFO_KHR,
            .renderArea = {
                .offset = {
                    .x = 0,
                    .y = 0,
                },
                .extent = packet->backbufferPacket->backbuffer->extent,
            },
            .layerCount = packet->backbufferPacket->backbuffer->layerCount,
            .viewMask = 0,
            .colorAttachmentCount = 1,
            .pColorAttachments = &backbufferCAI,
        };

        packet->device->functions.khr.dynamicRendering.cmdBeginRendering(packet->commandBuffer, &ri);
        ImGui_ImplVulkan_RenderDrawData(ImGui::GetDrawData(), packet->commandBuffer, VK_NULL_HANDLE);
        packet->device->functions.khr.dynamicRendering.cmdEndRendering(packet->commandBuffer);
        return true;
    }
};

void debugLogger(KRFW_DebugSeverity severity, uint32_t originLen, const char* origin, uint32_t messageLen, const char* message) {
    std::cout << "[" << severity << "] (" << origin << "): " << message << std::endl;
}

PFN_vkVoidFunction imguiVulkanLoader(const char* name, void* userData) {
    KRFW_Vulkan_Renderer* renderer = (KRFW_Vulkan_Renderer*) userData;
    return renderer->_instance.functions.getInstanceProcAddr(renderer->_instance.instance, name);
}

int main(int argc, char** argv) {
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("krfw demo", 1200, 800, SDL_WINDOW_VULKAN);
    if (window == nullptr) {
        return 1;
    }

    KRFW_Vulkan_Renderer renderer;
    krfwVulkanInstantiateRenderer(&renderer);
    
    renderer.setDebugLogger((KRFW_IRenderer*) &renderer, debugLogger, KRFW_DEBUG_SEVERITY_VERBOSE);

    KRFW_Window krfwWindow = {
        .nativeWindowHandle = reinterpret_cast<KRFW_NativeWindowHandle>(SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, nullptr)),
        .nativeWindowType = KRFW_NATIVE_WINDOW_TYPE_COCOA,
    };

    if (!renderer.createWSI((KRFW_IRenderer*) &renderer, &krfwWindow, KRFW_WSI_SETTING_DONT_CARE)) {
        return 1;
    }

    if (!renderer.init((KRFW_IRenderer*) &renderer, false, false, true)) {
        return 1;
    }

    if (ImGui::CreateContext() == nullptr) {
        return 1;
    }
    
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    if (!ImGui_ImplSDL3_InitForVulkan(window)) {
        return 1;
    }

    if (!ImGui_ImplVulkan_LoadFunctions(VK_API_VERSION_1_2, imguiVulkanLoader, &renderer)) {
        return 1;
    }

    VkFormat backbufferFormat = VK_FORMAT_B8G8R8A8_SRGB;
    ImGui_ImplVulkan_InitInfo imguiVulkanInitInfo = {
        .ApiVersion = VK_API_VERSION_1_2,
        .Instance = renderer._instance.instance,
        .PhysicalDevice = renderer._device.physical,
        .Device = renderer._device.logical,
        .QueueFamily = renderer._generalQueue->family,
        .Queue = renderer._generalQueue->queue,
        .DescriptorPool = VK_NULL_HANDLE,
        .DescriptorPoolSize = 1024,
        .MinImageCount = 3,
        .ImageCount = 3,
        .PipelineInfoMain = {
            .PipelineRenderingCreateInfo = {
                .sType = VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
                .colorAttachmentCount = 1,
                .pColorAttachmentFormats = &backbufferFormat,
            }
        },
        .UseDynamicRendering = true,
    };

    if (!ImGui_ImplVulkan_Init(&imguiVulkanInitInfo)) {
        return 1;
    }

    KRFW_Vulkan_Pass imguiPass = {
        .init = ImGuiPass::init,
        .destroy = ImGuiPass::destroy,
        .requiresBackbuffer = ImGuiPass::requiresBackbuffer,
        .execute = ImGuiPass::execute,
    };

    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            ImGui_ImplSDL3_ProcessEvent(&event);
            switch (event.type) {
            case SDL_EVENT_QUIT:
                running = false;
                break;
            default:
                break;
            }
        }
        
        if (!running) {
            break;
        }

        ImGui_ImplVulkan_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("Test");
        ImGui::End();

        ImGui::Render();

        const KRFW_IPass* passes = { (KRFW_IPass*) &imguiPass };
        if (!renderer.executePasses((KRFW_IRenderer*) &renderer, 1, &passes, &krfwWindow)) {
            std::cout << "Failed execute passes" << std::endl;
        }
    }

    ImGui_ImplVulkan_Shutdown();
    ImGui_ImplSDL3_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}