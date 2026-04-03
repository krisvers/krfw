package krfw

WSIHandle :: distinct u64

WSI_HANDLE_INVALID :: max(WSIHandle)

WSISetting :: enum u32 {
    DontCare    = 0,
    VSync       = 1,
    Immediate   = 2,
    Mailbox     = 3,
}

NativeWindowType :: enum {
    Win32   = 1,
    Xlib    = 2,
    Xcb     = 3,
    Wayland = 4,
    Metal   = 5,
    Cocoa   = 6,
}

Window :: struct {
    nativeWindowHandle:     rawptr,
    nativeDisplayHandle:    rawptr,
    nativeWindowType:       NativeWindowType,
}

IPass :: struct {
    using _: IPassVTable,
}

ProcIPassInit               :: #type proc "c" (this: ^IPass) -> b32
ProcIPassDestroy            :: #type proc "c" (this: ^IPass)
ProcIPassRequiresBackbuffer :: #type proc "c" () -> b32

IPassVTable :: struct {
    init:               ProcIPassInit,
    destroy:            ProcIPassDestroy,
    requiresBackbuffer: ProcIPassRequiresBackbuffer,
}

IRenderer :: struct {
    using _: IRendererVTable,
}

DebugSeverity :: enum i32 {
    Debug   = -2,
    Verbose = -1,
    Info    =  0,
    Warning =  1,
    Error   =  2,
    Fatal   =  3,
}

ProcDebugLogger :: #type proc "c" (severity: DebugSeverity, originLen: u32, origin: cstring, messageLen: u32, message: cstring)

ProcIRendererSetDebugLogger :: #type proc "c" (this: ^IRenderer, logger: ProcDebugLogger)
ProcIRendererInit           :: #type proc "c" (this: ^IRenderer, debug := b32(false)) -> b32
ProcIRendererDestroy        :: #type proc "c" (this: ^IRenderer)
ProcIRendererCreateWSI      :: #type proc "c" (this: ^IRenderer, window: ^Window, setting := WSISetting.DontCare) -> WSIHandle
ProcIRendererDestroyWSI     :: #type proc "c" (this: ^IRenderer, handle: WSIHandle)
ProcIRendererExecutePasses  :: #type proc "c" (this: ^IRenderer, passCount: u32, passes: [^]^IPass, wsiHandle := WSI_HANDLE_INVALID) -> b32

IRendererVTable :: struct {
    setDebugLogger: ProcIRendererSetDebugLogger,

    init:           ProcIRendererInit,
    destroy:        ProcIRendererDestroy,
    createWSI:      ProcIRendererCreateWSI,
    destroyWSI:     ProcIRendererDestroyWSI,
    executePasses:  ProcIRendererExecutePasses,
}