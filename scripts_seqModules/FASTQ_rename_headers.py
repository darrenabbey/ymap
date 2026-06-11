from Bio import SeqIO
import sys

filename = sys.argv[-1]

COUNT = 0

with open(filename, "r") as r:
	for line in r:
		if line.startswith("@"):
			COUNT += 1;
			print(f'@{COUNT}');
		elif line.startswith("+"):
			print(f'+{COUNT}');
		else:
			print(line.rstrip());
close(filename);

