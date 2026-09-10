# Load the configuration file
configfile: "config/config.yaml"


# Access the variables
RAW_DIR = config["directories"]["raw"]
QC_DIR = config["directories"]["qc"]
TRIM_DIR = config["directories"]["trimmed"]
SUBSAMPLE_DIR = config["directories"]["subsampled"]
ASSEMBLY_DIR = config["directories"]["assembly"]
BLAST_DIR = config["directories"]["blast"]
ANNOTATION_DIR = config["directories"]["annotation"]
AMR_DIR = config["directories"]["amr"]
KRAKEN2_DB_DIR = config["directories"]["kraken2_db"]
BLAST_DB_DIR = config["directories"]["blast_db"]
QUAST_DIR = config["directories"]["quast"]

SAMPLES = config["samples"]


rule all:
    input:
        expand(f"{ANNOTATION_DIR}/{{sample}}.gff", sample=SAMPLES),
        f"{QC_DIR}/pre_trim/multiqc_report.html",
        f"{QC_DIR}/post_trim/multiqc_report.html",
        expand(f"{ASSEMBLY_DIR}/{{sample}}_report.txt", sample=SAMPLES),
        expand(f"{QUAST_DIR}/{{sample}}/report.tsv", sample=SAMPLES),
        expand(f"{AMR_DIR}/{{sample}}_amr_results.tsv", sample=SAMPLES),


include: "rules/01_download.smk"
include: "rules/02_pre_trim_qc.smk"
include: "rules/03_trim.smk"
include: "rules/04_post_trim_qc.smk"
include: "rules/05_subsample.smk"
include: "rules/06_assembly.smk"
include: "rules/07_kraken.smk"
include: "rules/08_quast.smk"
include: "rules/09_annotate.smk"
include: "rules/10_blast.smk"
include: "rules/11_amr.smk"
