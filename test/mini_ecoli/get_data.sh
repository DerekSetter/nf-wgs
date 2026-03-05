#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READS_DIR="${ROOT_DIR}/reads"
REF_DIR="${ROOT_DIR}/ref"

mkdir -p "${READS_DIR}" "${REF_DIR}"

# Public paired-end E. coli reads (ENA)
curl -L "https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz" -o "${READS_DIR}/ECOLI_MINI_R1.fastq.gz"
curl -L "https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz" -o "${READS_DIR}/ECOLI_MINI_R2.fastq.gz"

# E. coli K-12 MG1655 reference (NCBI RefSeq)
curl -L "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz" -o "${REF_DIR}/ecoli_k12_mg1655.fa.gz"
gunzip -f "${REF_DIR}/ecoli_k12_mg1655.fa.gz"

echo "Downloaded mini E. coli dataset into ${ROOT_DIR}"
