#!/bin/bash
#SBATCH --job-name=neon_raw_dl
#SBATCH --output=/N/project/Krolab/Rebekah/NEON_metagenomics/shotgun/slurm_logs/neon_raw_dl_%A_%a.out
#SBATCH --error=/N/project/Krolab/Rebekah/NEON_metagenomics/shotgun/slurm_logs/neon_raw_dl_%A_%a.err
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH -A r00750
#SBATCH -p general
#SBATCH --array=1-52%10
#SBATCH --mail-user=rebelann@iu.edu
#SBATCH --mail-type=FAIL,END

set -eo pipefail
shopt -s nullglob

SHOTGUN_ROOT="/N/project/Krolab/Rebekah/NEON_metagenomics/shotgun"
OUT_ROOT="${SHOTGUN_ROOT}/raw_fastq"
LOG_DIR="${OUT_ROOT}/logs"
TASKLIST="${SHOTGUN_ROOT}/scripts/download_tasklist.tsv"

mkdir -p "$OUT_ROOT" "$LOG_DIR" "${SHOTGUN_ROOT}/slurm_logs"

# One log set per ARRAY TASK (so parallel jobs don't collide)
LOG_OK="$LOG_DIR/download_ok_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.tsv"
LOG_FAIL="$LOG_DIR/download_fail_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.tsv"
LOG_SKIP="$LOG_DIR/download_skip_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.tsv"

printf "timestamp\tcollection_folder\tfile\turl\n" > "$LOG_OK"
printf "timestamp\tcollection_folder\tfile\turl\treason\n" > "$LOG_FAIL"
printf "timestamp\tcollection_folder\tfile\turl\treason\n" > "$LOG_SKIP"

echo "Job started: $(date)"
echo "Node: $(hostname)"
echo "Tasklist: $TASKLIST"
echo "Array job: ${SLURM_ARRAY_JOB_ID} task: ${SLURM_ARRAY_TASK_ID}"

if [[ ! -f "$TASKLIST" ]]; then
  echo "ERROR: Tasklist not found: $TASKLIST"
  exit 1
fi

# Get this task's collection folder + meta folder (skip header, so NR==task+1)
LINE=$(awk -v t="${SLURM_ARRAY_TASK_ID}" 'NR==t+1 {print $0}' "$TASKLIST")
if [[ -z "${LINE}" ]]; then
  echo "ERROR: No line for task ${SLURM_ARRAY_TASK_ID} in $TASKLIST"
  exit 1
fi

collection_folder=$(echo "$LINE" | cut -f1)
meta_folder=$(echo "$LINE" | cut -f2)

echo "collection_folder: $collection_folder"
echo "meta_folder:       $meta_folder"

out_folder="${OUT_ROOT}/${collection_folder}"
mkdir -p "$out_folder"

# Find the benthicRawDataFiles CSV inside this SITE_YYYY-MM folder
csv_files=( "$meta_folder"/NEON.D??.*.DP1.20279.001.mms_benthicRawDataFiles.*.csv )
if [[ ${#csv_files[@]} -eq 0 ]]; then
  printf "%s\t%s\t%s\t%s\t%s\n" "$(date -Is)" "$collection_folder" "-" "-" "no_mms_benthicRawDataFiles_csv_found" >> "$LOG_SKIP"
  echo "No mms_benthicRawDataFiles CSV found in: $meta_folder"
  exit 0
fi

# Process each matching CSV found (usually 1)
for csv_path in "${csv_files[@]}"; do
  csv_base="$(basename "$csv_path")"
  echo "Processing ${collection_folder} / ${csv_base}"

  # Find column index (1-based) of rawDataFilePath in header row
  col=$(head -n 1 "$csv_path" | awk -F',' '{
    for (i=1; i<=NF; i++) {
      gsub(/^"|"$/, "", $i)
      if ($i=="rawDataFilePath") { print i; exit }
    }
  }')

  if [[ -z "${col:-}" ]]; then
    printf "%s\t%s\t%s\t%s\t%s\n" "$(date -Is)" "$collection_folder" "-" "-" "missing_rawDataFilePath_column" >> "$LOG_SKIP"
    echo "Missing rawDataFilePath column in: $csv_path"
    continue
  fi

  # Extract URLs from rawDataFilePath column, skip header, dequote, remove blanks
  awk -F',' -v c="$col" 'NR>1 {print $c}' "$csv_path" \
    | sed 's/^"//; s/"$//' \
    | awk 'NF>0' \
    | while IFS= read -r url; do

        url="${url//$'\r'/}"

        fname="$(basename "${url%%\?*}")"
        outpath="${out_folder}/${fname}"
        partpath="${outpath}.part"

        # 1) If final file exists and non-empty -> SKIP
        if [[ -s "$outpath" ]]; then
          printf "%s\t%s\t%s\t%s\t%s\n" "$(date -Is)" "$collection_folder" "$fname" "$url" "already_present" >> "$LOG_SKIP"
          echo "SKIP exists: $outpath"
          continue
        fi

        # 2) Download to .part and resume if partial exists
        echo "[${collection_folder}] downloading ${fname}"

        if curl -L -C - --retry 8 --retry-delay 15 --fail -o "$partpath" "$url"; then
          mv -f "$partpath" "$outpath"
          printf "%s\t%s\t%s\t%s\n" "$(date -Is)" "$collection_folder" "$fname" "$url" >> "$LOG_OK"
        else
          # keep .part for resume
          printf "%s\t%s\t%s\t%s\t%s\n" "$(date -Is)" "$collection_folder" "$fname" "$url" "curl_failed_kept_part" >> "$LOG_FAIL"
          echo "FAIL (kept partial if any): $partpath"
        fi
      done
done

echo "Job finished: $(date)"
echo "Logs:"
echo "  OK:   $LOG_OK"
echo "  FAIL: $LOG_FAIL"
echo "  SKIP: $LOG_SKIP"
