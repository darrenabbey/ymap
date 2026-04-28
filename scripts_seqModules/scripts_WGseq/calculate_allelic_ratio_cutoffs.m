%%===========================================================================================
%% Calculate allelic fraction cutoffs.
%%-------------------------------------------------------------------------------------------
%% Initialize vectors.
for chr = num_chrs
	if (chr_in_use(chr) == 1)
		for segment = 1:length(chrCopyNum{chr})
			chrSegment_peaks{              chr}{segment} = [];
			chrSegment_mostLikelyGaussians{chr}{segment} = [];
			chrSegment_Rsquared{           chr}{segment} = [];
			chrSegment_actual_cutoffs{     chr}{segment} = [];
			chrSegment_smoothed{           chr}{segment} = [];
		end;
	end;
end;

%% Initialize allelic_ratios.txt file in project directory.
filename_allelic_ratios = [workingDir '/allelic_ratios.txt'];
fid = fopen (filename_allelic_ratios, "w");
fputs (fid, "### Chromosome_name, Chromosome_segment, allelic-ratio_cutoffs\n");
fclose (fid);

%% process individual chromosome segments.
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		chr_length = chr_size(chr);
		for segment = 1:length(chrCopyNum{chr})
			histAll_a = [];
			histAll_b = [];
			histAll2  = [];
			% Look through all SNP data in every chr_bin_SNP, to determine if any are within the segment boundries.

			fprintf( '^^^\n');
			fprintf(['^^^ chrID         = ' num2str(chr)                                   '\n']);
			fprintf(['^^^ segmentID     = ' num2str(segment)                               '\n']);
			fprintf(['^^^ segment start = ' num2str(chr_breaks{chr}(segment  )*chr_length) '\n']);
			fprintf(['^^^ segment end   = ' num2str(chr_breaks{chr}(segment+1)*chr_length) '\n']);

			%% Construct and smooth a histogram of alleleic fraction data in the segment of interest.
			% phased data is stored into arrays 'histAll_a' and 'histAll_b', since proper phasing is known.
			% unphased data is stored inverted into the second array, since proper phasing is not known.
			for chr_bin_SNP = 1:length(chr_SNPdata{chr,1})
				%   1 : phased SNP ratio data.
				%   2 : unphased SNP ratio data.
				%   3 : phased SNP position data.
				%   4 : unphased SNP position data.
				ratioData_phased        = chr_SNPdata{chr,1}{chr_bin_SNP};
				ratioData_unphased      = chr_SNPdata{chr,2}{chr_bin_SNP};
				coordinateData_phased   = chr_SNPdata{chr,3}{chr_bin_SNP};
				coordinateData_unphased = chr_SNPdata{chr,4}{chr_bin_SNP};
				if (useHapmap)
					if (length(ratioData_phased) > 0)
						for SNP_in_bin = 1:length(ratioData_phased)
							%fprintf('^^^\n');
							%fprintf(['^^^ 1st type   = ' typeinfo(coordinateData_phased(SNP_in_bin))		'\n']);
							%fprintf(['^^^     length = ' num2str(length(coordinateData_phased(SNP_in_bin)))		'\n']);
							%if (strcmp( typeinfo(coordinateData_phased(SNP_in_bin)) , 'cell' ) == 1)
							%	fprintf(['^^^     value  = ' num2str(coordinateData_phased(SNP_in_bin){1})	'\n']);
							%else
							%	fprintf(['^^^     value  = ' num2str(coordinateData_phased(SNP_in_bin))		'\n']);
							%end;
							%fprintf(['^^^ 2nd type   = ' typeinfo(chr_breaks{chr}(segment)*chr_length)		'\n']);
							%fprintf(['^^^     value  = ' num2str(chr_breaks{chr}(segment)*chr_length)		'\n']);

							% if (typeinfo(coordinateData_phased(SNP_in_bin)) == 'cell')
							if (strcmp( typeinfo(coordinateData_phased(SNP_in_bin)) , 'cell' ) == 1)
								test1 = coordinateData_phased(SNP_in_bin){1};
							else
								test1 = coordinateData_phased(SNP_in_bin);
							end;

							if ( (test1 > chr_breaks{chr}(segment)*chr_length) && (test1 <= chr_breaks{chr}(segment+1)*chr_length) )
								% Ratio data is phased, so it is added twice in its proper orientation (to match density of unphased data below).
								if (isa(ratioData_phased(SNP_in_bin),'cell') == 1)
									allelic_ratio                 = str2num(cell2mat(ratioData_phased(SNP_in_bin)));
								else
									allelic_ratio                 = ratioData_phased(SNP_in_bin);
								end;
								histAll_a = [histAll_a allelic_ratio  ];
								histAll_b = [histAll_b allelic_ratio  ];
							end;
						end;
					end;
				end;
				if (length(ratioData_unphased) > 0)
					for SNP_in_bin = 1:length(ratioData_unphased)
						%fprintf(['#### SNP_in_bin                                     = ' num2str(SNP_in_bin)					'\n' ]); %dragon
						%fprintf(['####   chr                                          = ' num2str(chr)						'\n' ]);
						%fprintf(['####   segment                                      = ' num2str(segment)					'\n' ]);
						%fprintf(['####   chr_length                                   = ' num2str(chr_length)					'\n' ]);
						%fprintf(['####   chr_breaks{chr}(segment)                     = ' num2str(chr_breaks{chr}(segment))        		'\n' ]);
						%fprintf(['####   class(coordinateData_unphased(SNP_in_bin))   = ' class(coordinateData_unphased(SNP_in_bin))		'\n' ]);
						%if (isa(coordinateData_unphased(SNP_in_bin),'cell') == 1)
						%	fprintf(['####                                                  ' cell2mat(coordinateData_unphased(SNP_in_bin))	'\n' ]);
						%else
						%	fprintf(['####                                                  ' num2str(coordinateData_unphased(SNP_in_bin))	'\n' ]);
						%end;
						%fprintf(['####   class(chr_breaks{chr}(segment)*chr_length)   = ' class(chr_breaks{chr}(segment)*chr_length)		'\n' ]);
						%fprintf(['####   class(chr_breaks{chr}(segment+1)*chr_length) = ' class(chr_breaks{chr}(segment+1)*chr_length)		'\n' ]);

						if (isa(coordinateData_unphased(SNP_in_bin),'cell') == 1)
							testVal1 = str2num(cell2mat(coordinateData_unphased(SNP_in_bin)));
						else
							testVal1 = coordinateData_unphased(SNP_in_bin);
						end;

						if ( (testVal1 > chr_breaks{chr}(segment)*chr_length) && (testVal1 <= chr_breaks{chr}(segment+1)*chr_length) )
							% Ratio data is unphased, so it is added evenly in both orientations.
							if (isa(ratioData_unphased(SNP_in_bin),'cell') == 1)
								allelic_ratio = str2num(cell2mat(ratioData_unphased(SNP_in_bin)));
							else
								allelic_ratio = ratioData_unphased(SNP_in_bin);
							end;
							histAll_a = [histAll_a allelic_ratio  ];
							histAll_b = [histAll_b 1-allelic_ratio];
						end;
					end;
				end;
			end;

			% make a histogram of SNP allelic fractions in segment, then smooth for display.
			histAll                    = [histAll_a histAll_b];
			histAll(histAll == -1)     = [];

			% Invert histogram values;
			histAll                    = 1-histAll;

			% add bounds to the histogram values.
			histAll                    = [histAll 0 1];

			% generate the histogram.
			data_hist                  = hist(histAll,200);
			endPoints_hist             = hist([0 1],200);

			% remove the endpoints.
			data_hist                  = data_hist-endPoints_hist;

			% log-scale the histogram to minimize difference between hom & het peak heights.
			% average this with the raw histogram so the large peaks still appear visibily larger than the small peaks.

			data_hist                  = data_hist/2 + log(data_hist+1)/2;
			% data_hist                = log(data_hist+1);

			% smooth the histogram.
			smoothed                   = smooth_gaussian(data_hist,10,30);

			% flip the smoothed histogram left-right to make display consistent with values.
			smoothed                   = fliplr(smoothed);

			% scale the smoothed histogram to a max of 1.
			if (max(smoothed) > 0)
				smoothed           = smoothed/max(smoothed);
			end;

			%% Calculate Gaussian fitting details for segment.
			segment_copyNum            = round(chrCopyNum{chr}(segment));  % copy number estimate of this segment.

			segment_chrBreaks          = chr_breaks{chr}(segment);         % break points of this segment.
			segment_smoothedHistogram  = smoothed;                         % whole chromosome allelic ratio histogram smoothed.

			% Define cutoffs between Gaussian fits.
			descriptionString          = ['chr=' num2str(chr) '; seg=' num2str(segment)];
			makeFitFigures             = false;
			[peaks,actual_cutoffs,mostLikelyGaussians, Rsquared] = FindGaussianCutoffs_3(workingDir,descriptionString, chr,segment, segment_copyNum,segment_smoothedHistogram, makeFitFigures);

			fprintf(['^^^ copyNum             = ' num2str(segment_copyNum          ) '\n']);
			fprintf(['^^^ copyNum_raw         = ' num2str(chrCopyNum{chr}(segment) ) '\n']);
			fprintf(['^^^ peaks               = ' num2str(peaks                    ) '\n']);
			fprintf(['^^^ mostLikelyGaussians = ' num2str(mostLikelyGaussians      ) '\n']);
			fprintf(['^^^ actual_cutoffs      = ' num2str(actual_cutoffs           ) '\n']);

			chrSegment_peaks{              chr}{segment} = peaks;
			chrSegment_mostLikelyGaussians{chr}{segment} = mostLikelyGaussians;
			chrSegment_Rsquared{           chr}{segment} = Rsquared;
			chrSegment_actual_cutoffs{     chr}{segment} = actual_cutoffs;
			chrSegment_smoothed{           chr}{segment} = smoothed;

			%% Save allelic ratio cutoffs to 'allelic_ratios.txt' file.
			% chrName = chr_name{chr}
			% segment = num2str(segment);
			% cutoffs = chrSegment_actual_cutoffs{chr}{segment};
			if (length(actual_cutoffs) > 0)
				alleleic_ratio_string = [chr_name{chr} ' ' num2str(segment) ' [' num2str(actual_cutoffs(1)) ];
				if (length(actual_cutoffs) > 1)
					for ii = 2:length(actual_cutoffs)
						alleleic_ratio_string = [alleleic_ratio_string ',' num2str(actual_cutoffs(ii)) ];
					end;
				end;
				alleleic_ratio_string = [alleleic_ratio_string "]\n"];
				fid = fopen (filename_allelic_ratios, "a");
				fputs (fid, alleleic_ratio_string);
				fclose (fid);
			end;
		end;
	end;
end;
