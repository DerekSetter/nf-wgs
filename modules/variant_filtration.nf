/*
========================================================================================
    VARIANT_FILTRATION - Hard-filter SNPs and indels from joint VCF using GATK
========================================================================================
    Separates SNPs and indels, applies hard filters, then merges results.
*/

process VARIANT_FILTRATION {

    tag "variant_filtration"

    input:
    path  vcf
    path  vcf_tbi
    path  genome
    path  genome_fai
    path  genome_dict
    val   snp_filter_expr
    val   indel_filter_expr

    output:
    path "filtered.vcf.gz",     emit: vcf
    path "filtered.vcf.gz.tbi", emit: tbi

    stub:
    """
    echo "gatk SelectVariants -R ${genome} -V ${vcf} --select-type-to-include SNP -O snps.vcf.gz"
    echo "gatk VariantFiltration -R ${genome} -V snps.vcf.gz --filter-expression '${snp_filter_expr}' --filter-name 'snp_hard_filter' -O snps.filtered.vcf.gz"
    echo "gatk SelectVariants -R ${genome} -V ${vcf} --select-type-to-include INDEL -O indels.vcf.gz"
    echo "gatk VariantFiltration -R ${genome} -V indels.vcf.gz --filter-expression '${indel_filter_expr}' --filter-name 'indel_hard_filter' -O indels.filtered.vcf.gz"
    echo "gatk MergeVcfs -I snps.filtered.vcf.gz -I indels.filtered.vcf.gz -O filtered.vcf.gz"
    touch snps.vcf.gz snps.vcf.gz.tbi
    touch indels.vcf.gz indels.vcf.gz.tbi
    touch snps.filtered.vcf.gz snps.filtered.vcf.gz.tbi
    touch indels.filtered.vcf.gz indels.filtered.vcf.gz.tbi
    touch filtered.vcf.gz
    touch filtered.vcf.gz.tbi
    """

    script:
    """
    # Select and filter SNPs
    gatk SelectVariants \\
        -R ${genome} \\
        -V ${vcf} \\
        --select-type-to-include SNP \\
        -O snps.vcf.gz

    gatk VariantFiltration \\
        -R ${genome} \\
        -V snps.vcf.gz \\
        --filter-expression '${snp_filter_expr}' \\
        --filter-name 'snp_hard_filter' \\
        -O snps.filtered.vcf.gz

    # Select and filter indels
    gatk SelectVariants \\
        -R ${genome} \\
        -V ${vcf} \\
        --select-type-to-include INDEL \\
        -O indels.vcf.gz

    gatk VariantFiltration \\
        -R ${genome} \\
        -V indels.vcf.gz \\
        --filter-expression '${indel_filter_expr}' \\
        --filter-name 'indel_hard_filter' \\
        -O indels.filtered.vcf.gz

    # Merge filtered SNPs and indels
    gatk MergeVcfs \\
        -I snps.filtered.vcf.gz \\
        -I indels.filtered.vcf.gz \\
        -O filtered.vcf.gz
    """

}
