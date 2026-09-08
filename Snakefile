# Load the configuration file
configfile: "config.yaml"

# Access the variables
RAW_DIR = config["directories"]["raw"]
QC_DIR = config["directories"]["qc"]
TRIM_DIR = config["directories"]["trimmed"]
SUBSAMPLE_DIR = config["directories"]["subsampled"]
ASSEMBLY_DIR = config["directories"]["assembly"]
BLAST_DIR = config["directories"]["blast"]
ANNOTATION_DIR = config["directories"]["annotation"]
AMR_DIR = config["directories"]["amr"]

SAMPLES = config["samples"]

rule all:
	input:
		expand(f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz", sample=SAMPLES),
		f"{QC_DIR}/pre_trim/multiqc_report.html"

rule download:
	output: 
		r1 = f"{RAW_DIR}/{{sample}}_1.fastq.gz",
		r2 = f"{RAW_DIR}/{{sample}}_2.fastq.gz"
	log: "logs/download/{sample}.log"
	threads: config["params"]["download_threads"]
	conda: "envs/env.yaml"
	shell:
		"""
		fasterq-dump {wildcards.sample} --split-files --threads {threads} --outdir data/raw > {log} 2>&1
		gzip {RAW_DIR}/{wildcards.sample}_1.fastq >> {log} 2>&1
		gzip {RAW_DIR}/{wildcards.sample}_2.fastq >> {log} 2>&1
		"""
		
rule pre_trim_qc:
	input:
		r1 = f"{RAW_DIR}/{{sample}}_1.fastq.gz",
		r2 = f"{RAW_DIR}/{{sample}}_2.fastq.gz"
	output:
		html1 = f"{QC_DIR}/pre_trim/{{sample}}_1_fastqc.html",
		html2 = f"{QC_DIR}/pre_trim/{{sample}}_2_fastqc.html"
	log:
		"logs/qc/pre_trim/{sample}.log"
	threads: config["params"]["fastqc_threads"]
	conda: "envs/env.yaml"
	shell:
		"""
		mkdir -p {QC_DIR}/pre_trim
		fastqc {input.r1} {input.r2} -o {QC_DIR}/pre_trim -t {threads} > {log} 2>&1
		"""

rule pre_trim_multi_qc:
	input:
		html1 = expand(f"{QC_DIR}/pre_trim/{{sample}}_1_fastqc.html", sample=SAMPLES),
		html2 = expand(f"{QC_DIR}/pre_trim/{{sample}}_2_fastqc.html", sample=SAMPLES)
	output:
		"results/01_qc/pre_trim/multiqc_report.html"
	log:
		"logs/qc/pre_trim/pre_trim_multiqc_report.log"
	threads: config["params"]["fastqc_threads"]
	conda: "envs/env.yaml"
	shell:
		"""
		multiqc {QC_DIR}/pre_trim/ -o {QC_DIR}/pre_trim/ > {log} 2>&1
		"""

rule trim:
	input:
		r1 = f"{RAW_DIR}/{{sample}}_1.fastq.gz",
		r2 = f"{RAW_DIR}/{{sample}}_2.fastq.gz"
	output:
		t1 = f"{TRIM_DIR}/{{sample}}_1_trimmed.fastq.gz",
		t2 = f"{TRIM_DIR}/{{sample}}_2_trimmed.fastq.gz",
		html = f"{TRIM_DIR}/{{sample}}_fastp.html",
		json = f"{TRIM_DIR}/{{sample}}_fastp.json"
	log: "logs/trim/{sample}.log"
	threads: config["params"]["trim_threads"]
	conda: "envs/env.yaml"
	params:
		phred_cutoff = config["params"]["phred_cutoff"],
		min_length = config["params"]["min_length"]
	shell:
		"""
		fastp -w {threads} \
		-i {input.r1} -I {input.r2} \
		-o {output.t1} -O {output.t2} \
		--qualified_quality_phred {params.phred_cutoff} \
 		--length_required {params.min_length} \
		--detect_adapter_for_pe \
		-h {output.html} -j {output.json} > {log} 2>&1
		"""

# rule post_trim_qc:
	# input:
	# output:
	# log:
	# threads:
	# conda:
	# shell:

# rule subsample:
	# input:
	# output:
	# log:
	# threads:
	# conda:
	# shell:

# rule assembly:
	# input:
	# output:
	# log:
	# threads:
	# conda:
	# shell:

# rule blast:
	# input:
	# output:
	# log:
	# threads:
	# conda:
	# shell:

# rule annotation:
	# input:
	# output:
	# log:
	# threads:
	# conda:
	# shell:

# rule amr:
	# input:
	# output:
	# log:
	# threads:
	# conda:
	# shell: