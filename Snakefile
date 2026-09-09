# Load the configuration file
configfile: "config.yaml"


# Access the variables
RAW_DIR = config["directories"]["raw"]
QC_DIR = config["directories"]["qc"]
TRIM_DIR = config["directories"]["trimmed"]
SUBSAMPLE_DIR = config["directories"]["subsampled"]
ASSEMBLY_DIR = config["directories"]["assembly"]
BLAST_DIR = config["directories"]["blast"]
ANNOTATION_DIR = config["directories"]["annotation"]
AMR_DIR = config["directories"]["amr"]

SAMPLES = config["samples"]


rule all:
    input:
        expand(f"{ANNOTATION_DIR}/{{sample}}.gff", sample=SAMPLES),
        f"{QC_DIR}/pre_trim/multiqc_report.html",
        f"{QC_DIR}/post_trim/multiqc_report.html",


rule download:
    output:
        r1=f"{RAW_DIR}/{{sample}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{sample}}_2.fastq.gz",
    log:
        "logs/download/{sample}.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["download_threads"]
    shell:
        """
        fasterq-dump {wildcards.sample} --split-files --threads {threads} --outdir data/raw >{log} 2>&1
        gzip {RAW_DIR}/{wildcards.sample}_1.fastq >>{log} 2>&1
        gzip {RAW_DIR}/{wildcards.sample}_2.fastq >>{log} 2>&1
        """


rule pre_trim_qc:
    input:
        r1=f"{RAW_DIR}/{{sample}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{sample}}_2.fastq.gz",
    output:
        html1=f"{QC_DIR}/pre_trim/{{sample}}_1_fastqc.html",
        html2=f"{QC_DIR}/pre_trim/{{sample}}_2_fastqc.html",
    log:
        "logs/qc/pre_trim/{sample}.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        mkdir -p {QC_DIR}/pre_trim
        fastqc {input.r1} {input.r2} -o {QC_DIR}/pre_trim -t {threads} >{log} 2>&1
        """


rule pre_trim_multi_qc:
    input:
        html1=expand(f"{QC_DIR}/pre_trim/{{sample}}_1_fastqc.html", sample=SAMPLES),
        html2=expand(f"{QC_DIR}/pre_trim/{{sample}}_2_fastqc.html", sample=SAMPLES),
    output:
        "results/01_qc/pre_trim/multiqc_report.html",
    log:
        "logs/qc/pre_trim/pre_trim_multiqc_report.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        multiqc {QC_DIR}/pre_trim/ -o {QC_DIR}/pre_trim/ >{log} 2>&1
        """


rule trim:
    input:
        r1=f"{RAW_DIR}/{{sample}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{sample}}_2.fastq.gz",
        report="results/01_qc/pre_trim/multiqc_report.html"
    output:
        t1=f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
        t2=f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
        html=f"{TRIM_DIR}/{{sample}}_fastp.html",
        json=f"{TRIM_DIR}/{{sample}}_fastp.json",
    log:
        "logs/trim/{sample}.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["trim_threads"]
    params:
        phred_cutoff=config["params"]["phred_cutoff"],
        min_length=config["params"]["min_length"],
    shell:
        """
        fastp -w {threads} \
            -i {input.r1} -I {input.r2} \
            -o {output.t1} -O {output.t2} \
            --qualified_quality_phred {params.phred_cutoff} \
            --length_required {params.min_length} \
            --detect_adapter_for_pe \
            -h {output.html} -j {output.json} >{log} 2>&1
        """


rule post_trim_qc:
    input:
        t1=f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
        t2=f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
    output:
        html1=f"{QC_DIR}/post_trim/{{sample}}_1_fastqc.html",
        html2=f"{QC_DIR}/post_trim/{{sample}}_2_fastqc.html",
    log:
        "logs/qc/post_trim/{sample}.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        fastqc {input.t1} {input.t2} -o "{QC_DIR}/post_trim" -t {threads}
        """


rule post_trim_multi_qc:
    input:
        html1=expand(f"{QC_DIR}/post_trim/{{sample}}_1_fastqc.html", sample=SAMPLES),
        html2=expand(f"{QC_DIR}/post_trim/{{sample}}_2_fastqc.html", sample=SAMPLES),
    output:
        report=f"{QC_DIR}/post_trim/multiqc_report.html",
    log:
        "logs/qc/post_trim/post_trim_multiqc_report.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        multiqc {QC_DIR}/post_trim/ \
            -n multiqc_report.html \
            -o {QC_DIR}/post_trim/ \
            -f >{log} 2>&1
        """


rule subsample:
    input:
        t1=f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
        t2=f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
        report=f"{QC_DIR}/post_trim/multiqc_report.html"
    output:
        s1=f"{SUBSAMPLE_DIR}/{{sample}}_1.subsampled.fastq.gz",
        s2=f"{SUBSAMPLE_DIR}/{{sample}}_2.subsampled.fastq.gz",
    log:
        "logs/subsample/{sample}.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["subsample_threads"]
    shell:
        """
        # Note: SeqKit requires careful handling for paired-end data.
        # A safer tool for paired fastq subsampling is seqtk, or using seqkit with two-pass pairing.
        # Assuming SeqKit, we must ensure threads are utilized and outputs match:

        seqkit sample -p 0.3 -s 42 -j {threads} {input.t1} -o {output.s1} >{log} 2>&1
        seqkit sample -p 0.3 -s 42 -j {threads} {input.t2} -o {output.s2} >>{log} 2>&1
        """


rule assembly:
    input:
        s1=f"{SUBSAMPLE_DIR}/{{sample}}_1.subsampled.fastq.gz",
        s2=f"{SUBSAMPLE_DIR}/{{sample}}_2.subsampled.fastq.gz",
    output:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
    log:
        "logs/assembly/{sample}.log",
    conda:
        "envs/env.yaml"
    threads: config["params"]["assembly_threads"]
    shell:
        """
        spades.py -t {threads} \
            --isolate \
            -k 21,33,55 \
            --pe1-1 {input.s1} \
            --pe1-2 {input.s2} \
            -o "{ASSEMBLY_DIR}/{wildcards.sample}_spades_tmp" >{log} 2>&1
        mv "{ASSEMBLY_DIR}/{wildcards.sample}_spades_tmp/contigs.fasta" "{output.a}"
        rm -rf "{ASSEMBLY_DIR}/{wildcards.sample}_spades_tmp"
        """


rule annotate:
    input:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
    output:
        gff=f"{ANNOTATION_DIR}/{{sample}}.gff",
        faa=f"{ANNOTATION_DIR}/{{sample}}.faa",
    log:
        "logs/annotate/{sample}.log",
    conda:
        "envs/prokka.yaml"
    threads: config["params"]["amr_threads"]
    shell:
        """
        prokka {input.a} \
            --outdir {ANNOTATION_DIR} \
            --prefix {wildcards.sample} \
            --cpus {threads} >{log} 2>&1
        """


# rule blast:
# input:
# output:
# log:
# threads:
# conda:
# shell:

# rule amr:
# input:
# output:
# log:
# threads:
# conda:
# shell:
