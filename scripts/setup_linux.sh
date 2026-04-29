#!/usr/bin/env bash
# =============================================================================
# setup_linux.sh — Workshop environment for Linux / WSL2 Ubuntu
#
# Installs: Java 21, Apptainer, Nextflow 24.04.2, nf-core tools
# Tested on: Ubuntu 22.04, Ubuntu 24.04, WSL2 Ubuntu
# =============================================================================

set -euo pipefail

NEXTFLOW_VERSION="24.04.2"
INSTALL_DIR="${HOME}/.local/bin"

green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$1"; }
red() { printf "\033[0;31m%s\033[0m\n" "$1"; }

green "=== Nextflow Workshop Setup (Linux/WSL2) ==="
echo

mkdir -p "${INSTALL_DIR}" "${HOME}/.apptainer/cache"

# ---- 1. System packages -----------------------------------------------------
green "[1/4] Installing system dependencies..."
sudo apt update
sudo apt install -y curl wget git software-properties-common

# ---- 2. Java 21 -------------------------------------------------------------
if ! command -v java &>/dev/null || \
   [[ "$(java -version 2>&1 | awk -F\" 'NR==1{print $2}' | cut -d. -f1)" -lt 17 ]]; then
    green "[2/4] Installing OpenJDK 21..."
    sudo apt install -y openjdk-21-jre-headless
else
    yellow "[2/4] Java already installed: $(java -version 2>&1 | head -n1)"
fi

# ---- 3. Apptainer -----------------------------------------------------------
if ! command -v apptainer &>/dev/null; then
    green "[3/4] Installing Apptainer..."
    sudo add-apt-repository -y ppa:apptainer/ppa
    sudo apt update
    sudo apt install -y apptainer
else
    yellow "[3/4] Apptainer already installed: $(apptainer --version)"
fi

# ---- 4. Nextflow ------------------------------------------------------------
if ! command -v nextflow &>/dev/null; then
    green "[4/4] Installing Nextflow ${NEXTFLOW_VERSION}..."
    cd /tmp
    curl -fsSL https://get.nextflow.io | bash
    chmod +x nextflow
    mv nextflow "${INSTALL_DIR}/nextflow"
    cd - >/dev/null
else
    yellow "[4/4] Nextflow already installed: $(nextflow -v)"
fi

# ---- 5. Shell environment ---------------------------------------------------
SHELL_RC="${HOME}/.bashrc"
[[ -n "${ZSH_VERSION:-}" ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "# >>> nextflow workshop >>>" "${SHELL_RC}"; then
    cat >> "${SHELL_RC}" <<EOF

# >>> nextflow workshop >>>
export PATH="\${HOME}/.local/bin:\${PATH}"
export NXF_VER=${NEXTFLOW_VERSION}
export APPTAINER_CACHEDIR="\${HOME}/.apptainer/cache"
export NXF_APPTAINER_CACHEDIR="\${HOME}/.apptainer/cache"
# <<< nextflow workshop <<<
EOF
    green "Added env vars to ${SHELL_RC}"
fi

green ""
green "=== Setup complete ==="
yellow "IMPORTANT: Open a new terminal (or run: source ${SHELL_RC})"
yellow "Then run: ./scripts/verify.sh"
