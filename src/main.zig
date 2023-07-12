const std = @import("std");
const cli = @import("cli.zig");
const cfg = @import("cfg.zig");
const llama = @import("llama.zig");
const allocator = std.heap.c_allocator;

pub fn main() !void {
    var args = cli.parseArgs() catch return printHelp();
    defer args.arena.deinit();

    if (args.options.help > 0) return printHelp();
    if (args.options.version > 0) return printVersion();

    const config = try cfg.loadConfig(allocator);
    defer config.deinit();

    const input = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(input);

    applyDefaults(&args.options, &config.value);

    return run(
        &config.value,
        input,
        args.instruction,
        args.options,
    );
}

fn printHelp() !void {
    return std.io.getStdOut().writeAll(cli.help);
}

fn printVersion() !void {
    return std.io.getStdOut().writeAll("dan " ++ @import("build_options").version ++ "\n");
}

fn applyDefaults(options: *cli.Options, config: *const cfg.Config) void {
    inline for (std.meta.fields(cli.Options)) |f| {
        if (f.type == u8) continue;

        if (@field(options, f.name) == null) {
            @field(options, f.name) = @field(config.defaults, f.name);
        }
    }
}

fn run(
    config: *const cfg.Config,
    input: []const u8,
    instruction: ?[]const u8,
    options: cli.Options,
) !void {
    _ = options;
    _ = instruction;

    const model_cfg = config.getModelConfig();

    var cx = try llama.LlamaContext.init(allocator, model_cfg.path);
    defer cx.deinit();

    try cx.generate(
        input,
        std.io.getStdOut().writer(),
    );
}
