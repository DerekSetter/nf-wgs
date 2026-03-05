/*
========================================================================================
    MULTIQC - Aggregate QC metrics from FastQC/fastp into one report
========================================================================================
*/

process MULTIQC {

    tag "multiqc"

    input:
    path qc_files

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data",        emit: data

    script:
    def qc_args = qc_files instanceof List ? qc_files.join(' ') : qc_files
    """
    multiqc \
        --force \
        --outdir . \
        ${qc_args}
    """

    stub:
    """
    mkdir -p multiqc_data
    touch multiqc_report.html
    touch multiqc_data/multiqc_data.json
    """

}
