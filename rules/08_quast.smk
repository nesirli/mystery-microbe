rule quast:
    input:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
        ref=f"reference/GCA_000005845.2.fasta",
    output:
        q=f"{QUAST_DIR}/{{sample}}/report.tsv",
    log:
        "logs/assembly/quast/{sample}.log",
    conda:
        "../envs/quast.yaml"
    threads: config["params"]["quast_threads"]
    shell:
        """
        quast.py {input.a} \
            -o {QUAST_DIR}/{wildcards.sample} \
            -r {input.ref}
        """
