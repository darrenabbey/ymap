from Bio import SeqIO
import sys
sys.modules.keys()

filename = sys.argv[-1]

for r in SeqIO.parse(filename, "fastq"):
    r.letter_annotations["solexa_quality"] = [40] * len(r)
    print(r.format("fasta"), end='')
