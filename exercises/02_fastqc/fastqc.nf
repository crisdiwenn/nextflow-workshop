#!/usr/bin/env nextflow

/*
 * ============================================================================
 *  Exercise 02 — FASTQC in a Biocontainer
 * ============================================================================
 *
 *  GOAL
 *    Run a real bioinformatics tool (FASTQC) inside a container, with
 *    Nextflow handling the container automatically.
 *
 *  WHAT IT DOES
 *    Takes paired-end Illumina reads, runs FASTQC on each pair, and
 *    publishes the HTML reports + zip archives.
 *
 *  HOW TO RUN
 *    cd exercises/02_fastqc
 *    nextflow run fastqc.nf -profile apptainer    # Linux / WSL2
 *    nextflow run fastqc.nf -profile docker       # macOS
 *
 *  KEY NEW CONCEPT
 *    The 'container' directive tells Nextflow which image to use for this
 *    process. Nextflow downloads it once, then runs the script inside it.
 *
 * ============================================================================
 */

nextflow.enable.dsl = 2


/*
 * ----------------------------------------------------------------------------
 *  PARAMETERS
 * ----------------------------------------------------------------------------
 */
// CSV file describing samples. Each row: sample_id,read1,read2
params.samplesheet = "${projectDir}/../data/samplesheet.csv"
params.outdir      = 'results'


/*
 * ----------------------------------------------------------------------------
 *  PROCESS: FASTQC
 * ----------------------------------------------------------------------------
 *  Runs FASTQC on a pair of read files. The container directive picks the
 *  exact version — same image works on Apptainer and Docker.
 *
 *  Note the 'tuple' input: Nextflow groups related files together so a
 *  sample's R1 and R2 always travel as one unit.
 */
process FASTQC {
    tag "$sample_id"
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(read1), path(read2)

    output:
    path "*.html", emit: html
    path "*.zip",  emit: zip

    script:
    """
    fastqc --threads ${task.cpus} ${read1} ${read2}
    """
}


/*
 * ----------------------------------------------------------------------------
 *  WORKFLOW
 * ----------------------------------------------------------------------------
 *  1. Read the sample sheet
 *  2. Download the reads for each sample
 *  3. Run FASTQC on each pair
 */
workflow {
    // Channel.fromPath().splitCsv() reads a CSV row by row.
    // 'header: true' uses the first row as column names.
    reads_ch = Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample_id, file(row.read1), file(row.read2)) }

    // Run FASTQC on each tuple
    FASTQC(reads_ch)
}


/*
 * ============================================================================
 *  TRY THIS
 * ============================================================================
 *  1. Run with verbose container info: nextflow run fastqc.nf -profile apptainer -with-trace
 *  2. Open results/fastqc/*.html in your browser — these are the QC reports
 *  3. Look in work/ — find a folder for one FASTQC run, see the .command.sh
 *     file. That's exactly what Nextflow ran inside the container.
 *  4. Comment out the publishDir line, re-run with -resume, and watch what
 *     happens. (Files stay in work/, never reach results/)
 *
 *  COMMON ERRORS
 *    - "image not found" → check internet connection, retry
 *    - "command not found: fastqc" → you forgot to specify a profile (-profile apptainer)
 *
 *  KEY IDEAS
 *    - 'container' makes any tool reproducible without manual install
 *    - 'tuple' keeps related files together as they flow through the pipeline
 *    - 'tag' makes parallel runs distinguishable in the log
 *    - 'emit:' on outputs lets downstream processes pick specific outputs by name
 * ============================================================================
 */
