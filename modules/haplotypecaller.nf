/*
========================================================================================
    HAPLOTYPECALLER - Per-sample variant calling with GATK HaplotypeCaller (GVCF mode)
========================================================================================
*/

process HAPLOTYPECALLER {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(bam), path(bai)
    path  genome
    path  genome_fai
    path  genome_dict

    output:
    tuple val(sample_id), path("${sample_id}.g.vcf.gz"), path("${sample_id}.g.vcf.gz.tbi"), emit: gvcf

    stub:
    """
    echo "gatk HaplotypeCaller -I ${bam} -R ${genome} -O ${sample_id}.g.vcf.gz -ERC GVCF --native-pair-hmm-threads ${task.cpus}"
    touch ${sample_id}.g.vcf.gz
    touch ${sample_id}.g.vcf.gz.tbi
    """

    script:
    """
    gatk HaplotypeCaller \\
        -I ${bam} \\
        -R ${genome} \\
        -O ${sample_id}.g.vcf.gz \\
        -ERC GVCF \\
        --native-pair-hmm-threads ${task.cpus}
    """

}
