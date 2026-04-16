#ifndef KRFW_H
#define KRFW_H

#include <cstdint>
#ifdef __cplusplus
#warning  "Use krfw.hpp for C++ instead"
#endif

#include <stdint.h>

/* internal use only */
typedef struct KRFW_Odin_Allocator {
    void*   _procedure;
    void*   _data;
} KRFW_Odin_Allocator;

typedef struct KRFW_Odin_RawDynamicArray {
    void*               _data;
    int64_t             _len;
    int64_t             _cap;
    KRFW_Odin_Allocator _allocator;
} KRFW_Odin_RawDynamicArray;

typedef struct KRFW_Odin_RawSlice {
    void*   _data;
    int64_t _len;
} KRFW_Odin_RawSlice;

typedef struct KRFW_Odin_RawString {
    uint8_t*    _data;
    int64_t     _len;
} KRFW_Odin_RawString;

typedef struct KRFW_Odin_RawMap {
    uintptr_t           _data;
    uintptr_t           _len;
    KRFW_Odin_Allocator _allocator;
} KRFW_Odin_RawMap;

typedef struct KRFW_Odin_SourceCodeLocation {
    KRFW_Odin_RawString _filePath;
    int32_t             _line;
    int32_t             _column;
    KRFW_Odin_RawString _procedure;
} KRFW_Odin_SourceCodeLocation;

typedef struct KRFW_Odin_Logger {
    void*           _procedure;
    void*           _data;
    unsigned int    _lowestLevel;
    int64_t         _options;
} KRFW_Odin_Logger;

typedef struct KRFW_Odin_RandomGenerator {
    void*   _procedure;
    void*   _data;
} KRFW_Odin_RandomGenerator;

typedef struct KRFW_Odin_Context {
    KRFW_Odin_Allocator             _allocator;
    KRFW_Odin_Allocator             _tempAllocator;
    void*                           _assertionFailureProc;
    KRFW_Odin_Logger                _logger;
    KRFW_Odin_RandomGenerator       _randomGenerator;

    void*   _userPtr;
    int64_t _userIndex;

    void*   _internal;
} KRFW_Odin_Context;

/* basic typedefs */
typedef int32_t KRFW_bool;

#define KRFW_TRUE ((KRFW_bool) 1)
#define KRFW_FALSE ((KRFW_bool) 0)

typedef int32_t KRFW_DebugSeverity;
enum KRFW_DebugSeverity_Enum {
    KRFW_DEBUG_SEVERITY_VERBOSE = -1,
    KRFW_DEBUG_SEVERITY_INFO    =  0,
    KRFW_DEBUG_SEVERITY_WARNING =  1,
    KRFW_DEBUG_SEVERITY_ERROR   =  2,
    KRFW_DEBUG_SEVERITY_FATAL   =  3,
};

typedef int32_t KRFW_WSISetting;
enum KRFW_WSISetting_Enum {
    KRFW_WSI_SETTING_DONT_CARE  = 0,
    KRFW_WSI_SETTING_IMMEDIATE  = 1,
    KRFW_WSI_SETTING_VSYNC      = 2,
    KRFW_WSI_SETTING_MAILBOX    = 3,
};

typedef int32_t KRFW_NativeWindowType;
enum KRFW_NativeWindowType_Enum {
    KRFW_NATIVE_WINDOW_TYPE_WIN32   = 1,
    KRFW_NATIVE_WINDOW_TYPE_XLIB    = 2,
    KRFW_NATIVE_WINDOW_TYPE_XCB     = 3,
    KRFW_NATIVE_WINDOW_TYPE_WAYLAND = 4,
    KRFW_NATIVE_WINDOW_TYPE_METAL   = 5,
    KRFW_NATIVE_WINDOW_TYPE_COCOA   = 6,
};

typedef void* KRFW_NativeWindowHandle;
typedef void* KRFW_NativeDisplayHandle;

typedef struct KRFW_Window {
    KRFW_NativeWindowHandle     nativeWindowHandle;
    KRFW_NativeDisplayHandle    nativeDisplayHandle;
    KRFW_NativeWindowType       nativeWindowType;
} KRFW_Window;

typedef KRFW_bool   (*KRFW_ProcIPassInit)               (struct KRFW_IPass* self);
typedef void        (*KRFW_ProcIPassDestroy)            (struct KRFW_IPass* self);
typedef KRFW_bool   (*KRFW_ProcIPassRequiresBackbuffer) (struct KRFW_IPass* self);

typedef struct KRFW_IPass {
    KRFW_ProcIPassInit                  init;
    KRFW_ProcIPassDestroy               destroy;
    KRFW_ProcIPassRequiresBackbuffer    requiresBackbuffer;
} KRFW_IPass;

typedef void (*KRFW_ProcDebugLogger)(KRFW_DebugSeverity severity, uint32_t originLen, const char* origin, uint32_t messageLen, const char* message);

typedef void        (*KRFW_ProcIRendererSetDebugLogger) (struct KRFW_IRenderer* self, KRFW_ProcDebugLogger logger, KRFW_DebugSeverity lowestSeverity);
typedef KRFW_bool   (*KRFW_ProcIRendererInit)           (struct KRFW_IRenderer* self, KRFW_bool lowPower, KRFW_bool headless, KRFW_bool debug);
typedef void        (*KRFW_ProcIRendererDestroy)        (struct KRFW_IRenderer* self);
typedef KRFW_bool   (*KRFW_ProcIRendererCreateWSI)      (struct KRFW_IRenderer* self, const KRFW_Window* window, KRFW_WSISetting setting);
typedef void        (*KRFW_ProcIRendererDestroyWSI)     (struct KRFW_IRenderer* self, const KRFW_Window* window);
typedef KRFW_bool   (*KRFW_ProcIRendererExecutePasses)  (struct KRFW_IRenderer* self, uint32_t passCount, const KRFW_IPass** passes, const KRFW_Window* window);

typedef struct KRFW_IRenderer {
    KRFW_ProcIRendererSetDebugLogger    setDebugLogger;
    KRFW_ProcIRendererInit              init;
    KRFW_ProcIRendererDestroy           destroy;
    KRFW_ProcIRendererCreateWSI         createWSI;
    KRFW_ProcIRendererDestroyWSI        destroyWSI;
    KRFW_ProcIRendererExecutePasses     executePasses;
} KRFW_IRenderer;

#endif