package krfw

import "kom"

VERSION_MAJOR :: 0
VERSION_MINOR :: 2

/* general types */
WSISetting :: enum i32 {
    DontCare    = 0,
    Immediate   = 1,
    VSync       = 2,
    Mailbox     = 3,
}

NativeWindowType :: enum i32 {
    Win32   = 1,
    Xlib    = 2,
    Xcb     = 3,
    Wayland = 4,
    Metal   = 5,
    Cocoa   = 6,
}

NativeWindowHandle  :: distinct rawptr
NativeDisplayHandle :: distinct rawptr

Window :: struct {
    nativeWindowHandle:     NativeWindowHandle,
    nativeDisplayHandle:    NativeDisplayHandle,
    nativeWindowType:       NativeWindowType,
}

DebugSeverity :: enum i32 {
    Verbose = -1,
    Info    =  0,
    Warning =  1,
    Error   =  2,
    Fatal   =  3,
}

ProcDebugLogger :: #type proc "c" (severity: DebugSeverity, originLen: u32, origin: cstring, messageLen: u32, message: cstring)

/* IPass (ecc60f45-33fd-4b53-8879-873e10f1d8f8) */
ProcIPassRequiresBackbuffer :: #type proc "c" (this: ^IPass) -> b32

IPass_IID :: kom.IID {
    0xec, 0xc6, 0x0f, 0x45,
    0x33, 0xfd,
    0x4b, 0x53,
    0x88, 0x79,
    0x87, 0x3e, 0x10, 0xf1, 0xd8, 0xf8
}

IPass :: struct {
    using ichild:        kom.IChild,

    requiresBackbuffer: ProcIPassRequiresBackbuffer,
}

/* IRenderer (eee9ef30-8735-4054-a4b4-1bbbe82701b3) */
ProcIRendererInit           :: #type proc "c" (this: ^IRenderer, lowPower := b32(false), headless := b32(false), debug := b32(false)) -> b32
ProcIRendererSetDebugLogger :: #type proc "c" (this: ^IRenderer, logger: ProcDebugLogger, lowestSeverity := DebugSeverity.Warning)
ProcIRendererCreateWSI      :: #type proc "c" (this: ^IRenderer, window: ^Window, setting := WSISetting.DontCare) -> b32
ProcIRendererDestroyWSI     :: #type proc "c" (this: ^IRenderer, window: ^Window)
ProcIRendererExecutePasses  :: #type proc "c" (this: ^IRenderer, passCount: u32, passes: [^]^IPass, window: ^Window) -> b32

IRenderer_IID :: kom.IID {
    0xee, 0xe9, 0xef, 0x30,
    0x87, 0x35,
    0x40, 0x54,
    0xa4, 0xb4,
    0x1b, 0xbb, 0xe8, 0x27, 0x01, 0xb3
}

IRenderer :: struct {
    using ibase:    kom.IBase,

    init:           ProcIRendererInit,
    setDebugLogger: ProcIRendererSetDebugLogger,
    createWSI:      ProcIRendererCreateWSI,
    destroyWSI:     ProcIRendererDestroyWSI,
    executePasses:  ProcIRendererExecutePasses,
}