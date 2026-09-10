rule assembly:
    input:
        s1=f"{SUBSAMPLE_DIR}/{{sample}}_1.subsampled.fastq.gz",
        s2=f"{SUBSAMPLE_DIR}/{{sample}}_2.subsampled.fastq.gz",
    output:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
    log:
        "logs/assembly/{sample}.log",
    conda:
        "../envs/spades.yaml"
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
