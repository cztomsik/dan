const std = @import("std");

const c = @cImport({
    @cInclude("llama.h");
});

pub const LlamaContext = struct {
    allocator: std.mem.Allocator,
    model: *c.llama_model,
    ctx: *c.llama_context,

    top_k: u32 = 40,
    top_p: f32 = 0.9,
    temperature: f32 = 0.8,

    tokens: []c.llama_token,
    candidates: []c.llama_token_data,

    pub fn init(allocator: std.mem.Allocator, model_path: []const u8) !LlamaContext {
        c.llama_backend_init(false);

        var params = c.llama_context_default_params();
        params.n_gpu_layers = 1;
        // params.n_ctx = 2048;

        // Try to load the model
        var c_path = try allocator.dupeZ(u8, model_path);
        defer allocator.free(c_path);
        var model = c.llama_load_model_from_file(c_path, params) orelse return error.InvalidModel;
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

    pub fn generate(self: *LlamaContext, input: []const u8, writer: anytype) !void {
        var c_input = try self.allocator.dupeZ(u8, input);
        defer self.allocator.free(c_input);

        var n_tokens = c.llama_tokenize(self.ctx, c_input, self.tokens.ptr, @intCast(self.tokens.len), true);

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

        if (self.temperature <= 0) {
            return c.llama_sample_token_greedy(self.ctx, &candidates);
        }

        c.llama_sample_top_k(self.ctx, &candidates, @intCast(self.top_k), 1);
        c.llama_sample_top_p(self.ctx, &candidates, self.top_p, 1);
        c.llama_sample_temperature(self.ctx, &candidates, self.temperature);

        return c.llama_sample_token(self.ctx, &candidates);
    }
};
