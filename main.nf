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

import java.nio.file.Paths
import java.nio.file.Files

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
    def samplesheet = file(csv_path, checkIfExists: true)
    def samplesheetDir = samplesheet.parent

    def resolveInputPath = { String rawPath ->
        def path = Paths.get(rawPath)
        if (path.isAbsolute()) {
            return path.toString()
        }

        def candidates = [
            samplesheetDir.resolve(rawPath),
            Paths.get(projectDir.toString()).resolve(rawPath),
            Paths.get(rawPath)
        ]

        def existing = candidates.find { Files.exists(it) }
        return (existing ?: samplesheetDir.resolve(rawPath)).toString()
    }

    channel
        .fromPath(samplesheet)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def sample_id = row.sample_id ?: row.sample
            def fastq_1 = file(resolveInputPath(row.fastq_1), checkIfExists: true)
            def fastq_2 = file(resolveInputPath(row.fastq_2), checkIfExists: true)

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
    ============================================================
    """.stripIndent()

    // Build read channel from samplesheet
    ch_reads = parseSamplesheet(params.input)

    // Resolve reference genome files
    ch_genome      = file(params.genome,                checkIfExists: true)

    // Run the bioinformatics workflow
    WGS(
        ch_reads,
        ch_genome
    )

}
