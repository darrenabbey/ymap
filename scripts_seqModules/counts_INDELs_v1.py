# Processing SAM/BAM files for putative SNPs.
#------------------------------------------------------------------------------------------------------------
# Generate pileup file using samtools:
#	"samtools pileup -f CaSC5314_v21.fasta my_file.bam -i > my_indels.pileup"
#	(chromosome name; coordinate; base; read count; reads; read quality)"
# Generate putative SNPs list using this script:
# 	"python counts_INDELs_v1.py my_indels.pileup > FH1_putative_INDELs_v#.txt"
#============================================================================================================

import string, sys, re;
my_file = file(sys.argv[1],'r').xreadlines();

#------------------------------------------------------------------------------------------------------------
# dump_indels(astr) removes any insertions or deletions from the read base data in the pileup.
#	'\+[0-9]+[ATCGNatcgn]+' : indicates an insertion.
#	'\-[0-9]+[ATCGNatcgn]+' : indicates a deletion.
def dump_indels(astr):
	result = "";
	i = 0;
	astr_len = len(astr);

	while i < astr_len:
		char = astr[i];

		if char == "+" or char == "-":
			# Look ahead to parse the full integer length of the indel
			start = i + 1;
			val_str = "";

			# Safe boundary check along with proper digit matching (includes '0')
			while start < astr_len and '0' <= astr[start] <= '9':
				val_str += astr[start];
				start += 1;

			if val_str:
				indel_len = int(val_str);
				# Skip past the +/- character, the digits, and the indel bases
				i = start + indel_len;
			else:
				# Fallback if a standalone +/- sign is found without digits
				i += 1;
		else:
			# Process base match, mismatch, or reference tokens
			if char in "ATGC.atgc,":
				result += char;
			i += 1;
	return result;

#------------------------------------------------------------------------------------------------------------
# dump_startend(astr) removes any marks indicating a start or end of a read segment from the read base data.
#	'\$'  : indicates the start of a read.
#	'\^.' : indicates the end of a read, with a single character describing quality of that read.
def dump_startend(astr):
	result = ""
	i = 0
	astr_len = len(astr)

	while i < astr_len:
		char = astr[i]

		if char == "^":
			# Skip the '^' token and the single mapping quality character following it.
			i += 2
		elif char == "$":
			# Skip the '$' read-end token
			i += 1
		else:
			# Keep the valid sequence character
			result += char
			i += 1
	return result;

#------------------------------------------------------------------------------------------------------------
for i in my_file:	# process pileup file line by line.
	line                      = i.strip().split('\t');
	chrom                     = line[0];				# chromosome label for locus.
	pos                       = line[1];				# coordinate for locus (in bp).
	total                     = line[3];				# total count of reads at locus.
	reads                     = line[4];
        reads_noStartEnd          = dump_startend(reads)
	# Count individual indel events by finding literal '+' and '-' characters.
	inserts   = reads_noStartEnd.count("+");
	deletions = reads_noStartEnd.count("-");

	# Only deal with loci with an INDEL.
	if inserts + deletions > 0:
		print(f"{chrom}\t{pos}\t{total}\t{inserts}\t{deletions}")
