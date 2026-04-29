#!/usr/bin/env bash
# =============================================================================
# prepull_containers.sh — Pre-cache all biocontainers used in the workshop
#
# Useful for: slow conference WiFi, corporate firewalls, offline workshops.
# Detects whether to use Apptainer (Linux) or Docker (macOS).
# =============================================================================

set -euo pipefail

# Containers used in workshop exercises
APPTAINER_IMAGES=(
    "https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0"
    "https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0"
    "https://depot.galaxyproject.org/singularity/multiqc:1.21--pyhdfd78af_0"
)

DOCKER_IMAGES=(
    "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
    "quay.io/biocontainers/fastp:0.23.4--h5f740d0_0"
    "quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0"
)

if command -v apptainer &>/dev/null; then
    echo "Using Apptainer..."
    mkdir -p "${HOME}/.apptainer/cache"
    for img in "${APPTAINER_IMAGES[@]}"; do
        echo ">> Pulling ${img}"
        apptainer pull --dir "${HOME}/.apptainer/cache" --force "${img}" || true
    done
elif command -v docker &>/dev/null; then
    echo "Using Docker..."
    for img in "${DOCKER_IMAGES[@]}"; do
        echo ">> Pulling ${img}"
        docker pull "${img}" || true
    done
else
    echo "ERROR: Neither apptainer nor docker found. Run setup script first."
    exit 1
fi

echo
echo "Pre-pull complete. All workshop containers are cached locally."
