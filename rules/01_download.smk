rule download:
    output:
        r1=f"{RAW_DIR}/{{sample}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{sample}}_2.fastq.gz",
    log:
        "logs/download/{sample}.log",
    conda:
        "../envs/sra-tools.yaml"
    threads: config["params"]["download_threads"]
    shell:
        """
        fasterq-dump {wildcards.sample} --split-files --threads {threads} --outdir data/raw >{log} 2>&1
        gzip {RAW_DIR}/{wildcards.sample}_1.fastq >>{log} 2>&1
        gzip {RAW_DIR}/{wildcards.sample}_2.fastq >>{log} 2>&1
        """
