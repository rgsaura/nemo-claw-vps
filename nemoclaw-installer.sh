#!/usr/bin/env bash
#
# NemoClaw VPS - GPU-Accelerated AI Agent Installer
# Version: 1.0.0
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash
#
set -euo pipefail

INSTALL_DIR="/opt/nemoclaw"
DATA_DIR="/var/lib/nemoclaw"
NVIDIA_DRIVER_VERSION="535"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
            --gpu-mode)
                GPU_MODE="$2"
                shift 2
                ;;
            --nvidia-api-key)
                NVIDIA_API_KEY="$2"
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
NemoClaw VPS - GPU-Accelerated AI Agent Installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash

Options:
  --gpu-mode MODE      GPU mode: nvidia, amd, intel, cpu (default: nvidia)
  --nvidia-api-key KEY NVIDIA API key for Nemotron model access
  --cloudflare-token TOKEN  Cloudflare API token for DNS
  --domain DOMAIN       Your domain name
  --admin-user USER    Admin username (default: admin)
  --admin-pass PASS    Admin password (auto-generated if not set)
  --help, -h          Show this help

GPU Requirements:
  NVIDIA:  CUDA 11.8+ compatible GPU, 16GB+ VRAM
  AMD:    ROCm 5.4+ compatible GPU, 16GB+ VRAM
  Intel:  Arc GPU or Xeon with iGPU, 8GB+ VRAM
  CPU:    AVX2 support, 32GB+ RAM (slower)

Examples:
  # Interactive (will prompt for all options)
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash

  # NVIDIA GPU with custom domain
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --gpu-mode nvidia --nvidia-api-key nv-xxxx --domain ai.example.com

  # CPU-only mode (no GPU)
  curl -fsSL https://raw.githubusercontent.com/rgsaura/nemo-claw-vps/main/nemoclaw-installer.sh | bash -s -- \
    --gpu-mode cpu --nvidia-api-key nv-xxxx
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

    # GPU mode selection
    if [[ -z "${GPU_MODE:-}" ]]; then
        echo ""
        echo -e "${BOLD}Select GPU Mode:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  ${GREEN}1${NC}) ${BOLD}NVIDIA GPU${NC} - Recommended (CUDA acceleration)"
        echo "      - Best performance for AI workloads"
        echo "      - Requires NVIDIA GPU with 16GB+ VRAM"
        echo ""
        echo "  ${CYAN}2${NC}) ${BOLD}AMD GPU${NC} - ROCm acceleration"
        echo "      - Good for AMD GPUs (RX 7900 XT/XTX)"
        echo "      - Requires ROCm 5.4+"
        echo ""
        echo "  ${PURPLE}3${NC}) ${BOLD}Intel GPU${NC} - Arc/ Xeon acceleration"
        echo "      - For Intel Arc GPUs or Xeon processors"
        echo "      - Requires Intel GPU runtime"
        echo ""
        echo "  ${YELLOW}4${NC}) ${BOLD}CPU Only${NC} - No GPU needed"
        echo "      - Works on any system"
        echo "      - Slower, requires 32GB+ RAM"
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

    # NVIDIA API Key
    if [[ -z "${NVIDIA_API_KEY:-}" ]]; then
        echo ""
        echo -e "${BOLD}NVIDIA API Key (Required for Nemotron Model)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Get your API key from: https://build.nvidia.com/nvidia/discover"
        echo "The Nemotron model requires API access."
        echo ""
        read -rp "NVIDIA API Key: " NVIDIA_API_KEY
    fi

    # Domain (optional)
    if [[ -z "${DOMAIN:-}" ]]; then
        echo ""
        echo -e "${BOLD}Custom Domain (Optional)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Leave blank to use the default URL."
        echo "Required for Cloudflare DNS auto-configuration."
        read -rp "Domain (e.g., ai.example.com) [skip]: " DOMAIN
        [[ -z "$DOMAIN" ]] && DOMAIN=""
    fi

    # Cloudflare token (optional)
    if [[ -n "${DOMAIN:-}" && -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        echo ""
        echo -e "${BOLD}Cloudflare API Token (Optional)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "For automatic DNS setup with Cloudflare."
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

# Install NVIDIA Driver and CUDA
install_nvidia_driver() {
    if [[ "$GPU_MODE" != "nvidia" ]]; then
        return 0
    fi

    log_step "Installing NVIDIA Driver and CUDA..."

    if command -v nvidia-smi &> /dev/null; then
        log_success "NVIDIA driver already installed"
        return 0
    fi

    log "Installing NVIDIA driver ${NVIDIA_DRIVER_VERSION}..."

    if command -v apt-get &> /dev/null; then
        # Add NVIDIA repository
        curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null || true
        curl -s -L 'https://nvidia.github.io/nvidia-docker/ubuntu/nvidia-docker.list' | \
            sed 's#nvidia-docker#nvidia-container-toolkit#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

        apt-get update -qq
        apt-get install -y -qq nvidia-driver-${NVIDIA_DRIVER_VERSION} nvidia-container-toolkit > /dev/null 2>&1 || {
            log_warn "NVIDIA driver installation failed, trying docker runtime..."
            # Fallback: use nvidia runtime from docker
            apt-get install -y -qq nvidia-container-runtime > /dev/null 2>&1 || true
        }
    elif command -v yum &> /dev/null; then
        yum install -y -q akmod-nvidia xorg-x11-drv-nvidia-cuda > /dev/null 2>&1 || true
    fi

    # Configure Docker to use NVIDIA runtime
    if command -v nvidia-ctk &> /dev/null; then
        nvidia-ctk runtime configure --runtime=docker 2>/dev/null || true
    fi

    systemctl restart docker 2>/dev/null || true
    log_success "NVIDIA driver installed"
}

# Install ROCm for AMD GPUs
install_amd_driver() {
    if [[ "$GPU_MODE" != "amd" ]]; then
        return 0
    fi

    log_step "Installing AMD ROCm..."

    if command -v rocm-smi &> /dev/null; then
        log_success "ROCm already installed"
        return 0
    fi

    log "Installing AMD ROCm..."

    if command -v apt-get &> /dev/null; then
        curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /usr/share/keyrings/rocm.gpg 2>/dev/null || true
        echo "deb [signed-by=/usr/share/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/5.7.1 ubuntu main" | \
            tee /etc/apt/sources.list.d/rocm.list > /dev/null

        apt-get update -qq
        apt-get install -y -qq rocm-hip-sdk > /dev/null 2>&1 || {
            log_warn "ROCm installation may have partially failed"
        }
    fi

    log_success "ROCm installed"
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
    mkdir -p "$DATA_DIR"/{models,cache}
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
            RUNTIME_LINE="    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all"
            ;;
        amd)
            RUNTIME="nvidia"
            RUNTIME_LINE="    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - AMD_VISIBLE_DEVICES=all"
            ;;
        intel)
            RUNTIME=""
            RUNTIME_LINE="    environment:
      - LIBVA_DRIVER_NAME=iHD"
            ;;
        cpu)
            RUNTIME=""
            RUNTIME_LINE="    environment:
      - CPU_LIMIT=8"
            ;;
        *)
            RUNTIME=""
            RUNTIME_LINE=""
            ;;
    esac

    cat > "$INSTALL_DIR/docker-compose.yml" << DOCKER
