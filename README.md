# Mistery Microbe

## Dataset
- **Accession**: SRR2584863
- **Platform**: Illumina HiSeq 2500 2×150 bp
- **Total read pairs**: [fill in]

## QC Summary
- **Reads after trimming**: [fill in]
- **% reads passing QC**: [fill in]
- **Mean quality score**: [from fastp report]
- **GC content**: [from FastQC — this is a clue!]

## Species Identification
- **Top BLAST hit**: [species name]
- **Average % identity**: [fill in]
- **Number of reads matching**: [fill in]
- **Confidence**: [High/Medium/Low]

## Conclusion
Based on BLAST analysis of [N] randomly sampled reads against NCBI nt,
the isolate is identified as [species name] with high confidence
([X]% of reads matching at >[Y]% identity).

## Tools and Versions
- FastQC: [version]
- fastp: [version]
- BLAST+: [version]
- seqkit: [version]


zcat data/raw/SRR2584863_1.fastq.gz | awk 'END{print NR/4}'
1553259

zcat data/raw/SRR2584863_2.fastq.gz | awk 'END{print NR/4}'
1553259

