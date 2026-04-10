from Bio import SeqIO
import sys
filename = sys.argv[-1]

for r in SeqIO.parse(filename, "fasta"):
    r.letter_annotations["solexa_quality"] = [40] * len(r)
    print(r.format("fastq"), end='')
