#!/usr/bin/env nextflow
/*
========================================================================================
    nf-wgs - Whole-Genome Sequence Processing Pipeline
========================================================================================
    Entry point.  Validates parameters, logs workflow metadata, and calls the WGS
    bioinformatics workflow defined in workflows/wgs.nf.
----------------------------------------------------------------------------------------
    Usage:
        nextflow run main.nf \\
            --input      samplesheet.csv \\
            --outdir     results \\
            --genome     /path/to/genome.fa

    Stub / dry-run (no real tools needed):
        nextflow run main.nf -stub \\
            --input      samplesheet.csv \\
            --outdir     results \\
            --genome     /path/to/genome.fa
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

include { WGS } from './workflows/wgs'

// ── Parameter validation ──────────────────────────────────────────────────────

def validateParams() {

    def errors = []

    if (!params.input) {
        errors << "Please provide an input samplesheet with --input  (e.g. --input samplesheet.csv)"
    }

    if (!params.genome) {
        errors << "Please provide a reference genome FASTA with --genome  (e.g. --genome /path/to/genome.fa)"
    }

    if (errors) {
        log.error "Parameter errors:\n  " + errors.join('\n  ')
        System.exit(1)
    }

}

// ── Helper: parse samplesheet CSV ────────────────────────────────────────────
//  Expected columns: sample_id, fastq_1, fastq_2

def parseSamplesheet(csv_path) {
    channel
        .fromPath(csv_path)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def sample_id = row.sample_id ?: row.sample
            def fastq_1   = file(row.fastq_1, checkIfExists: true)
            def fastq_2   = file(row.fastq_2, checkIfExists: true)
            tuple(sample_id, fastq_1, fastq_2)
        }
}

// ── Workflow entry point ──────────────────────────────────────────────────────

workflow {

    validateParams()

    log.info """
    ============================================================
     nf-wgs  ~  Whole-Genome Sequence Processing Pipeline
    ============================================================
     input       : ${params.input}
     outdir      : ${params.outdir}
     genome      : ${params.genome}
        genome_index: ${params.genome_index ?: params.genome}
    ============================================================
    """.stripIndent()

    // Build read channel from samplesheet
    ch_reads = parseSamplesheet(params.input)

    // Resolve reference genome files
    ch_genome      = file(params.genome,                checkIfExists: true)
    // Resolve BWA-MEM2 index prefix (defaults to genome path)
    ch_genome_index = params.genome_index
        ? params.genome_index
        : params.genome

    // Run the bioinformatics workflow
    WGS(
        ch_reads,
        ch_genome,
        ch_genome_index
    )

}
