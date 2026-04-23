package demo

import "base:builtin"
import "base:runtime"

import "core:c"
import "core:fmt"
import "core:mem"
import "core:unicode/utf16"
import "core:strings"

import krfw "krfw"
import krfw_vk "krfw/vulkan"

import vk "vendor:vulkan"
import "vendor:sdl3"
import "vendor:directx/dxc"

when ODIN_OS == .Windows {
    @(private) _convertCStringToWString :: proc(s: string) -> []c.wchar_t {
        wstring := make([]c.wchar_t, len(s) + 1)
        utf16.encode_string(wstring, s)
        wstring[len(s)] = 0
        return wstring
    }
} else {
    @(private) _convertCStringToWString :: proc(s: string) -> []c.wchar_t {
        wstring := make([]c.wchar_t, len(s) + 1)
        for i in 0..<len(s) {
            wstring[i] = c.wchar_t(s[i])
        }
        wstring[len(s)] = 0
        return wstring
    }
}

compileHLSL :: proc(renderer: ^krfw_vk.Renderer, utils: ^dxc.IUtils, compiler: ^dxc.ICompiler, source: cstring, entry_point: cstring, stage: vk.ShaderStageFlags) -> (module: vk.ShaderModule, result: vk.Result) {
    allocator := renderer->getAllocator()
    device := renderer->getDevice()
    assert(device != nil)

    blobEncoding: ^dxc.IBlobEncoding
    if utils->CreateBlob(rawptr(source), u32(len(source)), dxc.CP_UTF8, &blobEncoding) != 0 {
        return 0, .ERROR_UNKNOWN
    }
    defer blobEncoding->Release()

    wtarget := _convertCStringToWString("-T")
    wtargetValue: []c.wchar_t
    if .VERTEX in stage {
        wtargetValue = _convertCStringToWString("vs_6_0")
    } else if .FRAGMENT in stage {
        wtargetValue = _convertCStringToWString("ps_6_0")
    } else if .COMPUTE in stage {
        wtargetValue = _convertCStringToWString("cs_6_0")
    } else if .GEOMETRY in stage {
        wtargetValue = _convertCStringToWString("gs_6_0")
    } else if .TESSELLATION_CONTROL in stage {
        wtargetValue = _convertCStringToWString("hs_6_0")
    } else if .TESSELLATION_EVALUATION in stage {
        wtargetValue = _convertCStringToWString("ds_6_0")
    }

    wentry := _convertCStringToWString("-E")
    wentryValue := _convertCStringToWString(string(entry_point))

    wspirv := _convertCStringToWString("-spirv")
    wdebug := _convertCStringToWString("-Zi")

    defer {
        delete(wtarget)
        delete(wtargetValue)
        delete(wentry)
        delete(wentryValue)
        delete(wspirv)
        delete(wdebug)
    }

    arguments: [6]dxc.wstring
    arguments[0] = dxc.wstring(&wtarget[0])
    arguments[1] = dxc.wstring(&wtargetValue[0])
    arguments[2] = dxc.wstring(&wentry[0])
    arguments[3] = dxc.wstring(&wentryValue[0])
    arguments[4] = dxc.wstring(&wspirv[0])

    argumentCount := u32(5)

    when ODIN_DEBUG {
        arguments[argumentCount] = dxc.wstring(&wdebug[0])
        argumentCount += 1
    }

    dxcResult: ^dxc.IResult
    if compiler->Compile(
        blobEncoding,
        nil,
        dxc.wstring(&wentryValue[0]),
        dxc.wstring(&wtargetValue[0]),
        &arguments[0],
        argumentCount,
        nil,
        0,
        nil,
        (^^dxc.IOperationResult)(&dxcResult)
    ) != 0 {
        return 0, .ERROR_UNKNOWN
    }
    defer dxcResult->Release()

    handleErrorWithMsg := proc(dxcResult: ^dxc.IResult) {
        blob: ^dxc.IBlobEncoding
        if dxcResult->GetErrorBuffer(&blob) != 0 {
            fmt.println("DXC compilation failed (no error message available)")
            return
        }

        known: dxc.BOOL
        encoding: u32
        if blob->GetEncoding(&known, &encoding) != 0 || !known || encoding != dxc.CP_UTF8 && encoding != dxc.CP_UTF16 {
            fmt.println("DXC compilation failed (no error message available)")
            return
        }

        switch encoding {
            case dxc.CP_UTF8: fmt.printf("DXC compilation error: %s", strings.string_from_ptr(([^]u8)(blob->GetBufferPointer()), int(blob->GetBufferSize())))
            case dxc.CP_UTF16:
                st := make([]u8, blob->GetBufferSize() / 2)
                utf16.decode_to_utf8(st, ([^]u16)(blob->GetBufferPointer())[:blob->GetBufferSize() / 2])
                fmt.printf("DXC compilation error: %s", string(st))
                delete(st)
        }
    }

    dxcHResult: dxc.HRESULT
    dxcResult->GetStatus(&dxcHResult)
    if dxcHResult != 0 {
        handleErrorWithMsg(dxcResult)
        return 0, .ERROR_UNKNOWN
    }

    blob: ^dxc.IBlob
    if dxcResult->GetResult(&blob) != 0 {
        handleErrorWithMsg(dxcResult)
        return 0, .ERROR_UNKNOWN
    }

    if blob->GetBufferPointer() == nil || blob->GetBufferSize() == 0 {
        handleErrorWithMsg(dxcResult)
        return 0, .ERROR_UNKNOWN
    }

    size := int(blob->GetBufferSize())
    code := ([^]u32)(blob->GetBufferPointer())

    result = device.createShaderModule(device.logical, &{
        sType = .SHADER_MODULE_CREATE_INFO,
        codeSize = size,
        pCode = code
    }, allocator, &module)

    if result != .SUCCESS {
        return 0, result
    }

    return module, .SUCCESS
}

