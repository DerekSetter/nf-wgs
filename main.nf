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
            --genome     /path/to/genome.fa \\
            --known_sites /path/to/dbsnp.vcf.gz

    Stub / dry-run (no real tools needed):
        nextflow run main.nf -stub \\
            --input      samplesheet.csv \\
            --outdir     results \\
            --genome     /path/to/genome.fa \\
            --known_sites /path/to/dbsnp.vcf.gz
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
    Channel
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
     known_sites : ${params.known_sites}
     intervals   : ${params.containsKey('intervals') ? params.intervals : 'none'}
    ============================================================
    """.stripIndent()

    // Build read channel from samplesheet
    ch_reads = parseSamplesheet(params.input)

    // Resolve reference genome files
    ch_genome      = file(params.genome,                checkIfExists: true)
    ch_genome_fai  = file("${params.genome}.fai",       checkIfExists: false)
    ch_genome_dict = file(params.genome.replaceAll(/\.(fa|fasta)$/, '.dict'), checkIfExists: false)

    // Resolve BWA-MEM2 index (directory or same prefix as genome)
    ch_genome_index = params.genome_index
        ? file(params.genome_index, checkIfExists: true)
        : file(params.genome,       checkIfExists: true)   // bwa-mem2 accepts the FASTA when index files are co-located

    // Known sites for BQSR
    ch_known_sites     = params.known_sites     ? params.known_sites.collect     { f -> file(f, checkIfExists: true) } : []
    ch_known_sites_tbi = params.known_sites_tbi ? params.known_sites_tbi.collect { f -> file(f, checkIfExists: true) } : []

    // Optional interval string (e.g. "chr1,chr2" or path to BED/interval_list)
    def intervals = params.containsKey('intervals') ? params.intervals : null

    // Run the bioinformatics workflow
    WGS(
        ch_reads,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict,
        ch_genome_index,
        ch_known_sites,
        ch_known_sites_tbi,
        intervals
    )

}
