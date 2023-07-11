const std = @import("std");
const cli = @import("cli.zig");
const cfg = @import("cfg.zig");
const llama = @import("llama.zig");
const allocator = std.heap.c_allocator;

pub fn main() !void {
    const res = cli.parseArgs() catch return printHelp();
    defer res.deinit();

    if (res.args.help > 0 or res.positionals.len > 1) return printHelp();
    if (res.args.version > 0) return printVersion();

    const config = try cfg.loadConfig(allocator);
    defer config.deinit();

    const input = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(input);

    return run(
        &config.value,
        input,
        if (res.positionals.len == 1) res.positionals[0] else null,
        res.args,
    );
}

fn printHelp() !void {
    return std.io.getStdOut().writeAll(cli.help);
}

fn printVersion() !void {
    return std.io.getStdOut().writeAll("dan " ++ @import("build_options").version ++ "\n");
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
