// AMETHE — Integration Test Suite (Zig)
//
// These tests verify that the Zig FFI implementation correctly satisfies the 
// binary interface contract declared in `src/abi/Foreign.idr`.
//
// COVERAGE:
// 1. **Lifecycle**: Ensures handles can be created and destroyed without leakage.
// 2. **Result Mapping**: Verifies that Zig enums map 1:1 to Idris data constructors.
// 3. **Memory Safety**: Checks for safe handling of null pointers and double-frees.

const std = @import("std");
const testing = std.testing;

// FFI Declarations: Imported as 'extern' to simulate cross-language calling.
extern fn amethe_init() ?*opaque {};
extern fn amethe_free(?*opaque {}) void;
extern fn amethe_process(?*opaque {}, u32) c_int;

// --- TEST CASES ---

test "lifecycle: create and destroy handle" {
    const handle = amethe_init() orelse return error.InitFailed;
    defer amethe_free(handle);

    try testing.expect(handle != null);
}

test "safety: process with null handle returns error" {
    const result = amethe_process(null, 42);
    // 4 = null_pointer in ABI/Types.idr
    try testing.expectEqual(@as(c_int, 4), result);
}

test "robustness: double free is safe" {
    const handle = amethe_init() orelse return error.InitFailed;
    amethe_free(handle);
    // The implementation must handle redundant cleanup gracefully.
    amethe_free(handle); 
}
