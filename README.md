# Environmental_Metagenomics_Epilithon-
Metagenomic surveillance analysis of stream epilithon biofilm communities, functional potential, and resistome content across four NEON aquatic sites. MS Bioinformatics thesis, IU Indianapolis.

# Environmental Surveillance Analysis Using Metagenomics of Stream Epilithon Biofilm

Analysis code for an MS Bioinformatics thesis (Indiana University Indianapolis, 
Luddy School of Informatics, 2026) characterizing bacterial, archaeal, and fungal 
communities and antibiotic resistance gene (ARG) content in stream epilithon biofilm 
across four NEON aquatic sites and three sampling years (2021-2023).

## Overview

This thesis applied 16S rRNA, ITS, and shotgun metagenomic sequencing to characterize 
microbial community composition, functional potential, and resistome content in stream 
epilithon biofilm samples from four NEON aquatic sites (LEWI, MART, POSE, WALK) across 
three NEON aquatic domains (Mid-Atlantic D02, Cumberland Plateau D07, Pacific Northwest 
D16). The central findings show that site is the dominant driver of variation across 
all five analysis layers (taxonomy, function, and resistome), and that NEON epilithon 
biofilm contains clinically-relevant resistance machinery including the carbapenemases 
blaIMP-8 and blaCAM-1, supporting epilithon as a viable One Health surveillance matrix.

## Pipeline

The analysis is organized into five stages:

1. **Data download and metadata** (`scripts/01_data_download/`) - NEON metadata parsing 
   and SLURM array job for shotgun raw FASTQ download
2. **Amplicon processing** (`scripts/02_amplicon/`) - QIIME2/DADA2 16S and ITS workflows, 
   phyloseq object construction and filtering, alpha and beta diversity analyses
3. **Shotgun processing** (`scripts/03_shotgun/`) - Kraken2/Bracken taxonomic 
   classification of shotgun metagenomic reads
4. **Functional analysis** (`scripts/04_functional/`) - HUMAnN3 pathway profiling 
   and MaAsLin2 differential abundance testing
5. **Resistome analysis** (`scripts/05_resistome/`) - ResFinder and CARD/RGI ARG 
   detection and WHO Critically Important Antimicrobials categorization

## Software and tool versions

- QIIME2 v2025.4
- DADA2 (within QIIME2)
- R v4.4.0
- phyloseq v1.52.0
- vegan v2.7.3
- ggplot2 v4.0.2
- patchwork v1.3.2
- Kraken2 / Bracken
- MetaPhlAn v4.1.1 (database: mpa_vJun23_CHOCOPhlAnSGB_202403)
- HUMAnN v3.9
- MMUPHin (R) for batch correction
- MaAsLin2 (R) for differential abundance
- ResFinder v4.0
- CARD v4.0.1 (May 2025 JSON release, with WildCARD allelic variants)
- RGI v6.0.5 (metagenomic read-mapping mode with KMA aligner)
- KMA aligner

## Repository structure

```
.
├── README.md
├── LICENSE
├── data/
│   ├── shotgun_metadata.tsv
│   ├── filtered_metadata_metagenomes.tsv
│   ├── shotgun_manifest.tsv
│   ├── filtered_metadata_16S_q2_swap.tsv
│   └── filtered_metadata_ITS_fixed.tsv
└── scripts/
    ├── 01_data_download/
    ├── 02_amplicon/
    ├── 03_shotgun/
    ├── 04_functional/
    └── 05_resistome/
```

## Data

### Shotgun metagenomic samples

Sample metadata for the 40 shotgun samples is provided in `data/shotgun_metadata.tsv`. 
This file is the recommended starting point and contains NEON sample IDs 
(`dnaSampleID`, `genomicsSampleID`), site, year, collection date, sequencing details, 
QC status, and the renamed R1/R2 FASTQ filenames used in this analysis.

#### Downloading shotgun raw FASTQ data

The raw FASTQ files are publicly available through the NEON data portal under product 
**DP1.20279.001** (Microbe community composition - metagenomes). NEON distributes 
sequencing data in multiple formats: separate R1/R2 FASTQ files (newer samples), 
interleaved FASTQ files (some samples), and barcoded archive formats (older samples).

