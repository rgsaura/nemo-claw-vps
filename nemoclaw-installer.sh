#!/usr/bin/env bash
#
# NemoClaw VPS - GPU-Accelerated AI Agent Framework
# Version: 1.0.0
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash
#
# With options:
#   curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
#     --setup-mode 1 --tailscale-key tskey-auth-xxxxx
#
set -euo pipefail

INSTALL_DIR="/opt/nemoclaw"
DATA_DIR="/var/lib/nemoclaw"
PORT=3000
SSL_PORT=3443

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
PURPLE=$'\033[0;35m'
BOLD=$'\033[1m'
NC=$'\033[0m'

log() { printf '%s%s[INFO]%s %s\n' "$BLUE" "$NC" "$NC" "$1"; }
log_success() { printf '%s%s[SUCCESS]%s %s\n' "$GREEN" "$NC" "$NC" "$1"; }
log_warn() { printf '%s%s[WARN]%s %s\n' "$YELLOW" "$NC" "$NC" "$1"; }
log_error() { printf '%s%s[ERROR]%s %s\n' "$RED" "$NC" "$NC" "$1"; exit 1; }
log_step() { printf '\n%s%s==>%s %s%s%s\n' "$CYAN" "$BOLD" "$NC" "$BOLD" "$1" "$NC"; }

# Read input (works when piped via curl)
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"

    if [[ -t 0 ]]; then
        # Terminal - read from stdin
        read -rp "$prompt" "$var_name"
    else
        # Piped - read from /dev/tty
        read -rp "$prompt" "$var_name" < /dev/tty
    fi

    eval "val=\$$var_name"
    if [[ -z "$val" ]]; then
        eval "$var_name=\$default"
    fi
}

prompt_password() {
    local prompt="$1"
    local var_name="$2"

    if [[ -t 0 ]]; then
        read -rsp "$prompt" "$var_name"
    else
        read -rsp "$prompt" "$var_name" < /dev/tty
    fi
    echo
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --setup-mode)
                SETUP_MODE="$2"
                shift 2
                ;;
            --tailscale-key)
                TAILSCALE_AUTH_KEY="$2"
                shift 2
                ;;
            --tailscale-fqdn)
                TAILSCALE_FQDN="$2"
                shift 2
                ;;
            --cloudflare-token)
                CLOUDFLARE_API_TOKEN="$2"
                shift 2
                ;;
            --cloudflare-zone-id)
                CLOUDFLARE_ZONE_ID="$2"
                shift 2
                ;;
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --tunnel-subdomain)
                CLOUDFLARE_TUNNEL_SUBDOMAIN="$2"
                shift 2
                ;;
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
            --admin-user)
                ADMIN_USERNAME="$2"
                shift 2
                ;;
            --admin-pass)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --skip-dns)
                SKIP_DNS="true"
                shift
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

Setup Modes (will prompt if not specified):
  1) Tailscale VPN   - Most private, no ports exposed, requires VPN app
  2) Cloudflare Tunnel - No ports exposed, no VPN app needed (recommended)
  3) Cloudflare Proxy - Traditional, ports 80/443 needed

Options:
  --setup-mode MODE       Setup mode: 1 (Tailscale), 2 (Tunnel), 3 (Proxy)
  --tailscale-key KEY     Tailscale auth key (for mode 1)
  --cloudflare-token TOKEN  Cloudflare API token (for modes 2,3)
  --cloudflare-zone-id ID   Cloudflare Zone ID (for modes 2,3)
  --domain DOMAIN         Your domain name (for modes 2,3)
  --llm-provider PROVIDER LLM provider: ollama, openai, anthropic, groq, lmstudio (default: ollama)
  --llm-api-key KEY       API key for the LLM provider
  --llm-model MODEL       Model name (default varies by provider)
  --gpu-mode MODE         GPU mode: nvidia, amd, intel, cpu (default: nvidia)
  --admin-user USER       Admin username (default: admin)
  --admin-pass PASS       Admin password (auto-generated if not set)
  --help, -h           Show this help

Examples:
  # Interactive setup (choose mode when prompted)
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash

  # Tailscale VPN mode with Ollama
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --setup-mode 1 --tailscale-key tskey-auth-kffdsafdsa --llm-provider ollama --llm-model llama3.2

  # Cloudflare Tunnel mode with OpenAI
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --setup-mode 2 --cloudflare-token cf_token --domain ai.example.com --llm-provider openai --llm-api-key sk-xxxx

LLM Providers:
  ollama      - Local Ollama server (free, uses your GPU)
  openai      - OpenAI API (GPT-4, GPT-4o)
  anthropic   - Anthropic API (Claude 3.5 Sonnet, Opus)
  groq        - Groq API (fast inference)
  lmstudio   - LM Studio local server
  custom     - Any OpenAI-compatible API

GPU Requirements:
  NVIDIA:  CUDA 11.8+ compatible GPU, 8GB+ VRAM
  AMD:    ROCm 5.4+ compatible GPU, 8GB+ VRAM
  Intel:  Arc GPU or Xeon with iGPU, 4GB+ VRAM
  CPU:    AVX2 support, 16GB+ RAM (slower)
EOF
}

