/*
========================================================================================
    SAMBAMBA_MARKDUP - Mark duplicate reads in a coordinate-sorted BAM
========================================================================================
*/

process SAMBAMBA_MARKDUP {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}.markdup.bam"), path("${sample_id}.markdup.bam.bai"), emit: bam
    path "${sample_id}.markdup.metrics.txt",                                                         emit: metrics

    script:
    """
    sambamba markdup \
        --nthreads ${task.cpus} \
        --overflow-list-size 600000 \
        --tmpdir . \
        ${bam} \
        ${sample_id}.markdup.bam \
        > ${sample_id}.markdup.metrics.txt

    sambamba index \
        --nthreads ${task.cpus} \
        ${sample_id}.markdup.bam
    """

    stub:
    """
    echo "sambamba markdup --nthreads ${task.cpus} --overflow-list-size 600000 --tmpdir . ${bam} ${sample_id}.markdup.bam > ${sample_id}.markdup.metrics.txt"
    echo "sambamba index --nthreads ${task.cpus} ${sample_id}.markdup.bam"
    touch ${sample_id}.markdup.bam
    touch ${sample_id}.markdup.bam.bai
    touch ${sample_id}.markdup.metrics.txt
    """

}
