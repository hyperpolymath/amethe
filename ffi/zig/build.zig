// AMETHE — Zig Build Configuration
//
// This script defines the compilation pipeline for the Amethe FFI layer.
// It manages the generation of both shared and static libraries and 
// orchestrates the verified test suite.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // SHARED LIBRARY: For dynamic loading by Idris/Rust.
    const lib = b.addSharedLibrary(.{
        .name = "amethe",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // C COMPATIBILITY: Installs the generated header for Idris %foreign access.
    const header = b.addInstallHeader(b.path("include/amethe.h"), "amethe.h");
    b.getInstallStep().dependOn(&header.step);

    // TEST RUNNER: Unit tests integrated into the build tool.
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run kernel unit tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
}
