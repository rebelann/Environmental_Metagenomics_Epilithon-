#!/bin/bash
#SBATCH --job-name=dada2_ITS_HHJFLDRX5
#SBATCH --output=/N/scratch/rebelann/MG_runs/slurm_logs/dada2_ITS_HHJFLDRX5_%j.out
#SBATCH --error=/N/scratch/rebelann/MG_runs/slurm_logs/dada2_ITS_HHJFLDRX5_%j.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

# Put QIIME2 temp on scratch
export TMPDIR=/N/scratch/rebelann/tmp_qiime2/${SLURM_JOB_ID}
export TEMP=$TMPDIR
export TMP=$TMPDIR
mkdir -p "$TMPDIR"

echo "Job started at: $(date)"
echo "Running on: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Working directory: $(pwd)"
echo "TMPDIR: $TMPDIR"

module purge
module load conda/25.3.0
eval "$(conda shell.bash hook)"
conda activate /N/slate/rebelann/conda_envs/qiime2-amplicon-2025.4

cd /N/scratch/rebelann/MG_runs/scripts

python ITS_preproc_HHJFLDRX5.py
