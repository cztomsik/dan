const std = @import("std");

const c = @cImport({
    @cInclude("llama.h");
});

pub const LlamaContext = struct {
    allocator: std.mem.Allocator,
    model: *c.llama_model,
    ctx: *c.llama_context,
    tokens: []c.llama_token,
    candidates: []c.llama_token_data,

    pub fn init(allocator: std.mem.Allocator) !LlamaContext {
        c.llama_init_backend(false);

        var params = c.llama_context_default_params();

        // Try to load the model
        var model = c.llama_load_model_from_file("/Users/cztomsik/Downloads/orca-mini-7b.ggmlv3.q4_0.bin", params) orelse return error.InvalidModel;
        errdefer c.llama_free_model(model);

        // Create a context
        var ctx = c.llama_new_context_with_model(model, params) orelse return error.UnexpectedError;
        errdefer c.llama_free(ctx);

        // Prepare buffers
        var tokens = try allocator.alloc(c.llama_token, @intCast(c.llama_n_ctx(ctx)));
        errdefer allocator.free(tokens);
        var candidates = try allocator.alloc(c.llama_token_data, @intCast(c.llama_n_vocab(ctx)));
        errdefer allocator.free(candidates);

        return .{
            .allocator = allocator,
            .model = model,
            .ctx = ctx,
            .tokens = tokens,
            .candidates = candidates,
        };
    }

    pub fn deinit(self: *LlamaContext) void {
        c.llama_free(self.ctx);
        c.llama_free_model(self.model);

        self.allocator.free(self.tokens);
        self.allocator.free(self.candidates);
    }

    pub fn generate(self: *LlamaContext, input: [*c]const u8, writer: anytype) !void {
        var n_tokens = c.llama_tokenize(self.ctx, input, self.tokens.ptr, @intCast(self.tokens.len), true);

        if (n_tokens < 0) {
            return error.TooManyTokens;
        }

        while (c.llama_get_kv_cache_token_count(self.ctx) < c.llama_n_ctx(self.ctx)) {
            if (c.llama_eval(
                self.ctx,
                self.tokens.ptr,
                n_tokens,
                c.llama_get_kv_cache_token_count(self.ctx),
                4,
            ) > 0) {
                return error.FailedToEval;
            }

            const token = self.sample_token();

            if (token == c.llama_token_eos()) {
                return;
            }

            try writer.writeAll(std.mem.span(c.llama_token_to_str(self.ctx, token)));

            // continue with the new token
            self.tokens[0] = token;
            n_tokens = 1;
        }
    }

    fn sample_token(self: *LlamaContext) c.llama_token {
        var logits = c.llama_get_logits(self.ctx);

        for (self.candidates, 0..) |*candidate, i| {
            candidate.* = .{
                .id = @intCast(i),
                .logit = logits[i],
                .p = 0,
            };
        }

        var candidates: c.llama_token_data_array = .{
            .data = self.candidates.ptr,
            .size = self.candidates.len,
            .sorted = false,
        };

        return c.llama_sample_token_greedy(self.ctx, &candidates);
    }
};
