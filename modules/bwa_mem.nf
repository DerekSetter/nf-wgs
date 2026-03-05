/*
========================================================================================
    BWA_MEM - Map paired-end reads to a reference genome using BWA-MEM2
========================================================================================
*/

process BWA_MEM {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(fastq_1), path(fastq_2)
    path  genome
    path  genome_index   // directory or prefix for BWA-MEM2 index files

    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: bam

    stub:
    """
    echo "bwa-mem2 mem -t ${task.cpus} -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:lib1' ${genome} ${fastq_1} ${fastq_2} | samtools view -bS -o ${sample_id}.bam"
    touch ${sample_id}.bam
    """

    script:
    """
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:lib1' \\
        ${genome} \\
        ${fastq_1} \\
        ${fastq_2} \\
        | samtools view -bS -o ${sample_id}.bam
    """

}
