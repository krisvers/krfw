project('krfw_demo', 'cpp', default_options: ['cpp_std=c++20'])

cc = meson.get_compiler('cpp')

libkrfw_vulkan = cc.find_library('krfw_vulkan', dirs: ['/Users/krisvers/Dev/krfw', '/Users/krisvers/Dev/krfw/build'])

krfw_vulkan = declare_dependency(
    include_directories: [include_directories('src/krfw')],
    dependencies: [libkrfw_vulkan],
)

sdl3_subproject = subproject('sdl3')
imgui_subproject = subproject('imgui')

vk = dependency('vulkan', version: '>=1.2.0', required: true)
sdl3 = dependency('sdl3', version: '>=3.0.0', required: true)
imgui = dependency('imgui', version: '>=1.92.5', required: true)


executable('demo',
    sources: ['src/demo.cpp'],
    dependencies: [vk, sdl3, imgui, krfw_vulkan],
    override_options: ['cpp_std=c++20'],
    c_args: ['-DIMGUI_IMPL_VULKAN_USE_LOADER', '-DIMGUI_IMPL_VULKAN_NO_PROTOTYPES']
)