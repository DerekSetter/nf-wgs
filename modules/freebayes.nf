/*
========================================================================================
    FREEBAYES - Per-sample variant calling and summary reporting
========================================================================================
*/

process FREEBAYES {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(bam), path(bai)
    path genome

    output:
    tuple val(sample_id), path("${sample_id}.freebayes.vcf"), emit: vcf
    path "${sample_id}.freebayes.report.txt",                emit: report

    script:
    """
    freebayes \
        -f ${genome} \
        ${bam} > ${sample_id}.freebayes.vcf

    total_variants=\$(grep -vc '^#' ${sample_id}.freebayes.vcf || true)
    snps=\$(awk '!/^#/ { if(length(\$4)==1 && length(\$5)==1) c++ } END { print c+0 }' ${sample_id}.freebayes.vcf)
    indels=\$(awk '!/^#/ { if(!(length(\$4)==1 && length(\$5)==1)) c++ } END { print c+0 }' ${sample_id}.freebayes.vcf)

    {
      echo "sample_id=${sample_id}"
      echo "vcf=${sample_id}.freebayes.vcf"
      echo "total_variants=\${total_variants}"
      echo "snps=\${snps}"
      echo "indels=\${indels}"
    } > ${sample_id}.freebayes.report.txt
    """

    stub:
    """
    cat > ${sample_id}.freebayes.vcf <<'EOF'
    ##fileformat=VCFv4.2
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
    chr1\t100\t.\tA\tG\t60\tPASS\t.
    EOF

    cat > ${sample_id}.freebayes.report.txt <<'EOF'
    sample_id=${sample_id}
    vcf=${sample_id}.freebayes.vcf
    total_variants=1
    snps=1
    indels=0
    EOF
    """

}
