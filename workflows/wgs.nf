/*
========================================================================================
    WGS Bioinformatics Workflow
========================================================================================
    Imports all submodules and defines the end-to-end variant-calling workflow:

        FASTQC          → quality control of raw reads
        FASTP           → adapter trimming and quality filtering
        BWA_MEM         → map reads to reference genome + MAPQ filter + sort/index
        SAMBAMBA_MARKDUP → mark duplicate reads
        FREEBAYES       → joint variant calling across all samples
----------------------------------------------------------------------------------------
*/

include { FASTQC            } from '../modules/fastqc'
include { FASTP             } from '../modules/fastp'
include { MULTIQC           } from '../modules/multiqc'
include { BWA_MEM           } from '../modules/bwa_mem'
include { SAMBAMBA_MARKDUP  } from '../modules/sambamba_markdup'
include { FREEBAYES         } from '../modules/freebayes'

workflow WGS {

    take:
    reads           // channel: [ val(sample_id), path(fastq_1), path(fastq_2) ]
    genome          // path: reference genome FASTA
    genome_fai      // path: reference genome FASTA index (.fai)

    main:

    // ----- QC raw reads -------------------------------------------------------
    FASTQC(reads)

    // ----- Trim adapters and low-quality bases --------------------------------
    FASTP(reads)

    // ----- Aggregate QC reports -------------------------------------------------
    ch_multiqc_files = FASTQC.out.zip
        .map { _sample_id, fastqc_zip -> fastqc_zip }
        .mix(FASTP.out.html)
        .mix(FASTP.out.json)
        .collect()

    MULTIQC(ch_multiqc_files)

    // ----- Map trimmed reads to reference genome (MAPQ filter + sort/index) ---
    BWA_MEM(
        FASTP.out.trimmed_reads,
        genome
    )

    // ----- Mark duplicate reads ------------------------------------------------
    SAMBAMBA_MARKDUP(BWA_MEM.out.bam)

    // ----- Joint variant calling and reporting ---------------------------------
    ch_markdup_bams = SAMBAMBA_MARKDUP.out.bam
        .map { _sample_id, bam, _bai -> bam }
        .collect()

    FREEBAYES(
        ch_markdup_bams,
        genome,
        genome_fai
    )

    emit:
    fastqc_html       = FASTQC.out.html
    fastqc_zip        = FASTQC.out.zip
    fastp_html        = FASTP.out.html
    fastp_json        = FASTP.out.json
    multiqc_report    = MULTIQC.out.report
    multiqc_data      = MULTIQC.out.data
    markdup_metrics   = SAMBAMBA_MARKDUP.out.metrics
    final_bam         = SAMBAMBA_MARKDUP.out.bam
    variants_vcf      = FREEBAYES.out.vcf
    variant_report    = FREEBAYES.out.report

}
