#!/bin/bash
#SBATCH --job-name=multiqc_raw
#SBATCH --output=/N/scratch/rebelann/shotgun/qc/logs/multiqc_raw_%j.out
#SBATCH --error=/N/scratch/rebelann/shotgun/qc/logs/multiqc_raw_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --partition=general
#SBATCH -A r00750
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
conda activate /N/slate/rebelann/conda_envs/multiqc_env

QC_DIR="/N/scratch/rebelann/shotgun/qc"
RAW_FASTQC_DIR="${QC_DIR}/fastqc_raw"
MULTIQC_DIR="${QC_DIR}/multiqc_raw"

mkdir -p "$MULTIQC_DIR"

cd "$RAW_FASTQC_DIR"

cd "$RAW_FASTQC_DIR"
echo "Changed to directory: $(pwd)"
echo "About to run MultiQC: $(date)"
multiqc . -o "$MULTIQC_DIR" --no-version-check
echo "MultiQC complete: $(date)"

echo "MultiQC complete!"
