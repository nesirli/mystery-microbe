import argparse

from Bio.Blast import NCBIWWW, NCBIXML
from Bio import SeqIO

parser = argparse.ArgumentParser(description="CLI tools for BLAST using Biopython")
parser.add_argument("--filename", required=True, help="Add a file to blast")
args = parser.parse_args()

filename = args.filename

# Read first 5 sequences
records = list(SeqIO.parse(filename, "fasta"))[:5]

for record in records:
    print(f'BLASTing {record.id} ...')
    result = NCBIWWW.qblast('blastn', 'nt', str(record.seq[:100]))
    blast_records = NCBIXML.parse(result)
    blast_record = next(blast_records)

    if blast_record.alignments:
        top_hit = blast_record.alignments[0]
        print(f"  Top hit: {top_hit.title[:100]}")
        print(f"  E-value: {top_hit.hsps[0].expect}")
        print(f"  Identity: {top_hit.hsps[0].identities}/{top_hit.hsps[0].align_length}")
    print()