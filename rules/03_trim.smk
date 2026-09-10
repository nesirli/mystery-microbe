rule trim:
    input:
        r1=f"{RAW_DIR}/{{sample}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{sample}}_2.fastq.gz",
        report="results/01_qc/pre_trim/multiqc_report.html",
    output:
        t1=f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
        t2=f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
        html=f"{TRIM_DIR}/{{sample}}_fastp.html",
        json=f"{TRIM_DIR}/{{sample}}_fastp.json",
    log:
        "logs/trim/{sample}.log",
    conda:
        "../envs/fastp.yaml"
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
