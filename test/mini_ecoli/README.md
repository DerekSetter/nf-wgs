# mini_ecoli test dataset

This directory is used by the `mini_ecoli` profile in `nextflow.config`.

## Data sources

- Paired-end reads: ENA run `SRR2584863`
- Reference: NCBI RefSeq `GCF_000005845.2_ASM584v2`

## Download

```bash
chmod +x test/mini_ecoli/get_data.sh
./test/mini_ecoli/get_data.sh
```

## Run profile

```bash
nextflow run main.nf -profile mini_ecoli,docker
```
