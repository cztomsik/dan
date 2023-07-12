# DAN (do anything)

## Usage

```
Usage: dan [options] [instruction]

Transform stdin using language models.

Examples:
  echo "Tell a joke." | dan
  cat hello.c | dan "Explain this code. Reason step by step."

Options:
  -h, --help               Display this help and exit.
  -v, --version            Display version info and exit.

  -m, --model <str>        Model name or path.
  -p, --prompt <str>       Prompt template.

  --top-k <u32>            Top-k sampling. (default: 40)
  --top-p <f32>            Top-p sampling. (default: 0.9)
  --temp <f32>             Temperature sampling. (default: 0.8)
 
Notes:
  - The configuration file is located at ~/.danrc
```

## Install

- Download binary from https://github.com/cztomsik/dan/actions
- unzip, `chmod +x dan`, put it in your PATH

## Build from source

```bash
git clone https://github.com/cztomsik/dan
cd dan
git submodule update --init --recursive
zig build -Doptimize=ReleaseFast

./zig-out/bin/dan -h
```
