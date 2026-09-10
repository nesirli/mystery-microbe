rule kraken_download:
    output:
        db=f"{KRAKEN2_DB_DIR}/hash.k2d",
    log:
        "logs/assembly/kraken/db_download.log",
    conda:
        "../envs/kraken2.yaml"
    shell:
        """
        exec >{log} 2>&1
        # Create the database directory if it doesn't exist
        mkdir -p {KRAKEN2_DB_DIR}

        # Download directly into the target directory
        curl -L -o {KRAKEN2_DB_DIR}/k2_standard_08gb_20250402.tar.gz \
            https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20250402.tar.gz

        # Unpack inside the target directory
        tar -xzf {KRAKEN2_DB_DIR}/k2_standard_08gb_20250402.tar.gz -C {KRAKEN2_DB_DIR}

        # Clean up the tarball
        rm {KRAKEN2_DB_DIR}/k2_standard_08gb_20250402.tar.gz
        """


rule kraken_run:
    input:
        a=f"{ASSEMBLY_DIR}/{{sample}}_assembled.fasta",
        db=f"{KRAKEN2_DB_DIR}/hash.k2d",
    output:
        report=f"{ASSEMBLY_DIR}/{{sample}}_report.txt",
    log:
        "logs/assembly/kraken/{sample}.log",
    conda:
        "../envs/kraken2.yaml"
    threads: config["params"]["kraken2_threads"]
    shell:
        """
        kraken2 --db {KRAKEN2_DB_DIR} \
            --threads {threads} \
            --report {output.report} \
            --output /dev/null \
            {input.a} >{log} 2>&1
        """
