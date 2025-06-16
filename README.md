# ATAC-seq Pipeline

This repository contains a reproducible ATAC-seq analysis pipeline designed for use on the HTC cluster at Washington University in St. Louis (HTCF).

 ## Overview

The pipeline performs the following steps:

Quality control with FastQC

Alignment using Bowtie2

Conversion to BAM, sorting, and deduplication with Samtools

Peak calling using Genrich (ATAC-seq mode)

Normalized coverage tracks with deepTools (bamCoverage)

## File Requirements

samples.tsv: Tab-separated file with full paths to R1 and R2 FASTQ files, one pair per line.

Reference genome index for Bowtie2 (e.g., mm10).


# Usage

Activate Conda each time you open and login into htcf:

Installing and Using Conda on HTCF @ WashU

This guide walks through setting up a working Conda environment using Spack on the HTCF.

1. Load Spack
```
module load spack
```
If module is not found, initialize Spack manually:
```
source /opt/spack/share/spack/setup-env.sh
```
2. Check for miniconda3
```
spack find miniconda3
```
If not installed:
```
spack install miniconda3
```
3. Load Miniconda from Spack
```
eval "$(spack load --sh miniconda3)"
```
4. Create a Conda Environment
```
conda create -n atac_env python=3.9
conda activate atac_env_py39
```
5. Install Required Packages
```
conda install -c bioconda bowtie2 samtools fastqc genrich deeptools
```

6. Activate Conda in SLURM Scripts

In your sbatch script:
```
eval "$(spack load --sh miniconda3)"
source activate ~/path/to/envs/atac_env_py39
```
To locate Conda environments:
```
conda info --envs
```

7. Run script

```sbatch atac_genrich_v2.sh```
Ensure SLURM_ARRAY_TASK_ID matches the line number in your samples.tsv.
 
## Alternative to load conda:
```
source /ref/bmlab/software/spack/opt/spack/linux-rocky8-x86_64/gcc-8.5.0/miniconda3-4.10.3-ffenge4p23qz6ydwhfcmz5uj7tzidg2t/bin/activate
```

## Output

*.dedup.bam: Deduplicated BAM files

*.peaks.narrowPeak: Peak files from Genrich

*.bw: Normalized bigWig files for genome browser viewing

## Dependencies

bowtie2

samtools

fastqc

genrich

deepTools

