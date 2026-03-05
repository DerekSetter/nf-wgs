/*
========================================================================================
    BASE_RECALIBRATOR - Compute base quality score recalibration (BQSR) table with GATK
========================================================================================
*/

process BASE_RECALIBRATOR {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(bam), path(bai)
    path  genome
    path  genome_fai
    path  genome_dict
    path  known_sites     // list of VCF files with known variant sites
    path  known_sites_tbi // list of corresponding TBI index files

    output:
    tuple val(sample_id), path("${sample_id}.recal.table"), emit: recal_table

    stub:
    def known_sites_arg = known_sites instanceof List
        ? known_sites.collect { "--known-sites ${it}" }.join(' ')
        : "--known-sites ${known_sites}"
    """
    echo "gatk BaseRecalibrator -I ${bam} -R ${genome} ${known_sites_arg} -O ${sample_id}.recal.table"
    touch ${sample_id}.recal.table
    """

    script:
    def known_sites_arg = known_sites instanceof List
        ? known_sites.collect { "--known-sites ${it}" }.join(' ')
        : "--known-sites ${known_sites}"
    """
    gatk BaseRecalibrator \\
        -I ${bam} \\
        -R ${genome} \\
        ${known_sites_arg} \\
        -O ${sample_id}.recal.table
    """

}
