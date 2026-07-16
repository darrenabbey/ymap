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

alleleRatiosFid = fopen(fullfile(projectDir, ['allele_ratios.' project_  '.bed']), 'w');
if (alleleRatiosFid == -1)
	printf('[***] openAlleleRatiosTrack.m: Not a valid filename, skipping.');
else
	fprintf(alleleRatiosFid, ['track name=' project_ 'AlleleRatios description="' project_ ' allele ratios" useScore=0 itemRGB=On\n']);
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			chromName = chrom_name{chrom};
			for chrom_bin_SNP = 1:ceil(chrom_size(chrom)/bases_per_bin_SNP)
				%
				% Determining colors for each SNP coordinate from calculated cutoffs.
				%
				allelic_ratios                                          = [chrom_SNPdata{chrom,1}{chrom_bin_SNP} chrom_SNPdata{chrom,2}{chrom_bin_SNP}];
				coordinates                                             = [chrom_SNPdata{chrom,3}{chrom_bin_SNP} chrom_SNPdata{chrom,4}{chrom_bin_SNP}];

				if (sizeof(chrom_SNPdata{chrom,5}{chrom_bin_SNP}) == 0)
					phased_alleles = '';
				else
					phased_alleles = chrom_SNPdata{chrom,5}{chrom_bin_SNP};
				end;
				if (sizeof(chrom_SNPdata{chrom,6}{chrom_bin_SNP}) == 0)
					unphased_alleles = '';
				else
					unphased_alleles = chrom_SNPdata{chrom,6}{chrom_bin_SNP};
				end;
				allele_strings                                          = [phased_alleles unphased_alleles];

				if (length(allelic_ratios) > 0)
					for SNP = 1:length(allelic_ratios)
						% Load phased SNP data from earlier defined structure.
						if (isa(allelic_ratios(SNP),'cell') == 1)
							if (isscalar(allelic_ratios(SNP){1}) == 1)
								allelic_ratio           = allelic_ratios(SNP){1};
							else
								allelic_ratio           = str2num(cell2mat(allelic_ratios(SNP)));
							end;
						else
							allelic_ratio                   = allelic_ratios(SNP);
						end;

						if (isa(coordinates(SNP),'cell') == 1)
							if (isscalar(coordinates(SNP){1}) == 1)
								coordinate              = coordinates(SNP){1};
							else
								coordinate              = str2num(cell2mat(coordinates(SNP)));
							end;
						else
							coordinate                      = coordinates(SNP);
						end;

						if (isa(allele_strings,'cell') == 1)
							if (length(allelic_ratios) > 1)
								allele_string           = allele_strings{SNP};
							else
								allele_string           = allele_strings;
							end;
						else
							allele_string                   = allele_strings;
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
							writeAlleleRatioLine(alleleRatiosFid, chromName, coordinate, homologA, homologB, colorList);
						end
					end;
				end;
			end;

			%
			% Average colors of SNPs found in bin.
			%
			fprintf('\t|\tDetermine average color for SNPs in chromosome bin.\n');
			for chrom_bin_SNP = 1:ceil(chrom_size(chrom)/bases_per_bin_SNP)
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
