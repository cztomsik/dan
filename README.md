# DAN (do anything)

`dan` is a command-line interface tool that uses language models to perform transformations on standard input data.

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
  --temperature <f32>      Temperature sampling. (default: 0.8)

Notes:
  - If no instruction is given, dan will read from stdin.
  - Different models may work better with different prompt templates.
  - The configuration file is located at ~/.danrc
    see https://github.com/cztomsik/dan#configuration
```

## Installation

Follow these steps to install DAN:

- Download the binary file from the project's GitHub actions page: https://github.com/cztomsik/dan/actions
- Extract the binary file from the downloaded .zip file.
- Change the permissions of the binary file to make it executable: chmod +x dan
- Add the binary to your system PATH.

## Download models

We only support latest GGML formats. You can find some models here:
  - https://huggingface.co/TheBloke
  - https://www.reddit.com/r/LocalLLaMA/

## Configuration

**Optional:** You can create a `~/.danrc` with your custom defaults & preconfigured models:

```json
{
  "defaults": {
    "model": "name-of-the-default-model-or-path",
    "prompt": "USER: {instruction}{input}\nASSISTANT:",
  },

  "models": [
    {
      "name": "llama",
      "path": "/path/to/open-llama-xxx-ggml.bin"
    }
  ]
}
```

And then you can use the model by name (or even leave it in this case because we have default).

```bash
echo "Tell a joke." | dan -m ollama
```

## Build from source

If you want to build DAN from its source code, use the following commands:

```bash
# Clone the repository and its submodules
git clone https://github.com/cztomsik/dan
cd dan
git submodule update --init --recursive

# Build the project
zig build -Doptimize=ReleaseFast

# Run the program
./zig-out/bin/dan -h
```
