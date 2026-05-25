#!/bin/bash
#SBATCH --job-name=humann_array
#SBATCH --output=/N/scratch/rebelann/shotgun/slurm_logs/humann_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/slurm_logs/humann_%A_%a.err
#SBATCH --time=96:00:00
#SBATCH --mem=256G
#SBATCH --cpus-per-task=16
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --array=1-40
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

# ============================================================
# HUMAnN array script for NEON epilithon shotgun samples
# Runs HUMAnN 3.9 using pre-computed MetaPhlAn profiles
# Two-step workflow required due to MetaPhlAn 4.1.1 version
# string compatibility with HUMAnN 3.9
# ============================================================

module purge
module load conda/25.3.0
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /N/slate/rebelann/conda_envs/humann3_new

# ---- Paths ----
SAMPLE_LIST=/N/scratch/rebelann/shotgun/sample_ids_2022_2023.txt
TRIMMED=/N/scratch/rebelann/shotgun/trimmed
CAT_DIR=/N/scratch/rebelann/shotgun/cat_reads
METAPHLAN_OUT=/N/scratch/rebelann/shotgun/humann3/metaphlan_profiles
HUMANN_OUT=/N/scratch/rebelann/shotgun/humann3

# ---- Get sample ID for this array task ----
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $SAMPLE_LIST)

echo "Processing sample: $SAMPLE"
echo "Start time: $(date)"

# ---- Check MetaPhlAn profile exists ----
METAPHLAN_PROFILE=$METAPHLAN_OUT/${SAMPLE}_metaphlan.txt

if [ ! -f "$METAPHLAN_PROFILE" ]; then
    echo "ERROR: MetaPhlAn profile not found for $SAMPLE"
    echo "Expected: $METAPHLAN_PROFILE"
    echo "Please run metaphlan_array.slurm first"
    exit 1
fi

# ---- Create output directory for this sample ----
mkdir -p $HUMANN_OUT/${SAMPLE}

# ---- Check if HUMAnN already completed for this sample ----
if [ -f "$HUMANN_OUT/${SAMPLE}/${SAMPLE}_cat_pathabundance.tsv" ]; then
    echo "HUMAnN output already exists for $SAMPLE, skipping"
    exit 0
fi

# ---- Run HUMAnN ----
echo "Running HUMAnN for $SAMPLE: $(date)"

humann --input $CAT_DIR/${SAMPLE}_cat.fastq.gz \
       --output $HUMANN_OUT/${SAMPLE} \
       --threads 16 \
       --taxonomic-profile $METAPHLAN_PROFILE \
       --verbose \
       --memory-use maximum

echo "HUMAnN complete for $SAMPLE: $(date)"
echo "Done: $(date)"

