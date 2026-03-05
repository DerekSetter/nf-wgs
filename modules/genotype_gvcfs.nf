/*
========================================================================================
    GENOTYPE_GVCFS - Joint genotyping of per-sample GVCFs with GATK GenotypeGVCFs
========================================================================================
    Combines all sample GVCFs via GenomicsDBImport before joint genotyping.
*/

process GENOTYPE_GVCFS {

    tag "joint_genotyping"

    input:
    path  sample_map       // Text file: two-column TSV with sample name and GVCF path
    path  gvcfs            // All GVCF files (staged alongside sample_map)
    path  gvcf_tbis        // All GVCF TBI index files
    path  genome
    path  genome_fai
    path  genome_dict
    val   intervals        // Optional: comma-separated list of intervals/chromosomes

    output:
    path "joint.vcf.gz",     emit: vcf
    path "joint.vcf.gz.tbi", emit: tbi

    stub:
    def intervals_arg = intervals ? "--intervals ${intervals}" : ""
    """
    echo "gatk GenomicsDBImport --sample-name-map ${sample_map} --genomicsdb-workspace-path genomicsdb ${intervals_arg}"
    echo "gatk GenotypeGVCFs -R ${genome} -V gendb://genomicsdb -O joint.vcf.gz ${intervals_arg}"
    mkdir -p genomicsdb
    touch joint.vcf.gz
    touch joint.vcf.gz.tbi
    """

    script:
    def intervals_arg = intervals ? "--intervals ${intervals}" : ""
    """
    gatk GenomicsDBImport \\
        --sample-name-map ${sample_map} \\
        --genomicsdb-workspace-path genomicsdb \\
        ${intervals_arg}

    gatk GenotypeGVCFs \\
        -R ${genome} \\
        -V gendb://genomicsdb \\
        -O joint.vcf.gz \\
        ${intervals_arg}
    """

}
