# Mystery Microbe

Identify an unknown bacterial isolate from raw Illumina reads using a Snakemake
pipeline: download → QC → trim → subsample → assemble → identify.

## Dataset
- **Accession**: SRR2584863
- **Platform**: Illumina HiSeq 2500 2×150 bp
- **Total read pairs**: 1,553,259 (per mate)

## Pipeline

```
download → pre_trim_qc → trim → post_trim_qc → subsample → assembly
                                                              ├── kraken
                                                              ├── quast
                                                              ├── annotate
                                                              ├── blast
                                                              └── amr
```

| Step | Rule(s) | Tool | Output |
|------|---------|------|--------|
| 01 Download | `download` | sra-tools | `data/raw/{sample}_{1,2}.fastq.gz` |
| 02 Pre-trim QC | `pre_trim_qc`, `pre_trim_multi_qc` | fastqc, multiqc | `results/01_qc/pre_trim/` |
| 03 Trim | `trim` | fastp | `results/02_trimmed/` |
| 04 Post-trim QC | `post_trim_qc`, `post_trim_multi_qc` | fastqc, multiqc | `results/01_qc/post_trim/` |
| 05 Subsample | `subsample` | seqkit | `results/03_subsampled/` |
| 06 Assembly | `assembly` | spades | `results/04_assembly/{sample}_assembled.fasta` |
| 07 Kraken | `kraken_download`, `kraken_run` | kraken2 | `results/04_assembly/{sample}_report.txt` |
| 08 QUAST | `quast` | quast | `results/04_assembly/quast/{sample}/report.tsv` |
| 09 Annotate | `annotate` | prokka | `results/06_annotation/{sample}.gff` |
| 10 BLAST | `barrnap`, `extract_16s`, `download_16s_db`, `blastn_16s` | barrnap, bedtools, blast | `results/05_blast/{sample}_16S_blastn.tsv` |
| 11 AMR | `amr` | abricate | `results/07_amr/{sample}_amr_results.tsv` |

## Requirements
- [Snakemake](https://snakemake.readthedocs.io/) (with conda support)
- [Conda](https://docs.conda.io/) / Mamba
- Reference files in `reference/`:
  - `GCA_000005845.2.fasta` (QUAST reference genome)
  - `blast_db/16S_ribosomal_RNA` (downloaded by the `download_16s_db` rule)
  - `kraken2_db/` (downloaded by the `kraken_download` rule)

Each rule declares its own conda environment under `envs/`, so no manual tool
installation is required.

## Usage

```bash
# Preview the workflow
snakemake -n

# Run (create/activate conda envs per rule)
snakemake --use-conda --cores 4

# Force a full re-run
snakemake --use-conda --cores 4 -F
```

Edit `config/config.yaml` to add samples or change directories/parameters.
Logs are written to `logs/` and results to `results/`.

## QC Summary
- **Reads after trimming**: [fill in]
- **% reads passing QC**: [fill in]
- **Mean quality score**: [from fastp report]
- **GC content**: [from FastQC — this is a clue!]

## Assembly Summary
- **# contigs**: [from QUAST report]
- **Total length / N50**: [from QUAST report]
- **Reference**: GCA_000005845.2

## Species Identification
- **Top BLAST hit**: [species name]
- **Average % identity**: [fill in]
- **Number of reads matching**: [fill in]
- **Confidence**: [High/Medium/Low]

## AMR / Annotation Notes
- [fill in notable genes from `results/07_amr/` and `results/06_annotation/`]

## Conclusion
Based on BLAST analysis of [N] randomly sampled reads against NCBI nt,
the isolate is identified as [species name] with high confidence
([X]% of reads matching at >[Y]% identity).

## Tools and Versions
- sra-tools: [version]
- fastqc / multiqc: [version]
- fastp: [version]
- seqkit: [version]
- spades: [version]
- kraken2: [version]
- quast: [version]
- prokka: [version]
- barrnap / bedtools: [version]
- blast: [version]
- abricate: [version]
