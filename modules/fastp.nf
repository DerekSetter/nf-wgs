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
    tuple val(sample_id), path("${sample_id}.1.trim.fq.gz"), path("${sample_id}.2.trim.fq.gz"), emit: trimmed_reads
    path "${sample_id}_fastp.html",                                                                          emit: html
    path "${sample_id}_fastp.json",                                                                          emit: json



    script:
    """
    fastp \\
        -p \\
        --detect_adapter_for_pe \\
        --in1  ${fastq_1} \\
        --in2  ${fastq_2} \\
        --out1 ${sample_id}.1.trim.fq.gz \\
        --out2 ${sample_id}.2.trim.fq.gz \\
        --cut_front \\
        --cut_tail \\
        --cut_window_size ${params.fastp_cut_window_size} \\
        --cut_mean_quality ${params.fastp_cut_mean_quality} \\
        --html ${sample_id}_fastp.html \\
        --json ${sample_id}_fastp.json \\
        --thread ${task.cpus}
    """

    stub:
    """
    echo "fastp -p --detect_adapter_for_pe --in1 ${fastq_1} --in2 ${fastq_2} --out1 ${sample_id}.1.trim.fq.gz --out2 ${sample_id}.2.trim.fq.gz --cut_front --cut_tail --cut_window_size ${params.fastp_cut_window_size} --cut_mean_quality ${params.fastp_cut_mean_quality} --html ${sample_id}_fastp.html --json ${sample_id}_fastp.json --thread ${task.cpus}"
    touch ${sample_id}.1.trim.fq.gz
    touch ${sample_id}.2.trim.fq.gz
    touch ${sample_id}_fastp.html
    touch ${sample_id}_fastp.json
    """

}
