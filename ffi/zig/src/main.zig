// AMETHE — Zig FFI Implementation
//
// This module implements the binary interface declared in the Idris ABI.
// It uses standard C conventions to ensure compatibility with both Idris 
// and Rust consumers.
//
// SAFETY: All memory allocated in this layer MUST be explicitly freed 
// via the `{{project}}_free*` functions.

const std = @import("std");

// VERSIONING: Authoritative build metadata.
const VERSION = "0.1.0";
const BUILD_INFO = "Amethe (Zig) - High-Assurance Storage Engine";

/// THREAD-LOCAL ERRORS: Stores the last error message for retrieval 
/// by the `last_error` FFI call.
threadlocal var last_error: ?[]const u8 = null;

//==============================================================================
// CORE TYPES: ABI-Stable Representations
//==============================================================================

/// RESULT CODES: Must match the `Result` type in `ABI/Types.idr`.
pub const Result = enum(c_int) {
    ok = 0,
    @"error" = 1,
    invalid_param = 2,
    out_of_memory = 3,
    null_pointer = 4,
};

/// OPAQUE HANDLE: Prevents Idris from inspecting the internal Zig state.
pub const Handle = opaque {
    allocator: std.mem.Allocator,
    initialized: bool,
    // Storage-specific fields would go here (e.g., file descriptors, buffers).
};

//==============================================================================
// LIFECYCLE: Resource Allocation & Deallocation
//==============================================================================

/// INITIALIZATION: Allocates the opaque handle on the C-compatible heap.
export fn amethe_init() ?*Handle {
    const allocator = std.heap.c_allocator;

    const handle = allocator.create(Handle) catch {
        last_error = "FFI: Out of memory during init";
        return null;
    };

    handle.* = .{
        .allocator = allocator,
        .initialized = true,
    };

    return handle;
}

/// CLEANUP: Safely destroys the handle and releases memory.
export fn amethe_free(handle: ?*Handle) void {
    const h = handle orelse return;
    const allocator = h.allocator;
    h.initialized = false;
    allocator.destroy(h);
}
