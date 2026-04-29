#!/usr/bin/env bash
# =============================================================================
# verify.sh — Confirm the workshop environment is working
#
# Detects OS, checks every required tool, runs a Nextflow hello-world.
# Output is designed to be pasted into Slack/Discord by attendees.
# =============================================================================

set +e   # don't abort on first failure — we want to report everything

PASS=0
FAIL=0

green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
red() { printf "\033[0;31m%s\033[0m\n" "$1"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$1"; }

check() {
    local name="$1"
    local cmd="$2"
    local expected="${3:-}"

    if eval "${cmd}" &>/dev/null; then
        local version
        version=$(eval "${cmd}" 2>&1 | head -n1)
        green "  ✓ ${name}: ${version}"
        PASS=$((PASS+1))
    else
        red "  ✗ ${name}: NOT FOUND"
        FAIL=$((FAIL+1))
    fi
}

echo "================================================================"
echo "Nextflow Workshop — Environment Check"
echo "Date: $(date)"
echo "OS: $(uname -s) $(uname -r)"
echo "Shell: ${SHELL}"
echo "================================================================"
echo

echo "Tool versions:"
check "Java" "java -version 2>&1"
check "Nextflow" "nextflow -v"

# Container runtime varies by OS
if command -v apptainer &>/dev/null; then
    check "Apptainer" "apptainer --version"
    CONTAINER_RUNTIME="apptainer"
elif command -v docker &>/dev/null; then
    check "Docker" "docker --version"
    if docker info &>/dev/null; then
        green "  ✓ Docker daemon: running"
        PASS=$((PASS+1))
    else
        red "  ✗ Docker daemon: not running (open Docker Desktop)"
        FAIL=$((FAIL+1))
    fi
    CONTAINER_RUNTIME="docker"
else
    red "  ✗ No container runtime found (need Apptainer on Linux or Docker on macOS)"
    FAIL=$((FAIL+1))
    CONTAINER_RUNTIME="none"
fi

echo
echo "Environment variables:"
echo "  NXF_VER = ${NXF_VER:-(not set)}"
echo "  PATH includes ~/.local/bin: $([[ ":${PATH}:" == *":${HOME}/.local/bin:"* ]] && echo yes || echo no)"

echo
echo "Pulling a test biocontainer (this verifies network + container runtime):"

if [[ "${CONTAINER_RUNTIME}" == "apptainer" ]]; then
    if apptainer pull --force /tmp/_workshop_test.sif \
        https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0 &>/tmp/_pull.log; then
        green "  ✓ Container pull successful"
        PASS=$((PASS+1))
        if apptainer exec /tmp/_workshop_test.sif fastqc --version &>/dev/null; then
            green "  ✓ Container execution successful"
            PASS=$((PASS+1))
        else
            red "  ✗ Container pulled but won't execute"
            FAIL=$((FAIL+1))
        fi
        rm -f /tmp/_workshop_test.sif
    else
        red "  ✗ Container pull failed (see /tmp/_pull.log)"
        FAIL=$((FAIL+1))
    fi
elif [[ "${CONTAINER_RUNTIME}" == "docker" ]]; then
    if docker pull quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0 &>/tmp/_pull.log; then
        green "  ✓ Container pull successful"
        PASS=$((PASS+1))
        if docker run --rm quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0 \
            fastqc --version &>/dev/null; then
            green "  ✓ Container execution successful"
            PASS=$((PASS+1))
        else
            red "  ✗ Container pulled but won't execute"
            FAIL=$((FAIL+1))
        fi
    else
        red "  ✗ Container pull failed (see /tmp/_pull.log)"
        FAIL=$((FAIL+1))
    fi
fi

echo
echo "Running Nextflow hello-world:"
if nextflow run hello -ansi-log false &>/tmp/_nf_test.log; then
    green "  ✓ Nextflow hello-world completed"
    PASS=$((PASS+1))
else
    red "  ✗ Nextflow hello-world failed (see /tmp/_nf_test.log)"
    FAIL=$((FAIL+1))
fi

echo
echo "================================================================"
if [[ ${FAIL} -eq 0 ]]; then
    green "ALL CHECKS PASSED (${PASS}/${PASS}) — you're ready for the workshop!"
else
    red "${FAIL} CHECK(S) FAILED (${PASS} passed, ${FAIL} failed)"
    yellow "Paste this output in the workshop Slack/Discord channel for help."
fi
echo "================================================================"