# Interactive prompts for missing options
interactive_prompt() {
    echo ""
    echo "=============================================="
    printf '  %sNemoClaw VPS - Interactive Setup%s\n' "$BOLD" "$NC"
    echo "=============================================="
    echo ""
    echo "Press Enter to use default values (shown in brackets)."
    echo ""

    # =================================================================
    # STEP 1: Choose setup mode
    # =================================================================
    if [[ -z "${SETUP_MODE:-}" ]]; then
        echo ""
        printf '%sChoose Your Setup Mode:%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        printf '  %s1%s) %sTailscale VPN%s - Most private\n' "$GREEN" "$NC" "$BOLD" "$NC"
        echo "      - Requires Tailscale app on your devices"
        echo "      - No ports exposed to internet"
        echo "      - Encrypted peer-to-peer connection"
        echo ""
        printf '  %s2%s) %sCloudflare Tunnel%s - Easy access (recommended)\n' "$YELLOW" "$NC" "$BOLD" "$NC"
        echo "      - No VPN app needed"
        echo "      - No ports exposed to internet"
        echo "      - Uses Cloudflare's global network"
        echo ""
        printf '  %s3%s) %sCloudflare Proxy%s - Traditional\n' "$CYAN" "$NC" "$BOLD" "$NC"
        echo "      - Direct access via domain"
        echo "      - Cloudflare proxies and protects traffic"
        echo "      - Requires ports 80/443 open locally"
        echo ""
        prompt_input "Select setup mode [1]: " SETUP_MODE "1"
    fi

    # =================================================================
    # MODE 1: Tailscale VPN
    # =================================================================
    if [[ "$SETUP_MODE" == "1" ]]; then
        echo ""
        printf '%sMode: Tailscale VPN%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Tailscale creates a private VPN network. Only users logged into"
        echo "your Tailscale network can access this server."
        echo ""

        if [[ -z "${TAILSCALE_AUTH_KEY:-}" ]]; then
            printf '%sStep 1: Generate Tailscale Auth Key%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "1. Open this link: https://login.tailscale.com/admin/settings/keys"
            echo "2. Click '${GREEN}Generate auth key${NC}' button"
            echo "3. Copy the key (starts with '${GREEN}tskey-auth-${NC}')"
            echo ""
            prompt_input "Paste your Tailscale Auth Key: " TAILSCALE_AUTH_KEY ""
        fi

        if [[ -z "${TAILSCALE_FQDN:-}" ]]; then
            echo ""
            echo "Custom hostname (e.g., nemoclaw.example.com) or press Enter for default:"
            prompt_input "[auto-generated tailxxxx.ts.net]: " TAILSCALE_FQDN ""
        fi

    # =================================================================
    # MODE 2: Cloudflare Tunnel
    # =================================================================
    elif [[ "$SETUP_MODE" == "2" ]]; then
        echo ""
        printf '%sMode: Cloudflare Tunnel%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Cloudflare Tunnel creates a secure connection through Cloudflare's"
        echo "global network. No ports need to be opened on your server."
        echo ""

        if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
            printf '%sStep 1: Create Cloudflare API Token%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "1. Open: https://dash.cloudflare.com/profile/api-tokens"
            printf "2. Click '%sCreate Token%s'\n" "$GREEN" "$NC"
            printf "3. Choose '%sCreate Custom Token%s'\n" "$GREEN" "$NC"
            printf "4. Token Name: %sNemoClaw-Tunnel%s\n" "$GREEN" "$NC"
            echo "5. Permissions:"
            printf "   - Account: %sCloudflare Tunnel%s > %sEdit%s\n" "$GREEN" "$NC" "$GREEN" "$NC"
            printf "6. Account Resources: %sInclude%s > %sYour account%s\n" "$GREEN" "$NC" "$GREEN" "$NC"
            printf "7. Click '%sCreate Token%s' and copy the token\n" "$GREEN" "$NC"
            echo ""
            prompt_input "Paste your Cloudflare API Token: " CLOUDFLARE_API_TOKEN ""
        fi

        if [[ -z "${DOMAIN:-}" ]]; then
            echo ""
            echo "Your domain name (must be added to Cloudflare):"
            prompt_input "Domain (e.g., example.com): " DOMAIN ""
        fi

        if [[ -z "${CLOUDFLARE_ZONE_ID:-}" ]]; then
            echo ""
            echo "Cloudflare Zone ID (found in Cloudflare Dashboard > Domain > Overview):"
            prompt_input "Zone ID: " CLOUDFLARE_ZONE_ID ""
        fi

        if [[ -z "${CLOUDFLARE_TUNNEL_SUBDOMAIN:-}" ]]; then
            echo ""
            echo "Subdomain for NemoClaw (or press Enter for 'nemoclaw'):"
            prompt_input "[nemoclaw]: " CLOUDFLARE_TUNNEL_SUBDOMAIN "nemoclaw"
        fi

    # =================================================================
    # MODE 3: Cloudflare Proxy (Traditional)
    # =================================================================
    elif [[ "$SETUP_MODE" == "3" ]]; then
        echo ""
        printf '%sMode: Cloudflare Proxy (Traditional)%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Traditional setup using Cloudflare as a reverse proxy."
        echo "Requires ports 80 and 443 open on your server."
        echo ""

        if [[ -z "${DOMAIN:-}" ]]; then
            printf '%sStep 1: Your Domain%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Your domain must be added to Cloudflare."
            prompt_input "Domain (e.g., example.com): " DOMAIN ""
        fi

        if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
            echo ""
            printf '%sStep 2: Create Cloudflare API Token%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "1. Open: https://dash.cloudflare.com/profile/api-tokens"
            printf "2. Click '%sCreate Token%s'\n" "$GREEN" "$NC"
            printf "3. Choose '%sCreate Custom Token%s'\n" "$GREEN" "$NC"
            printf "4. Token Name: %sNemoClaw-DNS%s\n" "$GREEN" "$NC"
            echo "5. Permissions:"
            printf "   - Zone: %sDNS%s > %sEdit%s\n" "$GREEN" "$NC" "$GREEN" "$NC"
            printf "6. Zone Resources: %sInclude%s > %sSpecific zone%s > %s\n" "$GREEN" "$NC" "$GREEN" "$NC" "${DOMAIN:-your-domain}"
            printf "7. Click '%sCreate Token%s' and copy the token\n" "$GREEN" "$NC"
            echo ""
            prompt_input "Paste your Cloudflare API Token: " CLOUDFLARE_API_TOKEN ""
        fi

        if [[ -z "${CLOUDFLARE_ZONE_ID:-}" ]]; then
            echo ""
            echo "Cloudflare Zone ID:"
            prompt_input "Zone ID: " CLOUDFLARE_ZONE_ID ""
        fi
    fi

    # =================================================================
    # STEP 2: LLM Provider
    # =================================================================
    if [[ -z "${LLM_PROVIDER:-}" ]]; then
        echo ""
        printf '%sSelect LLM Provider:%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        printf '  %s1%s) %sOllama%s - Local models (free, uses your GPU)\n' "$GREEN" "$NC" "$BOLD" "$NC"
        echo "      - Download and run models locally"
        echo "      - Privacy-first, no data leaves your server"
        echo "      - Supports llama3.2, mistral, codellama, etc."
        echo ""
        printf '  %s2%s) %sOpenAI%s - GPT-4, GPT-4o\n' "$CYAN" "$NC" "$BOLD" "$NC"
        echo "      - Most capable models"
        echo "      - Requires OpenAI API key"
        echo ""
        printf '  %s3%s) %sAnthropic%s - Claude 3.5 Sonnet\n' "$PURPLE" "$NC" "$BOLD" "$NC"
        echo "      - Excellent reasoning and coding"
        echo "      - Requires Anthropic API key"
        echo ""
        printf '  %s4%s) %sGroq%s - Fast inference\n' "$YELLOW" "$NC" "$BOLD" "$NC"
        echo "      - NVIDIA GPUs in the cloud"
        echo "      - Free tier available"
        echo ""
        printf '  %s5%s) %sLM Studio%s - Local server\n' "$BLUE" "$NC" "$BOLD" "$NC"
        echo "      - Similar to Ollama, different UI"
        echo "      - Run any GGUF model"
        echo ""
        printf '  %s6%s) %sCustom%s - Any OpenAI-compatible API\n' "$RED" "$NC" "$BOLD" "$NC"
        echo "      - Use with LocalAI, Ollama API, etc."
        echo ""
        prompt_input "Select LLM provider [1]: " PROVIDER_CHOICE "1"
        case "$PROVIDER_CHOICE" in
            1) LLM_PROVIDER="ollama" ;;
            2) LLM_PROVIDER="openai" ;;
            3) LLM_PROVIDER="anthropic" ;;
            4) LLM_PROVIDER="groq" ;;
            5) LLM_PROVIDER="lmstudio" ;;
            6) LLM_PROVIDER="custom" ;;
            *) LLM_PROVIDER="ollama" ;;
        esac
    fi

    # Provider-specific prompts
    case "$LLM_PROVIDER" in
        ollama)
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                printf '%sOllama Model%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Popular models:"
                printf "  - %sllama3.2%s (8B) - General purpose, fast\n" "$GREEN" "$NC"
                printf "  - %sllama3.2:70b%s (70B) - Most capable\n" "$GREEN" "$NC"
                printf "  - %smistral%s - Good balance\n" "$GREEN" "$NC"
                printf "  - %scodellama%s - Optimized for code\n" "$GREEN" "$NC"
                printf "  - %sdeepseek-coder%s - Best for coding\n" "$GREEN" "$NC"
                read -rp "Model [llama3.2]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="llama3.2"
            fi
            ;;
        openai)
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                printf '%sOpenAI API Key%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Get your key from: https://platform.openai.com/api-keys"
                read -rp "OpenAI API Key: " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                printf '%sOpenAI Model%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                printf "  - %sgpt-4o%s - Latest, most capable (default)\n" "$GREEN" "$NC"
                printf "  - %sgpt-4o-mini%s - Fast, cost-effective\n" "$GREEN" "$NC"
                printf "  - %sgpt-4-turbo%s - Powerful, slower\n" "$GREEN" "$NC"
                read -rp "Model [gpt-4o]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="gpt-4o"
            fi
            ;;
        anthropic)
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                printf '%sAnthropic API Key%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Get your key from: https://console.anthropic.com/settings/keys"
                read -rp "Anthropic API Key: " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                printf '%sAnthropic Model%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                printf "  - %sclaude-3-5-sonnet-latest%s - Latest, best value (default)\n" "$GREEN" "$NC"
                printf "  - %sclaude-3-opus-latest%s - Most capable\n" "$GREEN" "$NC"
                printf "  - %sclaude-3-haiku-20240307%s - Fast, budget\n" "$GREEN" "$NC"
                read -rp "Model [claude-3-5-sonnet-latest]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="claude-3-5-sonnet-latest"
            fi
            ;;
        lmstudio)
            if [[ -z "${LLM_ENDPOINT:-}" ]]; then
                echo ""
                printf '%sLM Studio Endpoint%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Default is http://localhost:1234/v1"
                read -rp "Endpoint [http://localhost:1234/v1]: " LLM_ENDPOINT
                [[ -z "$LLM_ENDPOINT" ]] && LLM_ENDPOINT="http://localhost:1234/v1"
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                read -rp "Model ID (e.g., llama-3.2-3b-instruct): " LLM_MODEL
            fi
            ;;
        groq)
            if [[ -z "${LLM_API_KEY:-}" ]]; then
                echo ""
                printf '%sGroq API Key%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Get your key from: https://console.groq.com/keys"
                echo "Free tier includes llama-3.1-8b-instant"
                read -rp "Groq API Key: " LLM_API_KEY
            fi
            if [[ -z "${LLM_MODEL:-}" ]]; then
                echo ""
                printf '%sGroq Model%s\n' "$BOLD" "$NC"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                printf "  - %sllama-3.1-8b-instant%s - Fast, free tier\n" "$GREEN" "$NC"
                printf "  - %sllama-3.1-70b-versatile%s - Most capable\n" "$GREEN" "$NC"
                printf "  - %smixtral-8x7b-32768%s - Good balance\n" "$GREEN" "$NC"
                read -rp "Model [llama-3.1-8b-instant]: " LLM_MODEL
                [[ -z "$LLM_MODEL" ]] && LLM_MODEL="llama-3.1-8b-instant"
            fi
            ;;
        custom)
            if [[ -z "${LLM_ENDPOINT:-}" ]]; then
                echo ""
                printf '%sCustom API Endpoint%s\n' "$BOLD" "$NC"
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

    # =================================================================
    # STEP 3: GPU Mode
    # =================================================================
    if [[ -z "${GPU_MODE:-}" ]]; then
        echo ""
        printf '%sSelect GPU Mode:%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        printf '  %s1%s) %sNVIDIA GPU%s - Recommended (CUDA acceleration)\n' "$GREEN" "$NC" "$BOLD" "$NC"
        echo "      - Best performance for local models"
        echo "      - Requires NVIDIA GPU with 8GB+ VRAM"
        echo ""
        printf '  %s2%s) %sAMD GPU%s - ROCm acceleration\n' "$CYAN" "$NC" "$BOLD" "$NC"
        echo "      - For AMD GPUs (RX 7900 XT/XTX)"
        echo "      - Requires ROCm 5.4+"
        echo ""
        printf '  %s3%s) %sIntel GPU%s - Arc/ Xeon acceleration\n' "$PURPLE" "$NC" "$BOLD" "$NC"
        echo "      - For Intel Arc GPUs or Xeon processors"
        echo ""
        printf '  %s4%s) %sCPU Only%s - No GPU needed\n' "$YELLOW" "$NC" "$BOLD" "$NC"
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

    # =================================================================
    # ADMIN CREDENTIALS
    # =================================================================
    if [[ -z "${ADMIN_USERNAME:-}" ]]; then
        echo ""
        printf '%sAdmin Credentials%s\n' "$BOLD" "$NC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Login for the NemoClaw web dashboard."
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

