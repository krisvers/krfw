package krfw_vulkan

@(export, link_name="krfwVulkanInstantiateRenderer")
instantiateRenderer :: proc "c" (renderer: ^Renderer) {
    renderer^ = RENDERER
}