This thesis used a SLURM array job (`scripts/01_data_download/neon_raw_dl.slurm`) to 
download the raw FASTQ files in parallel across collection folders, using the 
`rawDataFilePath` URLs from each per-collection `mms_benthicRawDataFiles` CSV. The 
array tasklist (`scripts/01_data_download/download_tasklist.tsv`) maps each array 
task to a collection folder and its corresponding NEON metadata folder. Users who 
want to reuse this approach will need to adjust the HPC paths at the top of the 
SLURM script to their own environment.

For users without HPC access, the recommended way to download is via the 
`neonUtilities` R package, which handles format selection automatically:

```r
library(neonUtilities)
zipsByProduct(dpID = "DP1.20279.001", 
              site = c("LEWI", "MART", "POSE", "WALK"),
              startdate = "2022-07", 
              enddate = "2023-07",
              package = "expanded")
```

The downloaded zip files contain both the metadata tables and the raw FASTQ download 
URLs. URLs for each FASTQ file are in the `rawDataFileName` column of the 
`mms_benthicRawDataFiles` table.

### Amplicon samples

Sample metadata for the 178 amplicon samples is provided in two QIIME2-formatted files:

- `data/filtered_metadata_16S_q2_swap.tsv` - 16S V4-V5 rRNA samples
- `data/filtered_metadata_ITS_fixed.tsv` - ITS1 samples

Both files include NEON sample IDs, site, season, year, collection date, and 
substrate/habitat metadata, formatted for direct use with QIIME2. The `sample-id` 
column uses hyphens instead of underscores as required by QIIME2; original 
underscore-delimited sample IDs are preserved in the `original_sample_id` column 
(16S) or `cleaned_sample_id` column (ITS). The `was_modified` column indicates 
whether the original ID was reformatted.

QIIME2 manifest files mapping sample IDs to FASTQ file paths were generated 
per-sequencing-run from the renamed FASTQ files (R1/R2 convention matching the 
`sample-id` column in the metadata files). These manifest files are not included 
in this repository because the file paths are specific to the HPC environment used 
in this analysis. Users reproducing this work will need to generate manifests for 
their own environment using QIIME2's standard manifest format.

A subset of samples carry the NEON sample ID prefix `RUSH` but were collected at 
LEWI; the `site` column reflects the corrected site assignment for these samples.

#### Amplicon raw data download

Raw FASTQ files for the 16S V4-V5 rRNA (NEON product DP1.20280.001) and ITS1 
(NEON product DP1.20282.001) amplicon datasets are publicly available through the 
NEON data portal. The original SLURM download script used in this thesis is not 
included in this repository, but the download approach parallels the shotgun 
pipeline: each per-collection NEON metadata download contains a 
`mmg_benthicRawDataFiles` CSV with download URLs in the `rawDataFilePath` column.

The recommended approach for users is the `neonUtilities` R package:

```r
library(neonUtilities)

# 16S amplicon data
zipsByProduct(dpID = "DP1.20280.001", 
              site = c("LEWI", "MART", "POSE", "WALK"),
              startdate = "2021-01", 
              enddate = "2023-12",
              package = "expanded")

# ITS amplicon data
zipsByProduct(dpID = "DP1.20282.001", 
              site = c("LEWI", "MART", "POSE", "WALK"),
              startdate = "2021-01", 
              enddate = "2023-12",
              package = "expanded")
```

Alternatively, users can also adapt the shotgun SLURM download script 
(`scripts/01_data_download/neon_raw_dl.slurm`) to point at the amplicon 
`mmg_benthicRawDataFiles` tables instead of `mms_benthicRawDataFiles`. The structure 
is parallel between the two product families.

#### Reproducing the metadata parsing

For users who want to reproduce the metadata parsing from the NEON downloads, 
`scripts/01_data_download/shotgun_sample_meta.R` shows how the per-product NEON 
metadata tables (`amb_fieldParent`, `mms_benthicMetagenomeDnaExtraction`, 
`mms_benthicMetagenomeSequencing`, `mms_benthicRawDataFiles`) were combined into 
`filtered_metadata_metagenomes.tsv` and `shotgun_manifest.tsv`. 
`scripts/01_data_download/combine_shotgun_metadata.R` then joins these into the 
single user-facing `shotgun_metadata.tsv`.


## Citation

Lanning, R. E., Krohannon, A. (2026). Environmental Surveillance Analysis Using Metagenomics of Stream 
Epilithon Biofilm [Master's thesis, Indiana University Indianapolis].

## Contact

rebekah.lanning4@gmail.com


