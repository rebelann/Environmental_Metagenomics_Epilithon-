#!/bin/bash
#SBATCH --job-name=chocophlan_dl
#SBATCH --output=/N/scratch/rebelann/shotgun/slurm_logs/chocophlan_%j.out
#SBATCH --error=/N/scratch/rebelann/shotgun/slurm_logs/chocophlan_%j.err
#SBATCH --time=96:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

# ============================================================
# Download ChocoPhlAn full database for HUMAnN3
# Using humann_databases command (better retry logic than wget)
# ============================================================

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/slate/rebelann/conda_envs/humann3_new

mkdir -p /N/scratch/rebelann/shotgun/databases/humann3/chocophlan

echo "Downloading ChocoPhlAn full database: $(date)"
echo "Target: /N/scratch/rebelann/shotgun/databases/humann3/chocophlan"

humann_databases --download chocophlan full \
  /N/scratch/rebelann/shotgun/databases/humann3/chocophlan

echo "Download complete: $(date)"

# Verify download
echo "Verifying download:"
ls -lh /N/scratch/rebelann/shotgun/databases/humann3/chocophlan/

# Update HUMAnN3 config to point to this location
echo "Updating HUMAnN3 config: $(date)"
humann_config --update database_folders nucleotide \
  /N/scratch/rebelann/shotgun/databases/humann3/chocophlan

echo "ChocoPhlAn database ready: $(date)"

