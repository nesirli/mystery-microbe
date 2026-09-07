SAMPLE_ID=SRR2584863
THREADS=4

IMG_SRA=quay.io/biocontainers/sra-tools:3.4.1--2_linux_64
IMG_FASTQC=quay.io/biocontainers/fastqc:0.11.9--hdfd78af_1
IMG_MULTIQC=quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0
IMG_FASTP=quay.io/biocontainers/fastp:0.24.3--heae3180_0
IMG_SEQKIT=quay.io/biocontainers/seqkit:2.8.2--h9ee0642_0
IMG_SPADES=quay.io/biocontainers/spades:4.3.0--hde4eca7_1
IMG_QUAST=quay.io/biocontainers/quast:5.2.0--py312pl5321hc60241a_4
IMG_PROKKA=quay.io/biocontainers/prokka:1.14.6--pl5321hdfd78af_5
IMG_PY=quay.io/biocontainers/biopython:1.84

RUN=docker run --rm -v /etc/ssl:/etc/ssl:ro -v $(CURDIR):/work -w /work

# The quay.io biocontainer is only published for linux/amd64 and crashes
SPADES_CMD=spades.py

.PHONY: all setup setup-test pull download qc trim subsample blast clean

all: setup download pre_trim_qc trim post_trim_qc subsample assembly

setup: pull
	mkdir -p data/raw results/{01_qc,02_trimmed,03_subsampled,04_assembly,05_blast,06_annotation,07_amr} scripts
	@echo "Setup complete"

pull:
	docker pull $(IMG_SRA)
	docker pull $(IMG_FASTQC)
	docker pull $(IMG_FASTP)
	docker pull $(IMG_SEQKIT)
	docker pull $(IMG_SPADES)
	docker pull $(IMG_PY)
	@echo "Pull complete"

setup-test: pull
	$(RUN) --entrypoint fasterq-dump $(IMG_SRA) --version
	$(RUN) --entrypoint fastqc $(IMG_FASTQC) --version
	$(RUN) --entrypoint fastp $(IMG_FASTP) --version
	$(RUN) --entrypoint seqkit $(IMG_SEQKIT) version
	$(RUN) --entrypoint spades.py $(IMG_SPADES) --version
	$(RUN) --entrypoint python3 $(IMG_PY) -c "import Bio; print(Bio.__version__)"
	@echo "Setup test complete"

data/raw/$(SAMPLE_ID)_1.fastq.gz data/raw/$(SAMPLE_ID)_2.fastq.gz:
	$(RUN) --entrypoint fasterq-dump $(IMG_SRA) $(SAMPLE_ID) --split-files --threads $(THREADS) -O /work/data/raw
	gzip -f data/raw/$(SAMPLE_ID)_1.fastq data/raw/$(SAMPLE_ID)_2.fastq

download: data/raw/$(SAMPLE_ID)_1.fastq.gz data/raw/$(SAMPLE_ID)_2.fastq.gz
	@echo "Download complete"

pre_trim_qc: download
	$(RUN) $(IMG_FASTQC) fastqc \
		data/raw/$(SAMPLE_ID)_1.fastq.gz \
		data/raw/$(SAMPLE_ID)_2.fastq.gz \
		-o results/01_qc \
		-t $(THREADS)
	$(RUN) $(IMG_MULTIQC) multiqc results/01_qc -o results/01_qc/pre_trim_multiqc_report
	rm -f results/01_qc/*_fastqc*
	@echo "QC complete"

trim: download
	$(RUN) $(IMG_FASTP) fastp -w $(THREADS) \
		-i data/raw/$(SAMPLE_ID)_1.fastq.gz -I data/raw/$(SAMPLE_ID)_2.fastq.gz \
		-o results/02_trimmed/$(SAMPLE_ID)_1.trim.fastq.gz -O results/02_trimmed/$(SAMPLE_ID)_2.trim.fastq.gz \
		--qualified_quality_phred 20 \
 		--length_required 100 \
		--detect_adapter_for_pe \
		-h results/02_trimmed/fastp.html -j results/02_trimmed/fastp.json
	@echo "Trimming complete"

post_trim_qc: trim
	$(RUN) $(IMG_FASTQC) fastqc \
		results/02_trimmed/$(SAMPLE_ID)_1.trim.fastq.gz \
		results/02_trimmed/$(SAMPLE_ID)_2.trim.fastq.gz \
		-o results/01_qc \
		-t $(THREADS)
	$(RUN) $(IMG_MULTIQC) multiqc results/01_qc -o results/01_qc/post_trim_multiqc_report
	rm -f results/01_qc/*_fastqc*

subsample: trim
	$(RUN) $(IMG_SEQKIT) seqkit sample -p 0.3 -s 42 \
		results/02_trimmed/$(SAMPLE_ID)_1.trim.fastq.gz \
		-o results/03_subsampled/$(SAMPLE_ID)_1.subsampled.fastq.gz
	$(RUN) $(IMG_SEQKIT) seqkit sample -p 0.3 -s 42 \
		results/02_trimmed/$(SAMPLE_ID)_2.trim.fastq.gz \
		-o results/03_subsampled/$(SAMPLE_ID)_2.subsampled.fastq.gz
	@echo "Subsampling complete"

assembly: subsample
	$(SPADES_CMD) -t $(THREADS) \
		--isolate \
		-k 21,33,55 \
		--pe1-1 results/03_subsampled/$(SAMPLE_ID)_1.subsampled.fastq.gz \
		--pe1-2 results/03_subsampled/$(SAMPLE_ID)_2.subsampled.fastq.gz \
		-o results/04_assembly/$(SAMPLE_ID)
	mv results/04_assembly/$(SAMPLE_ID)/contigs.fasta results/04_assembly/$(SAMPLE_ID)_assembled.fasta
	rm -rf results/04_assembly/$(SAMPLE_ID)
	@echo "Assembly complete"

blast:
	uv run scripts/01_blast.py \
	--filename results/04_assembly/$(SAMPLE_ID)_assembled.fasta
	@echo "BLAST complete"