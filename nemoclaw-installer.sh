#!/usr/bin/env bash
#
# NemoClaw VPS - GPU-Accelerated AI Agent Framework
# Version: 1.0.0
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash
#
set -euo pipefail

INSTALL_DIR="/opt/nemoclaw"
DATA_DIR="/var/lib/nemoclaw"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step() { echo -e "\n${CYAN}${BOLD}==>${NC} ${BOLD}$1${NC}"; }

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --llm-provider)
                LLM_PROVIDER="$2"
                shift 2
                ;;
            --llm-api-key)
                LLM_API_KEY="$2"
                shift 2
                ;;
            --llm-model)
                LLM_MODEL="$2"
                shift 2
                ;;
            --llm-endpoint)
                LLM_ENDPOINT="$2"
                shift 2
                ;;
            --gpu-mode)
                GPU_MODE="$2"
                shift 2
                ;;
            --cloudflare-token)
                CLOUDFLARE_API_TOKEN="$2"
                shift 2
                ;;
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --admin-user)
                ADMIN_USERNAME="$2"
                shift 2
                ;;
            --admin-pass)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
NemoClaw VPS - GPU-Accelerated AI Agent Framework

Usage:
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash

Options:
  --llm-provider PROVIDER  LLM provider: ollama, openai, anthropic, lmstudio (default: ollama)
  --llm-api-key KEY       API key for the LLM provider
  --llm-model MODEL       Model name (default varies by provider)
  --llm-endpoint URL      Custom endpoint URL (for proxies)
  --gpu-mode MODE         GPU mode: nvidia, amd, intel, cpu (default: nvidia)
  --cloudflare-token TOKEN  Cloudflare API token for DNS
  --domain DOMAIN         Your domain name
  --admin-user USER      Admin username (default: admin)
  --admin-pass PASS       Admin password (auto-generated if not set)
  --help, -h            Show this help

LLM Providers:
  ollama      - Local Ollama server (free, uses your GPU)
  openai      - OpenAI API (GPT-4, GPT-4o)
  anthropic   - Anthropic API (Claude 3.5 Sonnet, Opus)
  lmstudio   - LM Studio local server
  groq       - Groq API (fast inference)
 ollama      - Local models via Ollama

GPU Requirements:
  NVIDIA:  CUDA 11.8+ compatible GPU, 8GB+ VRAM
  AMD:    ROCm 5.4+ compatible GPU, 8GB+ VRAM
  Intel:  Arc GPU or Xeon with iGPU, 4GB+ VRAM
  CPU:    AVX2 support, 16GB+ RAM (slower)

Examples:
  # Interactive (will prompt for all options)
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash

  # Ollama (local, free) with NVIDIA GPU
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --llm-provider ollama --llm-model llama3.2 --gpu-mode nvidia

  # OpenAI with custom domain
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --llm-provider openai --llm-api-key sk-xxxx --llm-model gpt-4o --domain ai.example.com

  # Anthropic Claude
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --llm-provider anthropic --llm-api-key sk-ant-xxxx --llm-model claude-3-5-sonnet

  # CPU-only mode (no GPU)
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --llm-provider openai --llm-api-key sk-xxxx --gpu-mode cpu
EOF
}

