function [] = writeAlleleRatioLine(alleleRatiosFid, chrName, coordinate, homologA, homologB, rgb)

fprintf(alleleRatiosFid, ...
	['%s ' ... chromosome name
	'%d ' ... SNP start
	'%d ' ... SNP end
	'[%s/%s] ' ... annotation label - allele1/allele2
	'0 ' ... score
	'+ ' ... strand
	'%d ' ... thick start
	'%d ' ... thick end
	'%d,%d,%d\n'], ... rgb
	chrName, ...
	coordinate, ...
	coordinate, ...
	homologA, ...
	homologB, ...
	coordinate, ...
	coordinate, ...
	round(rgb * 255) ...
);

end	