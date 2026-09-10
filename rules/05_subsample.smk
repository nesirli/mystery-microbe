rule subsample:
    input:
        t1=f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
        t2=f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
        report=f"{QC_DIR}/post_trim/multiqc_report.html",
    output:
        s1=f"{SUBSAMPLE_DIR}/{{sample}}_1.subsampled.fastq.gz",
        s2=f"{SUBSAMPLE_DIR}/{{sample}}_2.subsampled.fastq.gz",
    log:
        "logs/subsample/{sample}.log",
    conda:
        "../envs/seqkit.yaml"
    threads: config["params"]["subsample_threads"]
    shell:
        """
        seqkit sample -p 0.3 -s 42 -j {threads} {input.t1} -o {output.s1} >{log} 2>&1
        seqkit sample -p 0.3 -s 42 -j {threads} {input.t2} -o {output.s2} >>{log} 2>&1
        """
