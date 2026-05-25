#!/bin/bash
#SBATCH --job-name=16S_tax_merged
#SBATCH --output=/N/scratch/rebelann/MG_runs/slurm_logs/16S_tax_%j.out
#SBATCH --error=/N/scratch/rebelann/MG_runs/slurm_logs/16S_tax_%j.err
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
MERGED="/N/scratch/rebelann/MG_runs/dada2_output/merged"
REPSEQ="${MERGED}/rep-seqs-merged.qza"
TABLE="${MERGED}/table-merged-filtered.qza"
CLASSIFIER="/N/slate/rebelann/classifier_training/silva_v4v5/silva-138-99-V4V5-classifier.qza"
METADATA="/N/scratch/rebelann/MG_site_data/final_metadata/filtered_metadata_16S_q2_swap.tsv"

# -------------------------
# OUTPUT PATHS
# -------------------------
OUTPUT="/N/scratch/rebelann/MG_runs/taxonomy"
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
  --o-classification "${OUTPUT}/taxonomy.qza"

# Visualize taxonomy
qiime metadata tabulate \
  --m-input-file "${OUTPUT}/taxonomy.qza" \
  --o-visualization "${OUTPUT}/taxonomy.qzv"

# Taxa bar plot
qiime taxa barplot \
  --i-table "$TABLE" \
  --i-taxonomy "${OUTPUT}/taxonomy.qza" \
  --m-metadata-file "$METADATA" \
  --o-visualization "${OUTPUT}/taxa-barplot.qzv"

echo "Taxonomy complete!"
echo "Outputs in: $OUTPUT"
echo "Finished: $(date)"
