# NemoClaw VPS - GPU-Accelerated AI Agent Framework

A GPU-accelerated AI agent framework that connects to **any LLM provider** - local (Ollama, LM Studio) or cloud (OpenAI, Anthropic, Groq). Deploy on any VPS with optional GPU acceleration.

## Key Features

- **Any LLM Provider** - OpenAI, Anthropic, Ollama, Groq, LM Studio, or custom
- **GPU Acceleration** - NVIDIA CUDA, AMD ROCm, Intel GPU, or CPU-only
- **One-Line Install** - Deploy on any server with a single curl command
- **Flexible Access** - Tailscale VPN, Cloudflare Tunnel, or Cloudflare Proxy
- **Secure** - TLS 1.3, security headers, container isolation

## Choose Your Setup Mode

| Mode | Security | Accessibility | Best For |
|------|----------|---------------|----------|
| **1. Tailscale VPN** | Highest | Requires VPN app | Maximum privacy, team with Tailscale |
| **2. Cloudflare Tunnel** | High | No VPN app | Easy access, global availability |
| **3. Cloudflare Proxy** | High | No VPN app | Traditional hosting, full CF features |

All modes: **No ports exposed to public internet** (except Mode 3 which needs 80/443)

---

## Quick Start

### Interactive Setup

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash
```

You'll be prompted to choose your setup mode and LLM provider.

---

## Setup Mode 1: Tailscale VPN

**Most private** - No internet exposure, requires Tailscale app on devices.

### 1. Get Tailscale Auth Key

1. Go to [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys)
2. Click "Generate auth key"
3. Copy the key (starts with `tskey-auth-`)

### 2. Install

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --setup-mode 1 \
  --tailscale-key tskey-auth-xxxxx \
  --llm-provider ollama \
  --llm-model llama3.2
```

### 3. Access

Visit: `https://your-server.tail1234.ts.net`

Requires Tailscale app on your device.

---

## Setup Mode 2: Cloudflare Tunnel (Recommended)

**Easy access** - No VPN app needed, uses Cloudflare's global network.

### 1. Get Cloudflare API Token

1. Go to [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token" → "Create Custom Token"
3. Name: `NemoClaw Tunnel`
4. Permissions: Account > Cloudflare Tunnel > Edit
5. Account Resources: Include > Your account
6. Create and copy the token

### 2. Install

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --setup-mode 2 \
  --cloudflare-token cf_token \
  --domain yourdomain.com \
  --llm-provider openai \
  --llm-api-key sk-xxxx
```

### 3. Access

Visit: `https://nemoclaw.yourdomain.com`

No VPN app needed.

---

## Setup Mode 3: Cloudflare Proxy (Traditional)

**Traditional setup** - Requires ports 80/443 open.

### 1. Get Cloudflare API Token

1. Go to [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token" → "Create Custom Token"
3. Name: `NemoClaw`
4. Permissions: Zone > DNS > Edit
5. Zone Resources: Include > Specific zone > Your domain
6. Create and copy the token

### 2. Install

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --setup-mode 3 \
  --cloudflare-token cf_token \
  --cloudflare-zone-id cf_zone_id \
  --domain yourdomain.com \
  --llm-provider anthropic \
  --llm-api-key sk-ant-xxxx
```

### 3. Access

Visit: `https://nemoclaw.yourdomain.com`

Ensure ports 80 and 443 are open on your server.

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
  --llm-provider anthropic --llm-api-key sk-ant-xxxx --llm-model claude-3-5-sonnet
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

## All Options

| Option | Mode | Description |
|--------|------|-------------|
| `--setup-mode` | All | 1=Tailscale, 2=Tunnel, 3=Proxy |
| `--tailscale-key` | 1 | Tailscale auth key (`tskey-auth-...`) |
| `--cloudflare-token` | 2,3 | Cloudflare API token |
| `--cloudflare-zone-id` | 2,3 | Cloudflare Zone ID |
| `--domain` | 2,3 | Your domain name |
| `--llm-provider` | All | Provider: ollama, openai, anthropic, groq, lmstudio, custom |
| `--llm-api-key` | All | API key for the provider |
| `--llm-model` | All | Model name (default varies by provider) |
| `--llm-endpoint` | All | Custom endpoint URL for proxies |
| `--gpu-mode` | All | nvidia, amd, intel, cpu (default: nvidia) |
| `--admin-user` | All | Admin username (default: admin) |
| `--admin-pass` | All | Admin password (auto-generated if not set) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        MODE 1: TAILSCALE                      │
│  User ──► Tailscale VPN ──► Server (no ports exposed)       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    MODE 2: CLOUDFLARE TUNNEL                  │
│  User ──► Cloudflare Network ──► Tunnel ──► Server          │
│                                          (no ports exposed)  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    MODE 3: CLOUDFLARE PROXY                  │
│  User ──► Cloudflare ──► Nginx:3443 ──► Server              │
│                              (ports 80/443 must be open)    │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- Nginx with TLS 1.3 termination
- Node.js AI agent with LLM integration
- Ollama container (when using local models)
- Docker containers with security hardening

---

## GPU Modes

| Mode | Performance | VRAM | Best For |
|------|-------------|------|----------|
| **NVIDIA** | Best | 8GB+ | Local models, fast inference |
| **AMD** | Best | 8GB+ | RX 7900 XT/XTX |
| **Intel** | Good | 4GB+ | Arc GPUs, Xeon |
| **CPU** | Slow | 16GB+ RAM | Testing, budget |

---

## Supported LLM Providers

| Provider | Type | GPU Support | API Key |
|----------|------|-------------|---------|
| **Ollama** | Local (free) | Yes | None |
| **OpenAI** | Cloud | No | Required |
| **Anthropic** | Cloud | No | Required |
| **Groq** | Cloud (fast) | No | Optional |
| **LM Studio** | Local | Yes | None |
| **Custom** | Any OpenAI-compatible | Depends | Optional |

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
- For Mode 1: Tailscale account ([tailscale.com](https://tailscale.com))
- For Mode 2/3: Cloudflare account with domain added ([cloudflare.com](https://cloudflare.com))

---

## License

MIT