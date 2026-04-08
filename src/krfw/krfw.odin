package krfw

VERSION_MAJOR :: 0
VERSION_MINOR :: 1

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
    Verbose = -1,
    Info    =  0,
    Warning =  1,
    Error   =  2,
    Fatal   =  3,
}

ProcDebugLogger :: #type proc "c" (severity: DebugSeverity, originLen: u32, origin: cstring, messageLen: u32, message: cstring)

ProcIRendererSetDebugLogger :: #type proc "c" (this: ^IRenderer, logger: ProcDebugLogger, lowestSeverity := DebugSeverity.Warning)
ProcIRendererInit           :: #type proc "c" (this: ^IRenderer, lowPower := b32(false), headless := b32(false), debug := b32(false)) -> b32
ProcIRendererDestroy        :: #type proc "c" (this: ^IRenderer)
ProcIRendererCreateWSI      :: #type proc "c" (this: ^IRenderer, window: ^Window, setting := WSISetting.DontCare) -> b32
ProcIRendererDestroyWSI     :: #type proc "c" (this: ^IRenderer, window: ^Window)
ProcIRendererExecutePasses  :: #type proc "c" (this: ^IRenderer, passCount: u32, passes: [^]^IPass, window: ^Window) -> b32

IRendererVTable :: struct {
    setDebugLogger: ProcIRendererSetDebugLogger,

    init:           ProcIRendererInit,
    destroy:        ProcIRendererDestroy,
    createWSI:      ProcIRendererCreateWSI,
    destroyWSI:     ProcIRendererDestroyWSI,
    executePasses:  ProcIRendererExecutePasses,
}