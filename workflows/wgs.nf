/*
========================================================================================
    WGS Bioinformatics Workflow
========================================================================================
    Imports all submodules and defines the end-to-end variant-calling workflow:

        FASTQC          → quality control of raw reads
        FASTP           → adapter trimming and quality filtering
        BWA_MEM         → map reads to reference genome
        SAMTOOLS_SORT   → coordinate-sort and index BAM
        MARK_DUPLICATES → mark PCR duplicates
        BASE_RECALIBRATOR / APPLY_BQSR → base quality score recalibration
        HAPLOTYPECALLER → per-sample GVCF variant calling
        GENOTYPE_GVCFS  → joint genotyping across all samples
        VARIANT_FILTRATION → hard-filter SNPs and indels
----------------------------------------------------------------------------------------
*/

include { FASTQC            } from '../modules/fastqc'
include { FASTP             } from '../modules/fastp'
include { BWA_MEM           } from '../modules/bwa_mem'
include { SAMTOOLS_SORT     } from '../modules/samtools_sort'
include { MARK_DUPLICATES   } from '../modules/mark_duplicates'
include { BASE_RECALIBRATOR } from '../modules/base_recalibrator'
include { APPLY_BQSR        } from '../modules/apply_bqsr'
include { HAPLOTYPECALLER   } from '../modules/haplotypecaller'
include { GENOTYPE_GVCFS    } from '../modules/genotype_gvcfs'
include { VARIANT_FILTRATION} from '../modules/variant_filtration'

workflow WGS {

    take:
    reads           // channel: [ val(sample_id), path(fastq_1), path(fastq_2) ]
    genome          // path: reference genome FASTA
    genome_fai      // path: reference genome FAI index
    genome_dict     // path: reference genome sequence dictionary
    genome_index    // path: BWA-MEM2 index directory
    known_sites     // list of paths: VCFs with known variant sites (for BQSR)
    known_sites_tbi // list of paths: TBI indexes for known_sites VCFs
    intervals       // val: optional interval string for genotyping (can be null/"")

    main:

    // ----- QC raw reads -------------------------------------------------------
    FASTQC(reads)

    // ----- Trim adapters and low-quality bases --------------------------------
    FASTP(reads)

    // ----- Map trimmed reads to reference genome ------------------------------
    BWA_MEM(
        FASTP.out.trimmed_reads,
        genome,
        genome_index
    )

    // ----- Coordinate-sort and index the BAM ----------------------------------
    SAMTOOLS_SORT(BWA_MEM.out.bam)

    // ----- Mark PCR duplicates ------------------------------------------------
    MARK_DUPLICATES(SAMTOOLS_SORT.out.sorted_bam)

    // ----- Base quality score recalibration -----------------------------------
    BASE_RECALIBRATOR(
        MARK_DUPLICATES.out.bam,
        genome,
        genome_fai,
        genome_dict,
        known_sites,
        known_sites_tbi
    )

    // Join the markdup BAM with its recal table
    ch_bqsr_input = MARK_DUPLICATES.out.bam
        .join(BASE_RECALIBRATOR.out.recal_table, by: 0)
        .map { sample_id, bam, bai, recal_table -> tuple(sample_id, bam, bai, recal_table) }

    APPLY_BQSR(
        ch_bqsr_input,
        genome,
        genome_fai,
        genome_dict
    )

    // ----- Per-sample variant calling (GVCF mode) -----------------------------
    HAPLOTYPECALLER(
        APPLY_BQSR.out.bam,
        genome,
        genome_fai,
        genome_dict
    )

    // ----- Build GenomicsDB sample map and run joint genotyping ---------------
    // Collect all per-sample GVCFs and build a two-column sample map file
    ch_sample_map = HAPLOTYPECALLER.out.gvcf
        .collect { sample_id, gvcf, tbi -> "${sample_id}\t${gvcf}" }
        .map     { lines -> lines.join('\n') }
        .collectFile(name: 'sample_map.tsv', newLine: false)

    ch_all_gvcfs    = HAPLOTYPECALLER.out.gvcf.map { sid, g, t -> g }.collect()
    ch_all_gvcf_tbi = HAPLOTYPECALLER.out.gvcf.map { sid, g, t -> t }.collect()

    GENOTYPE_GVCFS(
        ch_sample_map,
        ch_all_gvcfs,
        ch_all_gvcf_tbi,
        genome,
        genome_fai,
        genome_dict,
        intervals ?: ""
    )

    // ----- Hard-filter SNPs and indels ----------------------------------------
    VARIANT_FILTRATION(
        GENOTYPE_GVCFS.out.vcf,
        GENOTYPE_GVCFS.out.tbi,
        genome,
        genome_fai,
        genome_dict,
        params.snp_filter_expr,
        params.indel_filter_expr
    )

    emit:
    fastqc_html       = FASTQC.out.html
    fastqc_zip        = FASTQC.out.zip
    fastp_html        = FASTP.out.html
    fastp_json        = FASTP.out.json
    markdup_metrics   = MARK_DUPLICATES.out.metrics
    final_bam         = APPLY_BQSR.out.bam
    gvcf              = HAPLOTYPECALLER.out.gvcf
    joint_vcf         = GENOTYPE_GVCFS.out.vcf
    filtered_vcf      = VARIANT_FILTRATION.out.vcf

}