# Interactive prompts
interactive_prompt() {
    echo ""
    echo "=============================================="
    echo -e "  ${BOLD}NemoClaw VPS - Interactive Setup${NC}"
    echo "=============================================="
    echo ""
    echo "Press Enter to use default values (shown in brackets)."
    echo ""

    # LLM Provider selection
    if [[ -z "${LLM_PROVIDER:-}" ]]; then
        echo ""
        echo -e "${BOLD}Select LLM Provider:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  ${GREEN}1${NC}) ${BOLD}Ollama${NC} - Local models (free, uses your GPU)"
        echo "      - Download and run models locally"
        echo "      - Privacy-first, no data leaves your server"
        echo "      - Supports llama3.2, mistral, codellama, etc."
        echo ""
        echo "  ${CYAN}2${NC}) ${BOLD}OpenAI${NC} - GPT-4, GPT-4o"
        echo "      - Most capable models"
        echo "      - Requires OpenAI API key"
        echo ""
        echo "  ${PURPLE}3${NC}) ${BOLD}Anthropic${NC} - Claude 3.5 Sonnet"
        echo "      - Excellent reasoning and coding"
        echo "      - Requires Anthropic API key"
        echo ""
        echo "  ${YELLOW}4${NC}) ${BOLD}LM Studio${NC} - Local server"
        echo "      - Similar to Ollama, different UI"
        echo "      - Run any GGUF model"
        echo ""
        echo "  ${BLUE}5${NC}) ${BOLD}Groq${NC} - Fast inference"
        echo "      - NVIDIA GPUs in the cloud"
        echo "      - Free tier available"
        echo ""
        echo "  ${RED}6${NC}) ${BOLD}Custom${NC} - Any OpenAI-compatible API"
        echo "      - Use with LocalAI, Ollama API, etc."
        echo ""
        read -rp "Select LLM provider [1]: " PROVIDER_CHOICE
        [[ -z "$PROVIDER_CHOICE" ]] && PROVIDER_CHOICE="1"
        case "$PROVIDER_CHOICE" in
            1) LLM_PROVIDER="ollama" ;;
            2) LLM_PROVIDER="openai" ;;
            3) LLM_PROVIDER="anthropic" ;;
            4) LLM_PROVIDER="lmstudio" ;;
            5) LLM_PROVIDER="groq" ;;
            6) LLM_PROVIDER="custom" ;;
            *) LLM_PROVIDER="ollama" ;;
        esac
    fi

    # Provider-specific prompts
    case "$LLM_PROVIDER" in
        ollama)
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                echo -e "${BOLD}Ollama Model${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Popular models:"
                echo "  - ${GREEN}llama3.2${NC} (8B) - General purpose, fast"
                echo "  - ${GREEN}llama3.2:70b${NC} (70B) - Most capable"
                echo "  - ${GREEN}mistral${NC} - Good balance"
                echo "  - ${GREEN}codellama${NC} - Optimized for code"
                echo "  - ${GREEN}deepseek-coder${NC} - Best for coding"
                read -rp "Model [llama3.2]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="llama3.2"
            fi
            ;;
        openai)
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                echo -e "${BOLD}OpenAI API Key${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Get your key from: https://platform.openai.com/api-keys"
                read -rp "OpenAI API Key: " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                echo -e "${BOLD}OpenAI Model${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  - ${GREEN}gpt-4o${NC} - Latest, most capable (default)"
                echo "  - ${GREEN}gpt-4o-mini${NC} - Fast, cost-effective"
                echo "  - ${GREEN}gpt-4-turbo${NC} - Powerful, slower"
                read -rp "Model [gpt-4o]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="gpt-4o"
            fi
            ;;
        anthropic)
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                echo -e "${BOLD}Anthropic API Key${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Get your key from: https://console.anthropic.com/settings/keys"
                read -rp "Anthropic API Key: " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                echo -e "${BOLD}Anthropic Model${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  - ${GREEN}claude-3-5-sonnet-latest${NC} - Latest, best value (default)"
                echo "  - ${GREEN}claude-3-opus-latest${NC} - Most capable"
                echo "  - ${GREEN}claude-3-haiku-20240307${NC} - Fast, budget"
                read -rp "Model [claude-3-5-sonnet-latest]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="claude-3-5-sonnet-latest"
            fi
            ;;
        lmstudio)
            if [[ -z "${LLM_ENDPOINT:-}" ]]; then
                echo ""
                echo -e "${BOLD}LM Studio Endpoint${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Default is http://localhost:1234/v1"
                read -rp "Endpoint [http://localhost:1234/v1]: " LLM_ENDPOINT
                [[ -z "$LLM_ENDPOINT" ]] && LLM_ENDPOINT="http://localhost:1234/v1"
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                echo -e "${BOLD}LM Studio Model ID${NC}"
                read -rp "Model ID (e.g., llama-3.2-3b-instruct): " LLM_MODEL
            fi
            ;;
        groq)
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                echo -e "${BOLD}Groq API Key${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Get your key from: https://console.groq.com/keys"
                echo "Free tier includes llama-3.1-8b-instant"
                read -rp "Groq API Key: " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                echo -e "${BOLD}Groq Model${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  - ${GREEN}llama-3.1-8b-instant${NC} - Fast, free tier"
                echo "  - ${GREEN}llama-3.1-70b-versatile${NC} - Most capable"
                echo "  - ${GREEN}mixtral-8x7b-32768${NC} - Good balance"
                read -rp "Model [llama-3.1-8b-instant]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="llama-3.1-8b-instant"
            fi
            ;;
        custom)
            if [[ -z "${LLM_ENDPOINT:-}" ]]; then
                echo ""
                echo -e "${BOLD}Custom API Endpoint${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Enter your OpenAI-compatible API endpoint"
                read -rp "Endpoint URL: " LLM_ENDPOINT
            fi
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                read -rp "API Key (or press Enter for no auth): " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                read -rp "Model name: " LLM_MODEL
            fi
            ;;
    esac

    # GPU mode selection
    if [[ -z "${GPU_MODE:-}" ]]; then
        echo ""
        echo -e "${BOLD}Select GPU Mode:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  ${GREEN}1${NC}) ${BOLD}NVIDIA GPU${NC} - Recommended (CUDA acceleration)"
        echo "      - Best performance for local models"
        echo "      - Requires NVIDIA GPU with 8GB+ VRAM"
        echo ""
        echo "  ${CYAN}2${NC}) ${BOLD}AMD GPU${NC} - ROCm acceleration"
        echo "      - For AMD GPUs (RX 7900 XT/XTX)"
        echo "      - Requires ROCm 5.4+"
        echo ""
        echo "  ${PURPLE}3${NC}) ${BOLD}Intel GPU${NC} - Arc/ Xeon acceleration"
        echo "      - For Intel Arc GPUs or Xeon processors"
        echo ""
        echo "  ${YELLOW}4${NC}) ${BOLD}CPU Only${NC} - No GPU needed"
        echo "      - Works on any system"
        echo "      - Slower, requires 16GB+ RAM"
        echo ""
        read -rp "Select GPU mode [1]: " GPU_CHOICE
        [[ -z "$GPU_CHOICE" ]] && GPU_CHOICE="1"
        case "$GPU_CHOICE" in
            1) GPU_MODE="nvidia" ;;
            2) GPU_MODE="amd" ;;
            3) GPU_MODE="intel" ;;
            4) GPU_MODE="cpu" ;;
            *) GPU_MODE="nvidia" ;;
        esac
    fi

    # Domain (optional)
    if [[ -z "${DOMAIN:-}" ]]; then
        echo ""
        echo -e "${BOLD}Custom Domain (Optional)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Leave blank to use the default URL."
        read -rp "Domain (e.g., ai.example.com) [skip]: " DOMAIN
        [[ -z "$DOMAIN" ]] && DOMAIN=""
    fi

    # Cloudflare token (optional)
    if [[ -n "${DOMAIN:-}" && -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        echo ""
        echo -e "${BOLD}Cloudflare API Token (Optional)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Create token at: https://dash.cloudflare.com/profile/api-tokens"
        echo "Permissions: Zone > DNS > Edit"
        read -rp "Cloudflare API Token: " CLOUDFLARE_API_TOKEN
    fi

    # Admin credentials
    if [[ -z "${ADMIN_USERNAME:-}" ]]; then
        echo ""
        echo -e "${BOLD}Admin Credentials${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        read -rp "Admin username [admin]: " ADMIN_USERNAME
        [[ -z "$ADMIN_USERNAME" ]] && ADMIN_USERNAME="admin"
    fi

    if [[ -z "${ADMIN_PASSWORD:-}" ]]; then
        echo ""
        echo "Leave blank to auto-generate a secure password."
        read -rp "Admin password [auto-generate]: " ADMIN_PASSWORD
        [[ -z "$ADMIN_PASSWORD" ]] && ADMIN_PASSWORD=""
    fi

    echo ""
}

# Detect GPU
detect_gpu() {
    log_step "Detecting GPU..."

    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "NVIDIA GPU")
        log_success "NVIDIA GPU detected: $GPU_INFO"
        DETECTED_GPU="nvidia"
    elif command -v rocm-smi &> /dev/null; then
        GPU_INFO=$(rocm-smi --showproductname 2>/dev/null || echo "AMD GPU")
        log_success "AMD GPU detected: $GPU_INFO"
        DETECTED_GPU="amd"
    elif command -v clinfo &> /dev/null; then
        log_success "Intel GPU potential (clinfo available)"
        DETECTED_GPU="intel"
    else
        log_warn "No GPU detected - will use CPU mode"
        DETECTED_GPU="cpu"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    for cmd in curl docker docker-compose; do
        if ! command -v "$cmd" &> /dev/null; then
            log "Installing $cmd..."
            install_dep "$cmd"
        fi
    done

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Start Docker and try again."
    fi

    log_success "Prerequisites OK"
}

