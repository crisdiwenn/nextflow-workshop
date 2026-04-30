# Exercise 03 — A Real QC Pipeline

**Time:** ~40 minutes
**Goal:** Build a proper QC pipeline that chains four tools: FASTQC → FASTP → FASTQC → MultiQC.

## Pipeline diagram

```
reads ──► FASTQC_RAW ──┐
                       │
reads ──► FASTP ───┬──► FASTQC_TRIMMED ──┐
                   │                     ├──► MULTIQC ──► report.html
reads ─────────────┘                     │
                                         │
FASTP_LOGS ──────────────────────────────┘
```

## Run it

```bash
cd exercises/03_qc_pipeline

# Linux / WSL2
nextflow run qc_pipeline.nf -profile apptainer

# macOS
nextflow run qc_pipeline.nf -profile docker
```

First run: ~3–5 minutes (downloads reads + 4 containers). Subsequent runs are cached.

## What you should see

```
[xx/yyyyyy] DOWNLOAD_READS         [100%] 2 of 2 ✔
[xx/yyyyyy] FASTQC (sample_A_raw)  [100%] 2 of 2 ✔
[xx/yyyyyy] FASTP (sample_A)       [100%] 2 of 2 ✔
[xx/yyyyyy] FASTQC (sample_A_trimmed) [100%] 2 of 2 ✔
[xx/yyyyyy] MULTIQC                [100%] 1 of 1 ✔
```

The headline output is `results/multiqc_report.html` — a single dashboard comparing raw vs trimmed read quality across all samples.

## Try this

1. **Open `multiqc_report.html`** — see how the General Statistics section shows raw and trimmed metrics side-by-side
2. **Generate a DAG visualization:**
   ```bash
   sudo apt install graphviz   # if not already installed
   nextflow run qc_pipeline.nf -profile apptainer -with-dag flowchart.png
   ```
3. **Modify FASTP parameters** by editing the `script:` block — try adding `--qualified_quality_phred 20` for stricter quality filtering
4. **Add a third sample** to `../data/samplesheet.csv`, run with `-resume`, watch only the new sample reprocess

## What you learned

- Chaining processes via channel outputs (the `fastp_out.reads → FASTQC` pattern)
- Using the same process twice with different inputs (FASTQC on raw + trimmed)
- Channel operators: `.mix()` to merge multiple channels, `.collect()` to gather all emissions into one list (which MultiQC needs)
- Configuring per-process resources (`withName: FASTP`)
- Generating execution reports, timelines, and DAGs for free

## Going further

The `slurm` profile in `nextflow.config` is a starting template for running this same pipeline on an HPC cluster. The pipeline code doesn't change — only the executor and resource directives.

This is the core promise of Nextflow: write once, run anywhere. Laptop → HPC → cloud, same code.
