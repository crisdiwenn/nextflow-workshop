#!/usr/bin/env nextflow

/*
 * ============================================================================
 *  Exercise 01 — Hello World
 * ============================================================================
 *
 *  GOAL
 *    Learn the three building blocks of every Nextflow pipeline:
 *      1. processes  (units of work, like functions)
 *      2. channels   (data flowing between processes, like pipes)
 *      3. workflow   (how processes connect)
 *
 *  WHAT IT DOES
 *    Takes a list of greetings, makes each one uppercase, and prints them.
 *    No bioinformatics yet — just Nextflow concepts.
 *
 *  HOW TO RUN
 *    cd exercises/01_hello_world
 *    nextflow run hello_world.nf
 *
 *  EXPECTED OUTPUT
 *    Five lines starting with "GREETING:" — order may vary because Nextflow
 *    runs processes in parallel by default!
 *
 * ============================================================================
 */

// DSL2 is the modern Nextflow syntax. Always use it.
nextflow.enable.dsl = 2


/*
 * ----------------------------------------------------------------------------
 *  PARAMETERS
 * ----------------------------------------------------------------------------
 *  params.* values can be overridden from the command line, e.g.:
 *      nextflow run hello_world.nf --greeting "Привет"
 */
params.greetings = ['Hello', 'Bonjour', 'Hola', 'Ciao', 'Hej']
params.outdir    = 'results'


/*
 * ----------------------------------------------------------------------------
 *  PROCESS: SHOUT
 * ----------------------------------------------------------------------------
 *  A process is a unit of work. It has:
 *    - input:   what comes in (here: one greeting at a time)
 *    - output:  what goes out (here: a string with the greeting in uppercase)
 *    - script:  a bash snippet that does the work
 *
 *  Every value in the input channel triggers ONE execution of this process.
 *  Five greetings → five parallel executions.
 */
process SHOUT {
    // Where to publish results. The 'mode: copy' makes a real file you can
    // open afterwards (instead of leaving it in Nextflow's work/ directory).
    publishDir params.outdir, mode: 'copy'

    input:
    val greeting

    output:
    path "shouted_${greeting}.txt"

    script:
    """
    echo "GREETING: ${greeting.toUpperCase()}!" > shouted_${greeting}.txt
    """
}


/*
 * ----------------------------------------------------------------------------
 *  WORKFLOW
 * ----------------------------------------------------------------------------
 *  The workflow block wires processes together. Channels carry data between
 *  them. Here we have just one process, so it's simple.
 */
workflow {
    // Channel.of(...) creates a channel that emits each item as a separate
    // value. So 5 greetings → 5 emissions → 5 parallel SHOUT runs.
    greeting_ch = Channel.of(*params.greetings)

    // Pipe the channel into the process. The process returns a channel of
    // its outputs, which we capture for inspection.
    shouted_ch = SHOUT(greeting_ch)

    // .view() prints whatever flows through a channel. Great for debugging.
    shouted_ch.view { file -> "Wrote: ${file}" }
}


/*
 * ============================================================================
 *  TRY THIS
 * ============================================================================
 *  1. Run it: nextflow run hello_world.nf
 *  2. Look in results/ — there should be 5 .txt files
 *  3. Run it again — Nextflow caches results! It says "[cached]" in the log.
 *  4. Force re-run: nextflow run hello_world.nf -resume false
 *  5. Notice the work/ directory — every run is sandboxed there. Inspect it.
 *
 *  KEY IDEAS TO REMEMBER
 *    - Channels are the data flow. Processes are the work.
 *    - Nextflow parallelizes automatically when items are independent.
 *    - publishDir copies results out of work/ into a clean output folder.
 *    - -resume reuses cached results
 * ============================================================================
 */