install_dep() {
    case $1 in
        docker)
            curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
            systemctl enable docker --now 2>/dev/null || true
            ;;
        docker-compose)
            local arch=$(uname -m)
            [[ "$arch" == "aarch64" ]] && arch="aarch64" || arch="x86_64"
            curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${arch}" \
                -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            ;;
    esac
}

# Install Ollama
install_ollama() {
    if [[ "$LLM_PROVIDER" != "ollama" ]]; then
        return 0
    fi

    log_step "Installing Ollama..."

    if command -v ollama &> /dev/null; then
        log_success "Ollama already installed"
    else
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://ollama.ai/install.sh | sh > /dev/null 2>&1 || {
                log_warn "Ollama installation failed"
            }
        elif command -v yum &> /dev/null; then
            curl -fsSL https://ollama.ai/install.sh | sh > /dev/null 2>&1 || {
                log_warn "Ollama installation failed"
            }
        fi
    fi

    if command -v ollama &> /dev/null; then
        log "Pulling model: ${LLM_MODEL:-llama3.2}..."
        ollama pull "${LLM_MODEL:-llama3.2}" 2>/dev/null || true
        log_success "Ollama installed with model ${LLM_MODEL:-llama3.2}"
    fi
}

# Generate secrets
generate_secrets() {
    SESSION_SECRET=$(openssl rand -base64 32 2>/dev/null | tr -d '/+=' | head -c 32)

    if [[ -z "${ADMIN_PASSWORD:-}" ]]; then
        ADMIN_PASSWORD=$(openssl rand -base64 24 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 16)
        log "Admin password generated"
    fi

    ADMIN_PASSWORD_HASH=$(echo "$ADMIN_PASSWORD" | openssl passwd -1 -stdin 2>/dev/null || echo "CHANGEME")
}

