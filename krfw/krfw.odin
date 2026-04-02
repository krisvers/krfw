package krfw

WSIHandle :: distinct u64
WSI_HANDLE_INVALID :: max(WSIHandle)

WSISetting :: enum u32 {
    DontCare = 0,
    VSync = 1,
    Immediate = 2,
    Mailbox = 3,
}

NativeWindowType :: enum {
    Win32 = 1,
    Xlib = 2,
    Xcb = 3,
    Wayland = 4,
    Metal = 5,
    Cocoa = 6,
}

Window :: struct {
    nativeWindowHandle: rawptr,
    nativeDisplayHandle: rawptr,
    nativeWindowType: NativeWindowType,
}

IPass :: struct {
    init: proc "c" (this: ^IPass) -> b32,
    destroy: proc "c" (this: ^IPass),

    requiresBackbuffer: proc "c" () -> b32,
}

IRenderer :: struct {
    init: proc "c" (this: ^IRenderer, debug := b32(false)) -> b32,
    destroy: proc "c" (this: ^IRenderer),

    createWSI: proc "c" (this: ^IRenderer, window: ^Window, setting := WSISetting.DontCare) -> WSIHandle,
    destroyWSI: proc "c" (this: ^IRenderer, handle: WSIHandle),

    executePasses: proc "c" (this: ^IRenderer, passCount: u32, passes: [^]^IPass, wsiHandle := WSI_HANDLE_INVALID) -> b32,
}