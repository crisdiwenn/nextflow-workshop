# Exercise 02 — FASTQC in a Biocontainer

**Time:** ~15 minutes
**Goal:** Run FASTQC on real Illumina reads, with Nextflow handling the container automatically.

## Run it

```bash
cd exercises/02_fastqc

# Linux / WSL2
nextflow run fastqc.nf -profile apptainer

# macOS
nextflow run fastqc.nf -profile docker
```

First run downloads ~50 MB of test reads and the FASTQC container (~80 MB). Subsequent runs are cached.

## What you should see

After ~1–2 minutes:

```
[xx/yyyyyy] DOWNLOAD_READS (sample_A) [100%] 2 of 2 ✔
[xx/yyyyyy] FASTQC (sample_B)         [100%] 2 of 2 ✔
```

And in `results/fastqc/`:
- `sample_A_R1_fastqc.html` ← open this in your browser
- `sample_A_R1_fastqc.zip`
- `sample_A_R2_fastqc.html`
- `sample_A_R2_fastqc.zip`
- ...same for sample_B

## Try this

1. Open `pipeline_report.html` in `results/` — Nextflow's resource usage report
2. Look in `work/` — find one FASTQC task folder. Inspect `.command.sh` (what was run) and `.command.log` (what it printed)
3. Add a third sample to `../data/samplesheet.csv` and run with `-resume` — only the new sample reprocesses

## What you learned

- The `container` directive runs any tool in a reproducible environment
- Profiles (`-profile apptainer` vs `-profile docker`) handle the runtime difference between OSes
- `tuple` channels keep related files (R1 + R2) together as they move through the pipeline
- `tag "$sample_id"` makes the log readable when many samples run in parallel
- `emit:` names outputs so downstream processes can pick specific ones
