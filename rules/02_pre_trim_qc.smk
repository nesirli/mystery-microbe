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
        "../envs/qc.yaml"
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
        "../envs/qc.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        multiqc {QC_DIR}/pre_trim/ -o {QC_DIR}/pre_trim/ >{log} 2>&1
        """
