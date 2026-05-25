#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --output=/N/scratch/rebelann/shotgun/qc/logs/fastqc_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/qc/logs/fastqc_%A_%a.err
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --array=1-118%20
#SBATCH --partition=general
#SBATCH -A r00750
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail
shopt -s nullglob

module purge
module load fastqc/0.12.1

RAW_DIR="/N/scratch/rebelann/shotgun/raw_fastq/sum_raw_fastq"
QC_DIR="/N/scratch/rebelann/shotgun/qc"
RAW_FASTQC_DIR="${QC_DIR}/fastqc_raw"
LOG_DIR="${QC_DIR}/logs"

mkdir -p "$RAW_FASTQC_DIR" "$LOG_DIR"

FILES=("$RAW_DIR"/*.fastq.gz)

FILE="${FILES[$SLURM_ARRAY_TASK_ID-1]}"

if [[ -z "${FILE:-}" ]]; then
    echo "No file found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

echo "Processing file: $FILE"
echo "Start time: $(date)"

fastqc -t 2 -o "$RAW_FASTQC_DIR" "$FILE"

echo "Finished: $FILE"
echo "End time: $(date)"
