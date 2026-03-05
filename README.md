# nf-wgs

Nextflow pipeline for whole-genome sequence (WGS) data processing.

## Overview

The pipeline covers the following steps in order:

| Step | Tool | Description |
|------|------|-------------|
| 1 | FastQC | Quality control of raw reads |
| 2 | fastp | Adapter trimming and quality filtering |
| 3 | BWA-MEM2 | Map reads to a reference genome |
| 4 | samtools sort | Coordinate-sort and index the BAM |

**change to sambamba and freebayes**
| 5 | GATK MarkDuplicates | Mark (and flag) PCR duplicates |
| 6 | GATK BaseRecalibrator | Compute base quality score recalibration table |
| 7 | GATK ApplyBQSR | Apply BQSR table to produce a recalibrated BAM |
| 8 | GATK HaplotypeCaller | Per-sample variant calling in GVCF mode |
| 9 | GATK GenotypeGVCFs | Joint genotyping across all samples |
| 10 | GATK VariantFiltration | Hard-filter SNPs and indels |

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
│   ├── bwa_mem.nf
│   ├── samtools_sort.nf
│   ├── mark_duplicates.nf
│   ├── base_recalibrator.nf
│   ├── apply_bqsr.nf
│   ├── haplotypecaller.nf
│   ├── genotype_gvcfs.nf
│   └── variant_filtration.nf
└── test/
    ├── samplesheet.csv        # Example samplesheet
    └── data/                  # Placeholder FASTQ files for stub runs
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
    --known_sites /path/to/dbsnp.vcf.gz \
    --known_sites_tbi /path/to/dbsnp.vcf.gz.tbi \
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
    --genome     test/data/genome.fa
```

## Configuration

Process-specific resource settings (CPUs, memory, wall-time, container image) are
stored in `conf/processes.config`, which is automatically included by
`nextflow.config`.  Override any value on the command line with `-process.withName`
or by editing the config file directly.

## Output

Each process writes its outputs to a subdirectory of `--outdir` named after the
process (lower-cased), e.g.:

```
results/
├── fastqc/
├── fastp/
├── bwa_mem/
├── samtools_sort/
├── mark_duplicates/
├── base_recalibrator/
├── apply_bqsr/
├── haplotypecaller/
├── genotype_gvcfs/
└── variant_filtration/
```
