/*
========================================================================================
    FREEBAYES - Joint multi-sample variant calling and summary reporting
========================================================================================
*/

process FREEBAYES {

    tag "joint"

    input:
    path bams
    path genome

    output:
    path "joint.freebayes.vcf.gz",      emit: vcf
    path "joint.freebayes.report.txt",  emit: report
    path "freebayes.done",              emit: done

    script:
    def n_bams = bams.size()
    def bam_args = bams.collect { bam_file -> "--bam ${bam_file}" }.join(' \\\n+        ')
    """
    freebayes-parallel <(fasta_generate_regions.py ${genome} ${params.freebayes_region_size}) ${params.freebayes_parallel_chunks} \
        -f ${genome} \
        --limit-coverage ${params.freebayes_limit_coverage} \
        --use-best-n-alleles ${params.freebayes_use_best_n_alleles} \
        --no-population-priors \
        --use-mapping-quality \
        --ploidy ${params.freebayes_ploidy} \
        --haplotype-length ${params.freebayes_haplotype_length} \
        ${bam_args} \
      | gzip -c > joint.freebayes.vcf.gz

    touch freebayes.done

    total_variants=\$(zgrep -vc '^#' joint.freebayes.vcf.gz || true)
    snps=\$(zcat joint.freebayes.vcf.gz | awk '!/^#/ { if(length(\$4)==1 && length(\$5)==1) c++ } END { print c+0 }')
    indels=\$(zcat joint.freebayes.vcf.gz | awk '!/^#/ { if(!(length(\$4)==1 && length(\$5)==1)) c++ } END { print c+0 }')

    {
      echo "mode=joint"
      echo "vcf=joint.freebayes.vcf.gz"
        echo "n_bams=${n_bams}"
      echo "total_variants=\${total_variants}"
      echo "snps=\${snps}"
      echo "indels=\${indels}"
    } > joint.freebayes.report.txt
    """

    stub:
    def n_bams = bams.size()
    """
    cat > joint.freebayes.vcf <<'EOF'
    ##fileformat=VCFv4.2
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
    chr1\t100\t.\tA\tG\t60\tPASS\t.
    EOF

    gzip -c joint.freebayes.vcf > joint.freebayes.vcf.gz
    touch freebayes.done

    cat > joint.freebayes.report.txt <<'EOF'
    mode=joint
    vcf=joint.freebayes.vcf.gz
    n_bams=${n_bams}
    total_variants=1
    snps=1
    indels=0
    EOF

    rm -f joint.freebayes.vcf
    """

}
