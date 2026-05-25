from qiime2 import Artifact
from qiime2.plugins.demux.visualizers import summarize as demux_summarize
from qiime2.plugins.dada2.methods import denoise_paired
from qiime2.plugins.feature_table.visualizers import summarize as table_summarize
from qiime2.plugins.feature_table.visualizers import tabulate_seqs
from qiime2.plugins.metadata.visualizers import tabulate
import qiime2
import os

# Set input manifest and output directory
manifest_path = '/N/scratch/rebelann/MG_runs/manifests/manifest_16S_HHJFLDRX5.tsv'
output_dir    = '/N/scratch/rebelann/MG_runs/dada2_output/HHJFLDRX5'
os.makedirs(output_dir, exist_ok=True)

# Step 1: Import paired-end sequences using manifest
print("Importing sequences...")
demuxed = Artifact.import_data(
    'SampleData[PairedEndSequencesWithQuality]',
    manifest_path,
    view_type='PairedEndFastqManifestPhred33'
)
demuxed.save(os.path.join(output_dir, 'demux-paired-end.qza'))
print("Import complete.")

# Step 2: Visualize quality profile
summary_viz = demux_summarize(data=demuxed)
summary_viz.visualization.save(os.path.join(output_dir, 'paired-end-demux.qzv'))
print("Demux summary saved.")

# Step 3: Denoise with DADA2
print("Running DADA2 denoising (this will take several hours)...")
dada2_output = denoise_paired(
    demultiplexed_seqs=demuxed,
    trunc_len_f=220,
    trunc_len_r=240,
    trim_left_f=19,
    trim_left_r=20,
    n_threads=8
)

# Save core DADA2 outputs
dada2_output.table.save(os.path.join(output_dir, 'table.qza'))
dada2_output.representative_sequences.save(os.path.join(output_dir, 'rep-seqs.qza'))
dada2_output.denoising_stats.save(os.path.join(output_dir, 'denoising-stats.qza'))
print("DADA2 outputs saved.")

# Step 4: Visualize results
summary_table = table_summarize(table=dada2_output.table)
summary_table.visualization.save(os.path.join(output_dir, 'table-summary.qzv'))

rep_seqs_viz = tabulate_seqs(data=dada2_output.representative_sequences)
rep_seqs_viz.visualization.save(os.path.join(output_dir, 'rep-seqs.qzv'))

stats_metadata = dada2_output.denoising_stats.view(qiime2.Metadata)
stats_viz = tabulate(input=stats_metadata)
stats_viz.visualization.save(os.path.join(output_dir, 'denoising-stats.qzv'))

print("All visualizations saved.")
print("DADA2 preprocessing complete for HHJFLDRX5.")
