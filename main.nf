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
include { WGSNOTRIMMING } from './workflows/wgs'

// Allow users to skip the trimming step by selecting the alternate workflow
params.skip_trimming = params.skip_trimming ?: false

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

def resolveInputPath(samplesheet_dir, raw_path) {
    def path = java.nio.file.Paths.get(raw_path)
    if (path.isAbsolute()) {
        return path.toString()
    }

    def candidates = [
        samplesheet_dir.resolve(raw_path),
        java.nio.file.Paths.get(projectDir.toString()).resolve(raw_path),
        java.nio.file.Paths.get(raw_path)
    ]

    def existing = candidates.find { candidate -> java.nio.file.Files.exists(candidate) }
    return (existing ?: samplesheet_dir.resolve(raw_path)).toString()
}

def parseSamplesheet(csv_path) {
    def samplesheet = file(csv_path, checkIfExists: true)
    def samplesheetDir = samplesheet.parent

    channel
        .fromPath(samplesheet)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def sample_id = row.sample_id ?: row.sample
            def fastq_1 = file(resolveInputPath(samplesheetDir, row.fastq_1), checkIfExists: true)
            def fastq_2 = file(resolveInputPath(samplesheetDir, row.fastq_2), checkIfExists: true)

            tuple(sample_id, fastq_1, fastq_2)
        }
}

// ── Helper: ensure FASTA index exists beside reference FASTA ───────────────────────

def ensureGenomeFai(genome_path) {
    def genomePath = java.nio.file.Paths.get(genome_path).toAbsolutePath().normalize()
    def faiPath = java.nio.file.Paths.get("${genomePath}.fai")

    if (java.nio.file.Files.exists(faiPath)) {
        log.info "Using existing FASTA index: ${faiPath}"
        return faiPath.toString()
    }

    log.info "FASTA index not found; generating with samtools faidx: ${faiPath}"
    def proc = ["samtools", "faidx", genomePath.toString()].execute()
    def stdout = new StringBuffer()
    def stderr = new StringBuffer()
    proc.waitForProcessOutput(stdout, stderr)

    if (proc.exitValue() != 0 || !java.nio.file.Files.exists(faiPath)) {
        if (stdout) log.error stdout.toString().trim()
        if (stderr) log.error stderr.toString().trim()
        log.error "Failed to generate FASTA index at ${faiPath}. Ensure samtools is installed and writable permissions exist in the genome directory."
        System.exit(1)
    }

    log.info "Generated FASTA index: ${faiPath}"
    return faiPath.toString()
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
    genome_fai_path = ensureGenomeFai(params.genome)
    ch_genome       = file(params.genome, checkIfExists: true)
    ch_genome_fai   = file(genome_fai_path, checkIfExists: true)

    // Run the bioinformatics workflow (select no-trimming variant if requested)
    if (params.skip_trimming) {
        WGSNOTRIMMING(
            ch_reads,
            ch_genome,
            ch_genome_fai
        )
    } else {
        WGS(
            ch_reads,
            ch_genome,
            ch_genome_fai
        )
    }

}
