#!/bin/bash
#
#SBATCH --job-name=atac_align
#SBATCH --output=atac_align_%A_%a.out
#SBATCH --error=atac_align_%A_%a.err
#SBATCH --array=1-4%2
#SBATCH --cpus-per-task=4
#SBATCH --mem=16000
#SBATCH --time=12:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=b.olszowy@wustl.edu

# Load Conda environment (Python 3.9 compatible)
eval "$(spack load --sh miniconda3)"
source activate ~/my_envs/atac_env_py39

# Parse FASTQ paths from samples.tsv
IFS=$'\t' read -r R1 R2 < <(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.tsv)
SAMPLE=$(basename "$R1")
SAMPLE=${SAMPLE%%_R1*}

# Set Bowtie2 genome index prefix (mm10)
GENOME_INDEX=/scratch/bmlab/bolszowy/projects/genomes/mm10/mm10

# Step 0: Run FastQC
mkdir -p qc_reports
fastqc -o qc_reports -t 4 "$R1" "$R2"

# Step 1: Align reads with Bowtie2
bowtie2 -x "$GENOME_INDEX" \
  -1 "$R1" -2 "$R2" \
  -X 2000 --very-sensitive -p 4 -S "${SAMPLE}.sam"

# Step 2: Convert to BAM and sort
samtools view -@ 4 -bS "${SAMPLE}.sam" > "${SAMPLE}.unsorted.bam"
rm "${SAMPLE}.sam"

# Step 3: Fixmate, sort by coordinate, and mark duplicates
samtools fixmate -m -@ 4 "${SAMPLE}.unsorted.bam" "${SAMPLE}.fixmate.bam"
samtools sort -@ 4 -o "${SAMPLE}.sorted.bam" "${SAMPLE}.fixmate.bam"
samtools markdup -r -@ 4 "${SAMPLE}.sorted.bam" "${SAMPLE}.dedup.bam"
samtools index "${SAMPLE}.dedup.bam"
rm "${SAMPLE}.unsorted.bam" "${SAMPLE}.fixmate.bam" "${SAMPLE}.sorted.bam"

# Step 4: Sort by query name for Genrich
samtools sort -n -@ 4 "${SAMPLE}.dedup.bam" -o "${SAMPLE}.qname_sorted.bam"

# Step 5: Peak calling with Genrich (ATAC-seq mode)
Genrich -t "${SAMPLE}.qname_sorted.bam" -o "${SAMPLE}_peaks.narrowPeak" -j -y -r -v

# Optional: clean up queryname-sorted BAM
rm "${SAMPLE}.qname_sorted.bam"

# Step 6: Generate normalized bigWig file
bamCoverage -b "${SAMPLE}.dedup.bam" -o "${SAMPLE}.bw" \
  --normalizeUsing CPM --binSize 10 --extendReads -p 4