# Create directories
create_directories() {
    log_step "Creating directories..."
    mkdir -p "$INSTALL_DIR"/{config,data,logs}
    mkdir -p "$DATA_DIR"/{cache,plugins}
    chmod -R 755 "$INSTALL_DIR"
    log_success "Directories created"
}

# Generate Docker Compose
generate_docker_compose() {
    log_step "Generating Docker Compose configuration..."

    # Set runtime based on GPU mode
    case "$GPU_MODE" in
        nvidia)
            RUNTIME="nvidia"
            GPU_ENV="- NVIDIA_VISIBLE_DEVICES=all"
            ;;
        amd)
            RUNTIME="nvidia"
            GPU_ENV="- AMD_VISIBLE_DEVICES=all"
            ;;
        intel)
            RUNTIME=""
            GPU_ENV="- LIBVA_DRIVER_NAME=iHD"
            ;;
        cpu)
            RUNTIME=""
            GPU_ENV="- CPU_LIMIT=8"
            ;;
        *)
            RUNTIME=""
            GPU_ENV=""
            ;;
    esac

    cat > "$INSTALL_DIR/docker-compose.yml" << DOCKER
version: '3.8'

services:
  nemoclaw:
    image: ghcr.io/openclaw/nemoclaw:latest
    container_name: nemoclaw-app
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
      - "127.0.0.1:8080:8080"
    environment:
      - LLM_PROVIDER=${LLM_PROVIDER:-ollama}
      - LLM_API_KEY=${LLM_API_KEY:-}
      - LLM_MODEL=${LLM_MODEL:-llama3.2}
      - LLM_ENDPOINT=${LLM_ENDPOINT:-http://host.docker.internal:11434/v1}
      - GPU_MODE=${GPU_MODE:-nvidia}
      - SESSION_SECRET=${SESSION_SECRET}
      - ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
      - ADMIN_PASSWORD_HASH=${ADMIN_PASSWORD_HASH}
      - TRUST_PROXY=true
${GPU_ENV:-}
    volumes:
      - ./config:/app/config
      - ./data:/app/data
    networks:
      - nemoclaw-net
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    extra_hosts:
      - "host.docker.internal:host-gateway"

  # Ollama (if using local models)
  ollama:
    image: ollama/ollama:latest
    container_name: nemoclaw-ollama
    restart: unless-stopped
    profiles:
      - ollama
    ports:
      - "127.0.0.1:11434:11434"
${GPU_ENV:-}
    volumes:
      - ollama-data:/root/.ollama
    networks:
      - nemoclaw-net
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

networks:
  nemoclaw-net:
    driver: bridge

volumes:
  ollama-data:
    driver: local
DOCKER

    log_success "Docker Compose configuration generated"
}

