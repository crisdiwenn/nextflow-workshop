#!/usr/bin/env nextflow

/*
 * ============================================================================
 *  Exercise 03 — A Real QC Pipeline
 * ============================================================================
 *
 *  GOAL
 *    Build a complete read-QC pipeline: assess raw reads, trim them,
 *    re-assess the trimmed reads, then summarize everything with MultiQC.
 *
 *  PIPELINE FLOW
 *
 *      reads ──► FASTQC_RAW ────────────────────┐
 *                                              │
 *      reads ──► FASTP ──► FASTQC_TRIMMED ─────┤──► MULTIQC ──► report
 *                    │                         │
 *                    └── fastp.json ───────────┘
 *
 *  HOW TO RUN
 *    cd exercises/03_qc_pipeline
 *    nextflow run qc_pipeline.nf -profile apptainer    # Linux / WSL2
 *    nextflow run qc_pipeline.nf -profile docker       # macOS
 *
 *  KEY NEW CONCEPTS
 *    - Multiple processes chained via channels
 *    - Channel operators (.collect, .mix) to combine outputs
 *    - Same process used twice (FASTQC on raw + trimmed)
 *
 * ============================================================================
 */

nextflow.enable.dsl = 2


// ---- Parameters ------------------------------------------------------------
params.samplesheet = "${projectDir}/../data/samplesheet.csv"
params.outdir      = 'results'


/*
 * ----------------------------------------------------------------------------
 *  PROCESS: FASTQC_RAW / FASTQC_TRIMMED
 * ----------------------------------------------------------------------------
 *  DSL2 does not allow calling the same process twice in one workflow, so
 *  we define two identically-scripted processes with different publishDir
 *  destinations.
 */
process FASTQC_RAW {
    tag "$sample_id"
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    publishDir "${params.outdir}/fastqc_raw", mode: 'copy'

    input:
    tuple val(sample_id), path(read1), path(read2)

    output:
    path "*_fastqc.{html,zip}"

    script:
    """
    fastqc --threads ${task.cpus} ${read1} ${read2}
    """
}

process FASTQC_TRIMMED {
    tag "$sample_id"
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy'

    input:
    tuple val(sample_id), path(read1), path(read2)

    output:
    path "*_fastqc.{html,zip}"

    script:
    """
    fastqc --threads ${task.cpus} ${read1} ${read2}
    """
}


/*
 * ----------------------------------------------------------------------------
 *  PROCESS: FASTP
 * ----------------------------------------------------------------------------
 *  Trims adapters and low-quality bases. Outputs trimmed reads + a JSON
 *  report (which MultiQC will later parse).
 */
process FASTP {
    tag "$sample_id"
    container 'quay.io/biocontainers/fastp:0.23.4--h5f740d0_0'
    publishDir "${params.outdir}/fastp", mode: 'copy'

    input:
    tuple val(sample_id), path(read1), path(read2)

    output:
    tuple val(sample_id),
          path("${sample_id}_trimmed_R1.fastq.gz"),
          path("${sample_id}_trimmed_R2.fastq.gz"), emit: reads
    path  "${sample_id}_fastp.json",                emit: json
    path  "${sample_id}_fastp.html",                emit: html

    script:
    """
    fastp \\
        --in1 ${read1} \\
        --in2 ${read2} \\
        --out1 ${sample_id}_trimmed_R1.fastq.gz \\
        --out2 ${sample_id}_trimmed_R2.fastq.gz \\
        --json ${sample_id}_fastp.json \\
        --html ${sample_id}_fastp.html \\
        --thread ${task.cpus} \\
        --detect_adapter_for_pe
    """
}


/*
 * ----------------------------------------------------------------------------
 *  PROCESS: MULTIQC
 * ----------------------------------------------------------------------------
 *  Aggregates all QC tool outputs into one HTML report. This is the
 *  "nice deliverable" at the end of any QC pipeline.
 */
process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'
    publishDir params.outdir, mode: 'copy'

    input:
    path('*')   // collect everything into one staging directory

    output:
    path "multiqc_report.html"
    path "multiqc_report_data"

    script:
    """
    multiqc . --filename multiqc_report.html
    """
}


/*
 * ============================================================================
 *  WORKFLOW — wires the four processes together
 * ============================================================================
 */
workflow {

    // 1. Read the sample sheet, resolve local read paths
    raw_reads_ch = Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample_id, file(row.read1), file(row.read2)) }

    // 2. FASTQC on raw reads
    fastqc_raw_ch = FASTQC_RAW(raw_reads_ch)

    // 3. Trim with FASTP. Returns multiple named outputs (.reads, .json, .html)
    fastp_out = FASTP(raw_reads_ch)

    // 4. FASTQC on trimmed reads
    fastqc_trimmed_ch = FASTQC_TRIMMED(fastp_out.reads)

    // 5. MultiQC needs ALL the QC outputs in one place.
    //    .mix() merges channels; .collect() turns many emissions into one list.
    all_reports_ch = fastqc_raw_ch
        .mix(fastqc_trimmed_ch)
        .mix(fastp_out.json)
        .collect()

    MULTIQC(all_reports_ch)
}


/*
 * ============================================================================
 *  TRY THIS
 * ============================================================================
 *  1. Open results/multiqc_report.html — this is your final deliverable
 *  2. Notice how raw vs trimmed FASTQC are clearly compared in MultiQC
 *  3. Re-run with -resume after changing one sample — only that sample
 *     reprocesses through the whole chain
 *  WHAT YOU LEARNED
 *    - Same process can be called multiple times with different inputs
 *    - 'emit:' names outputs so you can grab specific ones (.reads, .json)
 *    - .mix() and .collect() are the bread-and-butter channel operators
 *    - MultiQC is a great closing step for any QC-heavy pipeline
 *
 *  WHERE TO GO FROM HERE
 *    - Replace FASTP with cutadapt / trimmomatic — it's just a container swap, look for it in biocontainers  
 *    - Run the same pipeline on Vera2 by adding a -profile slurm
 * ============================================================================
 */
