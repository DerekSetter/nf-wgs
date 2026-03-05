# nf-wgs

Nextflow pipeline for whole-genome sequence (WGS) data processing.

## Overview

The pipeline covers the following steps in order:

| Step | Tool | Description |
|------|------|-------------|
| 1 | FastQC | Quality control of raw reads |
| 2 | fastp | Adapter trimming and quality filtering |
| 3 | MultiQC | Aggregate FastQC/fastp metrics into one QC report |
| 4 | BWA-MEM2 | Map reads to a reference genome |
| 5 | samtools sort | Coordinate-sort and index the BAM |
| 6 | FreeBayes | Per-sample variant calling from sorted BAM |
| 7 | FreeBayes report | Per-sample SNP/indel/variant summary text report |

## Repository layout

```
nf-wgs/
├── main.nf                   # Entry point – validates params and launches the workflow
├── nextflow.config            # Main Nextflow configuration
├── conf/
│   └── processes.config       # Per-process CPU/memory/container settings
├── workflows/
│   └── wgs.nf                 # End-to-end bioinformatics workflow
├── modules/
│   ├── fastqc.nf
│   ├── fastp.nf
│   ├── multiqc.nf
│   ├── bwa_mem.nf
│   ├── samtools_sort.nf
│   └── freebayes.nf
└── test/
    ├── samplesheet.csv        # Example samplesheet
    ├── data/                  # Placeholder FASTQ files for stub runs
    └── mini_ecoli/
        ├── get_data.sh        # Downloads a small public E. coli dataset + reference
        ├── samplesheet.csv
        ├── reads/
        └── ref/
```

## Samplesheet format

The `--input` samplesheet is a comma-separated (CSV) file with a header row:

```csv
sample_id,fastq_1,fastq_2
SAMPLE_01,/path/to/SAMPLE_01_R1.fastq.gz,/path/to/SAMPLE_01_R2.fastq.gz
SAMPLE_02,/path/to/SAMPLE_02_R1.fastq.gz,/path/to/SAMPLE_02_R2.fastq.gz
```

## Usage

### Full run (requires all tools installed or containers enabled)

```bash
nextflow run main.nf \
    --input      samplesheet.csv \
    --outdir     results \
    --genome     /path/to/genome.fa \
    -profile docker
```

### Stub / dry-run (no bioinformatic tools needed)

The `-stub` flag activates the stub block inside each module.  Each process will
**print** the command that would be executed and **touch** every output file so
that the full directory structure and file names can be inspected without running
any real tools.

```bash
nextflow run main.nf -stub \
    --input      test/samplesheet.csv \
    --outdir     test_results \
    --genome     test/data/genome.fa \
    --genome_index .
```

```bash
nextflow run main.nf -stub --input test/samplesheet.csv --outdir test_results --genome test/data/genome.fa --genome_index .
```

## Configuration

Process-specific resource settings (CPUs, memory, wall-time, container image) are
stored in `conf/processes.config`, which is automatically included by
`nextflow.config`.  Override any value on the command line with `-process.withName`
or by editing the config file directly.

### mini_ecoli test profile

This repository includes a lightweight public E. coli test profile:

```bash
chmod +x test/mini_ecoli/get_data.sh
./test/mini_ecoli/get_data.sh

nextflow run main.nf \
    -profile mini_ecoli,docker
```

Notes:
- Outputs are written to `test_results_mini_ecoli/` by default.

### freebayes_test example run

Use this command when you want an explicit FreeBayes smoke-test style run name and output folder:

```bash
nextflow run main.nf \
    -profile mini_ecoli,docker \
    --outdir test_results_freebayes_test
```

This uses the same mini E. coli inputs and reference from the `mini_ecoli` profile, but writes results to `test_results_freebayes_test/`.

## Output

Each process writes its outputs to a subdirectory of `--outdir` named after the
process (lower-cased), e.g.:

```
results/
├── fastqc/
├── fastp/
├── multiqc/
├── bwa_mem/
├── samtools_sort/
└── freebayes/
```
