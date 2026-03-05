/*
========================================================================================
    FASTQC - Quality control of raw FASTQ reads
========================================================================================
*/

process FASTQC {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(fastq_1), path(fastq_2)

    output:
    tuple val(sample_id), path("${sample_id}_fastqc/*.html"), emit: html
    tuple val(sample_id), path("${sample_id}_fastqc/*.zip"),  emit: zip

    stub:
    """
    echo "fastqc --threads ${task.cpus} --outdir ${sample_id}_fastqc ${fastq_1} ${fastq_2}"
    mkdir -p ${sample_id}_fastqc
    touch ${sample_id}_fastqc/${sample_id}_1_fastqc.html
    touch ${sample_id}_fastqc/${sample_id}_1_fastqc.zip
    touch ${sample_id}_fastqc/${sample_id}_2_fastqc.html
    touch ${sample_id}_fastqc/${sample_id}_2_fastqc.zip
    """

    script:
    """
    mkdir -p ${sample_id}_fastqc
    fastqc \\
        --threads ${task.cpus} \\
        --outdir ${sample_id}_fastqc \\
        ${fastq_1} \\
        ${fastq_2}
    """

}
