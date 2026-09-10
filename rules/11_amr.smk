rule amr:
    input:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
    output:
        o=f"{AMR_DIR}/{{sample}}_amr_results.tsv",
    log:
        "logs/amr/{sample}.log",
    conda:
        "../envs/abricate.yaml"
    threads: config["params"]["amr_threads"]
    shell:
        """
        abricate \
            --db card \
            --threads {threads} \
            {input.a} >{output.o} 2>{log}
        """
