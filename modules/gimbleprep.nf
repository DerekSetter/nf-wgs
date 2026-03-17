/*
========================================================================================
    GIMBLEPREP - Prepare alignments for downstream analysis using gimbleprep
========================================================================================

    Stages BAMs (and their indices) into the process workdir and creates a
    directory `bam_dir` containing symlinks to those files. Then runs `gimbleprep`.
*/

process GIMBLEPREP {

    tag "gimbleprep"

    cpus 2
    memory '8.GB'

    input:
    path staged_files
    val  bam_paths
    path genome
    path genome_fai
    path vcf

    output:
    path "gimbleprep.record.log", emit: record
    path "gimble.bed", emit: bed
    path "gimble.coverage_summary.csv", emit: coverage_summary
    path "gimble.genomefile", emit: genomefile
    path "gimble.log.txt", emit: log
    path "gimble.vcf.gz", emit: vcf
    path "gimble.samples.csv", emit: samples
    path "gimble.vcf.gz.tbi", emit: vcf_index

    script:
    """
    set -euo pipefail

    [[ -s ${genome_fai} ]]

    # Write a simple newline-separated list of BAM basenames into bam_list.txt
    cat > bam_list.txt <<'BAMLIST'
${bam_paths instanceof List ? bam_paths.join('\n') : bam_paths}
BAMLIST

    mkdir -p bam_dir

      # For each entry in bam_list.txt, create a symlink to the staged basename
      while IFS= read -r p || [ -n "\$p" ]; do
        [ -z "\$p" ] && continue
        base=\$(basename "\$p")
        if [ -e "\$base" ]; then
          ln -s "\$PWD/\$base" bam_dir/"\$base"
          # also link possible index files for this BAM
          if [ -e "\$base.bai" ]; then
            ln -s "\$PWD/\$base.bai" bam_dir/"\$base.bai"
          elif [ -e "\${base%.bam}.bai" ]; then
            ln -s "\$PWD/\${base%.bam}.bai" bam_dir/"\${base%.bam}.bai"
          fi
        elif [ -e "\${base}.bam" ]; then
          ln -s "\$PWD/\${base}.bam" bam_dir/"\${base}.bam"
          # also link index
          if [ -e "\${base}.bam.bai" ]; then
            ln -s "\$PWD/\${base}.bam.bai" bam_dir/"\${base}.bam.bai"
          elif [ -e "\${base}.bai" ]; then
            ln -s "\$PWD/\${base}.bai" bam_dir/"\${base}.bai"
          fi
        fi
      done < bam_list.txt

    ls -l bam_dir || true

    # Run gimbleprep and capture both stdout and stderr to a record file
    gimbleprep -f ${genome} -b bam_dir -v ${vcf} -g 2 -q 10 -m 8 -M 1.5 -t 10 2>&1 | tee gimbleprep.record.log

    """

    stub:
    """
    mkdir -p gimbleprep_output
    echo "gimbleprep: stub run" > gimbleprep_output/README.txt
    touch gimbleprep.record.log
    """

}