# Generate config
generate_config() {
    log_step "Generating NemoClaw configuration..."

    cat > "$INSTALL_DIR/config/nemoclaw.json" << CONFIG
{
  "version": "1.0.0",
  "llm": {
    "provider": "${LLM_PROVIDER:-ollama}",
    "model": "${LLM_MODEL:-llama3.2}",
    "api_key": "${LLM_API_KEY:-}",
    "endpoint": "${LLM_ENDPOINT:-}",
    "gpu_mode": "${GPU_MODE:-nvidia}"
  },
  "security": {
    "sandbox_enabled": true,
    "rate_limit": {
      "enabled": true,
      "requests_per_minute": 60
    },
    "allowed_tools": ["shell", "read", "write", "search", "browser"]
  },
  "presets": {
    "enabled": ["docker", "filesystem", "network"],
    "custom": []
  },
  "api": {
    "port": 3000,
    "web_port": 8080,
    "auth_required": true
  },
  "plugins": {
    "directory": "./plugins",
    "auto_update": true
  }
}
CONFIG

    log_success "Configuration generated"
}

# Build and start
build_and_start() {
    log_step "Building and starting NemoClaw..."

    cd "$INSTALL_DIR"
    docker-compose pull
    docker-compose up -d

    # If using Ollama, also start the ollama service
    if [[ "$LLM_PROVIDER" == "ollama" ]]; then
        docker-compose --profile ollama up -d
    fi

    log "Waiting for services..."
    for i in {1..30}; do
        if curl -sf http://localhost:3000/health &>/dev/null; then
            log_success "NemoClaw started successfully!"
            return 0
        fi
        sleep 2
    done

    log_warn "Services may still be starting. Check: docker-compose -f $INSTALL_DIR/docker-compose.yml logs"
}

# Print summary
print_summary() {
    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}NemoClaw VPS Installation Complete!${NC}"
    echo "=============================================="
    echo ""

    echo -e "${BOLD}LLM Provider:${NC} ${LLM_PROVIDER}"
    echo -e "${BOLD}Model:${NC} ${LLM_MODEL}"
    echo -e "${BOLD}GPU Mode:${NC} ${GPU_MODE}"
    echo ""
    echo -e "${BOLD}Access URL:${NC}"
    echo "  Local:   https://localhost:8080"
    if [[ -n "${DOMAIN:-}" ]]; then
        echo "  Remote:  https://nemoclaw.${DOMAIN}"
    fi
    echo ""
    echo -e "${BOLD}Admin Credentials:${NC}"
    echo "  Username: ${ADMIN_USERNAME:-admin}"
    echo "  Password: ${ADMIN_PASSWORD}"
    echo ""
    echo -e "${BOLD}LLM Status:${NC}"
    case "$LLM_PROVIDER" in
        ollama)
            echo "  Using local Ollama models (free, private)"
            echo "  Models stored at: ~/.ollama/models"
            ;;
        openai)
            echo "  Using OpenAI ${LLM_MODEL:-GPT-4o}"
            ;;
        anthropic)
            echo "  Using Anthropic ${LLM_MODEL:-Claude}"
            ;;
        lmstudio)
            echo "  Using LM Studio at ${LLM_ENDPOINT:-localhost:1234}"
            ;;
        groq)
            echo "  Using Groq ${LLM_MODEL}"
            ;;
        custom)
            echo "  Using custom endpoint: ${LLM_ENDPOINT:-}"
            ;;
    esac
    echo ""
    echo -e "${BOLD}Management Commands:${NC}"
    echo "  Logs:    docker-compose -f $INSTALL_DIR/docker-compose.yml logs -f"
    echo "  Stop:    docker-compose -f $INSTALL_DIR/docker-compose.yml down"
    echo "  Restart: docker-compose -f $INSTALL_DIR/docker-compose.yml restart"
    echo ""
    echo "  IMPORTANT: Change the admin password after first login!"
    echo ""
}

# Main
main() {
    echo ""
    echo "========================================"
    echo "  NemoClaw VPS - AI Agent Framework v1.0"
    echo "========================================"
    echo ""

    parse_args "$@"

    # Go interactive if no LLM provider specified
    if [[ -z "${LLM_PROVIDER:-}" ]]; then
        interactive_prompt
    fi

    detect_gpu
    check_prerequisites
    install_ollama
    generate_secrets
    create_directories
    generate_config
    generate_docker_compose
    build_and_start
    print_summary
}

main "$@"