pushDebugLabel :: proc(renderer: ^krfw_vk.Renderer, commandBuffer: vk.CommandBuffer, color: [4]f32, format: string, args: ..any) {
    if renderer._instance.ext.debugUtils.cmdBeginDebugUtilsLabel != nil {
        labelName := fmt.ctprintf(format, ..args)
        defer delete(labelName, context.temp_allocator)

        renderer._instance.ext.debugUtils.cmdBeginDebugUtilsLabel(commandBuffer, &{
            sType = .DEBUG_UTILS_LABEL_EXT,
            pLabelName = labelName,
            color = color,
        })
    }
}

popDebugLabel :: proc(renderer: ^krfw_vk.Renderer, commandBuffer: vk.CommandBuffer) {
    if renderer._instance.ext.debugUtils.cmdEndDebugUtilsLabel != nil {
        renderer._instance.ext.debugUtils.cmdEndDebugUtilsLabel(commandBuffer)
    }
}

HelloWorldPass :: struct {
    using vk_pass:  krfw_vk.Pass,

    _ctx:               runtime.Context,
    _renderer:          ^krfw_vk.Renderer,
    _vertexDataSize:    vk.DeviceSize,
    _indexDataSize:     vk.DeviceSize,
    _uploadBuffer:      krfw_vk.Buffer,
    _privateBuffer:     krfw_vk.Buffer,

    _vertexShader:      vk.ShaderModule,
    _fragmentShader:    vk.ShaderModule,

    _descriptorLayout:  vk.DescriptorSetLayout,
    _pipelineLayout:    vk.PipelineLayout,
    _pipeline:          vk.Pipeline,
}

