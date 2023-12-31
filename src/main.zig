const std = @import("std");
const cli = @import("cli.zig");
const cfg = @import("cfg.zig");
const llama = @import("llama.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.deinit();
    errdefer std.debug.print("Unexpected error\n", .{});

    // Parse CLI args
    var args = cli.parseArgs() catch return printHelp();
    defer args.arena.deinit();

    // Print help/version
    if (args.options.help > 0) return printHelp();
    if (args.options.version > 0) return printVersion();

    // Load config
    var arena = std.heap.ArenaAllocator.init(allocator);
    const config = try cfg.loadConfig(arena.allocator());
    defer arena.deinit();

    // Read input
    var input = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(input);

    // Apply model defaults
    if (args.options.model orelse config.defaults.model) |m| {
        if (config.findModelConfig(m)) |mc| {
            args.options.model = mc.path;
            applyDefaults(&args.options, mc.options);
        }

        // If not found, just use the model name as the path
    }

    // Apply global defaults
    applyDefaults(&args.options, config.defaults);

    // Check we have a model path
    const model_path = args.options.model orelse {
        try std.io.getStdErr().writeAll("Model path needs to be specified either in the config or as a CLI argument.\n");
        return error.NoModelPath;
    };

    // Prepare prompt
    const prompt = try preparePrompt(
        args.options.prompt orelse cfg.default_prompt,
        args.instruction orelse input,
        if (args.instruction != null) input else "",
    );
    defer allocator.free(prompt);

    // Print prompt in debug mode
    if (args.options.debug > 0) {
        try std.io.getStdOut().writeAll(prompt);
    }

    // Generate
    return run(
        model_path,
        prompt,
        args.options,
    );
}

fn printHelp() !void {
    return std.io.getStdOut().writeAll(cli.help);
}

fn printVersion() !void {
    return std.io.getStdOut().writeAll("dan " ++ @import("build_options").version ++ "\n");
}

fn applyDefaults(dest: *cli.Options, src: cli.Options) void {
    inline for (std.meta.fields(cli.Options)) |f| {
        if (f.type == u8) continue;

        if (@field(dest, f.name) == null) {
            @field(dest, f.name) = @field(src, f.name);
        }
    }
}

fn preparePrompt(
    template: []const u8,
    instruction: []const u8,
    input: []const u8,
) ![]const u8 {
    const temp = try std.mem.replaceOwned(u8, allocator, template, "{instruction}", instruction);
    defer allocator.free(temp);

    return std.mem.replaceOwned(u8, allocator, temp, "{input}", input);
}

fn run(
    model_path: []const u8,
    prompt: []const u8,
    options: cli.Options,
) !void {
    _ = options;

    if (prompt.len == 0) return error.EmptyPrompt;

    var cx = try llama.LlamaContext.init(allocator, model_path);
    defer cx.deinit();

    try cx.generate(
        prompt,
        std.io.getStdOut().writer(),
    );
}
