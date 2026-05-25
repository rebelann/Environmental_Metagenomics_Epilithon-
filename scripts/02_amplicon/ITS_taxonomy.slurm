#!/bin/bash
#SBATCH --job-name=ITS_tax_merged
#SBATCH --output=/N/scratch/rebelann/MG_runs/slurm_logs/ITS_tax_%j.out
#SBATCH --error=/N/scratch/rebelann/MG_runs/slurm_logs/ITS_tax_%j.err
#SBATCH --time=12:00:00
#SBATCH --mem=256G
#SBATCH --cpus-per-task=8
#SBATCH --partition=general
#SBATCH -A r00750
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail

module purge
module load conda/25.3.0
eval "$(conda shell.bash hook)"
conda activate /N/slate/rebelann/conda_envs/qiime2-amplicon-2025.4

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

echo "=== ENV CHECK ==="
echo "QIIME:   $(which qiime)"
qiime --version
python --version

# -------------------------
# INPUT PATHS
# -------------------------
MERGED="/N/scratch/rebelann/MG_runs/dada2_output/ITS"
REPSEQ="${MERGED}/merged_rep_seqs_ITS.qza"
TABLE="${MERGED}/merged_table_ITS.qza"
CLASSIFIER="/N/slate/rebelann/classifier_training/unite_its1/unite-its1-classifier.qza"
METADATA="/N/scratch/rebelann/MG_site_data/final_metadata/filtered_metadata_ITS_fixed.tsv"

# -------------------------
# OUTPUT PATHS
# -------------------------
OUTPUT="/N/scratch/rebelann/MG_runs/taxonomy/ITS"
LOG_DIR="/N/scratch/rebelann/MG_runs/slurm_logs"

mkdir -p "$OUTPUT"
mkdir -p "$LOG_DIR"

export TMPDIR="/N/scratch/rebelann/MG_runs/tmp/${SLURM_JOB_ID}"
mkdir -p "$TMPDIR"

echo "Job started: $(date)"
echo "Node: $(hostname)"
echo "REPSEQ: $REPSEQ"
echo "OUTPUT: $OUTPUT"
echo "TMPDIR: $TMPDIR"
echo "METADATA: $METADATA"

# -------------------------
# FILE CHECKS
# -------------------------
[[ -f "$REPSEQ" ]]       || { echo "ERROR: rep-seqs not found: $REPSEQ"; exit 1; }
[[ -f "$TABLE" ]]        || { echo "ERROR: table not found: $TABLE"; exit 1; }
[[ -f "$CLASSIFIER" ]]   || { echo "ERROR: classifier not found: $CLASSIFIER"; exit 1; }
[[ -f "$METADATA" ]]     || { echo "ERROR: metadata not found: $METADATA"; exit 1; }

# -------------------------
# Taxonomic Classification
# -------------------------
qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads "$REPSEQ" \
  --p-n-jobs 4 \
  --o-classification "${OUTPUT}/taxonomy_ITS.qza"

# Visualize taxonomy
qiime metadata tabulate \
  --m-input-file "${OUTPUT}/taxonomy_ITS.qza" \
  --o-visualization "${OUTPUT}/taxonomy_ITS.qzv"

# Taxa bar plot
qiime taxa barplot \
  --i-table "$TABLE" \
  --i-taxonomy "${OUTPUT}/taxonomy_ITS.qza" \
  --m-metadata-file "$METADATA" \
  --o-visualization "${OUTPUT}/taxa-barplot_ITS.qzv"

echo "ITS Taxonomy complete!"
echo "Outputs in: $OUTPUT"
echo "Finished: $(date)"

