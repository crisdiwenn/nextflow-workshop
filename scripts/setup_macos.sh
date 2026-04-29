#!/usr/bin/env bash
# =============================================================================
# setup_macos.sh — Workshop environment for macOS (Intel + Apple Silicon)
#
# Installs: Homebrew (if missing), Java 21, Nextflow 24.04.2, nf-core tools
# Container runtime: Docker Desktop (must be installed manually first)
# =============================================================================

set -euo pipefail

NEXTFLOW_VERSION="24.04.2"
INSTALL_DIR="${HOME}/.local/bin"

green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$1"; }
red() { printf "\033[0;31m%s\033[0m\n" "$1"; }

green "=== Nextflow Workshop Setup (macOS) ==="
echo

mkdir -p "${INSTALL_DIR}"

# ---- 1. Homebrew ------------------------------------------------------------
if ! command -v brew &>/dev/null; then
    green "[1/5] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for current session (Apple Silicon vs Intel)
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    yellow "[1/5] Homebrew already installed: $(brew --version | head -n1)"
fi

# ---- 2. Docker Desktop check ------------------------------------------------
if ! command -v docker &>/dev/null; then
    red "[2/5] Docker not found!"
    yellow ""
    yellow "Please install Docker Desktop from:"
    yellow "  https://www.docker.com/products/docker-desktop/"
    yellow ""
    yellow "After installing:"
    yellow "  1. Open Docker Desktop and wait for it to start"
    yellow "  2. Settings -> Resources -> set Memory to 8 GB or more"
    yellow "  3. Re-run this setup script"
    yellow ""
    exit 1
else
    green "[2/5] Docker found: $(docker --version)"
    if ! docker info &>/dev/null; then
        red "Docker is installed but not running. Open Docker Desktop and try again."
        exit 1
    fi
fi

# ---- 3. Java 21 -------------------------------------------------------------
if ! command -v java &>/dev/null || \
   [[ "$(java -version 2>&1 | awk -F\" 'NR==1{print $2}' | cut -d. -f1)" -lt 17 ]]; then
    green "[3/5] Installing OpenJDK 21..."
    brew install openjdk@21
    # Symlink so system java picks it up
    sudo ln -sfn "$(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk" \
        /Library/Java/JavaVirtualMachines/openjdk-21.jdk
else
    yellow "[3/5] Java already installed: $(java -version 2>&1 | head -n1)"
fi

# ---- 4. Nextflow ------------------------------------------------------------
if ! command -v nextflow &>/dev/null; then
    green "[4/5] Installing Nextflow ${NEXTFLOW_VERSION}..."
    cd /tmp
    curl -fsSL https://get.nextflow.io | bash
    chmod +x nextflow
    mv nextflow "${INSTALL_DIR}/nextflow"
    cd - >/dev/null
else
    yellow "[4/5] Nextflow already installed: $(nextflow -v)"
fi

# ---- 5. Shell environment ---------------------------------------------------
green "[5/5] Configuring shell..."
SHELL_RC="${HOME}/.zshrc"
[[ "${SHELL}" == *bash ]] && SHELL_RC="${HOME}/.bash_profile"

if ! grep -q "# >>> nextflow workshop >>>" "${SHELL_RC}" 2>/dev/null; then
    cat >> "${SHELL_RC}" <<EOF

# >>> nextflow workshop >>>
export PATH="\${HOME}/.local/bin:\${PATH}"
export NXF_VER=${NEXTFLOW_VERSION}
export JAVA_HOME="\$(/usr/libexec/java_home -v 21 2>/dev/null || echo '')"
# <<< nextflow workshop <<<
EOF
    green "Added env vars to ${SHELL_RC}"
fi

green ""
green "=== Setup complete ==="
yellow "IMPORTANT: Open a new terminal (or run: source ${SHELL_RC})"
yellow "Then run: ./scripts/verify.sh"
