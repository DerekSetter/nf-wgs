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

    output:
    tuple val(sample_id), path("${sample_id}.sam"), emit: sam

 
    script:
    """
    if [[ ! -f "${genome}.bwt.2bit.64" ]]; then
        bwa-mem2 index ${genome}
    fi

    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:lib1' \\
        ${genome} \\
        ${fastq_1} \\
        ${fastq_2} \\
        > ${sample_id}.sam
    """


    stub:
    """
    echo "bwa-mem2 mem -t ${task.cpus} -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:lib1' ${genome} ${fastq_1} ${fastq_2} > ${sample_id}.sam"
    touch ${sample_id}.sam
    """

}
