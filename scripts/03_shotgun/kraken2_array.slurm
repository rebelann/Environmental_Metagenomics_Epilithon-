#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --output=/N/scratch/rebelann/shotgun/kraken2/logs/kraken2_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/kraken2/logs/kraken2_%A_%a.err
#SBATCH --time=06:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=16
#SBATCH --array=1-40%20
#SBATCH --partition=general
#SBATCH -A r00750
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/project/Krolab/Rebekah/conda_envs/envs/kraken2_env

TRIMMED="/N/scratch/rebelann/shotgun/trimmed"
DB="/N/project/Krolab/Rebekah/databases/kraken2/k2_pluspf"
OUTDIR="/N/scratch/rebelann/shotgun/kraken2"
LOG_DIR="${OUTDIR}/logs"

mkdir -p "$OUTDIR" "$LOG_DIR"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /N/scratch/rebelann/shotgun/sample_ids_2022_2023.txt)

echo "Processing: $SAMPLE"
echo "Start: $(date)"

kraken2 \
  --db "$DB" \
  --paired \
  --threads 16 \
  --gzip-compressed \
  --report "${OUTDIR}/${SAMPLE}.k2report" \
  --output "${OUTDIR}/${SAMPLE}.k2output" \
  --report-zero-counts \
  "${TRIMMED}/${SAMPLE}_R1_trimmed.fastq.gz" \
  "${TRIMMED}/${SAMPLE}_R2_trimmed.fastq.gz"

echo "Done: $SAMPLE"
echo "End: $(date)"
