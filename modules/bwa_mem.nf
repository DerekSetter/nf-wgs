/*
========================================================================================
    BWA_MEM - Map paired-end reads to a reference genome and produce filtered, sorted BAM
========================================================================================
*/

process BWA_MEM {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(fastq_1), path(fastq_2)
    path  genome

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: bam

 
    script:
    """
    if [[ ! -f "${genome}.bwt.2bit.64" ]]; then
        bwa-mem2 index ${genome}
    fi

    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R '@RG\\tID:${sample_id}\\tSM:${sample_id}' \\
        ${genome} \\
        ${fastq_1} \\
        ${fastq_2} \\
        | samtools view -q ${params.mapq_filter} -b - \\
        | samtools sort -@ ${task.cpus} -o ${sample_id}.sorted.bam -

    samtools index ${sample_id}.sorted.bam
    """


    stub:
    """
    echo "bwa-mem2 mem -t ${task.cpus} -R '@RG\\tID:${sample_id}\\tSM:${sample_id}' ${genome} ${fastq_1} ${fastq_2} | samtools view -q ${params.mapq_filter} -b - | samtools sort -@ ${task.cpus} -o ${sample_id}.sorted.bam - && samtools index ${sample_id}.sorted.bam"
    touch ${sample_id}.sorted.bam
    touch ${sample_id}.sorted.bam.bai
    """

}