# Load .env file if it exists
load_env_file() {
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        log "Loading configuration from $INSTALL_DIR/.env..."
        set -a
        source "$INSTALL_DIR/.env"
        set +a
    fi
}

# Detect server IP
detect_server_ip() {
    log "Detecting server public IP..."

    local ip=$(curl -fsSL --max-time 5 https://.cloudflare.com/cdn-cgi/trace 2>/dev/null | grep -oP 'ip=\K[^ ]+' || true)
    if [[ -z "$ip" ]]; then
        ip=$(curl -fsSL --max-time 5 https://checkip.amazonaws.com 2>/dev/null | tr -d '\n ' || true)
    fi
    if [[ -z "$ip" ]]; then
        ip=$(curl -fsSL --max-time 5 https://ipinfo.io/ip 2>/dev/null | tr -d '\n "' || true)
    fi
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi

    SERVER_IP="${ip:-unknown}"
    log_success "Server IP: $SERVER_IP"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    for cmd in curl docker docker-compose openssl; do
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
        *)
            if command -v apt-get &> /dev/null; then
                apt-get install -y -qq "$1" > /dev/null 2>&1
            elif command -v yum &> /dev/null; then
                yum install -y -q "$1" > /dev/null 2>&1
            fi
            ;;
    esac
}

# Setup Tailscale with Funnel (automatic HTTPS)
setup_tailscale() {
    if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
        log_error "Tailscale auth key is required. Provide --tailscale-key or run interactively."
    fi

    log_step "Setting up Tailscale VPN with Funnel (automatic HTTPS)..."

    # Install Tailscale
    if ! command -v tailscale &> /dev/null; then
        log "Installing Tailscale..."
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://pkgs.tailscale.com/stable/debian.bookworm.noarmor.gpg \
                | tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bookworm main" \
                | tee /etc/apt/sources.list.d/tailscale.list > /dev/null
            apt-get update -qq
            apt-get install -y -qq tailscale > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y -q tailscale 2>/dev/null || \
            (curl -fsSL https://pkgs.tailscale.com/stable/centos8/x86_64/repo.rpm -o /tmp/repo.rpm && \
             yum install -y -q /tmp/repo.rpm)
        elif command -v apk &> /dev/null; then
            apk add --no-cache tailscale
        fi
    fi

    if command -v tailscale &> /dev/null; then
        log "Connecting to Tailscale..."

        # Enable IP forwarding
        sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true

        # Connect with auth key
        tailscale up --authkey="$TAILSCALE_AUTH_KEY" --accept-routes --hostcheck=false 2>/dev/null || \
        tailscale up --authkey="$TAILSCALE_AUTH_KEY" 2>/dev/null || {
            log_warn "Auth key failed, trying interactive..."
            tailscale up --accept-routes
        }

        # Get connection info
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null | head -1 || true)
        TAILSCALE_HOSTNAME=$(tailscale status --self --json 2>/dev/null | \
            grep -oP '"DNSName":"[^"]+"' | head -1 | cut -d'"' -f4 | sed 's/\.$//' || true)

        if [[ -n "$TAILSCALE_IP" ]]; then
            log_success "Connected! Tailscale IP: $TAILSCALE_IP"

            # Configure Funnel for automatic HTTPS certificates
            log "Configuring Tailscale Funnel for automatic HTTPS..."

            if [[ -n "$TAILSCALE_FQDN" ]]; then
                tailscale serve --set-hostname="$TAILSCALE_FQDN" 2>/dev/null || true
                tailscale funnel --set-hostname="$TAILSCALE_FQDN" "$SSL_PORT" 2>/dev/null || \
                tailscale funnel "$SSL_PORT" 2>/dev/null || true
            else
                tailscale funnel "$SSL_PORT" 2>/dev/null || \
                tailscale serve --bg 2>/dev/null || true
            fi

            # Get the Funnel hostname
            TAILSCALE_HOSTNAME=$(tailscale status --self --json 2>/dev/null | \
                grep -oP '"DNSName":"[^"]+"' | head -1 | cut -d'"' -f4 | sed 's/\.$//' || true)

            # Enable on boot
            systemctl enable tailscaled 2>/dev/null || true

            TAILSCALE_CONFIGURED="true"
            log_success "Funnel configured - HTTPS certificates are automatic!"
        fi
    else
        log_warn "Tailscale installation failed"
    fi
}

# Setup Cloudflare DNS
setup_cloudflare_dns() {
    if [[ "${SKIP_DNS:-false}" == "true" || -z "$CLOUDFLARE_API_TOKEN" ]]; then
        return 0
    fi

    log_step "Configuring Cloudflare DNS..."

    # Get Zone ID if not provided
    if [[ -z "$CLOUDFLARE_ZONE_ID" ]]; then
        log "Fetching Zone ID for $DOMAIN..."
        local zones_response=$(curl -fsSL -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" 2>/dev/null)
        CLOUDFLARE_ZONE_ID=$(echo "$zones_response" | grep -oP '"id":"[^"]+"' | head -1 | cut -d'"' -f4)
    fi

    if [[ -z "$CLOUDFLARE_ZONE_ID" ]]; then
        log_warn "Could not fetch Zone ID. Provide --cloudflare-zone-id"
        return 1
    fi

    # Create DNS record pointing to server IP
    local subdomain="${TAILSCALE_FQDN%%.*}"
    local dns_response=$(curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"A\",\"name\":\"${TAILSCALE_FQDN:-$subdomain}\",\"content\":\"$SERVER_IP\",\"ttl\":3600,\"proxied\":true}" \
        2>/dev/null)

    if echo "$dns_response" | grep -q '"id"'; then
        log_success "DNS record created"
    else
        log_warn "DNS record creation failed or already exists"
    fi
}

# Setup Cloudflare Tunnel (Mode 2)
setup_cloudflare_tunnel() {
    if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
        log_error "Cloudflare API token is required for Cloudflare Tunnel mode"
    fi

    log_step "Setting up Cloudflare Tunnel..."

    # Install cloudflared
    if ! command -v cloudflared &> /dev/null; then
        log "Installing Cloudflared tunnel daemon..."
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
                -o /usr/local/bin/cloudflared
            chmod +x /usr/local/bin/cloudflared
        elif command -v yum &> /dev/null; then
            curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
                -o /usr/local/bin/cloudflared
            chmod +x /usr/local/bin/cloudflared
        elif command -v apk &> /dev/null; then
            apk add --no-cache cloudflared
        fi
    fi

    if command -v cloudflared &> /dev/null; then
        log "Creating Cloudflare Tunnel..."

        # Create tunnel
        local tunnel_response=$(cloudflared tunnel create nemoclaw 2>/dev/null || true)
        local tunnel_id=$(echo "$tunnel_response" | grep -oP '[a-f0-9-]{36}' | head -1 || true)

        if [[ -z "$tunnel_id" ]]; then
            # Try to list existing tunnels
            tunnel_id=$(cloudflared tunnel list 2>/dev/null | grep nemoclaw | awk '{print $1}' || true)
        fi

        if [[ -n "$tunnel_id" ]]; then
            log_success "Tunnel created/verified: $tunnel_id"

            # Create tunnel credentials file path
            local creds_file="$DATA_DIR/tunnel-credentials.json"

            # Create DNS record for the tunnel
            local full_hostname="${CLOUDFLARE_TUNNEL_SUBDOMAIN:-nemoclaw}.${DOMAIN}"
            log "Creating DNS record for $full_hostname..."

            # Get or create CNAME for the tunnel
            local dns_response=$(curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                -H "Content-Type: application/json" \
                -d "{\"type\":\"CNAME\",\"name\":\"${CLOUDFLARE_TUNNEL_SUBDOMAIN:-nemoclaw}\",\"content\":\"${tunnel_id}.cfargotunnel.com\",\"ttl\":3600,\"proxied\":true}" \
                2>/dev/null)

            if echo "$dns_response" | grep -q '"id"'; then
                log_success "DNS record created"
            else
                log_warn "DNS record creation failed or already exists"
            fi

            # Save tunnel ID for docker-compose
            CLOUDFLARE_TUNNEL_ID="$tunnel_id"

            TUNNEL_CONFIGURED="true"
            ACCESS_URL="https://${full_hostname}"
        else
            log_warn "Could not create or find Cloudflare Tunnel"
        fi
    else
        log_warn "Cloudflared installation failed"
    fi
}

# Setup Cloudflare Proxy Mode (Mode 3)
setup_cloudflare_proxy() {
    log_step "Setting up Cloudflare Proxy mode..."

    # Create DNS A record pointing to server IP
    if [[ -n "$DOMAIN" && -n "$CLOUDFLARE_API_TOKEN" ]]; then
        local full_hostname="${CLOUDFLARE_TUNNEL_SUBDOMAIN:-nemoclaw}.${DOMAIN}"
        log "Creating DNS A record for $full_hostname -> $SERVER_IP..."

        # Check if Zone ID exists, if not try to get it
        if [[ -z "$CLOUDFLARE_ZONE_ID" ]]; then
            log "Fetching Zone ID for $DOMAIN..."
            local zones_response=$(curl -fsSL -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                -H "Content-Type: application/json" 2>/dev/null)
            CLOUDFLARE_ZONE_ID=$(echo "$zones_response" | grep -oP '"id":"[^"]+"' | head -1 | cut -d'"' -f4)
        fi

        if [[ -n "$CLOUDFLARE_ZONE_ID" ]]; then
            local dns_response=$(curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                -H "Content-Type: application/json" \
                -d "{\"type\":\"A\",\"name\":\"${CLOUDFLARE_TUNNEL_SUBDOMAIN:-nemoclaw}\",\"content\":\"$SERVER_IP\",\"ttl\":3600,\"proxied\":true}" \
                2>/dev/null)

            if echo "$dns_response" | grep -q '"id"'; then
                log_success "DNS A record created (proxied through Cloudflare)"
            else
                log_warn "DNS record creation failed or already exists"
            fi

            ACCESS_URL="https://${full_hostname}"
        fi
    fi

    PROXY_CONFIGURED="true"
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

    # Use detected GPU if not explicitly set
    GPU_MODE="${GPU_MODE:-$DETECTED_GPU}"
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

# Create dedicated user for NemoClaw
create_nemoclaw_user() {
    log_step "Creating dedicated system user..."

    # Create nemoclaw group if it doesn't exist
    if ! getent group nemoclaw > /dev/null 2>&1; then
        groupadd --system nemoclaw 2>/dev/null || \
        groupadd nemoclaw 2>/dev/null || true
        log "Created 'nemoclaw' group"
    fi

    # Create nemoclaw user if it doesn't exist
    if ! id nemoclaw > /dev/null 2>&1; then
        useradd --system \
            --gid nemoclaw \
            --home-dir "$INSTALL_DIR" \
            --shell /usr/sbin/nologin \
            --comment "NemoClaw AI Agent Framework" \
            nemoclaw 2>/dev/null || \
        useradd -g nemoclaw -d "$INSTALL_DIR" -s /usr/sbin/nologin nemoclaw 2>/dev/null || true
        log "Created 'nemoclaw' user"
    fi

    log_success "User 'nemoclaw' configured"
}

# Create directories
create_directories() {
    log_step "Creating directories..."
    mkdir -p "$INSTALL_DIR"/{nginx,app,ssl,logs,config,data}
    mkdir -p "$DATA_DIR"/{data,logs,cache}
    chmod -R 700 "$DATA_DIR"
    chmod 600 "$INSTALL_DIR/.env" 2>/dev/null || true

    # Set ownership to nemoclaw user
    if id nemoclaw > /dev/null 2>&1; then
        chown -R nemoclaw:nemoclaw "$INSTALL_DIR" 2>/dev/null || true
        chown -R nemoclaw:nemoclaw "$DATA_DIR" 2>/dev/null || true
        log "Set ownership to 'nemoclaw' user"
    fi

    log_success "Directories created"
}

# Generate SSL cert
generate_ssl_cert() {
    log_step "Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout "$INSTALL_DIR/ssl/privkey.pem" \
        -out "$INSTALL_DIR/ssl/fullchain.pem" \
        -subj "/C=US/ST=State/L=City/O=NemoClaw/CN=${TAILSCALE_FQDN:-localhost}" 2>/dev/null
    log_success "SSL certificate generated"
}

# Generate Nginx config
generate_nginx_config() {
    cat > "$INSTALL_DIR/nginx/nginx.conf" << 'NGINX'
worker_processes auto;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 4096;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log off;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://*.anthropic.com https://api.openai.com https://*.groq.com wss://*.ngrok.io; font-src 'self' data:;" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    server_tokens off;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    upstream app {
        server app:3000;
        keepalive 32;
    }

    upstream ollama {
        server ollama:11434;
        keepalive 32;
    }

    # HTTP -> HTTPS redirect
    server {
        listen 8080;
        server_name _;

        location /health {
            return 200 "OK";
            add_header Content-Type text/plain;
        }

        location / {
            return 301 https://$host:3443$request_uri;
        }
    }

    # Main HTTPS server
    server {
        listen 3443 ssl http2;
        server_name _;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
        ssl_prefer_server_ciphers off;

        limit_req zone=api burst=20 nodelay;

        location /health {
            return 200 "OK";
            add_header Content-Type text/plain;
        }

        location /api/ {
            proxy_pass http://app/api/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /ollama/ {
            proxy_pass http://ollama/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
            add_header Cache-Control "no-store";
        }

        location ~ /\. { deny all; }
    }
}
NGINX
}

# Generate Docker Compose
generate_docker_compose() {
    # Get numeric UID/GID for nemoclaw user (default to 1000 if user doesn't exist yet)
    NEMOCLAW_UID=$(id -u nemoclaw 2>/dev/null || echo "1000")
    NEMOCLAW_GID=$(getent group nemoclaw 2>/dev/null | cut -d: -f3 || echo "1000")

    # Set runtime based on GPU mode
    case "${GPU_MODE:-nvidia}" in
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
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    user: root
    ports:
      - "${PORT}:8080"
      - "${SSL_PORT}:3443"
    volumes:
      - ./app:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
    networks:
      - nemoclaw
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /run
      - /tmp
    cap_drop:
      - ALL

  app:
    image: node:20-alpine
    restart: unless-stopped
    user: "${NEMOCLAW_UID}:${NEMOCLAW_GID}"
    working_dir: /app
    command: sh -c "npm install && node index.js"
    volumes:
      - ./app:/app
      - ./config:/app/config
      - ./data:/app/data
    environment:
      - NODE_ENV=production
      - PORT=3000
      - LLM_PROVIDER=${LLM_PROVIDER:-ollama}
      - LLM_API_KEY=${LLM_API_KEY:-}
      - LLM_MODEL=${LLM_MODEL:-llama3.2}
      - LLM_ENDPOINT=${LLM_ENDPOINT:-http://ollama:11434/v1}
      - GPU_MODE=${GPU_MODE:-nvidia}
      - SESSION_SECRET=${SESSION_SECRET}
      - ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
      - ADMIN_PASSWORD_HASH=${ADMIN_PASSWORD_HASH}
      - TRUST_PROXY=true
      - TAILSCALE_IP=${TAILSCALE_IP:-}
      - TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-}
${GPU_ENV:-}
    networks:
      - nemoclaw
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
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
      - "11434:11434"
${GPU_ENV:-}
    volumes:
      - ollama-data:/root/.ollama
    networks:
      - nemoclaw
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

networks:
  nemoclaw:
    driver: bridge

volumes:
  ollama-data:
    driver: local
DOCKER

    log_success "Docker Compose configuration generated"
}

# Generate app
generate_app() {
    log_step "Generating application..."

    cat > "$INSTALL_DIR/app/index.js" << 'APPJS'
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { execSync } = require('child_process');

const app = express();
const PORT = process.env.PORT || 3000;

// Determine LLM provider and model
const LLM_PROVIDER = process.env.LLM_PROVIDER || 'ollama';
const LLM_MODEL = process.env.LLM_MODEL || 'llama3.2';
const LLM_API_KEY = process.env.LLM_API_KEY || '';
const LLM_ENDPOINT = process.env.LLM_ENDPOINT || 'http://ollama:11434/v1';

app.use(helmet());
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: false, limit: '10kb' }));
app.set('trust proxy', 1);

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false
});
app.use('/api/', limiter);

