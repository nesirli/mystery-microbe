rule post_trim_qc:
    input:
        t1=f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
        t2=f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
    output:
        html1=f"{QC_DIR}/post_trim/{{sample}}_1_trimmed_fastqc.html",
        html2=f"{QC_DIR}/post_trim/{{sample}}_2_trimmed_fastqc.html",
    log:
        "logs/qc/post_trim/{sample}.log",
    conda:
        "../envs/qc.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        fastqc {input.t1} {input.t2} -o "{QC_DIR}/post_trim" -t {threads}
        """


rule post_trim_multi_qc:
    input:
        html1=expand(
            f"{QC_DIR}/post_trim/{{sample}}_1_trimmed_fastqc.html", sample=SAMPLES
        ),
        html2=expand(
            f"{QC_DIR}/post_trim/{{sample}}_2_trimmed_fastqc.html", sample=SAMPLES
        ),
    output:
        report=f"{QC_DIR}/post_trim/multiqc_report.html",
    log:
        "logs/qc/post_trim/post_trim_multiqc_report.log",
    conda:
        "../envs/qc.yaml"
    threads: config["params"]["fastqc_threads"]
    shell:
        """
        multiqc {QC_DIR}/post_trim/ \
            -n multiqc_report.html \
            -o {QC_DIR}/post_trim/ \
            -f >{log} 2>&1
        """