instantiateHelloWorldPass :: proc(pass: ^HelloWorldPass, renderer: ^krfw_vk.Renderer) {
    assert(pass != nil)
    assert(renderer != nil)

    pass^ = {
        init = krfw.ProcIPassInit(proc "c" (this: ^HelloWorldPass) -> b32 {
            context = this._ctx

            instance := this._renderer->getInstance()
            assert(instance != nil)

            device := this._renderer->getDevice()
            assert(device != nil)

            allocator := this._renderer->getAllocator()

            vertexData := []f32 {
                -0.5, -0.5,
                 0.5, -0.5,
                 0.0,  0.5,
            }

            this._vertexDataSize = vk.DeviceSize(size_of(vertexData[0]) * len(vertexData))

            indexData := []u32 {
                0, 1, 2,
            }
            
            this._indexDataSize = vk.DeviceSize(size_of(indexData[0]) * len(indexData))

            if !this._renderer->getDefaultResourcePool()->createBuffer(&this._uploadBuffer, &{
                sType       = .BUFFER_CREATE_INFO,
                size        = this._vertexDataSize + this._indexDataSize,
                usage       = { .TRANSFER_SRC },
                sharingMode = .EXCLUSIVE,
            }, &{
                flags = { .Mapped },
                usage = .Cpu_To_Gpu,
            }) {
                return false
            }

            if !this._renderer->getDefaultResourcePool()->createBuffer(&this._privateBuffer, &{
                sType       = .BUFFER_CREATE_INFO,
                size        = this._vertexDataSize + this._indexDataSize,
                usage       = { .VERTEX_BUFFER, .INDEX_BUFFER, .TRANSFER_DST },
                sharingMode = .EXCLUSIVE,
            }, &{
                usage = .Gpu_Only,
            }) {
                return false
            }

            uploadMapped := (^u8)(this._uploadBuffer->mapResource())
            assert(uploadMapped != nil)

            mem.copy_non_overlapping(uploadMapped, &vertexData[0], int(this._vertexDataSize))
            mem.copy_non_overlapping(mem.ptr_offset(uploadMapped, this._vertexDataSize), &indexData[0], int(this._indexDataSize))

            transferCommandPool := this._renderer->getDefaultCommandPool(.Transfer)
            transferCommandBuffer := transferCommandPool->acquire()
            assert(transferCommandBuffer != nil)

            assert(device.beginCommandBuffer(transferCommandBuffer, &{
                sType = .COMMAND_BUFFER_BEGIN_INFO,
            }) == .SUCCESS)

            device.cmdCopyBuffer(transferCommandBuffer, this._uploadBuffer->getVulkanBuffer(), this._privateBuffer->getVulkanBuffer(), 1, &vk.BufferCopy {
                srcOffset = 0,
                dstOffset = 0,
                size = this._vertexDataSize + this._indexDataSize,
            })

            assert(device.endCommandBuffer(transferCommandBuffer) == .SUCCESS)

            transferFence := transferCommandPool->submit(transferCommandBuffer, 0, nil, 0, nil)
            assert(transferFence != 0)

            assert(device.waitForFences(device.logical, 1, &transferFence, true, max(u64)) == .SUCCESS)
            transferCommandPool->release(transferCommandBuffer, transferFence)

            if device.createDescriptorSetLayout(device.logical, &{
                sType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
                bindingCount = 0,
                pBindings = nil,
            }, allocator, &this._descriptorLayout) != .SUCCESS {
                return false
            }

            if device.createPipelineLayout(device.logical, &{
                sType = .PIPELINE_LAYOUT_CREATE_INFO,
                setLayoutCount = 1,
                pSetLayouts = &this._descriptorLayout,
            }, allocator, &this._pipelineLayout) != .SUCCESS {
                return false
            }

            shaderSource :: `
                struct VertexInput {
                    [[vk::location(0)]]
                    float2 position : POSITION;
                };

                struct VertexOutput {
                    float4 position : SV_Position;
                };

                VertexOutput vsmain(VertexInput vin) {
                    VertexOutput vout;
                    vout.position = float4(vin.position, 0.0, 1.0);
                    return vout;
                }

                struct FragmentOutput {
                    float4 color : SV_Target0;
                };

                FragmentOutput fsmain(VertexOutput vout) {
                    FragmentOutput fout;
                    fout.color = float4(1.0, 0.0, 1.0, 1.0);
                    return fout;
                }
            `

            utils: ^dxc.IUtils
            if dxc.CreateInstance(dxc.Utils_CLSID, dxc.IUtils_UUID, &utils) != 0 {
                return false
            }
            defer utils->Release()

            compiler: ^dxc.ICompiler
            if dxc.CreateInstance(dxc.Compiler_CLSID, dxc.ICompiler_UUID, &compiler) != 0 {
                return false
            }
            defer compiler->Release()

            result: vk.Result
            this._vertexShader, result = compileHLSL(this._renderer, utils, compiler, shaderSource, "vsmain", { .VERTEX })
            if result != .SUCCESS {
                return false
            }

            this._fragmentShader, result = compileHLSL(this._renderer, utils, compiler, shaderSource, "fsmain", { .FRAGMENT })
            if result != .SUCCESS {
                return false
            }

            return true
        }),

        destroy = krfw.ProcIPassDestroy(proc "c" (this: ^HelloWorldPass) {
            context = this._ctx

            device := this._renderer->getDevice()
            assert(device != nil)
            
            allocator := this._renderer->getAllocator()

            device.deviceWaitIdle(device.logical)

            device.destroyPipeline(device.logical, this._pipeline, allocator)
            device.destroyPipelineLayout(device.logical, this._pipelineLayout, allocator)
            device.destroyDescriptorSetLayout(device.logical, this._descriptorLayout, allocator)

            device.destroyShaderModule(device.logical, this._fragmentShader, allocator)
            device.destroyShaderModule(device.logical, this._vertexShader, allocator)
            
            this._privateBuffer->destroy()
            this._uploadBuffer->destroy()
        }),

        requiresBackbuffer = krfw.ProcIPassRequiresBackbuffer(proc "c" (this: ^HelloWorldPass) -> b32 {
            context = this._ctx

            return true
        }),

        execute = krfw_vk.ProcPassExecute(proc "c" (this: ^HelloWorldPass, packet: ^krfw_vk.Packet) -> b32 {
            context = this._ctx

            device := packet.renderer->getDevice()
            allocator := packet.renderer->getAllocator()

            if this._pipeline == 0 {
                pipelineShaderStageCIs := [2]vk.PipelineShaderStageCreateInfo {
                    {
                        sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
                        stage = { .VERTEX },
                        module = this._vertexShader,
                        pName = "vsmain",
                    },
                    {
                        sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
                        stage = { .FRAGMENT },
                        module = this._fragmentShader,
                        pName = "fsmain",
                    },
                }

                pipelineDynamicStates := [2]vk.DynamicState {
                    .VIEWPORT,
                    .SCISSOR,
                }

                if device.createGraphicsPipelines(device.logical, 0, 1, &vk.GraphicsPipelineCreateInfo {
                    sType = .GRAPHICS_PIPELINE_CREATE_INFO,
                    pNext = &vk.PipelineRenderingCreateInfoKHR {
                        sType = .PIPELINE_RENDERING_CREATE_INFO_KHR,
                        colorAttachmentCount = 1,
                        pColorAttachmentFormats = &packet.backbufferPacket.backbuffer.surfaceFormat.format,
                    },
                    stageCount = u32(len(pipelineShaderStageCIs)),
                    pStages = &pipelineShaderStageCIs[0],
                    pVertexInputState = &{
                        sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
                        vertexBindingDescriptionCount = 1,
                        pVertexBindingDescriptions = &vk.VertexInputBindingDescription {
                            binding = 0,
                            stride = size_of(f32) * 2,
                            inputRate = .VERTEX,
                        },
                        vertexAttributeDescriptionCount = 1,
                        pVertexAttributeDescriptions = &vk.VertexInputAttributeDescription {
                            location = 0,
                            binding = 0,
                            format = .R32G32_SFLOAT,
                            offset = 0,
                        },
                    },
                    pInputAssemblyState = &{
                        sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                        topology = .TRIANGLE_LIST,
                    },
                    pViewportState = &{
                        sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
                        viewportCount = 1,
                        pViewports = nil,
                        scissorCount = 1,
                        pScissors = nil,
                    },
                    pRasterizationState = &{
                        sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
                        polygonMode = .FILL,
                        cullMode = {},
                        frontFace = .COUNTER_CLOCKWISE,
                        lineWidth = 1.0,
                    },
                    pMultisampleState = &{
                        sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
                        rasterizationSamples = { ._1 },
                    },
                    pColorBlendState = &{
                        sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                        attachmentCount = 1,
                        pAttachments = &vk.PipelineColorBlendAttachmentState {
                            blendEnable = false,
                            colorWriteMask = { .R, .G, .B, .A },
                        },
                    },
                    pDynamicState = &{
                        sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
                        dynamicStateCount = u32(len(pipelineDynamicStates)),
                        pDynamicStates = &pipelineDynamicStates[0],
                    },
                    layout = this._pipelineLayout,
                }, allocator, &this._pipeline) != .SUCCESS {
                    return false
                }
            }

            pushDebugLabel(this._renderer, packet.commandBuffer, { 0.88, 0.24, 0.24, 1.0 }, "Hello World Pass")
            defer popDebugLabel(this._renderer, packet.commandBuffer)

            device.cmdPipelineBarrier(packet.commandBuffer,
                packet.backbufferPacket.lastStage,
                { .COLOR_ATTACHMENT_OUTPUT }, {},
                0, nil,
                0, nil,
                1, &vk.ImageMemoryBarrier {
                    sType = .IMAGE_MEMORY_BARRIER,
                    srcAccessMask = {},
                    dstAccessMask = { .COLOR_ATTACHMENT_WRITE },
                    oldLayout = packet.backbufferPacket.backbuffer.image->getLayout(),
                    newLayout = .COLOR_ATTACHMENT_OPTIMAL,
                    srcQueueFamilyIndex = packet.queue.family,
                    dstQueueFamilyIndex = packet.queue.family,
                    image = packet.backbufferPacket.backbuffer.image->getVulkanImage(),
                    subresourceRange = {
                        aspectMask = { .COLOR },
                        baseMipLevel = 0,
                        levelCount = 1,
                        baseArrayLayer = 0,
                        layerCount = packet.backbufferPacket.backbuffer.layerCount,
                    },
                },
            )

            packet.backbufferPacket.lastStage = { .COLOR_ATTACHMENT_OUTPUT }
            packet.backbufferPacket.backbuffer.image->setLayout(.COLOR_ATTACHMENT_OPTIMAL)

            device.khr.dynamicRendering.cmdBeginRendering(packet.commandBuffer, &{
                sType = .RENDERING_INFO_KHR,
                renderArea = {
                    offset = {
                        x = 0,
                        y = 0,
                    },
                    extent = packet.backbufferPacket.backbuffer.extent,
                },
                layerCount = packet.backbufferPacket.backbuffer.layerCount,
                colorAttachmentCount = 1,
                pColorAttachments = &vk.RenderingAttachmentInfoKHR {
                    sType = .RENDERING_ATTACHMENT_INFO_KHR,
                    imageView = packet.backbufferPacket.backbuffer.imageView,
                    imageLayout = packet.backbufferPacket.backbuffer.image->getLayout(),
                    loadOp = .CLEAR,
                    storeOp = .STORE,
                    clearValue = {
                        color = {
                            float32 = {
                                0.0, 0.0, 0.0, 1.0,
                            },
                        },
                    },
                },
            })

            device.cmdBindPipeline(packet.commandBuffer, .GRAPHICS, this._pipeline)

            device.cmdSetViewport(packet.commandBuffer, 0, 1, &vk.Viewport {
                x = 0.0,
                y = f32(packet.backbufferPacket.backbuffer.extent.height),
                width = f32(packet.backbufferPacket.backbuffer.extent.width),
                height = -f32(packet.backbufferPacket.backbuffer.extent.height),
                minDepth = 0.0,
                maxDepth = 1.0,
            })

            device.cmdSetScissor(packet.commandBuffer, 0, 1, &vk.Rect2D {
                offset = {
                    x = 0,
                    y = 0,
                },
                extent = packet.backbufferPacket.backbuffer.extent,
            })

            offset := vk.DeviceSize(0)
            vertexBuffers := [?]vk.Buffer { this._privateBuffer->getVulkanBuffer() }
            device.cmdBindVertexBuffers(packet.commandBuffer, 0, u32(len(vertexBuffers)), &vertexBuffers[0], &offset)
            device.cmdBindIndexBuffer(packet.commandBuffer, this._privateBuffer->getVulkanBuffer(), this._vertexDataSize, .UINT32)
            device.cmdDrawIndexed(packet.commandBuffer, 3, 1, 0, 0, 0)

            device.khr.dynamicRendering.cmdEndRendering(packet.commandBuffer)

            return true
        }),
        
        _ctx = context,
        _renderer = renderer,
    }
}