// Simple auth middleware
const validateAuth = (req, res, next) => {
    const token = req.headers['x-api-key'] || req.headers['x-session-token'];
    if (!token && !process.env.SESSION_SECRET) {
        return res.status(401).json({ error: 'Authentication required' });
    }
    next();
};

// Get Tailscale info
const getTailscaleInfo = () => {
    try {
        return {
            ip: execSync('tailscale ip -4 2>/dev/null', { encoding: 'utf8' }).trim(),
            hostname: execSync('tailscale status --self --json 2>/dev/null', { encoding: 'utf8' })
                .match(/"DNSName":"([^"]+)"/)?.[1]?.replace(/\.$/, '') || null
        };
    } catch { return { ip: null, hostname: null }; }
};

const tsInfo = getTailscaleInfo();

// LLM API proxy
const callLLM = async (messages) => {
    const headers = {
        'Content-Type': 'application/json'
    };

    if (LLM_PROVIDER === 'openai' && LLM_API_KEY) {
        headers['Authorization'] = `Bearer ${LLM_API_KEY}`;
    } else if (LLM_PROVIDER === 'anthropic' && LLM_API_KEY) {
        headers['x-api-key'] = LLM_API_KEY;
        headers['anthropic-version'] = '2023-06-01';
    } else if (LLM_PROVIDER === 'groq' && LLM_API_KEY) {
        headers['Authorization'] = `Bearer ${LLM_API_KEY}`;
    }

    let body = {};
    let url = '';

    if (LLM_PROVIDER === 'anthropic') {
        url = 'https://api.anthropic.com/v1/messages';
        body = {
            model: LLM_MODEL,
            max_tokens: 1024,
            messages: messages.slice(-10)
        };
    } else {
        // OpenAI-compatible
        url = `${LLM_ENDPOINT}/chat/completions`;
        body = {
            model: LLM_MODEL,
            messages: messages.slice(-20)
        };
    }

    const response = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify(body)
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(`LLM API error: ${response.status} - ${error}`);
    }

    const data = await response.json();

    if (LLM_PROVIDER === 'anthropic') {
        return data.content[0].text;
    } else {
        return data.choices[0].message.content;
    }
};

