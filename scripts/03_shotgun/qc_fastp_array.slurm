#!/bin/bash
#SBATCH --job-name=fastp_trim
#SBATCH --output=/N/scratch/rebelann/shotgun/qc/logs/fastp_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/qc/logs/fastp_%A_%a.err
#SBATCH --time=04:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-59%20
#SBATCH --partition=general
#SBATCH -A r00750
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
conda activate /N/slate/rebelann/conda_envs/fastp_env

RAW_DIR="/N/scratch/rebelann/shotgun/raw_fastq/sum_raw_fastq"
OUT_DIR="/N/scratch/rebelann/shotgun/trimmed"
QC_DIR="/N/scratch/rebelann/shotgun/qc/fastp_reports"
LOG_DIR="/N/scratch/rebelann/shotgun/qc/logs"

mkdir -p "$OUT_DIR" "$QC_DIR" "$LOG_DIR"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /N/scratch/rebelann/shotgun/sample_ids.txt)

R1="${RAW_DIR}/${SAMPLE}_R1.fastq.gz"
R2="${RAW_DIR}/${SAMPLE}_R2.fastq.gz"

echo "Processing: $SAMPLE"
echo "Start: $(date)"

fastp \
  --in1 "$R1" \
  --in2 "$R2" \
  --out1 "${OUT_DIR}/${SAMPLE}_R1_trimmed.fastq.gz" \
  --out2 "${OUT_DIR}/${SAMPLE}_R2_trimmed.fastq.gz" \
  --json "${QC_DIR}/${SAMPLE}_fastp.json" \
  --html "${QC_DIR}/${SAMPLE}_fastp.html" \
  --detect_adapter_for_pe \
  --correction \
  --cut_tail \
  --cut_tail_mean_quality 20 \
  --length_required 50 \
  --qualified_quality_phred 20 \
  --low_complexity_filter \
  --trim_poly_x \
  --thread 8

echo "Done: $SAMPLE"
echo "End: $(date)"
