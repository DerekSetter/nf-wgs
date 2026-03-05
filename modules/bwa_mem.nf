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
    val   genome_index   // prefix for BWA-MEM2 index files (optional)

    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: bam

 
    script:
    def index_prefix = genome_index ?: genome
    """
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:lib1' \\
        ${index_prefix} \\
        ${fastq_1} \\
        ${fastq_2} \\
        | samtools view -bS -o ${sample_id}.bam
    """


   stub:
    def index_prefix = genome_index ?: genome
    """
    echo "bwa-mem2 mem -t ${task.cpus} -R '@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:lib1' ${index_prefix} ${fastq_1} ${fastq_2} | samtools view -bS -o ${sample_id}.bam"
    touch ${sample_id}.bam
    """

}