main :: proc() {
    if !sdl3.Init({ .VIDEO }) {
        panic("SDL3 Init")
    }

    window := sdl3.CreateWindow("krfw demo", 800, 600, {})
    if window == nil {
        panic("SDL3 window creation")
    }

    krfwWindow := getKRFWWindow(window)

    renderer: krfw_vk.Renderer
    krfw_vk.instantiateRenderer(&renderer)

    renderer->setDebugLogger(proc "c" (severity: krfw.DebugSeverity, originLen: u32, origin: cstring, messageLen: u32, message: cstring) {
        context = runtime.default_context()
        fmt.printfln("[%s] (%s): %s", severity, origin, message)
    }, krfw.DebugSeverity.Verbose)

    if !renderer->createWSI(&krfwWindow, .Mailbox) {
        panic("Renderer create WSI")
    }

    if !renderer->init(debug = true) {
        panic("Failed to initialize renderer")
    }

    helloWorldPass: HelloWorldPass
    instantiateHelloWorldPass(&helloWorldPass, &renderer)

    if !helloWorldPass->init() {
        panic("fuck")
    }

    running := true
    for running {
        event: sdl3.Event
        for sdl3.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    running = false
            }
        }

        passes := []^krfw.IPass { &helloWorldPass }
        if !renderer->executePasses(u32(len(passes)), &passes[0], &krfwWindow) {
            panic("shit")
        }
    }

    helloWorldPass->destroy()
    renderer->destroyWSI(&krfwWindow)
    renderer->destroy()
}