/*
========================================================================================
    MARK_DUPLICATES - Mark (and optionally remove) PCR duplicates using GATK
========================================================================================
*/

process MARK_DUPLICATES {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}.markdup.bam"), path("${sample_id}.markdup.bam.bai"), emit: bam
    path "${sample_id}.markdup.metrics.txt",                                                       emit: metrics

    stub:
    """
    echo "gatk MarkDuplicates -I ${bam} -O ${sample_id}.markdup.bam -M ${sample_id}.markdup.metrics.txt && samtools index ${sample_id}.markdup.bam"
    touch ${sample_id}.markdup.bam
    touch ${sample_id}.markdup.bam.bai
    touch ${sample_id}.markdup.metrics.txt
    """

    script:
    """
    gatk MarkDuplicates \\
        -I ${bam} \\
        -O ${sample_id}.markdup.bam \\
        -M ${sample_id}.markdup.metrics.txt

    samtools index ${sample_id}.markdup.bam
    """

}
