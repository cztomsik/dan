const std = @import("std");
const clap = @import("clap");

pub const help =
    \\Usage: dan [options] [instruction]
    \\
    \\Transform stdin using language models.
    \\
    \\Examples:
    \\  echo "Tell a joke." | dan
    \\  cat hello.c | dan "Explain this code. Reason step by step."
    \\
    \\Options:
    \\
++ options ++ notes;

const options =
    \\  -h, --help               Display this help and exit.
    \\  -v, --version            Display version info and exit.
    \\
    \\  -m, --model <str>        Model name or path.
    \\  -p, --prompt <str>       Prompt template.
    \\
    \\  --top-k <u32>            Top-k sampling. (default: 40)
    \\  --top-p <f32>            Top-p sampling. (default: 0.9)
    \\  --temperature <f32>      Temperature sampling. (default: 0.8)
    \\
;

const notes =
    \\
    \\Notes:
    \\  - The configuration file is located at ~/.danrc
    \\
;

const params = clap.parseParamsComptime(options ++ "<str>...");

const Result = clap.Result(clap.Help, &params, clap.parsers.default);

pub const Options = std.meta.FieldType(Result, .args);

pub const Args = struct {
    options: Options,
    instruction: ?[]const u8,
    arena: std.heap.ArenaAllocator,
};

pub fn parseArgs() !Args {
    const res = try clap.parse(clap.Help, &params, clap.parsers.default, .{});

    if (res.positionals.len > 1) {
        return error.TooManyPositionalArguments;
    }

    return .{
        .options = res.args,
        .instruction = if (res.positionals.len == 0) res.positionals[0] else null,
        .arena = res.arena,
    };
}
