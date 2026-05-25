#!/bin/bash
#SBATCH --job-name=card_rgi
#SBATCH --output=/N/scratch/rebelann/shotgun/rgi_cards/logs/card_rgi_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/rgi_cards/logs/card_rgi_%A_%a.err
#SBATCH --time=48:00:00
#SBATCH --mem=256G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-40%10
#SBATCH --partition=general
#SBATCH -A r00750
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/project/Krolab/Rebekah/conda_envs/envs/rgi_env

# -------- Paths --------
TRIMMED="/N/scratch/rebelann/shotgun/trimmed"
CARD_DB="/N/slate/rebelann/databases/card"
OUTDIR="/N/scratch/rebelann/shotgun/rgi_cards"
LOG_DIR="${OUTDIR}/logs"
SAMPLE_LIST="/N/scratch/rebelann/shotgun/sample_ids_2022_2023.txt"

CARD_FASTA="card_database_v4.0.1.fasta"
WILDCARD_FASTA="wildcard_database_v4.0.1.fasta"

mkdir -p "${OUTDIR}/results" "${LOG_DIR}"

# -------- Get sample for this array task --------
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")
R1="${TRIMMED}/${SAMPLE}_R1_trimmed.fastq.gz"
R2="${TRIMMED}/${SAMPLE}_R2_trimmed.fastq.gz"

# Each task gets its own working dir for the local CARD DB
WORK_DIR="${OUTDIR}/results/${SAMPLE}_work"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

echo "=== Starting RGI bwt for ${SAMPLE} at $(date) ==="
echo "R1: ${R1}"
echo "R2: ${R2}"
echo "Working dir: ${WORK_DIR}"

# -------- Load CARD + WildCARD database (per-task local copy) --------
rgi clean --local || true
rgi load \
    --card_json "${CARD_DB}/card.json" \
    --card_annotation "${CARD_DB}/${CARD_FASTA}" \
    --wildcard_annotation "${CARD_DB}/${WILDCARD_FASTA}" \
    --wildcard_index "${CARD_DB}/wildcard/index-for-model-sequences.txt" \
    --local

# -------- Run RGI bwt with KMA, including WildCARD variants --------
rgi bwt \
    --read_one "${R1}" \
    --read_two "${R2}" \
    --aligner kma \
    --threads ${SLURM_CPUS_PER_TASK} \
    --output_file "${SAMPLE}" \
    --local \
    --include_wildcard \
    --clean

# Move output files to results dir
mv ${SAMPLE}.* "${OUTDIR}/results/" 2>/dev/null || true

echo "=== Finished RGI bwt for ${SAMPLE} at $(date) ==="
