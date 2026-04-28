package kom

import "core:encoding/uuid"

IID :: distinct uuid.Identifier

/* IBase (d183f36c-1864-4d73-9561-641e7dedb7bd) */
ProcIBaseRetain             :: #type proc "c" (this: ^IBase) -> u64
ProcIBaseRelease            :: #type proc "c" (this: ^IBase) -> u64
ProcIBaseQueryInterface     :: #type proc "c" (this: ^IBase, #by_ptr id: IID) -> rawptr

IBase_IID :: IID {
    0xd1, 0x83, 0xf3, 0x6c,
    0x18, 0x64,
    0x4d, 0x73,
    0x95, 0x61,
    0x64, 0x1e, 0x7d, 0xed, 0xb7, 0xbd
}

IBase :: struct {
    retain:             ProcIBaseRetain,
    release:            ProcIBaseRelease,
    queryInterface:     ProcIBaseQueryInterface,
}

/* auto-type cast helper */
queryInterface :: proc "odin" (base: ^IBase, #by_ptr id: IID, $T: typeid) -> ^T {
    return (^T)(base->queryInterface(id))
}

/* IChild (67382d73-ce34-4612-a01a-67fa1686e81d) */
ProcIChildGetParent :: #type proc "c" (this: ^IChild) -> ^IBase

IChild_IID :: IID {
    0x67, 0x38, 0x2d, 0x73,
    0xce, 0x34,
    0x46, 0x12,
    0xa0, 0x1a,
    0x67, 0xfa, 0x16, 0x86, 0xe8, 0x1d
}

IChild :: struct {
    using ibase:    IBase,

    getParent:      ProcIChildGetParent,
}

/* auto-type cast helper */
getParent :: proc "odin" (child: ^IChild, #by_ptr id: IID, $T: typeid) -> ^T {
    return queryInterface(child->getParent(), id, T)
}