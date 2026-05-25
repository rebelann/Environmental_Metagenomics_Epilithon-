#!/bin/bash
#SBATCH --job-name=metaphlan_array
#SBATCH --output=/N/scratch/rebelann/shotgun/slurm_logs/metaphlan_%A_%a.out
#SBATCH --error=/N/scratch/rebelann/shotgun/slurm_logs/metaphlan_%A_%a.err
#SBATCH --time=12:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=4
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --array=1-40
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

# ============================================================
# MetaPhlAn array script for NEON epilithon shotgun samples
# Runs MetaPhlAn 4.1.1 with vJun23 database on all 40 samples
# Compatible with HUMAnN 3.9 (Jun23 database required)
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
METAPHLAN_DB=/N/scratch/rebelann/shotgun/databases/metaphlan_jun23
METAPHLAN_INDEX=mpa_vJun23_CHOCOPhlAnSGB_202403

# ---- Get sample ID for this array task ----
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $SAMPLE_LIST)

echo "Processing sample: $SAMPLE"
echo "Start time: $(date)"

# ---- Create output directories ----
mkdir -p $METAPHLAN_OUT
mkdir -p $CAT_DIR

# ---- Step 1: Concatenate R1 and R2 reads ----
CAT_FILE=$CAT_DIR/${SAMPLE}_cat.fastq.gz

if [ -f "$CAT_FILE" ]; then
    echo "Cat file already exists for $SAMPLE, skipping concatenation"
else
    echo "Concatenating R1 and R2 for $SAMPLE"
    cat $TRIMMED/${SAMPLE}_R1_trimmed.fastq.gz \
        $TRIMMED/${SAMPLE}_R2_trimmed.fastq.gz \
        > $CAT_FILE
    echo "Concatenation complete: $(date)"
fi

# ---- Step 2: Run MetaPhlAn ----
METAPHLAN_PROFILE=$METAPHLAN_OUT/${SAMPLE}_metaphlan.txt

if [ -f "$METAPHLAN_PROFILE" ]; then
    echo "MetaPhlAn profile already exists for $SAMPLE, skipping"
else
    echo "Running MetaPhlAn for $SAMPLE: $(date)"
    /N/slate/rebelann/conda_envs/humann3_new/bin/metaphlan $CAT_FILE \
        --input_type fastq \
        --bowtie2db $METAPHLAN_DB \
        --index $METAPHLAN_INDEX \
        --nproc 4 \
        --bowtie2out $METAPHLAN_OUT/${SAMPLE}.bowtie2out.txt \
        -o $METAPHLAN_PROFILE

    echo "MetaPhlAn complete for $SAMPLE: $(date)"
fi

echo "Done: $(date)"

