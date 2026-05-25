#!/bin/bash
#SBATCH --job-name=fastq_check
#SBATCH --output=/N/scratch/rebelann/slurm_logs/fastq_check_%j.out
#SBATCH --error=/N/scratch/rebelann/slurm_logs/fastq_check_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END
set -eo pipefail
shopt -s nullglob

# CHANGE THIS TO YOUR SITE FOLDER
WORKDIR="/N/scratch/rebelann/NEON_metagenomics/shotgun/shotgun/raw_fastq/HOPB_2023-04"

cd "$WORKDIR"

LOG="fastq_integrity_${SLURM_JOB_ID}.tsv"
printf "file\tstatus\n" > "$LOG"

echo "Checking files in $WORKDIR"
echo "Started: $(date)"

for f in *.fastq.gz; do
    if gzip -t "$f"; then
        echo -e "$f\tOK" >> "$LOG"
    else
        echo -e "$f\tCORRUPT" >> "$LOG"
    fi
done

echo "Finished: $(date)"
echo "Log written to: $WORKDIR/$LOG"
