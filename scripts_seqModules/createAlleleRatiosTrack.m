fprintf(['[***] openAlleleRatiosTrack.m\n']);
fprintf(['[***]\tprojectDir   = ' projectDir '\n']);
fprintf(['[***]\tproject  = ' project    '\n']);

if (isempty(strfind(project,'/')))
	project_ = project;
else
	idx = strfind(project,'/');
	project_ = substr(project,idx+1);
end
fprintf(['[***]\tproject_  = ' project_ '\n']);
fprintf('[***]');
fprintf('[***]\t Score is calculated as allelic ratio (0.0 ... 1.0) scaled to standard BED score range (0 .. 1000).');

alleleRatiosFid = fopen(fullfile(projectDir, ['allele_ratios.' project_  '.bed']), 'w');
if (alleleRatiosFid == -1)
	printf('[***] openAlleleRatiosTrack.m: Not a valid filename, skipping.');
else
	fprintf(alleleRatiosFid, '#=================================================================================================================================\n');
	fprintf(alleleRatiosFid, '# BED file produced by YMAP (Yeast Mapping Analysis Pipeline).\n');
	fprintf(alleleRatiosFid, '#---------------------------------------------------------------------------------------------------------------------------------\n');
	fprintf(alleleRatiosFid, '# This file contains SNP alleles and their ratios found during dataset analysis.\n');
	fprintf(alleleRatiosFid, '#     Field 1, the "chrom" field of the BED format, contains the chromosome/contig name from the genome installed in YMAP.\n');
	fprintf(alleleRatiosFid, '#     Fields 2 & 3, the "chromStart" and "chromEnd" fields of the BED format, contain the base-pair coordinate of the SNP.\n');
	fprintf(alleleRatiosFid, '#     Field 4, the "name" field of the BED format, contains a string describing the SNP alleles found at this locus.\n');
	fprintf(alleleRatiosFid, '#     Field 5, the "score" field of the BED format, contains the allelic ratio [0..1] scaled to the the range of [0..1000],\n');
	fprintf(alleleRatiosFid, '#         where a 0.0 (0) represents the first allele, and a 1.0 (1000) represents the second allele. Intermediate values\n');
	fprintf(alleleRatiosFid, '#         are caused by a combination of the true ratio between the alleles present, and by sequencing noise.\n');
	fprintf(alleleRatiosFid, '#     Field 6, the "strand" field of the BED format, is arbitrarily set to "+".\n');
	fprintf(alleleRatiosFid, '#     Fields 7 & 8, the "thickStart" and "thickEnd" fields of the BED format, also contain the base-pair coordinate of the SNP.\n');
	fprintf(alleleRatiosFid, '#     Field 9, the "itemRGB" field of the BED format, contains the RGB values of the color assigned to the SNP in the YMAP\n');
	fprintf(alleleRatiosFid, '#          visualization. This color is assigned by which Gaussian of a multi-Gaussian fit curve the SNP is identified as.\n');
	fprintf(alleleRatiosFid, '#     Fields 10, 11, & 12 of the BED format are not used.\n');
	fprintf(alleleRatiosFid, '#\n');
	fprintf(alleleRatiosFid, '# Though the BED file format was not exactly designed for this purpose, this file should load normally as a BED file.\n');
	fprintf(alleleRatiosFid, '#---------------------------------------------------------------------------------------------------------------------------------\n');
	fprintf(alleleRatiosFid, ['track name=' project_ 'AlleleRatios description="' project_ ' allele ratios" useScore=0 itemRGB=On\n']);
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			num_bins_allocated = length(chrom_SNPdata{chrom,1});

			for chrom_bin_SNP = 1:num_bins_allocated
				%%================================================================
				% Determining colors for each SNP coordinate from calculated cutoffs.
				%-----------------------------------------------------------------
				allelic_ratios = [chrom_SNPdata{chrom,1}{chrom_bin_SNP} chrom_SNPdata{chrom,2}{chrom_bin_SNP}];
				coordinates    = [chrom_SNPdata{chrom,3}{chrom_bin_SNP} chrom_SNPdata{chrom,4}{chrom_bin_SNP}];

				% Right above the SNP loop: use {} instead of '' so cell concatenation never breaks
				if (isempty(chrom_SNPdata{chrom,5}{chrom_bin_SNP}))
					phased_alleles = {};
				else
					phased_alleles = chrom_SNPdata{chrom,5}{chrom_bin_SNP};
				end;
				if (isempty(chrom_SNPdata{chrom,6}{chrom_bin_SNP}))
					unphased_alleles = {};
				else
					unphased_alleles = chrom_SNPdata{chrom,6}{chrom_bin_SNP};
				end;
				allele_strings = [phased_alleles unphased_alleles];

				if (length(allelic_ratios) > 0)
					for SNP = 1:length(allelic_ratios)
						% 1. Unwrap allelic_ratio safely
						if (iscell(allelic_ratios))
							val = allelic_ratios{SNP};
						else
							val = allelic_ratios(SNP);
						end;
						if (ischar(val))
							allelic_ratio = str2double(val);
						else
							allelic_ratio = val;
						end;

						% 2. Unwrap coordinate safely
						if (iscell(coordinates))
							val = coordinates{SNP};
						else
							val = coordinates(SNP);
						end;
						if (ischar(val))
							coordinate = str2double(val);
						else
							coordinate = val;
						end;

						% 3. Unwrap allele_string safely (works for 1 SNP or many SNPs)
						if (iscell(allele_strings))
							allele_string = allele_strings{SNP};
						else
							allele_string = allele_strings;
						end;

						baseCall                                = allele_string(1);
						homologA                                = allele_string(3);
						homologB                                = allele_string(5);

						% identify the segment containing the SNP.
						segmentID                               = 0;
						for segment = 1:(length(chromCopyNum{chrom}))
							segment_start                   = chrom_breaks{chrom}(segment  )*chrom_size(chrom);
							segment_end                     = chrom_breaks{chrom}(segment+1)*chrom_size(chrom);
							if (coordinate > segment_start) && (coordinate <= segment_end)
								segmentID               = segment;
							end;
						end;

						% Load cutoffs between Gaussian fits performed earlier.
						segment_copyNum                         = round(chromCopyNum{              chrom}(segmentID));
						actual_cutoffs                          = chromSegment_actual_cutoffs{     chrom}{segmentID};
						mostLikelyGaussians                     = chromSegment_mostLikelyGaussians{chrom}{segmentID};
							% Calculate allelic ratio on range of [1..200].
						SNPratio_int                            = (allelic_ratio)*199+1;
							% Identify the allelic ratio region containing the SNP.
						cutoffs                                 = [1 actual_cutoffs 200];
						ratioRegionID                           = 0;
						for GaussianRegionID = 1:length(mostLikelyGaussians)
							cutoff_start                    = cutoffs(GaussianRegionID  );
							cutoff_end                      = cutoffs(GaussianRegionID+1);
							if (GaussianRegionID == 1)
								if (SNPratio_int >= cutoff_start) && (SNPratio_int <= cutoff_end)
									ratioRegionID   = mostLikelyGaussians(GaussianRegionID);
								end;
							else
								if (SNPratio_int > cutoff_start) && (SNPratio_int <= cutoff_end)
									ratioRegionID   = mostLikelyGaussians(GaussianRegionID);
								end;
							end;
						end;

						if (segment_copyNum <= 0);
							colorList = colorNoData;
						elseif (segment_copyNum == 1)
							% allelic fraction cutoffs: [0.50000] => [A B]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 2);            colorList = colorB;
								else                                colorList = colorA;
								end;
							else
								% ratioRegion == 1 or 2 will require the same output color depending on below conditions.
								if (useHapmap || useParent);        colorList = unphased_color_1of1;
								else                                colorList = noparent_color_1of1;
								end;
							end;
						elseif (segment_copyNum == 2)
							%   allelic fraction cutoffs: [0.25000 0.75000] => [AA AB BB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 3);            colorList = colorBB;
								elseif (ratioRegionID == 2);        colorList = colorAB;
								else                                colorList = colorAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 3);        colorList = unphased_color_2of2;
									elseif (ratioRegionID == 2);    colorList = unphased_color_1of2;
									else                            colorList = unphased_color_2of2;
									end;
								else
									if (ratioRegionID == 3);        colorList = noparent_color_2of2;
									elseif (ratioRegionID == 2);    colorList = noparent_color_1of2;
									else                            colorList = noparent_color_2of2;
									end;
								end;
							end;
						elseif (segment_copyNum == 3)
							% allelic fraction cutoffs: [0.16667 0.50000 0.83333] => [AAA AAB ABB BBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 4);            colorList = colorBBB;
								elseif (ratioRegionID == 3);        colorList = colorABB;
								elseif (ratioRegionID == 2);        colorList = colorAAB;
								else                                colorList = colorAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 4);        colorList = unphased_color_3of3;
									elseif (ratioRegionID == 3);    colorList = unphased_color_2of3;
									elseif (ratioRegionID == 2);    colorList = unphased_color_2of3;
									else                            colorList = unphased_color_3of3;
									end;
								else
									if (ratioRegionID == 4);        colorList = noparent_color_3of3;
									elseif (ratioRegionID == 3);    colorList = noparent_color_2of3;
									elseif (ratioRegionID == 2);    colorList = noparent_color_2of3;
									else                            colorList = noparent_color_3of3;
									end;
								end;
							end;
						elseif (segment_copyNum == 4)
							% allelic fraction cutoffs: [0.12500 0.37500 0.62500 0.87500] => [AAAA AAAB AABB ABBB BBBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 5);            colorList = colorBBBB;
								elseif (ratioRegionID == 4);        colorList = colorABBB;
								elseif (ratioRegionID == 3);        colorList = colorAABB;
								elseif (ratioRegionID == 2);        colorList = colorAAAB;
								else                                colorList = colorAAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 5);        colorList = unphased_color_4of4;
									elseif (ratioRegionID == 4);    colorList = unphased_color_3of4;
									elseif (ratioRegionID == 3);    colorList = unphased_color_2of4;
									elseif (ratioRegionID == 2);    colorList = unphased_color_3of4;
									else                            colorList = unphased_color_4of4;
									end;
								else
									if (ratioRegionID == 5);        colorList = noparent_color_4of4;
									elseif (ratioRegionID == 4);    colorList = noparent_color_3of4;
									elseif (ratioRegionID == 3);    colorList = noparent_color_2of4;
									elseif (ratioRegionID == 2);    colorList = noparent_color_3of4;
									else                            colorList = noparent_color_4of4;
									end;
								end;
	                                                end;
						elseif (segment_copyNum == 5)
							% allelic fraction cutoffs: [0.10000 0.30000 0.50000 0.70000 0.90000] => [AAAAA AAAAB AAABB AABBB ABBBB BBBBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 6);            colorList = colorBBBBB;
								elseif (ratioRegionID == 5);        colorList = colorABBBB;
								elseif (ratioRegionID == 4);        colorList = colorAABBB;
								elseif (ratioRegionID == 3);        colorList = colorAAABB;
								elseif (ratioRegionID == 2);        colorList = colorAAAAB;
								else                                colorList = colorAAAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 6);        colorList = unphased_color_5of5;
									elseif (ratioRegionID == 5);    colorList = unphased_color_4of5;
									elseif (ratioRegionID == 4);    colorList = unphased_color_3of5;
									elseif (ratioRegionID == 3);    colorList = unphased_color_3of5;
									elseif (ratioRegionID == 2);    colorList = unphased_color_4of5;
									else                            colorList = unphased_color_5of5;
									end;
								else
									if (ratioRegionID == 6);        colorList = noparent_color_5of5;
									elseif (ratioRegionID == 5);    colorList = noparent_color_4of5;
									elseif (ratioRegionID == 4);    colorList = noparent_color_3of5;
									elseif (ratioRegionID == 3);    colorList = noparent_color_3of5;
									elseif (ratioRegionID == 2);    colorList = noparent_color_4of5;
									else                            colorList = noparent_color_5of5;
									end;
								end;
							end;
						elseif (segment_copyNum == 6)
							% allelic fraction cutoffs: [0.08333 0.25000 0.41667 0.58333 0.75000 0.91667] => [AAAAAA AAAAAB AAAABB AAABBB AABBBB ABBBBB BBBBBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 7);            colorList = colorBBBBBB;
								elseif (ratioRegionID == 6);        colorList = colorABBBBB;
								elseif (ratioRegionID == 5);        colorList = colorAABBBB;
								elseif (ratioRegionID == 4);        colorList = colorAAABBB;
								elseif (ratioRegionID == 3);        colorList = colorAAAABB;
								elseif (ratioRegionID == 2);        colorList = colorAAAAAB;
								else                                colorList = colorAAAAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 7);        colorList = unphased_color_6of6;
									elseif (ratioRegionID == 6);    colorList = unphased_color_5of6;
									elseif (ratioRegionID == 5);    colorList = unphased_color_4of6;
									elseif (ratioRegionID == 4);    colorList = unphased_color_3of6;
									elseif (ratioRegionID == 3);    colorList = unphased_color_4of6;
									elseif (ratioRegionID == 2);    colorList = unphased_color_5of6;
									else                            colorList = unphased_color_6of6;
									end;
								else
									if (ratioRegionID == 7);        colorList = noparent_color_6of6;
									elseif (ratioRegionID == 6);    colorList = noparent_color_5of6;
									elseif (ratioRegionID == 5);    colorList = noparent_color_4of6;
									elseif (ratioRegionID == 4);    colorList = noparent_color_3of6;
									elseif (ratioRegionID == 3);    colorList = noparent_color_4of6;
									elseif (ratioRegionID == 2);    colorList = noparent_color_5of6;
									else                            colorList = noparent_color_6of6;
									end;
								end;
							end;
						elseif (segment_copyNum == 7)
							% allelic fraction cutoffs: [0.07143 0.21429 0.35714 0.50000 0.64286 0.78571 0.92857] => [AAAAAAA AAAAAAB AAAAABB AAAABBB AAABBBB AABBBBB ABBBBBB BBBBBBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 8);            colorList = colorBBBBBBB;
								elseif (ratioRegionID == 7);        colorList = colorABBBBBB;
								elseif (ratioRegionID == 6);        colorList = colorAABBBBB;
								elseif (ratioRegionID == 5);        colorList = colorAAABBBB;
								elseif (ratioRegionID == 4);        colorList = colorAAAABBB;
								elseif (ratioRegionID == 3);        colorList = colorAAAAABB;
								elseif (ratioRegionID == 2);        colorList = colorAAAAAAB;
								else                                colorList = colorAAAAAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 8);        colorList = unphased_color_7of7;
									elseif (ratioRegionID == 7);    colorList = unphased_color_6of7;
									elseif (ratioRegionID == 6);    colorList = unphased_color_5of7;
									elseif (ratioRegionID == 5);    colorList = unphased_color_4of7;
									elseif (ratioRegionID == 3);    colorList = unphased_color_4of7;
									elseif (ratioRegionID == 3);    colorList = unphased_color_5of7;
									elseif (ratioRegionID == 2);    colorList = unphased_color_6of7;
									else                            colorList = unphased_color_7of7;
									end;
								else
									if (ratioRegionID == 8);        colorList = noparent_color_7of7;
									elseif (ratioRegionID == 7);    colorList = noparent_color_6of7;
									elseif (ratioRegionID == 6);    colorList = noparent_color_5of7;
									elseif (ratioRegionID == 5);    colorList = noparent_color_4of7;
									elseif (ratioRegionID == 3);    colorList = noparent_color_4of7;
									elseif (ratioRegionID == 3);    colorList = noparent_color_5of7;
									elseif (ratioRegionID == 2);    colorList = noparent_color_6of7;
									else                            colorList = noparent_color_7of7;
									end;
								end;
							end;
						elseif (segment_copyNum == 8)
							% allelic fraction cutoffs: [0.06250 0.18750 0.31250 0.43750 0.56250 0.68750 0.81250 0.93750] => [AAAAAAAA AAAAAAAB AAAAAABB AAAAABBB AAAABBBB AAABBBBB AABBBBBB ABBBBBBB BBBBBBBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 9);            colorList = colorBBBBBBBB;
								elseif (ratioRegionID == 8);        colorList = colorABBBBBBB;
								elseif (ratioRegionID == 7);        colorList = colorAABBBBBB;
								elseif (ratioRegionID == 6);        colorList = colorAAABBBBB;
								elseif (ratioRegionID == 5);        colorList = colorAAAABBBB;
								elseif (ratioRegionID == 4);        colorList = colorAAAAABBB;
								elseif (ratioRegionID == 3);        colorList = colorAAAAAABB;
								elseif (ratioRegionID == 2);        colorList = colorAAAAAAAB;
								else                                colorList = colorAAAAAAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 9);        colorList = unphased_color_8of8;
									elseif (ratioRegionID == 8);    colorList = unphased_color_7of8;
									elseif (ratioRegionID == 7);    colorList = unphased_color_6of8;
									elseif (ratioRegionID == 6);    colorList = unphased_color_5of8;
									elseif (ratioRegionID == 5);    colorList = unphased_color_4of8;
									elseif (ratioRegionID == 4);    colorList = unphased_color_5of8;
									elseif (ratioRegionID == 3);    colorList = unphased_color_6of8;
									elseif (ratioRegionID == 2);    colorList = unphased_color_7of8;
									else                            colorList = unphased_color_8of8;
									end;
								else
									if (ratioRegionID == 9);        colorList = noparent_color_8of8;
									elseif (ratioRegionID == 8);    colorList = noparent_color_7of8;
									elseif (ratioRegionID == 7);    colorList = noparent_color_6of8;
									elseif (ratioRegionID == 6);    colorList = noparent_color_5of8;
									elseif (ratioRegionID == 5);    colorList = noparent_color_4of8;
									elseif (ratioRegionID == 4);    colorList = noparent_color_5of8;
									elseif (ratioRegionID == 3);    colorList = noparent_color_6of8;
									elseif (ratioRegionID == 2);    colorList = noparent_color_7of8;
									else                            colorList = noparent_color_8of8;
									end;
								end;
							end;
						elseif (segment_copyNum >= 9)
							% allelic fraction cutoffs: [0.05556 0.16667 0.27778 0.38889 0.50000 0.61111 0.72222 0.83333 0.94444] => [AAAAAAAAA AAAAAAAAB AAAAAAABB AAAAAABBB AAAAABBBB AAAABBBBB AAABBBBBB AABBB$
							%                                                                                                         ABBBBBBBB BBBBBBBBB]
							if ((baseCall == homologA) || (baseCall == homologB))
								if (ratioRegionID == 10);           colorList = colorBBBBBBBBB;
								elseif (ratioRegionID == 9);        colorList = colorABBBBBBBB;
								elseif (ratioRegionID == 8);        colorList = colorAABBBBBBB;
								elseif (ratioRegionID == 7);        colorList = colorAAABBBBBB;
								elseif (ratioRegionID == 6);        colorList = colorAAAABBBBB;
								elseif (ratioRegionID == 5);        colorList = colorAAAAABBBB;
								elseif (ratioRegionID == 4);        colorList = colorAAAAAABBB;
								elseif (ratioRegionID == 3);        colorList = colorAAAAAAABB;
								elseif (ratioRegionID == 2);        colorList = colorAAAAAAAAB;
								else                                colorList = colorAAAAAAAAA;
								end;
							else
								if (useHapmap || useParent)
									if (ratioRegionID == 10);       colorList = unphased_color_9of9;
									elseif (ratioRegionID == 9);    colorList = unphased_color_8of9;
									elseif (ratioRegionID == 8);    colorList = unphased_color_7of9;
									elseif (ratioRegionID == 7);    colorList = unphased_color_6of9;
									elseif (ratioRegionID == 6);    colorList = unphased_color_5of9;
									elseif (ratioRegionID == 5);    colorList = unphased_color_5of9;
									elseif (ratioRegionID == 4);    colorList = unphased_color_6of9;
									elseif (ratioRegionID == 3);    colorList = unphased_color_7of9;
									elseif (ratioRegionID == 2);    colorList = unphased_color_8of9;
									else                            colorList = unphased_color_9of9;
									end;
								else
									if (ratioRegionID == 10);       colorList = noparent_color_9of9;
									elseif (ratioRegionID == 9);    colorList = noparent_color_8of9;
									elseif (ratioRegionID == 8);    colorList = noparent_color_7of9;
									elseif (ratioRegionID == 7);    colorList = noparent_color_6of9;
									elseif (ratioRegionID == 6);    colorList = noparent_color_5of9;
									elseif (ratioRegionID == 5);    colorList = noparent_color_5of9;
									elseif (ratioRegionID == 4);    colorList = noparent_color_6of9;
									elseif (ratioRegionID == 3);    colorList = noparent_color_7of9;
									elseif (ratioRegionID == 2);    colorList = noparent_color_8of9;
									else                            colorList = noparent_color_9of9;
									end;
								end;
							end;
						end;
						% fprintf('\t|\n');
						% fprintf(['\t| chrom num         = ' num2str(chrom)  '\n']);
						% fprintf(['\t| segment_copyNum = ' num2str(segment_copyNum)  '\n']);
						% fprintf('\t|\n');
						chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP) = chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP) + colorList(1);
						chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP) = chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP) + colorList(2);
						chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP) = chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP) + colorList(3);
						chrom_SNPdata_countC{ chrom  }(chrom_bin_SNP) = chrom_SNPdata_countC{ chrom  }(chrom_bin_SNP) + 1;

						if (~all(colorList == colorNoData))
							writeAlleleRatioLine(alleleRatiosFid, chrom_name{chrom}, coordinate, homologA, homologB, colorList, allelic_ratio);
						end
					end;
				end;
			end;


			%%========================================================================
			% Average colors of SNPs found in bin.
			%-------------------------------------------------------------------------
			fprintf('\t|\tDetermine average color for SNPs in chromosome bin.\n');

			% DYNAMIC FIX; Lock the loop limit exactly to the number of bins
			% initialized in your data cell arrays to prevent out-of-bounds crashes.
			num_bins_allocated = length(chrom_SNPdata{chrom,1});
			for chrom_bin_SNP = 1:num_bins_allocated
				allelic_ratios = [chrom_SNPdata{chrom,1}{chrom_bin_SNP} chrom_SNPdata{chrom,2}{chrom_bin_SNP}];
				if (length(allelic_ratios) > 0)
					if (chrom_SNPdata_countC{chrom}(chrom_bin_SNP) > 0)
						chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP) = chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP)/chrom_SNPdata_countC{chrom}(chrom_bin_SNP);
						chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP) = chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP)/chrom_SNPdata_countC{chrom}(chrom_bin_SNP);
						chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP) = chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP)/chrom_SNPdata_countC{chrom}(chrom_bin_SNP);
					else
						chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP) = 1.0;
						chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP) = 1.0;
						chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP) = 1.0;
					end;
				else
					chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP) = 1.0;
					chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP) = 1.0;
					chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP) = 1.0;
				end;
			end;
		end;
	end;

	if (isempty(strfind(project,'/')))
		project_ = project;
	else
		idx = strfind(project,'/');
		project_ = substr(project,idx+1);
	end
	printf('[***] openAlleleRatiosTrack.m: SNP ratio track file created.');

	fclose(alleleRatiosFid);
	system(['chmod 774 ' projectDir 'allele_ratios.' project_  '.bed']);
end
