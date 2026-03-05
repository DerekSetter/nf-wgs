/*
========================================================================================
    FASTP - Adapter trimming and quality filtering of paired-end reads
========================================================================================
*/

process FASTP {

    tag "${sample_id}"

    input:
    tuple val(sample_id), path(fastq_1), path(fastq_2)

    output:
    tuple val(sample_id), path("${sample_id}_1.trimmed.fastq.gz"), path("${sample_id}_2.trimmed.fastq.gz"), emit: trimmed_reads
    path "${sample_id}_fastp.html",                                                                          emit: html
    path "${sample_id}_fastp.json",                                                                          emit: json

    stub:
    """
    echo "fastp --in1 ${fastq_1} --in2 ${fastq_2} --out1 ${sample_id}_1.trimmed.fastq.gz --out2 ${sample_id}_2.trimmed.fastq.gz --html ${sample_id}_fastp.html --json ${sample_id}_fastp.json --thread ${task.cpus}"
    touch ${sample_id}_1.trimmed.fastq.gz
    touch ${sample_id}_2.trimmed.fastq.gz
    touch ${sample_id}_fastp.html
    touch ${sample_id}_fastp.json
    """

    script:
    """
    fastp \\
        --in1  ${fastq_1} \\
        --in2  ${fastq_2} \\
        --out1 ${sample_id}_1.trimmed.fastq.gz \\
        --out2 ${sample_id}_2.trimmed.fastq.gz \\
        --html ${sample_id}_fastp.html \\
        --json ${sample_id}_fastp.json \\
        --thread ${task.cpus}
    """

}
