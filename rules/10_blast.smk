rule barrnap:
    input:
        assembly=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
    output:
        gff=f"{BLAST_DIR}/{{sample}}_rrna.gff",
    log:
        "logs/blast/{sample}_barrnap.log",
    conda:
        "../envs/barrnap.yaml"
    threads: config["params"]["barrnap_threads"]
    shell:
        """
        barrnap \
            --kingdom bac \
            --threads {threads} \
            --quiet \
            {input.assembly} >{output.gff} 2>{log}
        """


rule extract_16s:
    input:
        assembly=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
        gff=f"{BLAST_DIR}/{{sample}}_rrna.gff",
    output:
        gff=f"{BLAST_DIR}/{{sample}}_16S.gff",
        fasta=f"{BLAST_DIR}/{{sample}}_16S_rRNA.fasta",
    log:
        "logs/blast/{sample}_extract_16s.log",
    conda:
        "../envs/bedtools.yaml"
    shell:
        """
        awk -F'\\t' '$9 ~ /Name=16S_rRNA/' {input.gff} >{output.gff} 2>{log}

        rm -f {input.a}.fai 2>>{log}

        bedtools getfasta \
            -fi {input.assembly} \
            -bed {output.gff} \
            -fo {output.fasta} \
            -name >>{log} 2>&1

        if [ ! -s {output.fasta} ]; then
            echo "ERROR: No 16S rRNA genes found for {wildcards.sample}." >>{log}
            exit 1
        fi
        """


rule download_16s_db:
    output:
        done=touch(f"{BLAST_DB_DIR}/16S_ribosomal_RNA.done"),
    log:
        "logs/download_16s_db/download.log",
    conda:
        "../envs/blast.yaml"
    params:
        db_dir=BLAST_DB_DIR,
        db_name="16S_ribosomal_RNA",
    shell:
        """
        # Ensure the target directory exists
        mkdir -p {params.db_dir} 2>{log}

        # update_blastdb.pl is automatically included in your blast conda environment.
        # We run it inside a subshell `(cd ...)` so the path to {log} remains valid.
        (cd {params.db_dir} && update_blastdb.pl --decompress {params.db_name}) >>{log} 2>&1
        """


rule blastn_16s:
    input:
        fasta=f"{BLAST_DIR}/{{sample}}_16S_rRNA.fasta",
        db_done=f"{BLAST_DB_DIR}/16S_ribosomal_RNA.done",
    output:
        tsv=f"{BLAST_DIR}/{{sample}}_16S_blastn.tsv",
    log:
        "logs/blastn_16s/{sample}.log",
    conda:
        "../envs/blast.yaml"
    params:
        db=config["params"]["blast_db"],
    shell:
        """
        blastn \
            -db {params.db} \
            -query {input.fasta} \
            -out {output.tsv} \
            -outfmt '6 qseqid sseqid pident length evalue bitscore stitle' \
            -max_target_seqs 5 \
            -evalue 1e-10 2>{log}

        echo "Top 16S rRNA BLAST hits for {wildcards.sample}" >>{log}
        echo "--------------------------------------------------------------------------------" >>{log}
        awk -F'\\t' 'BEGIN {{printf "%-40s %6s %12s %s\\n", "Query", "%ID", "E-value", "Top hit"}} \
            {{printf "%-40s %6.1f %12s %s\\n", $1, $3, $5, $7}}' {output.tsv} >>{log}
        """
