rule annotate:
    input:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
    output:
        gff=f"{ANNOTATION_DIR}/{{sample}}.gff",
        faa=f"{ANNOTATION_DIR}/{{sample}}.faa",
    log:
        "logs/annotate/{sample}.log",
    conda:
        "../envs/prokka.yaml"
    threads: config["params"]["amr_threads"]
    shell:
        """
        prokka {input.a} \
            --outdir {ANNOTATION_DIR} \
            --force \
            --prefix {wildcards.sample} \
            --cpus {threads} >{log} 2>&1
        """
