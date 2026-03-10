/*
========================================================================================
    GIMBLE_PREPROCESS - Optional SNP-only and callable-sites preprocessing from joint VCF
========================================================================================
*/

process GIMBLE_PREPROCESS {

    tag "gimble"

    input:
    path vcf
    path genome
    path bams

    output:
    path "${params.gimble_prefix}*", emit: result

    script:
    def bams_file = 'joint.bams'
    def bam_lines = bams.collect { bam_file -> bam_file.toString() }.join('\n')
    """
    cat > ${bams_file} <<'EOF'
    ${bam_lines}
    EOF

    ${params.gimble_executable} preprocess \
        -f ${genome} \
        -v ${vcf} \
        -b ${bams_file} \
        -g ${params.gimble_g} \
        -q ${params.gimble_q} \
        -m ${params.gimble_m} \
        -M ${params.gimble_M} \
        -t ${task.cpus} \
        -o ${params.gimble_prefix} \
        -k
    """

    stub:
    """
    touch ${params.gimble_prefix}.vcf.gz
    touch ${params.gimble_prefix}.bed
    """

}
