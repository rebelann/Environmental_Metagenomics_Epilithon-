#!/bin/bash
#SBATCH --job-name=resfinder_all
#SBATCH --output=/N/scratch/rebelann/shotgun/resfinder/logs/resfinder_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/resfinder/logs/resfinder_%A_%a.err
#SBATCH --array=1-40%10
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/slate/rebelann/conda_envs/resfinder_env

TRIMMED="/N/scratch/rebelann/shotgun/trimmed"
DB_DIR="/N/scratch/rebelann/shotgun/databases/db_resfinder"
OUT_DIR="/N/scratch/rebelann/shotgun/resfinder"
LOG_DIR="${OUT_DIR}/logs"

mkdir -p "$OUT_DIR" "$LOG_DIR"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /N/scratch/rebelann/shotgun/sample_ids_2022_2023.txt)

R1="${TRIMMED}/${SAMPLE}_R1_trimmed.fastq.gz"
R2="${TRIMMED}/${SAMPLE}_R2_trimmed.fastq.gz"
SAMPLE_OUTDIR="${OUT_DIR}/results/${SAMPLE}"

mkdir -p "$SAMPLE_OUTDIR"

echo "Processing: $SAMPLE"
echo "Start: $(date)"

python -m resfinder \
  -ifq "$R1" "$R2" \
  -o "$SAMPLE_OUTDIR" \
  -s "Other" \
  -k $(which kma) \
  -db_res "$DB_DIR" \
  -db_res_kma "$DB_DIR" \
  -acq \
  -l 0.50 \
  -t 0.80

echo "Done: $SAMPLE"
echo "End: $(date)"
