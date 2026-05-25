#!/bin/bash
#SBATCH --job-name=uniref_ec_dl
#SBATCH --output=/N/scratch/rebelann/shotgun/slurm_logs/uniref_ec_%j.out
#SBATCH --error=/N/scratch/rebelann/shotgun/slurm_logs/uniref_ec_%j.err
#SBATCH --time=96:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

# ============================================================
# Download EC-filtered UniRef90 database for HUMAnN3
# EC-filtered version recommended by Huttenhower lab for
# pathway-level functional analysis (Beghini et al. 2021)
# Size ~0.9GB vs 20.7GB for full UniRef90
# ============================================================

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/slate/rebelann/conda_envs/humann3_new

mkdir -p /N/scratch/rebelann/shotgun/databases/humann3/uniref

echo "Downloading EC-filtered UniRef90 database: $(date)"
echo "Target: /N/scratch/rebelann/shotgun/databases/humann3/uniref"

humann_databases --download uniref uniref90_ec_filtered_diamond \
  /N/scratch/rebelann/shotgun/databases/humann3/uniref

echo "Download complete: $(date)"

# Verify download
echo "Verifying download:"
ls -lh /N/scratch/rebelann/shotgun/databases/humann3/uniref/

# Update HUMAnN3 config to point to this location
echo "Updating HUMAnN3 config: $(date)"
humann_config --update database_folders protein \
  /N/scratch/rebelann/shotgun/databases/humann3/uniref

echo "EC-filtered UniRef90 database ready: $(date)"