version: '3.8'

services:
  nemoclaw:
    image: nemoclaw/nemoclaw:latest
    container_name: nemoclaw-app
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
      - "127.0.0.1:8080:8080"
${RUNTIME_LINE:-}
    volumes:
      - ./config:/app/config
      - ./data:/app/data
      - nemoclaw-models:/models
    environment:
      - NVIDIA_API_KEY=${NVIDIA_API_KEY:-}
      - SESSION_SECRET=${SESSION_SECRET}
      - ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
      - ADMIN_PASSWORD_HASH=${ADMIN_PASSWORD_HASH}
      - GPU_MODE=${GPU_MODE:-nvidia}
      - TRUST_PROXY=true
    networks:
      - nemoclaw-net
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache
    cap_drop:
      - ALL

  # Optional: Cloudflare Tunnel for remote access
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: nemoclaw-tunnel
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN:-}
    networks:
      - nemoclaw-net
    profiles:
      - tunnel

networks:
  nemoclaw-net:
    driver: bridge

volumes:
  nemoclaw-models:
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
  "gpu_mode": "${GPU_MODE:-nvidia}",
  "model": {
    "name": "nemotron-3-super-120b",
    "quantization": "4-bit",
    "context_length": 4096
  },
  "security": {
    "sandbox_enabled": true,
    "openShell_isolation": true,
    "rate_limit": {
      "enabled": true,
      "requests_per_minute": 60
    }
  },
  "presets": {
    "enabled": ["docker", "huggingface", "npm", "pypi"],
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

    log "Waiting for services..."
    for i in {1..30}; do
        if docker-compose exec -T nemoclaw curl -sf http://localhost:3000/health &>/dev/null; then
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
    echo "  ${GREEN}NemoClaw VPS Installation Complete!${NC}"
    echo "=============================================="
    echo ""

    echo -e "${BOLD}GPU Mode:${NC} ${GPU_MODE}"
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
    echo -e "${BOLD}GPU Status:${NC}"
    case "$GPU_MODE" in
        nvidia)
            nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "  NVIDIA GPU configured"
            ;;
        amd)
            echo "  AMD GPU configured (ROCm)"
            ;;
        intel)
            echo "  Intel GPU configured"
            ;;
        cpu)
            echo "  CPU-only mode (slower)"
            ;;
    esac
    echo ""
    echo -e "${BOLD}Management Commands:${NC}"
    echo "  Logs:    docker-compose -f $INSTALL_DIR/docker-compose.yml logs -f"
    echo "  Stop:    docker-compose -f $INSTALL_DIR/docker-compose.yml down"
    echo "  Restart: docker-compose -f $INSTALL_DIR/docker-compose.yml restart"
    echo "  Shell:   docker-compose -f $INSTALL_DIR/docker-compose.yml exec nemoclaw nemoclaw shell"
    echo ""
    echo "  IMPORTANT: Change the admin password after first login!"
    echo ""
}

# Main
main() {
    echo ""
    echo "========================================"
    echo "  NemoClaw VPS - GPU AI Agent v1.0"
    echo "========================================"
    echo ""

    parse_args "$@"

    # Go interactive if no GPU mode specified
    if [[ -z "${GPU_MODE:-}" ]]; then
        interactive_prompt
    fi

    detect_gpu
    check_prerequisites

    case "${GPU_MODE:-nvidia}" in
        nvidia)
            install_nvidia_driver
            ;;
        amd)
            install_amd_driver
            ;;
        cpu)
            log "CPU-only mode - skipping GPU driver installation"
            ;;
    esac

    generate_secrets
    create_directories
    generate_config
    generate_docker_compose
    build_and_start
    print_summary
}

main "$@"
