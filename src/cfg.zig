const std = @import("std");
const cli = @import("cli.zig");

pub fn loadConfig(allocator: std.mem.Allocator) !std.json.Parsed(Config) {
    const contents = try readConfig(allocator);
    defer allocator.free(contents);

    return std.json.parseFromSlice(Config, allocator, contents, .{
        .allocate = .alloc_always,
    });
}

fn readConfig(allocator: std.mem.Allocator) ![]const u8 {
    const home = std.os.getenv("HOME") orelse return error.NoHome;

    const path = try std.fs.path.join(allocator, &.{ home, ".danrc" });
    defer allocator.free(path);

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    return file.readToEndAlloc(allocator, std.math.maxInt(usize));
}

pub const Config = struct {
    defaults: cli.Options = .{},
    models: []ModelConfig = &.{},

    pub fn getModelConfig(self: *const Config) *const ModelConfig {
        return &self.models[0];
    }
};

pub const ModelConfig = struct {
    name: []const u8,
    path: []const u8,
    options: cli.Options = .{},
};

// const default_prompt =
//     \\### System:
//     \\You are an AI assistant that follows instruction extremely well. Help as much as you can.
//     \\
//     \\### User:
//     \\{instruction}"
//     \\
//     \\### Input:
//     \\{input}"
//     \\
//     \\### Response:
// ;
