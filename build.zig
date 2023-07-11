const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const options = b.addOptions();

    // TODO: git describe --tags
    const rev = b.exec(&.{ "git", "rev-parse", "--short", "HEAD" });
    options.addOption([]const u8, "version", rev);

    const exe = b.addExecutable(.{
        .name = "dan",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addOptions("build_options", options);
    exe.linkLibC();
    exe.linkLibCpp();
    exe.addIncludePath("llama.cpp");
    exe.addCSourceFiles(&.{
        "llama.cpp/ggml.c",
    }, &.{"-std=c11"});
    exe.addCSourceFiles(&.{
        "llama.cpp/llama.cpp",
    }, &.{"-std=c++11"});

    var clap = b.dependency("clap", .{ .target = target, .optimize = optimize });
    exe.addModule("clap", clap.module("clap"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
