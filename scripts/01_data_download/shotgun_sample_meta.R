library(dplyr)
library(readr)
library(purrr)

# Find all amb_fieldParent CSV files
field_files <- list.files(
  path = "/Users/rebekahlanning/Documents/NEON/shotgun_metagen_metadata",
  pattern = ".*amb_fieldParent.*\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

# Check that files were found
field_files
length(field_files)

# Combine all "amb_fieldParent.csv" into 1 dataframe
field <- map_dfr(field_files, read_csv)

# Filter for only the 11 sites to be used
field_clean <- field %>%
  filter(!siteID %in% c("CARI", "OKSR", "SYCA", "TECR", "COMO", "WLOU", "CUPE", "GUIL", "LECO", "PRIN", "REDB", "BLDE", "ARIK"))

# Find all DNA extraction files 
dna_files <- list.files(
  path = "/Users/rebekahlanning/Documents/NEON/shotgun_metagen_metadata",
  pattern = ".*mms_benthicMetagenomeDnaExtraction.*\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

# Combine all DNA extraction files into 1 dataframe
dna <- map_dfr(dna_files, read_csv)

# Filter for only the 11 sites to be used
dna_clean <- dna %>%
  filter(!siteID %in% c("CARI", "OKSR", "SYCA", "TECR", "COMO", "WLOU", "CUPE", "GUIL", "LECO", "PRIN", "REDB", "BLDE", "ARIK"))

# Find all sequencing files
seq_files <- list.files(
  path = "/Users/rebekahlanning/Documents/NEON/shotgun_metagen_metadata",
  pattern = ".*mms_benthicMetagenomeSequencing.*\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

# Combine all sequencing files into 1 dataframe
seq <- map_dfr(seq_files, read_csv)

# Filter for only the 11 sites to be used
seq_clean <- seq %>%
  filter(!siteID %in% c("CARI", "OKSR", "SYCA", "TECR", "COMO", "WLOU", "CUPE", "GUIL", "LECO", "PRIN", "REDB", "BLDE", "ARIK"))

# Find all raw file tables
raw_files <- list.files(
  path = "/Users/rebekahlanning/Documents/NEON/shotgun_metagen_metadata",
  pattern = ".*mms_benthicRawDataFiles.*\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

# Combine all raw file tables into 1 dataframe
raw <- map_dfr(raw_files, read_csv)

# Filter for only the 11 sites to be used
raw_clean <- raw %>%
  filter(!siteID %in% c("CARI", "OKSR", "SYCA", "TECR", "COMO", "WLOU", "CUPE", "GUIL", "LECO", "PRIN", "REDB", "BLDE", "ARIK"))

# Which column matches dna$genomicsSampleID
sum(dna_clean$genomicsSampleID %in% field_clean$metagenomicSampleID, na.rm = TRUE)
sum(dna_clean$genomicsSampleID %in% field_clean$geneticSampleID, na.rm = TRUE)
sum(dna_clean$genomicsSampleID %in% field_clean$sampleID, na.rm = TRUE)

# Join the metadata together
meta <- dna_clean %>%
  left_join(seq_clean, by = "dnaSampleID") %>%
  left_join(field_clean, by = c("genomicsSampleID" = "geneticSampleID"))

# Count number of FASTQ records per dnaSampleID
reads <- raw_clean %>%
  group_by(dnaSampleID) %>%
  summarise(n_fastq = n(), .groups = "drop")

# Attach FASTQ counts to metadata
meta <- meta %>%
  left_join(reads, by = "dnaSampleID")

# Replace missing FASTQ counts with 0
meta <- meta %>%
  mutate(n_fastq = ifelse(is.na(n_fastq), 0, n_fastq))

# Summarize number of extractions per genomicsSampleID
dup_summary <- meta %>%
  group_by(genomicsSampleID) %>%
  summarise(n_extractions = n(), .groups = "drop")

# View genomics samples with multiple extractions
duplicates <- meta %>%
  group_by(genomicsSampleID) %>%
  filter(n() > 1) %>%
  arrange(genomicsSampleID, dnaSampleID)

# Choose one extraction per genomicsSampleID
# For now: keep the one with the highest n_fastq
best_extractions <- meta %>%
  group_by(genomicsSampleID) %>%
  slice_max(order_by = n_fastq, n = 1, with_ties = FALSE) %>%
  ungroup()

# Final cleaned sample table
clean_samples <- best_extractions

# QC checks
nrow(clean_samples)
n_distinct(clean_samples$genomicsSampleID)

# These should match:
# nrow(clean_samples) == n_distinct(clean_samples$genomicsSampleID)

# How many genomics samples had multiple extractions?
dup_summary %>%
  filter(n_extractions > 1)

# Keep only samples with FASTQ files
clean_samples <- meta %>%
  filter(n_fastq > 0)

# Check the number of FASTQ file records linked to each dnaSampleID
table(clean_samples$n_fastq)
# There are 251 samples with two FASTQ records (n_fastq = 2),
# consistent with standard paired-end sequencing (R1 and R2 files).

# There are 73 samples with only one FASTQ record (n_fastq = 1).
# These likely represent incomplete sequencing records or cases where
# only a single FASTQ file was released. These samples are typically
# excluded from paired-end metagenomic analyses.

# There are 50 dnaSampleIDs with no associated FASTQ records (n_fastq = 0).
# These samples appear in the metadata but do not have released raw
# sequence files, likely because they failed NEON QA/QC or sequencing.

# Optional: inspect sampleMaterial distribution after cleaning
table(clean_samples$sampleMaterial.x)

# Optional: inspect substrate / material distribution by site
table(clean_samples$siteID, clean_samples$sampleMaterial.x)

# Create a shotgun metadata file with only summer dates (June, July, August)
analysis_samples_summer <- clean_samples %>%
  mutate(
    site = siteID.x,
    collection_date = format(collectDate.x, "%Y-%m"),
    year = as.integer(format(collectDate.x, "%Y")),
    month = as.integer(format(collectDate.x, "%m"))
  ) %>%
  filter(month %in% c(6, 7, 8))

table(analysis_samples_summer$month)
table(analysis_samples_summer$site)
table(analysis_samples_summer$year)

####### Adding in sample mapping
library(dplyr)
library(readr)
library(purrr)
library(stringr)

# Find all of the sample name mapping files
rename_logs <- list.files(
  path = "/Users/rebekahlanning/Documents/NEON/shotgun_naming_logs",
  pattern = "rename_(log|map)_.*\\.tsv$",
  recursive = TRUE,
  full.names = TRUE
)

# Check files
rename_logs
length(rename_logs)

# Combine all sample name mapping files into one dataframe
rename_map <- map_dfr(rename_logs, function(f) {
  read_tsv(f) %>%
    mutate(
      source_file = basename(f),
      site_date = str_extract(source_file, "[A-Z]{4}_\\d{4}-\\d{2}")
    )
})

# Inspect rename_map
names(rename_map)
head(rename_map)

# Standardize the mapping columns
rename_map <- rename_map %>%
  rename(
    old_name = 1,
    new_name = 2
  )

# Add a column to help identify which final file is R1 or R2
rename_map <- rename_map %>%
  mutate(
    old_name = basename(old_name),
    new_name = basename(new_name),
    read = case_when(
      str_detect(new_name, "_R1\\.fastq\\.gz$") ~ "R1",
      str_detect(new_name, "_R2\\.fastq\\.gz$") ~ "R2",
      TRUE ~ NA_character_
    )
  )

# Check that there are matching R1 and R2 numbers
table(rename_map$read, useNA = "ifany")

# create a clean filename column using basename()
raw_clean <- raw_clean %>%
  mutate(old_name = basename(rawDataFileName))

# Join rename_map to raw_clean
raw_final <- raw_clean %>%
  left_join(rename_map, by = "old_name")

# Check the result of the merge
names(raw_final)
head(raw_final)

# Check whether the join worked
sum(is.na(raw_final$new_name))

# Inspect any unmatched rows
raw_final %>%
  filter(is.na(new_name)) %>%
  select(dnaSampleID, old_name) %>%
  distinct()

# Final FASTQ manifest 
fastq_manifest <- raw_final %>%
  filter(!is.na(new_name)) %>%
  select(dnaSampleID, new_name, read) %>%
  distinct() %>%
  tidyr::pivot_wider(
    names_from = read,
    values_from = new_name
  )

# compute the final paired-end structure
reads_final <- raw_final %>%
  group_by(dnaSampleID) %>%
  summarise(
    n_final_fastq = n_distinct(new_name),
    has_R1 = any(read == "R1"),
    has_R2 = any(read == "R2"),
    paired_complete = has_R1 & has_R2,
    .groups = "drop"
  )

table(reads_final$n_final_fastq)
table(reads_final$paired_complete)

reads_final %>%
  filter(!paired_complete)

# ── Check what field columns came through in analysis_samples_summer ──────
names(analysis_samples_summer)

# Look for habitat/substrate columns — they may have suffixes
names(analysis_samples_summer)[grepl("habitat|aquMicro|substratum", 
                                     names(analysis_samples_summer), 
                                     ignore.case = TRUE)]

# ── Create filtered analysis object (don't overwrite the full dataset) ────
thesis_metagenomes <- analysis_samples_summer %>%
  filter(
    site          %in% c("LEWI", "MART", "POSE", "WALK"),
    sampleMaterial.x == "biofilm",
    aquMicrobeType   == "epilithon"
  )

cat("Total samples after filters:", nrow(thesis_metagenomes), "\n\n")

cat("aquMicrobeType (should only be epilithon):\n")
thesis_metagenomes %>% count(aquMicrobeType) %>% print()

cat("\nSamples per site:\n")
thesis_metagenomes %>% count(site) %>% print()

cat("\nSamples per site x year:\n")
thesis_metagenomes %>%
  count(site, year) %>%
  tidyr::pivot_wider(names_from = year, values_from = n, values_fill = 0) %>%
  print()

cat("\nsubstratumSizeClass by site:\n")
thesis_metagenomes %>% count(site, substratumSizeClass) %>% print()

cat("\nAll paired complete?\n")
thesis_metagenomes %>%
  left_join(reads_final, by = "dnaSampleID") %>%
  count(paired_complete) %>%
  print()

thesis_metagenomes <- thesis_metagenomes %>%
  filter(
    year  != 2020,
    month %in% c(6, 7, 8)
  )

cat("Final sample count:", nrow(thesis_metagenomes), "\n\n")

cat("Months present (should only be 6, 7, 8):\n")
thesis_metagenomes %>% count(month) %>% print()

cat("\nSamples per site x year:\n")
thesis_metagenomes %>%
  count(site, year) %>%
  tidyr::pivot_wider(names_from = year, values_from = n, values_fill = 0) %>%
  print()

# ── Write final metagenomic metadata ─────────────────────────────────────
thesis_metagenomes %>%
  select(
    dnaSampleID,
    genomicsSampleID,
    site,
    year,
    month,
    collection_date,
    habitatType,
    aquMicrobeType,
    substratumSizeClass,
    sampleMaterial.x,
    sampleTotalReadNumber,
    sampleFilteredReadNumber,
    sequencerRunID,
    instrument_model,
    qaqcStatus.x,
    qaqcStatus.y
  ) %>%
  write.table(
    file      = "~/Documents/NEON/March_final_amplicon/filtered_metadata_metagenomes.tsv",
    sep       = "\t",
    quote     = FALSE,
    row.names = FALSE
  )

cat("Metagenomic metadata written.\n")
cat("Samples:", nrow(thesis_metagenomes), "\n")

#### Go run make_big_shotgun_rename_log.R and then do the below code with the variables from that script in this environment
# ── Step 1: get raw filenames for thesis samples only ─────────────────────
raw_thesis <- raw_clean %>%
  filter(dnaSampleID %in% thesis_metagenomes$dnaSampleID) %>%
  mutate(old_name = basename(rawDataFileName)) %>%
  select(dnaSampleID, old_name)

cat("Raw file records for thesis samples:", nrow(raw_thesis), "\n")
# Expect 59 * 2 = 118

# ── Step 2: join to rename_map to get new filenames ───────────────────────
raw_renamed <- raw_thesis %>%
  left_join(rename_map %>% select(old_name, new_name, read),
            by = "old_name")

# Check for any unmatched files
unmatched <- raw_renamed %>% filter(is.na(new_name))
cat("Unmatched files:", nrow(unmatched), "\n")
if (nrow(unmatched) > 0) print(unmatched)

# ── Step 3: pivot to wide format (one row per sample, R1 and R2 columns) ──
fastq_manifest <- raw_renamed %>%
  filter(!is.na(new_name)) %>%
  select(dnaSampleID, new_name, read) %>%
  tidyr::pivot_wider(
    names_from  = read,
    values_from = new_name
  )

cat("\nManifest rows:", nrow(fastq_manifest), "\n")
# Expect 59

# ── Step 4: join thesis metadata to get site/year/collection info ─────────
final_manifest <- thesis_metagenomes %>%
  select(dnaSampleID, site, year, month, collection_date,
         habitatType, aquMicrobeType, substratumSizeClass) %>%
  left_join(fastq_manifest, by = "dnaSampleID")

cat("Final manifest rows:", nrow(final_manifest), "\n")

# ── Sanity checks ─────────────────────────────────────────────────────────
cat("\nMissing R1:", sum(is.na(final_manifest$R1)), "\n")
cat("Missing R2:", sum(is.na(final_manifest$R2)), "\n")

cat("\nSamples per site x year:\n")
final_manifest %>%
  count(site, year) %>%
  tidyr::pivot_wider(names_from = year, values_from = n, values_fill = 0) %>%
  print()

cat("\nFirst few rows:\n")
final_manifest %>%
  select(dnaSampleID, site, year, R1, R2) %>%
  head(6) %>%
  print()

# ── Write output ──────────────────────────────────────────────────────────
write.table(
  final_manifest,
  file      = "~/Documents/NEON/March_final_amplicon/shotgun_manifest.tsv",
  sep       = "\t",
  quote     = FALSE,
  row.names = FALSE
)

cat("\nManifest written to shotgun_manifest.tsv\n")

# ── Generate list of FASTQ files to KEEP ─────────────────────────────────
files_to_keep <- final_manifest %>%
  select(R1, R2) %>%
  tidyr::pivot_longer(cols = everything(), values_to = "filename") %>%
  pull(filename) %>%
  sort()

cat("Total files to keep:", length(files_to_keep), "\n")
# Expect 118 (59 samples x 2 reads)

print(files_to_keep)

# Write to a text file to use in bash
writeLines(
  files_to_keep,
  "~/Documents/NEON/March_final_amplicon/files_to_keep.txt"
)

cat("File list written to files_to_keep.txt\n")
