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
    path genome_fai

    output:
    path "*.freebayes.vcf.gz",          emit: vcf
    path "joint.freebayes.report.txt",  emit: report
    path "freebayes.done",              emit: done

    script:
    def bam_list = (bams instanceof List) ? bams : [bams]
    def n_bams = bam_list.size()
    def vcf_prefix = (params.vcf_prefix ?: 'joint').toString()
    def vcf_name = "${vcf_prefix}.freebayes.vcf.gz"
    def bam_args = bam_list.collect { bam_file -> "--bam ${bam_file}" }.join(' ')
    """
    set -euo pipefail

    [[ -s ${genome_fai} ]]

    freebayes-parallel <(fasta_generate_regions.py ${genome} ${params.freebayes_region_size}) ${params.freebayes_parallel_chunks} \
        -f ${genome} \
        --limit-coverage ${params.freebayes_limit_coverage} \
        --use-best-n-alleles ${params.freebayes_use_best_n_alleles} \
        --no-population-priors \
        --use-mapping-quality \
        --ploidy ${params.freebayes_ploidy} \
        --haplotype-length ${params.freebayes_haplotype_length} \
        ${bam_args} \
      | gzip -c > ${vcf_name}

    touch freebayes.done

  total_variants=\$(zcat ${vcf_name} | awk '!/^#/ { c++ } END { print c+0 }')
    snps=\$(zcat ${vcf_name} | awk '!/^#/ { if(length(\$4)==1 && length(\$5)==1) c++ } END { print c+0 }')
    indels=\$(zcat ${vcf_name} | awk '!/^#/ { if(!(length(\$4)==1 && length(\$5)==1)) c++ } END { print c+0 }')

    {
      echo "mode=joint"
      echo "vcf=${vcf_name}"
      echo "n_bams=${n_bams}"
      echo "total_variants=\${total_variants}"
      echo "snps=\${snps}"
      echo "indels=\${indels}"
    } > joint.freebayes.report.txt
    """

    stub:
    def n_bams = bams.size()
    def vcf_prefix = (params.vcf_prefix ?: 'joint').toString()
    def vcf_name = "${vcf_prefix}.freebayes.vcf.gz"
    """
    cat > joint.freebayes.vcf <<'EOF'
    ##fileformat=VCFv4.2
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
    chr1\t100\t.\tA\tG\t60\tPASS\t.
    EOF

    gzip -c joint.freebayes.vcf > ${vcf_name}
    touch freebayes.done

    cat > joint.freebayes.report.txt <<'EOF'
    mode=joint
    vcf=${vcf_name}
    n_bams=${n_bams}
    total_variants=1
    snps=1
    indels=0
    EOF

    rm -f joint.freebayes.vcf
    """

}
