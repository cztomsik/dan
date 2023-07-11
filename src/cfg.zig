const std = @import("std");

pub fn loadConfig(allocator: std.mem.Allocator) !std.json.Parsed(Config) {
    const home = std.os.getenv("HOME") orelse @panic("HOME not set");

    const path = try std.fs.path.join(allocator, &.{ home, ".danrc" });
    defer allocator.free(path);

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    return std.json.parseFromSlice(Config, allocator, contents, .{
        .allocate = .alloc_always,
    });
}

pub const Config = struct {
    models: []ModelConfig = &.{},

    pub fn getModelConfig(self: *const Config) *const ModelConfig {
        return &self.models[0];
    }
};

pub const ModelConfig = struct {
    name: []const u8,
    path: []const u8,
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
