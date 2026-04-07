# NemoClaw VPS - GPU-Accelerated AI Agent

A GPU-accelerated AI agent system combining **OpenClaw** with **NVIDIA NemoClaw** enterprise security features. Deploy on any VPS with GPU support.

## Key Features

- **GPU Acceleration** - NVIDIA CUDA, AMD ROCm, or Intel GPU support
- **Sandboxed Execution** - NVIDIA OpenShell isolation
- **Pre-trained Model** - Nemotron 3 Super 120B (4-bit quantized)
- **One-Line Install** - Deploy on any server with a single curl command
- **Flexible Access** - Tailscale VPN, Cloudflare Tunnel, or direct access

## GPU Requirements

| GPU | VRAM | Recommended |
|-----|------|-------------|
| NVIDIA (CUDA 11.8+) | 16GB+ | RTX 4090, A100, L40 |
| AMD (ROCm 5.4+) | 16GB+ | RX 7900 XT/XTX |
| Intel Arc/Xeon | 8GB+ | Arc A770, Xeon |
| CPU-only | 32GB+ RAM | AVX2 support |

## Quick Start

### Interactive Setup

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash
```

You'll be prompted to select GPU mode and enter credentials.

---

## GPU Mode Selection

### Mode 1: NVIDIA GPU (Recommended)

Best performance for AI workloads. Requires NVIDIA GPU with CUDA support.

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --gpu-mode nvidia \
  --nvidia-api-key nv-xxxxx
```

### Mode 2: AMD GPU

For AMD GPUs using ROCm. Requires ROCm 5.4+.

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --gpu-mode amd \
  --nvidia-api-key nv-xxxxx
```

### Mode 3: Intel GPU

For Intel Arc GPUs or Xeon processors with integrated GPU.

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --gpu-mode intel \
  --nvidia-api-key nv-xxxxx
```

### Mode 4: CPU Only

No GPU required. Slower but works on any system.

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --gpu-mode cpu \
  --nvidia-api-key nv-xxxxx
```

---

## With Custom Domain

```bash
curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
  --gpu-mode nvidia \
  --nvidia-api-key nv-xxxxx \
  --domain ai.example.com \
  --cloudflare-token cf_token
```

---

## All Options

| Option | Description |
|--------|-------------|
| `--gpu-mode` | GPU mode: nvidia, amd, intel, cpu |
| `--nvidia-api-key` | NVIDIA API key for model access |
| `--cloudflare-token` | Cloudflare API token for DNS |
| `--domain` | Your domain name |
| `--admin-user` | Admin username (default: admin) |
| `--admin-pass` | Admin password (auto-generated if not set) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NEMOCLAW VPS                              │
│                                                              │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │   Nginx    │───►│  NemoClaw    │───►│  Nemotron    │  │
│  │  TLS/HTTPS │    │  AI Agent    │    │  3 Super     │  │
│  └─────────────┘    └──────────────┘    └───────────────┘  │
│                           │                                    │
│                    ┌──────▼──────┐                          │
│                    │   NVIDIA    │                          │
│                    │   OpenShell │                          │
│                    │  Sandbox    │                          │
│                    └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

**Security:**
- NVIDIA OpenShell sandboxed execution
- Sandboxed AI execution with isolation
- Rate limiting (60 req/min)
- Container isolation (read-only, dropped capabilities)
- TLS 1.3 with secure cipher suites

---

## Management Commands

```bash
# View logs
docker-compose -f /opt/nemoclaw/docker-compose.yml logs -f

# Stop services
docker-compose -f /opt/nemoclaw/docker-compose.yml down

# Restart services
docker-compose -f /opt/nemoclaw/docker-compose.yml restart

# Access shell
docker-compose -f /opt/nemoclaw/docker-compose.yml exec nemoclaw nemoclaw shell
```

---

## NVIDIA API Key

Get your free NVIDIA API key from:
**https://build.nvidia.com/nvidia/discover**

The Nemotron 3 Super 120B model requires API access for inference.

---

## Requirements

- Ubuntu/Debian/CentOS/Rocky Linux or Alpine
- Docker and Docker Compose
- Compatible GPU (or CPU with 32GB+ RAM)
- NVIDIA account (free at build.nvidia.com)

---

## License

MIT
