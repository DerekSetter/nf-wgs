/*
========================================================================================
    SAMTOOLS_SORT - Sort a BAM file by coordinate and index it
========================================================================================
*/

process SAMTOOLS_SORT {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: sorted_bam

    stub:
    """
    echo "samtools sort -@ ${task.cpus} -o ${sample_id}.sorted.bam ${bam} && samtools index ${sample_id}.sorted.bam"
    touch ${sample_id}.sorted.bam
    touch ${sample_id}.sorted.bam.bai
    """

    script:
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${sample_id}.sorted.bam \\
        ${bam}

    samtools index ${sample_id}.sorted.bam
    """

}
