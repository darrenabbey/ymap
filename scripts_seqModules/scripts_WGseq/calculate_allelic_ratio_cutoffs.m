%%===========================================================================================
%% Calculate allelic fraction cutoffs.
%%-------------------------------------------------------------------------------------------
%% Initialize vectors.
for chrom = length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		for segment = 1:length(chromCopyNum{chrom})
			chromSegment_peaks{              chrom}{segment} = [];
			chromSegment_mostLikelyGaussians{chrom}{segment} = [];
			chromSegment_Rsquared{           chrom}{segment} = [];
			chromSegment_actual_cutoffs{     chrom}{segment} = [];
			chromSegment_smoothed{           chrom}{segment} = [];
		end;
	end;
end;

%% Initialize allelic_ratios.txt file in project directory.
filename_allelic_ratios = [workingDir '/allelic_ratios.txt'];
fid = fopen (filename_allelic_ratios, "w");
fputs (fid, "### chromomosome_name, chromomosome_segment, allelic-ratio_cutoffs\n");
fclose (fid);

%% process individual chromomosome segments.
chromCounter = 0;
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		chromCounter += 1;
		chrom_length = chrom_size(chrom);
		for segment = 1:length(chromCopyNum{chrom})
			histAll_a = [];
			histAll_b = [];
			histAll2  = [];
			% Look through all SNP data in every chrom_bin_SNP, to determine if any are within the segment boundries.

			fprintf( '^^^\n');
			fprintf(['^^^ chromID       = ' num2str(chrom)                                   '\n']);
			fprintf(['^^^ segmentID     = ' num2str(segment)                               '\n']);
			fprintf(['^^^ segment start = ' num2str(chrom_breaks{chrom}(segment  )*chrom_length) '\n']);
			fprintf(['^^^ segment end   = ' num2str(chrom_breaks{chrom}(segment+1)*chrom_length) '\n']);

			%% Construct and smooth a histogram of alleleic fraction data in the segment of interest.
			% phased data is stored into arrays 'histAll_a' and 'histAll_b', since proper phasing is known.
			% unphased data is stored inverted into the second array, since proper phasing is not known.
			for chrom_bin_SNP = 1:length(chrom_SNPdata{chrom,1})
				%   1 : phased SNP ratio data.
				%   2 : unphased SNP ratio data.
				%   3 : phased SNP position data.
				%   4 : unphased SNP position data.
				ratioData_phased        = chrom_SNPdata{chrom,1}{chrom_bin_SNP};
				ratioData_unphased      = chrom_SNPdata{chrom,2}{chrom_bin_SNP};
				coordinateData_phased   = chrom_SNPdata{chrom,3}{chrom_bin_SNP};
				coordinateData_unphased = chrom_SNPdata{chrom,4}{chrom_bin_SNP};
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
							%fprintf(['^^^ 2nd type   = ' typeinfo(chrom_breaks{chrom}(segment)*chrom_length)		'\n']);
							%fprintf(['^^^     value  = ' num2str(chrom_breaks{chrom}(segment)*chrom_length)		'\n']);

							% if (typeinfo(coordinateData_phased(SNP_in_bin)) == 'cell')
							if (strcmp( typeinfo(coordinateData_phased(SNP_in_bin)) , 'cell' ) == 1)
								test1 = coordinateData_phased(SNP_in_bin){1};
							else
								test1 = coordinateData_phased(SNP_in_bin);
							end;

							if ( (test1 > chrom_breaks{chrom}(segment)*chrom_length) && (test1 <= chrom_breaks{chrom}(segment+1)*chrom_length) )
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
						%fprintf(['####   chrom                                          = ' num2str(chrom)						'\n' ]);
						%fprintf(['####   segment                                      = ' num2str(segment)					'\n' ]);
						%fprintf(['####   chrom_length                                   = ' num2str(chrom_length)					'\n' ]);
						%fprintf(['####   chrom_breaks{chrom}(segment)                     = ' num2str(chrom_breaks{chrom}(segment))        		'\n' ]);
						%fprintf(['####   class(coordinateData_unphased(SNP_in_bin))   = ' class(coordinateData_unphased(SNP_in_bin))		'\n' ]);
						%if (isa(coordinateData_unphased(SNP_in_bin),'cell') == 1)
						%	fprintf(['####                                                  ' cell2mat(coordinateData_unphased(SNP_in_bin))	'\n' ]);
						%else
						%	fprintf(['####                                                  ' num2str(coordinateData_unphased(SNP_in_bin))	'\n' ]);
						%end;
						%fprintf(['####   class(chrom_breaks{chrom}(segment)*chrom_length)   = ' class(chrom_breaks{chrom}(segment)*chrom_length)		'\n' ]);
						%fprintf(['####   class(chrom_breaks{chrom}(segment+1)*chrom_length) = ' class(chrom_breaks{chrom}(segment+1)*chrom_length)		'\n' ]);

						if (isa(coordinateData_unphased(SNP_in_bin),'cell') == 1)
							testVal1 = str2num(cell2mat(coordinateData_unphased(SNP_in_bin)));
						else
							testVal1 = coordinateData_unphased(SNP_in_bin);
						end;

						if ( (testVal1 > chrom_breaks{chrom}(segment)*chrom_length) && (testVal1 <= chrom_breaks{chrom}(segment+1)*chrom_length) )
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
			segment_copyNum            = round(chromCopyNum{chrom}(segment));  % copy number estimate of this segment.

			segment_chromBreaks          = chrom_breaks{chrom}(segment);         % break points of this segment.
			segment_smoothedHistogram  = smoothed;                         % whole chromomosome allelic ratio histogram smoothed.

			% Define cutoffs between Gaussian fits.
			descriptionString          = ['chrom' num2str(chromCounter) '.' num2str(segment)];
			makeFitFigures             = true;
			[peaks,actual_cutoffs,mostLikelyGaussians, Rsquared] = FindGaussianCutoffs_3(workingDir,descriptionString, chrom,segment, segment_copyNum,segment_smoothedHistogram, makeFitFigures);

			fprintf(['^^^ copyNum             = ' num2str(segment_copyNum          ) '\n']);
			fprintf(['^^^ copyNum_raw         = ' num2str(chromCopyNum{chrom}(segment) ) '\n']);
			fprintf(['^^^ peaks               = ' num2str(peaks                    ) '\n']);
			fprintf(['^^^ mostLikelyGaussians = ' num2str(mostLikelyGaussians      ) '\n']);
			fprintf(['^^^ actual_cutoffs      = ' num2str(actual_cutoffs           ) '\n']);

			chromSegment_peaks{              chrom}{segment} = peaks;
			chromSegment_mostLikelyGaussians{chrom}{segment} = mostLikelyGaussians;
			chromSegment_Rsquared{           chrom}{segment} = Rsquared;
			chromSegment_actual_cutoffs{     chrom}{segment} = actual_cutoffs;
			chromSegment_smoothed{           chrom}{segment} = smoothed;

			%% Save allelic ratio cutoffs to 'allelic_ratios.txt' file.
			% chromName = chrom_name{chrom}
			% segment = num2str(segment);
			% cutoffs = chromSegment_actual_cutoffs{chrom}{segment};
			if (length(actual_cutoffs) > 0)
				alleleic_ratio_string = [chrom_name{chrom} ' ' num2str(segment) ' [' num2str(actual_cutoffs(1)) ];
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

