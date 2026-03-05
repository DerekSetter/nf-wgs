/*
========================================================================================
    WGS Bioinformatics Workflow
========================================================================================
    Imports all submodules and defines the end-to-end variant-calling workflow:

        FASTQC          → quality control of raw reads
        FASTP           → adapter trimming and quality filtering
        BWA_MEM         → map reads to reference genome
        SAMTOOLS_SORT   → coordinate-sort and index BAM
        FREEBAYES       → per-sample variant calling and summary report
----------------------------------------------------------------------------------------
*/

include { FASTQC            } from '../modules/fastqc'
include { FASTP             } from '../modules/fastp'
include { MULTIQC           } from '../modules/multiqc'
include { BWA_MEM           } from '../modules/bwa_mem'
include { SAMTOOLS_SORT     } from '../modules/samtools_sort'
include { FREEBAYES         } from '../modules/freebayes'

workflow WGS {

    take:
    reads           // channel: [ val(sample_id), path(fastq_1), path(fastq_2) ]
    genome          // path: reference genome FASTA
    genome_index    // val: BWA-MEM2 index prefix (defaults to genome path)

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

    // ----- Map trimmed reads to reference genome ------------------------------
    BWA_MEM(
        FASTP.out.trimmed_reads,
        genome,
        genome_index
    )

    // ----- Coordinate-sort and index the BAM ----------------------------------
    SAMTOOLS_SORT(BWA_MEM.out.bam)

    // ----- Variant calling and reporting ---------------------------------------
    FREEBAYES(
        SAMTOOLS_SORT.out.sorted_bam,
        genome
    )

    emit:
    fastqc_html       = FASTQC.out.html
    fastqc_zip        = FASTQC.out.zip
    fastp_html        = FASTP.out.html
    fastp_json        = FASTP.out.json
    multiqc_report    = MULTIQC.out.report
    multiqc_data      = MULTIQC.out.data
    final_bam         = SAMTOOLS_SORT.out.sorted_bam
    variants_vcf      = FREEBAYES.out.vcf
    variant_report    = FREEBAYES.out.report

}
