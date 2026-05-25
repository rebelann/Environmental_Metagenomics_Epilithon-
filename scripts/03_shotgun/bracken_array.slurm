#!/bin/bash
#SBATCH --job-name=bracken
#SBATCH --output=/N/scratch/rebelann/shotgun/bracken/logs/bracken_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/bracken/logs/bracken_%A_%a.err
#SBATCH --array=1-40%20
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/slate/rebelann/conda_envs/bracken_env

DB="/N/project/Krolab/Rebekah/databases/kraken2/k2_pluspf"
K2DIR="/N/scratch/rebelann/shotgun/kraken2"
OUTDIR="/N/scratch/rebelann/shotgun/bracken"
LOG_DIR="${OUTDIR}/logs"

mkdir -p "$OUTDIR" "$LOG_DIR"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /N/scratch/rebelann/shotgun/sample_ids_2022_2023.txt)

echo "Processing: $SAMPLE"
echo "Start: $(date)"

# Run Bracken at Species, Genus, and Phylum levels
for LEVEL in S G P; do
    bracken \
        -d "$DB" \
        -i "${K2DIR}/${SAMPLE}.k2report" \
        -o "${OUTDIR}/${SAMPLE}_bracken_${LEVEL}.txt" \
        -w "${OUTDIR}/${SAMPLE}_bracken_${LEVEL}.report" \
        -r 150 \
        -l "$LEVEL" \
        -t 10
    echo "Bracken ${LEVEL} done: $SAMPLE"
done

echo "Done: $SAMPLE"
echo "End: $(date)"
