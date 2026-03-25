#include "SDL3/SDL_events.h"
#include "SDL3/SDL_video.h"
#include <SDL3/SDL.h>
#include <vector>

#include "imgui.h"
#include "imgui_impl_sdl3.h"
#include "imgui_impl_vulkan.h"

#define KRFW_IMGUI
#include <krfw.h>

class ImGuiRenderPool : public krfw::IRenderPool {
public:
    bool requiresBackbuffer() override {
        return true;
    }

    bool execute(krfw::RenderPoolPacket const& packet, krfw::RenderPoolBackbufferPacket* backbufferPacket, std::vector<krfw::SubmitInfoWait>& waits, std::vector<VkSemaphore>& signals) override {
        VkImageMemoryBarrier backbufferToColorAttachmentBarrier = {
            .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .srcAccessMask = {},
            .dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            .oldLayout = backbufferPacket->lastLayout,
            .newLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            .srcQueueFamilyIndex = packet.queue.familyIndex,
            .dstQueueFamilyIndex = packet.queue.familyIndex,
            .image = backbufferPacket->backbuffer.image,
            .subresourceRange = {
                .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = backbufferPacket->backbuffer.layerCount,
            },
        };

        vkCmdPipelineBarrier(packet.commandBuffer,
            backbufferPacket->lastStage,
            VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, {},
            0, nullptr,
            0, nullptr,
            1, &backbufferToColorAttachmentBarrier
        );

        backbufferPacket->lastStage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

        PFN_vkCmdBeginRenderingKHR vkCmdBeginRenderingKHR = reinterpret_cast<PFN_vkCmdBeginRenderingKHR>(vkGetInstanceProcAddr(packet.instance, "vkCmdBeginRenderingKHR"));
        PFN_vkCmdEndRenderingKHR vkCmdEndRenderingKHR = reinterpret_cast<PFN_vkCmdEndRenderingKHR>(vkGetInstanceProcAddr(packet.instance, "vkCmdEndRenderingKHR"));

        VkRenderingAttachmentInfoKHR backbufferCAI = {
            .sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO_KHR,
            .imageView = backbufferPacket->backbuffer.imageView,
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
                .extent = backbufferPacket->backbuffer.extent,
            },
            .layerCount = backbufferPacket->backbuffer.layerCount,
            .viewMask = 0,
            .colorAttachmentCount = 1,
            .pColorAttachments = &backbufferCAI,
        };

        vkCmdBeginRenderingKHR(packet.commandBuffer, &ri);
        ImGui_ImplVulkan_RenderDrawData(ImGui::GetDrawData(), packet.commandBuffer, VK_NULL_HANDLE);
        vkCmdEndRenderingKHR(packet.commandBuffer);
        return true;
    }
};

int main(int argc, char** argv) {
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("krfw demo", 1200, 800, SDL_WINDOW_VULKAN);
    if (window == nullptr) {
        return 1;
    }

    krfw::Renderer renderer = krfw::Renderer(true);
    renderer.initWSI(window, false);
    renderer.stage2();

    if (ImGui::CreateContext() == nullptr) {
        return 1;
    }
    
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    if (!ImGui_ImplSDL3_InitForVulkan(window)) {
        return 1;
    }

    ImGui_ImplVulkan_InitInfo imguiVulkanInitInfo = renderer.getImGuiImplVulkanInitInfo(window);
    if (!ImGui_ImplVulkan_Init(&imguiVulkanInitInfo)) {
        return 1;
    }

    ImGuiRenderPool imguiRenderPool = ImGuiRenderPool();

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

        std::vector<krfw::IRenderPool*> renderPools = { &imguiRenderPool };
        renderer.executeRenderPools(renderPools, window);
    }

    ImGui_ImplVulkan_Shutdown();
    ImGui_ImplSDL3_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}