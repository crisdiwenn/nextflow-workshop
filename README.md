# Nextflow + Biocontainers Workshop

A hands-on workshop for running reproducible bioinformatics pipelines with Nextflow and biocontainers.

> **Important:** Complete the setup below **before the workshop**. We have limited time and want to spend it on pipelines, not installation.

---

## Pre-flight checklist (do this 1 week before the workshop)

### Step 1 — Pick your operating system

| OS | Container runtime | Setup script |
|---|---|---|
| **WSL2 / Linux Ubuntu** | Apptainer | [`scripts/setup_linux.sh`](scripts/setup_linux.sh) |
| **macOS (Intel or Apple Silicon)** | Docker Desktop | [`scripts/setup_macos.sh`](scripts/setup_macos.sh) |

> **Don't have WSL2 yet?** Windows users: install WSL2 with Ubuntu first — see [Microsoft's guide](https://learn.microsoft.com/en-us/windows/wsl/install). Allow ~10 min.

### Step 2 — Run the setup script

**WSL2 / Linux:**
```bash
git clone https://github.com/crisdiwenn/nextflow-workshop.git
cd nextflow-workshop
chmod +x scripts/setup_linux.sh
./scripts/setup_linux.sh
```

**macOS:**
```bash
git clone https://github.com/crisdiwenn/nextflow-workshop.git
cd nextflow-workshop
chmod +x scripts/setup_macos.sh
./scripts/setup_macos.sh
```

### Step 3 — Verify your install

After the script finishes, **open a new terminal** and run:

```bash
./scripts/verify.sh
```

You should see all green checkmarks. **Paste the output in the workshop Slack/Discord channel** so we know you're ready.

If anything fails, see [Troubleshooting](#troubleshooting) below or message in the workshop channel.

---

## What gets installed

- **Java 21** — Nextflow runtime requirement
- **Nextflow 24.04.2** — pinned version so everyone runs the same code
- **Container runtime** — Apptainer on Linux/WSL2, Docker Desktop on macOS
- **nf-core tools** — for browsing and downloading curated pipelines

Total disk: ~2 GB. Total time: ~15 minutes on a decent connection.

---

## Workshop day

We'll work through three exercises:

1. **Hello world** — your first Nextflow pipeline (5 min)
2. **FASTQC on real reads** — running a single biocontainer (15 min)
3. **A small QC pipeline** — chaining FASTQC + FASTP with Nextflow (40 min)

All exercise materials are in [`exercises/`](exercises/).

---

## Troubleshooting

### "command not found" after running the script
Open a **new terminal**. The script adds env vars to your shell config which only load on new sessions.

### WSL2: "operation not permitted" when pulling containers
Your WSL2 instance may not have user namespaces enabled. Run:
```bash
sudo sh -c 'echo "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/00-local-userns.conf'
sudo sysctl --system
```

### macOS: Docker Desktop won't start
Make sure you have **8 GB+ RAM allocated** in Docker Desktop preferences (Settings → Resources). Default is often too low for biocontainers.

### "Java version too old"
Nextflow 24.x needs Java 17+. Check with `java -version`. The setup scripts install Java 21 — if you skipped that step, run the script again.

### Slow downloads / corporate firewall
You can pre-pull all containers used in the workshop:
```bash
./scripts/prepull_containers.sh
```
This caches them so the workshop runs offline.

---

## Resources

- [Nextflow docs](https://www.nextflow.io/docs/latest/)
- [nf-core pipelines](https://nf-co.re/pipelines)
- [Biocontainers registry](https://biocontainers.pro/)
- [Galaxy depot (SIF files)](https://depot.galaxyproject.org/singularity/)

---

## License

MIT — feel free to adapt for your own workshops.
