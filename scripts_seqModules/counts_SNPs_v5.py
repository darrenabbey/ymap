# Processing SAM/BAM files for putative SNPs.
#------------------------------------------------------------------------------------------------------------
# Generate pileup file using samtools:
#	"samtools pileup -f genome.fasta my_file.bam | awk '{print $1 " " $2 " " $3 " " $4 " " $5}' > output_file.pileup"
# Generate putative SNPs list using this script:
# 	"python counts_SNPs_v3.py FH1.pileup > FH1_putative_SNPs_v#.txt"
#============================================================================================================

import string, sys, re

# python 2 : my_file = file(sys.argv[1],'r').xreadlines()
# python 3
my_file = open(sys.argv[1]);


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
	line                              = i.strip().split();
	if not line or len(line) < 4:
		continue;
	chrom                             = line[0];				# chromosome label for locus.
	pos                               = line[1];				# coordinate for locus (in bp).
	ref_base                          = line[2].upper();			# reference base at this locus.
	total                             = line[3];				# total count of reads at locus.
	if (len(line) > 4):
		reads                     = line[4];				# string defining locus
		reads_noStartEnd          = dump_startend(reads);		# locus string without indels.
		reads_noIndels_noStartEnd = dump_indels(reads_noStartEnd);	# locus string without indels or end/start/quality.
		A                         = reads_noIndels_noStartEnd.count("A") + reads_noIndels_noStartEnd.count("a");
		T                         = reads_noIndels_noStartEnd.count("T") + reads_noIndels_noStartEnd.count("t");
		G                         = reads_noIndels_noStartEnd.count("G") + reads_noIndels_noStartEnd.count("g");
		C                         = reads_noIndels_noStartEnd.count("C") + reads_noIndels_noStartEnd.count("c");
		ref_count                 = reads_noIndels_noStartEnd.count(".") + reads_noIndels_noStartEnd.count(",");
	else:
		A = T = G = C = ref_count = 0;

	#print chrom + '\t' + pos + '\t' + ref_base + '\t' + str(A) + '\t' + str(T) + '\t' +  str(G) + '\t' +  str(C) + '\t' +  str(ref_count)
	# Adds reference base count to appropriate counter.
	# Without this, the apparent reads would only account for variations from reference, not the
	#    reference itself.   "...,...,,,...T.." would be interpreted as a single base (T) seen, instead of
	#    two (T and ref).
	# if samtools output does not contain '.,' characters for matching to reference, then ref_base = 'N'
	#    and no correction is needed for previous 'ATCG' counts.
	if ref_base == "A":
		A += ref_count;
	elif ref_base == "T":
		T += ref_count;
	elif ref_base == "C":
		C += ref_count;
	elif ref_base == "G":
		G += ref_count;

	# boolean interpretation of alternate bases from reference present in reads for locus.
	# isA+isT+isG+isC > 1 when more than one base is seen at this locus.
	isA = 1 if A > 0 else 0
	isT = 1 if T > 0 else 0
	isG = 1 if G > 0 else 0
	isC = 1 if C > 0 else 0

	if isA+isT+isG+isC > 1:		# Only deal with loci where more than one base is seen.
		print(f"{chrom}\t{pos}\t{ref_base}\t{A}\t{T}\t{G}\t{C}")