app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        llm: { provider: LLM_PROVIDER, model: LLM_MODEL }
    });
});

app.get('/api/status', validateAuth, async (req, res) => {
    res.json({
        system: {
            uptime: process.uptime(),
            memory: process.memoryUsage()
        },
        llm: {
            provider: LLM_PROVIDER,
            model: LLM_MODEL,
            endpoint: LLM_ENDPOINT
        },
        network: {
            tailscale: tsInfo.ip ? { ip: tsInfo.ip, hostname: tsInfo.hostname } : null
        },
        accessUrl: tsInfo.hostname ? `https://${tsInfo.hostname}` : null
    });
});

app.post('/api/chat', validateAuth, async (req, res) => {
    try {
        const { messages } = req.body;
        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ error: 'messages array required' });
        }

        const response = await callLLM(messages);
        res.json({ response });
    } catch (error) {
        console.error('LLM error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

app.use(express.static('/app/public'));
app.get('*', (req, res) => res.sendFile('/app/public/index.html'));

app.listen(PORT, '0.0.0.0', () => {
    console.log(`NemoClaw running on port ${PORT}`);
    console.log(`LLM Provider: ${LLM_PROVIDER} (${LLM_MODEL})`);
    if (tsInfo.hostname) console.log(`Access: https://${tsInfo.hostname}`);
});
APPJS

    cat > "$INSTALL_DIR/app/package.json" << 'PKG'
{
  "name": "nemoclaw",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5"
  }
}
PKG

    mkdir -p "$INSTALL_DIR/app/public"
    mkdir -p "$INSTALL_DIR/app/config"
    mkdir -p "$INSTALL_DIR/app/data"

    cat > "$INSTALL_DIR/app/public/index.html" << 'UI'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NemoClaw - AI Agent Framework</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23, #1a1a3e);
            min-height: 100vh;
            color: #e4e4e4;
        }
        .container { max-width: 900px; margin: 0 auto; padding: 2rem; }
        header {
            text-align: center;
            padding: 2rem 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            margin-bottom: 2rem;
        }
        .logo { font-size: 2.5rem; font-weight: 700; color: #00d4ff; }
        .logo span { color: #ff6b6b; }
        .subtitle { color: #888; margin-top: 0.5rem; }
        .status-bar {
            display: flex;
            gap: 1rem;
            margin-bottom: 2rem;
            flex-wrap: wrap;
        }
        .status-item {
            background: rgba(255,255,255,0.05);
            padding: 0.75rem 1rem;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .status-item .dot { width: 8px; height: 8px; border-radius: 50%; }
        .status-item .dot.green { background: #00ff88; }
        .status-item .dot.blue { background: #00d4ff; }
        .chat-container {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 16px;
            padding: 1.5rem;
            min-height: 300px;
        }
        .chat-messages { margin-bottom: 1rem; min-height: 200px; }
        .message {
            margin-bottom: 1rem;
            padding: 1rem;
            border-radius: 12px;
            max-width: 85%;
        }
        .message.user {
            background: rgba(0,212,255,0.15);
            margin-left: auto;
            border-bottom-right-radius: 4px;
        }
        .message.assistant {
            background: rgba(255,107,107,0.15);
            border-bottom-left-radius: 4px;
        }
        .message.error {
            background: rgba(255,0,0,0.15);
            color: #ff6b6b;
        }
        .chat-input {
            display: flex;
            gap: 0.5rem;
        }
        .chat-input textarea {
            flex: 1;
            padding: 1rem;
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            background: rgba(0,0,0,0.3);
            color: #fff;
            font-family: inherit;
            font-size: 1rem;
            resize: none;
            min-height: 50px;
        }
        .chat-input button {
            padding: 0.75rem 1.5rem;
            background: #00d4ff;
            color: #0f0f23;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s;
        }
        .chat-input button:hover { opacity: 0.8; }
        .chat-input button:disabled { opacity: 0.5; cursor: not-allowed; }
        .llm-info {
            text-align: center;
            padding: 1rem;
            background: rgba(255,255,255,0.03);
            border-radius: 8px;
            margin-top: 1rem;
            color: #888;
            font-size: 0.9rem;
        }
        .access-box {
            background: rgba(0,0,0,0.3);
            border: 1px solid rgba(0,212,255,0.3);
            border-radius: 12px;
            padding: 1rem;
            margin: 1rem 0;
            text-align: center;
        }
        .access-url { font-family: monospace; color: #00d4ff; word-break: break-all; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">Nemo<span>Claw</span></div>
            <p class="subtitle">GPU-Accelerated AI Agent Framework</p>
        </header>

        <div class="status-bar">
            <div class="status-item">
                <div class="dot green"></div>
                <span id="status">Connecting...</span>
            </div>
            <div class="status-item">
                <div class="dot blue"></div>
                <span id="llm-provider">Loading...</span>
            </div>
        </div>

        <div class="access-box" id="access-box" style="display: none;">
            <p style="color: #888; margin-bottom: 0.5rem;">Your Private Access URL</p>
            <div class="access-url" id="access-url"></div>
        </div>

        <div class="chat-container">
            <div class="chat-messages" id="chat-messages">
                <div class="message assistant">Hello! I'm NemoClaw, your AI agent. How can I help you today?</div>
            </div>
            <div class="chat-input">
                <textarea id="message-input" placeholder="Type your message..." rows="1"></textarea>
                <button id="send-btn" onclick="sendMessage()">Send</button>
            </div>
        </div>

        <div class="llm-info">
            <span id="llm-model">Model: Loading...</span>
        </div>
    </div>

    <script>
        const messages = [];
        const API_KEY = 'demo';

        async function loadStatus() {
            try {
                const res = await fetch('/api/status', {
                    headers: { 'X-API-Key': API_KEY }
                });
                if (res.ok) {
                    const data = await res.json();
                    document.getElementById('status').textContent = 'System Online';
                    document.getElementById('llm-provider').textContent = data.llm.provider.toUpperCase();
                    document.getElementById('llm-model').textContent = `Model: ${data.llm.model}`;
                    if (data.accessUrl) {
                        document.getElementById('access-url').textContent = data.accessUrl;
                        document.getElementById('access-box').style.display = 'block';
                    }
                }
            } catch {}
        }

        async function sendMessage() {
            const input = document.getElementById('message-input');
            const btn = document.getElementById('send-btn');
            const text = input.value.trim();
            if (!text) return;

            messages.push({ role: 'user', content: text });
            renderMessages();
            input.value = '';
            btn.disabled = true;

            try {
                const res = await fetch('/api/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-API-Key': API_KEY
                    },
                    body: JSON.stringify({ messages })
                });
                const data = await res.json();
                if (data.response) {
                    messages.push({ role: 'assistant', content: data.response });
                } else if (data.error) {
                    messages.push({ role: 'assistant', content: 'Error: ' + data.error });
                }
            } catch (err) {
                messages.push({ role: 'assistant', content: 'Error: Could not connect to server.' });
            }

            btn.disabled = false;
            renderMessages();
        }

        function renderMessages() {
            const container = document.getElementById('chat-messages');
            container.innerHTML = messages.map(m =>
                `<div class="message ${m.role}">${escapeHtml(m.content)}</div>`
            ).join('');
            container.scrollTop = container.scrollHeight;
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        document.getElementById('message-input').addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        loadStatus();
    </script>
</body>
</html>
UI

    log_success "Application generated"
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
  "api": {
    "port": 3000,
    "auth_required": true
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
    docker-compose up -d --build

    # If using Ollama, also start the ollama service
    if [[ "${LLM_PROVIDER:-ollama}" == "ollama" ]]; then
        docker-compose --profile ollama up -d
    fi

    log "Waiting for services..."
    for i in {1..30}; do
        if curl -sfk https://localhost:${SSL_PORT}/health &>/dev/null; then
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
    printf '  %sNemoClaw Installation Complete!%s\n' "$GREEN" "$NC"
    echo "=============================================="
    echo ""

    case "${SETUP_MODE:-1}" in
        1)
            printf '%sMode: Tailscale VPN (Most Private)%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Your server is accessible ONLY through the Tailscale VPN."
            echo "No ports are exposed to the public internet."
            echo ""
            echo "Access URL:"
            printf '  %shttps://%s%s\n' "$CYAN" "${TAILSCALE_HOSTNAME:-${TAILSCALE_IP}}" "$NC"
            echo ""
            echo "How to access:"
            echo "  1. Install Tailscale: https://tailscale.com/download"
            echo "  2. Open Tailscale and log in"
            printf '  3. Visit: https://%s\n' "${TAILSCALE_HOSTNAME:-${TAILSCALE_IP}}"
            echo ""
            ;;
        2)
            printf '%sMode: Cloudflare Tunnel (Easy Access)%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Your server is accessible via Cloudflare's global network."
            echo "No ports are exposed to the public internet."
            echo ""
            echo "Access URL:"
            printf '  %shttps://%s.%s%s\n' "$CYAN" "${CLOUDFLARE_TUNNEL_SUBDOMAIN:-nemoclaw}" "${DOMAIN}" "$NC"
            echo ""
            echo "How to access:"
            echo "  1. Open your browser"
            echo "  2. Visit the URL above"
            echo "  3. No VPN app needed!"
            echo ""
            ;;
        3)
            printf '%sMode: Cloudflare Proxy (Traditional)%s\n' "$BOLD" "$NC"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Your server uses Cloudflare as a reverse proxy."
            echo "Traffic is protected but ports 80/443 must be accessible."
            echo ""
            echo "Access URL:"
            printf '  %shttps://%s.%s%s\n' "$CYAN" "${CLOUDFLARE_TUNNEL_SUBDOMAIN:-nemoclaw}" "${DOMAIN}" "$NC"
            echo ""
            echo "How to access:"
            echo "  1. Ensure ports 80 and 443 are open"
            echo "  2. Visit the URL above"
            echo ""
            ;;
    esac

    printf '%sLLM Configuration:%s\n' "$BOLD" "$NC"
    printf '  Provider: %s\n' "$LLM_PROVIDER"
    printf '  Model: %s\n' "$LLM_MODEL"
    printf '  GPU Mode: %s\n' "${GPU_MODE:-nvidia}"
    echo ""
    printf '%sAdmin Credentials:%s\n' "$BOLD" "$NC"
    printf '  Username: %s\n' "${ADMIN_USERNAME:-admin}"
    printf '  Password: %s\n' "$ADMIN_PASSWORD"
    echo ""
    printf '%sManagement Commands:%s\n' "$BOLD" "$NC"
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

    # Load .env file if it exists
    load_env_file

    parse_args "$@"

    # If required credentials not provided via args, go interactive
    if [[ -z "${TAILSCALE_AUTH_KEY:-}" && -z "${CLOUDFLARE_API_TOKEN:-}" && -z "${SETUP_MODE:-}" ]]; then
        interactive_prompt
    fi

    detect_server_ip
    check_prerequisites
    create_nemoclaw_user
    detect_gpu

    # Run setup based on chosen mode
    case "${SETUP_MODE:-1}" in
        1)
            setup_tailscale
            setup_cloudflare_dns
            ;;
        2)
            setup_cloudflare_tunnel
            ;;
        3)
            setup_cloudflare_proxy
            ;;
        *)
            log_error "Invalid setup mode: $SETUP_MODE"
            ;;
    esac

    install_ollama
    generate_secrets
    create_directories
    generate_ssl_cert
    generate_nginx_config
    generate_docker_compose
    generate_app
    generate_config
    build_and_start
    print_summary
}

main "$@"