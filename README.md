# NemoClaw VPS - GPU-Accelerated AI Agent Framework

A GPU-accelerated AI agent framework that connects to **any LLM provider** - local (Ollama, LM Studio) or cloud (OpenAI, Anthropic, Groq). Deploy on any VPS with optional GPU acceleration.

## Key Features

- **Any LLM Provider** - OpenAI, Anthropic, Ollama, Groq, LM Studio, or custom
- **GPU Acceleration** - NVIDIA CUDA, AMD ROCm, Intel GPU, or CPU-only
- **One-Line Install** - Deploy on any server with a single curl command
- **Sandboxed Execution** - Secure AI agent with tool isolation
- **Flexible Access** - Tailscale VPN, Cloudflare Tunnel, or direct access

## Supported LLM Providers

| Provider | Type | GPU Support | API Key |
|----------|------|-------------|---------|
| **Ollama** | Local (free) | Yes | None |
| **OpenAI** | Cloud | No | Required |
| **Anthropic** | Cloud | No | Required |
| **Groq** | Cloud (fast) | No | Optional |
| **LM Studio** | Local | Yes | None |
| **Custom** | Any OpenAI-compatible | Depends | Optional |

## Quick Start

### Interactive Setup

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash
```

---

## LLM Provider Setup

### Ollama (Local, Free)

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --llm-provider ollama --llm-model llama3.2 --gpu-mode nvidia
```

Popular models:
- `llama3.2` - General purpose, fast
- `llama3.2:70b` - Most capable
- `mistral` - Good balance
- `codellama` - Optimized for code
- `deepseek-coder` - Best for coding

### OpenAI (GPT-4, GPT-4o)

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --llm-provider openai --llm-api-key sk-xxxx --llm-model gpt-4o
```

### Anthropic (Claude 3.5 Sonnet)

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --llm-provider anthropic --llm-api-key sk-ant-xxxx --llm-model claude-3-5-sonnet-latest
```

### Groq (Fast Cloud Inference)

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --llm-provider groq --llm-api-key gsk_xxxx --llm-model llama-3.1-70b-versatile
```

Free tier available with `llama-3.1-8b-instant`.

### LM Studio (Local)

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --llm-provider lmstudio --llm-endpoint http://localhost:1234/v1 --llm-model llama-3.2-3b-instruct
```

---

## GPU Modes

| Mode | Performance | VRAM | Best For |
|------|-------------|------|----------|
| **NVIDIA** | Best | 8GB+ | Local models, fast inference |
| **AMD** | Best | 8GB+ | RX 7900 XT/XTX |
| **Intel** | Good | 4GB+ | Arc GPUs, Xeon |
| **CPU** | Slow | 16GB+ RAM | Testing, budget |

---

## All Options

| Option | Description |
|--------|-------------|
| `--llm-provider` | Provider: ollama, openai, anthropic, groq, lmstudio, custom |
| `--llm-api-key` | API key for the provider |
| `--llm-model` | Model name (default varies by provider) |
| `--llm-endpoint` | Custom endpoint URL for proxies |
| `--gpu-mode` | nvidia, amd, intel, cpu (default: nvidia) |
| `--domain` | Your domain name |
| `--admin-user` | Admin username (default: admin) |
| `--admin-pass` | Admin password (auto-generated if not set) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NEMOCLAW VPS                                  │
│                                                                │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐  │
│  │   Nginx    │───►│  NemoClaw   │───►│  LLM Provider   │  │
│  │  TLS/HTTPS │    │  AI Agent   │    │  (Any of these) │  │
│  └─────────────┘    └──────────────┘    └─────────────────┘  │
│                           │                    │                 │
│                    ┌──────▼──────┐     ┌─────▼─────┐        │
│                    │   Sandbox   │     │  Ollama   │        │
│                    │  Execution  │     │  (local)  │        │
│                    └─────────────┘     └───────────┘        │
└─────────────────────────────────────────────────────────────┘
```

**LLM Providers:**
- OpenAI: GPT-4, GPT-4o, GPT-4o-mini
- Anthropic: Claude 3.5 Sonnet, Claude 3 Opus
- Groq: llama-3.1-70b, mixtral-8x7b
- Ollama: llama3.2, mistral, codellama (local)
- LM Studio: Any GGUF model (local)

---

## Management Commands

```bash
# View logs
docker-compose -f /opt/nemoclaw/docker-compose.yml logs -f

# Stop services
docker-compose -f /opt/nemoclaw/docker-compose.yml down

# Restart services
docker-compose -f /opt/nemoclaw/docker-compose.yml restart

# Ollama models (if using Ollama)
docker-compose -f /opt/nemoclaw/docker-compose.yml --profile ollama up -d
```

---

## API Keys

Get your API keys from:
- **OpenAI:** https://platform.openai.com/api-keys
- **Anthropic:** https://console.anthropic.com/settings/keys
- **Groq:** https://console.groq.com/keys
- **Ollama:** Free, no API key needed

---

## Requirements

- Ubuntu/Debian/CentOS/Rocky Linux or Alpine
- Docker and Docker Compose
- Compatible GPU for local models (optional)
- API key for cloud providers (optional)

---

## License

MIT
