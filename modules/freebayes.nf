/*
========================================================================================
    FREEBAYES - Joint multi-sample variant calling and summary reporting
========================================================================================
*/

process FREEBAYES {

    tag "joint"

    input:
    path staged_files
    val bam_paths
    path genome
    path genome_fai

    output:
    path "*.freebayes.vcf.gz",          emit: vcf
    path "joint.freebayes.report.txt",  emit: report
    path "freebayes.done",              emit: done

    script:
    def bam_list = (bam_paths instanceof List) ? bam_paths : [bam_paths]
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

process FREEBAYES_BASIC {

    tag "basic"

    input:
    path staged_files
    val bam_paths
    path genome
    path genome_fai

    output:
    path "basic.freebayes.vcf.gz",         emit: vcf
    path "basic.freebayes.report.txt",    emit: report
    path "freebayes_basic.done",          emit: done

    script:
    def bam_list = (bams instanceof List) ? bams : [bams]
    def bam_args = bam_list.collect { bam_file -> "${'--bam'} ${bam_file}" }.join(' ')
    """
    set -euo pipefail

    [[ -s ${genome_fai} ]]

    # Minimal, single-process run (no parallelization, minimal flags)
    freebayes -f ${genome} ${bam_args} > basic.freebayes.vcf 2> basic.freebayes.vcf.log

    gzip -c basic.freebayes.vcf > basic.freebayes.vcf.gz

    touch freebayes_basic.done

    total_variants=\$(zcat basic.freebayes.vcf.gz | awk '!/^#/ { c++ } END { print c+0 }')
    snps=\$(zcat basic.freebayes.vcf.gz | awk '!/^#/ { if(length(\$4)==1 && length(\$5)==1) c++ } END { print c+0 }')
    indels=\$(zcat basic.freebayes.vcf.gz | awk '!/^#/ { if(!(length(\$4)==1 && length(\$5)==1)) c++ } END { print c+0 }')

    {
      echo "mode=basic"
      echo "vcf=basic.freebayes.vcf.gz"
      echo "n_bams=${bam_list.size()}"
      echo "total_variants=\${total_variants}"
      echo "snps=\${snps}"
      echo "indels=\${indels}"
    } > basic.freebayes.report.txt
    """

    stub:
    def n_bams = (bams instanceof List) ? bams.size() : 1
    """
    cat > basic.freebayes.vcf <<'EOF'
    ##fileformat=VCFv4.2
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
    chr1\t100\t.\tA\tG\t60\tPASS\t.
    EOF

    gzip -c basic.freebayes.vcf > basic.freebayes.vcf.gz
    touch freebayes_basic.done

    cat > basic.freebayes.report.txt <<'EOF'
    mode=basic
    vcf=basic.freebayes.vcf.gz
    n_bams=${n_bams}
    total_variants=1
    snps=1
    indels=0
    EOF

    rm -f basic.freebayes.vcf
    """

}

process FREEBAYES_PARALLEL_BASIC {

    tag "parallel-basic"

    // request cores equal to the number of parallel chunks
    cpus params.freebayes_parallel_chunks
    container 'quay.io/biocontainers/freebayes:1.3.5--h7c3f5f9_2'

    input:
    path staged_files
    val bam_paths
    path genome
    path genome_fai

    output:
    path "parallel.freebayes.vcf.gz",         emit: vcf
    path "parallel.freebayes.report.txt",    emit: report
    path "freebayes_parallel.done",          emit: done

    script:
    def n_bams = (bam_paths instanceof List) ? bam_paths.size() : 1
    def bam_args = (bam_paths instanceof List) ? bam_paths.collect { bam_file -> "--bam ${bam_file}" }.join(' ') : "--bam ${bam_paths}"
    """
    set -euo pipefail

    [[ -s ${genome_fai} ]]

    # Use default params.freebayes_region_size and params.freebayes_parallel_chunks
    freebayes-parallel <(fasta_generate_regions.py ${genome} ${params.freebayes_region_size}) ${params.freebayes_parallel_chunks} \
        -f ${genome} \
        ${bam_args} \
      | gzip -c > parallel.freebayes.vcf.gz

    touch freebayes_parallel.done

    total_variants=\$(zcat parallel.freebayes.vcf.gz | awk '!/^#/ { c++ } END { print c+0 }')
    snps=\$(zcat parallel.freebayes.vcf.gz | awk '!/^#/ { if(length(\$4)==1 && length(\$5)==1) c++ } END { print c+0 }')
    indels=\$(zcat parallel.freebayes.vcf.gz | awk '!/^#/ { if(!(length(\$4)==1 && length(\$5)==1)) c++ } END { print c+0 }')

    {
      echo "mode=parallel-basic"
      echo "vcf=parallel.freebayes.vcf.gz"
      echo "n_bams=${n_bams}"
      echo "total_variants=\${total_variants}"
      echo "snps=\${snps}"
      echo "indels=\${indels}"
    } > parallel.freebayes.report.txt
    """

    stub:
    """
    cat > parallel.freebayes.vcf <<'EOF'
    ##fileformat=VCFv4.2
    #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
    chr1\t100\t.\tA\tG\t60\tPASS\t.
    EOF

    gzip -c parallel.freebayes.vcf > parallel.freebayes.vcf.gz
    touch freebayes_parallel.done

    cat > parallel.freebayes.report.txt <<'EOF'
    mode=parallel-basic
    vcf=parallel.freebayes.vcf.gz
    n_bams=${n_bams}
    total_variants=1
    snps=1
    indels=0
    EOF

    rm -f parallel.freebayes.vcf
    """

}
