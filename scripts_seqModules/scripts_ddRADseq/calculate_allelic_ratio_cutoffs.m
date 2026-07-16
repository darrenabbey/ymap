%% =========================================================================================
% Gather allelic ratio and coordinate data for SNPs into data structure.
%...........................................................................................
% if (useHapmap)
%       chrom_SNPdata{chrom,1}{chrom_bin} = phased SNP ratio data.
%       chrom_SNPdata{chrom,2}{chrom_bin} = unphased SNP ratio data.
%       chrom_SNPdata{chrom,3}{chrom_bin} = phased SNP position data.
%       chrom_SNPdata{chrom,4}{chrom_bin} = unphased SNP position data.
%       chrom_SNPdata{chrom,5}{chrom_bin} = flipper value for phased SNP.
%       chrom_SNPdata{chrom,6}{chrom_bin} = flipper value for unphased SNP.
% elseif (useParent)
%       chrom_SNPdata{chrom,1}{chrom_bin} = parent SNP ratio data.
%       chrom_SNPdata{chrom,2}{chrom_bin} = child SNP ratio data.
%       chrom_SNPdata{chrom,3}{chrom_bin} = parent SNP position data.
%       chrom_SNPdata{chrom,4}{chrom_bin} = child SNP position data.
% else
%       chrom_SNPdata{chrom,1}{chrom_bin} = SNP ratio data.
%       chrom_SNPdata{chrom,3}{chrom_bin} = SNP position data.
% end;
%-------------------------------------------------------------------------------------------
if (useHapmap)
	%       chrom_SNPdata{chrom,1}{chrom_bin} = phased SNP ratio data.
	%       chrom_SNPdata{chrom,2}{chrom_bin} = unphased SNP ratio data.
	%       chrom_SNPdata{chrom,3}{chrom_bin} = phased SNP position data.
	%       chrom_SNPdata{chrom,4}{chrom_bin} = unphased SNP position data.
	%       chrom_SNPdata{chrom,5}{chrom_bin} = flipper value for phased SNP.
	%       chrom_SNPdata{chrom,6}{chrom_bin} = flipper value for unphased SNP.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			if (length(C_chrom_SNP_data_positions{chrom}) > 1)
				%
				% Building SNP data sctructure 'chrom_SNPdata'.
				%

				for SNP = 1:length(C_chrom_SNP_data_positions{chrom})  % 'length(C_chrom_SNP_data_positions)' is the number of SNPs per chromosome.
					coordinate                      = C_chrom_SNP_data_positions{chrom}(SNP);
					pos                             = ceil(coordinate/new_bases_per_bin);
					localCopyEstimate               = round(CNVplot2{chrom}(pos)*ploidy*ploidyAdjust);
					baseCall                        = C_chrom_baseCall{          chrom}{SNP};
					homologA                        = C_chrom_SNP_homologA{      chrom}{SNP};
					homologB                        = C_chrom_SNP_homologB{      chrom}{SNP};
					flipper                         = C_chrom_SNP_flipHomologs{  chrom}(SNP);
					allelic_ratio                   = C_chrom_SNP_data_ratios{   chrom}(SNP);
					% Allelic ratio here is the ratio of the majority read call to all reads.
					% The consequence of this is that it will always be on the range [0.5 .. 1.0].
					if (flipper == 10)                         % Variable 'flipper' value of '10' indicates no phasing information is available in the hapmap.
						baseCall                = 'Z';     % Variable 'baseCall' value of 'Z' will prevent either hapmap allele from matching and so unphased ratio colors will be used in the following section.
						chrom_SNPdata{chrom,2}{pos} = [chrom_SNPdata{chrom,2}{pos} allelic_ratio 1-allelic_ratio];
						chrom_SNPdata{chrom,4}{pos} = [chrom_SNPdata{chrom,4}{pos} coordinate    coordinate     ];
						chrom_SNPdata{chrom,6}{pos} = [chrom_SNPdata{chrom,6}{pos} flipper       flipper        ];
						elseif (flipper == 1)
					temp                    = homologA;
						homologA                = homologB;
						homologB                = temp;
						if (baseCall == homologA)
							allelic_ratio = 1-allelic_ratio;
						end;
						chrom_SNPdata{chrom,1}{pos} = [chrom_SNPdata{chrom,1}{pos} allelic_ratio allelic_ratio];
						chrom_SNPdata{chrom,3}{pos} = [chrom_SNPdata{chrom,3}{pos} coordinate    coordinate   ];
						chrom_SNPdata{chrom,5}{pos} = [chrom_SNPdata{chrom,5}{pos} flipper       flipper      ];
					else % (flipper == 0)
						if (baseCall == homologA)
							allelic_ratio = 1-allelic_ratio;
						end;
						chrom_SNPdata{chrom,1}{pos} = [chrom_SNPdata{chrom,1}{pos} allelic_ratio allelic_ratio];
						chrom_SNPdata{chrom,3}{pos} = [chrom_SNPdata{chrom,3}{pos} coordinate    coordinate   ];
						chrom_SNPdata{chrom,5}{pos} = [chrom_SNPdata{chrom,5}{pos} flipper       flipper      ];
					end;
				end;
			end;
		end;
	end;
elseif (useParent)
	%       chrom_SNPdata{chrom,1}{chrom_bin} = child SNP ratio data.
	%       chrom_SNPdata{chrom,2}{chrom_bin} = parent SNP ratio data.
	%       chrom_SNPdata{chrom,3}{chrom_bin} = child SNP position data.
	%       chrom_SNPdata{chrom,4}{chrom_bin} = parent SNP position data.
	%
	% child data:  'C_chrom_SNP_data_positions','C_chrom_SNP_data_ratios','C_chrom_count'
        % parent data: 'P_chrom_SNP_data_positions','P_chrom_SNP_data_ratios','P_chrom_count'
	%
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			if (length(C_chrom_SNP_data_positions{chrom}) > 1)
				%
				% Building SNP data sctructure 'chrom_SNPdata' entries for child data.
				%

				for SNP = 1:length(C_chrom_SNP_data_positions{chrom})
					coordinate              = C_chrom_SNP_data_positions{chrom}(SNP);
					pos                     = ceil(coordinate/new_bases_per_bin);
					allelic_ratio           = C_chrom_SNP_data_ratios{   chrom}(SNP);
					allelic_ratio           = max(allelic_ratio, 1-allelic_ratio);

					% Allelic ratio here is the ratio of the majority read call to all reads.
					% The consequence of this is that it will always be on the range [0.5 .. 1.0].
					chrom_SNPdata{chrom,1}{pos} = [chrom_SNPdata{chrom,1}{pos} allelic_ratio];
					chrom_SNPdata{chrom,3}{pos} = [chrom_SNPdata{chrom,3}{pos} coordinate   ];
				end;
			end;
			if (length(P_chrom_SNP_data_positions{chrom}) > 1)
				%
				% Building SNP data sctructure 'chrom_SNPdata' entries for parent data.
				%

				for SNP = 1:length(P_chrom_SNP_data_positions{chrom})
					coordinate              = P_chrom_SNP_data_positions{chrom}(SNP);
					pos                     = ceil(coordinate/new_bases_per_bin);
					allelic_ratio           = P_chrom_SNP_data_ratios{   chrom}(SNP);
					allelic_ratio           = max(allelic_ratio, 1-allelic_ratio);

					% Allelic ratio here is the ratio of the majority read call to all reads.
					% The consequence of this is that it will always be on the range [0.5 .. 1.0].
					chrom_SNPdata{chrom,2}{pos} = [chrom_SNPdata{chrom,2}{pos} allelic_ratio];
					chrom_SNPdata{chrom,4}{pos} = [chrom_SNPdata{chrom,4}{pos} coordinate   ];
				end;
			end;
		end;
	end;
else    % useHapmap and useParent == false.
	% child == parent, so only one set of data needs to be organized.
	%       chrom_SNPdata{chrom,1}{chrom_bin} = SNP ratio data.
	%       chrom_SNPdata{chrom,3}{chrom_bin} = SNP position data.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			if (length(C_chrom_SNP_data_positions{chrom}) > 1)
				%
				% Building SNP data sctructure 'chrom_SNPdata'.
				%

				for SNP = 1:length(C_chrom_SNP_data_positions{chrom})
					coordinate              = C_chrom_SNP_data_positions{chrom}(SNP);
					pos                     = ceil(coordinate/new_bases_per_bin);
					allelic_ratio           = C_chrom_SNP_data_ratios{   chrom}(SNP);
					allelic_ratio           = max(allelic_ratio, 1-allelic_ratio);

					% Allelic ratio here is the ratio of the majority read call to all reads.
					% The consequence of this is that it will always be on the range [0.5 .. 1.0].
					chrom_SNPdata{chrom,1}{pos} = [chrom_SNPdata{chrom,1}{pos} allelic_ratio];
					chrom_SNPdata{chrom,3}{pos} = [chrom_SNPdata{chrom,3}{pos} coordinate   ];
				end;
			end;
		end;
	end;
end;


%% =========================================================================================
% Calculate allelic fraction cutoffs.
%-------------------------------------------------------------------------------------------
% Initialize 
for chrom = num_chroms
	if (chrom_in_use(chrom) == 1)
		for segment = 1:length(chromCopyNum{chrom})
			chromSegment_peaks{              chrom}{segment} = [];
			chromSegment_mostLikelyGaussians{chrom}{segment} = [];
			chromSegment_actual_cutoffs{     chrom}{segment} = [];
			chromSegment_smoothed{           chrom}{segment} = [];
		end;
	end;
end;
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		chrom_length = chrom_size(chrom);
		for segment = 1:length(chromCopyNum{chrom})
			histAll_a = [];
			histAll_b = [];
			histAll2  = [];
			% Look through all SNP data in every chrom_bin, to determine if any are within the segment boundries.
			% Speed up by only checking possible chrom_bins has not been implmented.

			fprintf( '^^^\n');
			fprintf(['^^^ chromID         = ' num2str(chrom)                                   '\n']);
			fprintf(['^^^ segmentID     = ' num2str(segment)                               '\n']);
			fprintf(['^^^ segment start = ' num2str(chrom_breaks{chrom}(segment  )*chrom_length) '\n']);
			fprintf(['^^^ segment end   = ' num2str(chrom_breaks{chrom}(segment+1)*chrom_length) '\n']);

			%% Construct and smooth a histogram of alleleic fraction data in the segment of interest.
			% phased data is stored into arrays 'histAll_a' and 'histAll_b', since proper phasing is known.
			% unphased data is stored inverted into the second array, since proper phasing is not known.
			for chrom_bin = 1:length(CNVplot2{chrom})
				%   1 : phased SNP ratio data.
				%   2 : unphased SNP ratio data.
				%   3 : phased SNP position data.
				%   4 : unphased SNP position data.
				ratioData_phased        = chrom_SNPdata{chrom,1}{chrom_bin};
				ratioData_unphased      = chrom_SNPdata{chrom,2}{chrom_bin};
				coordinateData_phased   = chrom_SNPdata{chrom,3}{chrom_bin};
				coordinateData_unphased = chrom_SNPdata{chrom,4}{chrom_bin};
				if (useHapmap)
					if (length(ratioData_phased) > 0)
						for SNP_in_bin = 1:length(ratioData_phased)
							if ((coordinateData_phased(SNP_in_bin) > chrom_breaks{chrom}(segment)*chrom_length) && (coordinateData_phased(SNP_in_bin) <= chrom_breaks{chrom}(segment+1)*chrom_length))
								% Ratio data is phased, so it is added twice in its proper orientation (to match density of unphased data below).
								allelic_ratio = ratioData_phased(SNP_in_bin);
								histAll_a = [histAll_a allelic_ratio  ];
								histAll_b = [histAll_b allelic_ratio  ];
							end;
						end;
					end;
				end;
				if (length(ratioData_unphased) > 0)
					for SNP_in_bin = 1:length(ratioData_unphased)
						if ((coordinateData_unphased(SNP_in_bin) > chrom_breaks{chrom}(segment)*chrom_length) && (coordinateData_unphased(SNP_in_bin) <= chrom_breaks{chrom}(segment+1)*chrom_length))
							% Ratio data is unphased, so it is added evenly in both orientations.
							allelic_ratio = ratioData_unphased(SNP_in_bin);
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
			
			%data_hist                  = (data_hist + log(data_hist+1))/2;
			data_hist                  = log(data_hist+1);
			

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
			segment_smoothedHistogram  = smoothed;                         % whole chromosome allelic ratio histogram smoothed.

			% Define cutoffs between Gaussian fits.
			saveName = ['allelic_ratios.chrom_' num2str(chrom) '.seg_' num2str(segment)];
			[peaks,actual_cutoffs,mostLikelyGaussians] = FindGaussianCutoffs_3(workingDir,saveName, chrom,segment, segment_copyNum,segment_smoothedHistogram, false);

			fprintf(['^^^ copyNum             = ' num2str(segment_copyNum    ) '\n']);
			fprintf(['^^^ peaks               = ' num2str(peaks              ) '\n']);
			fprintf(['^^^ mostLikelyGaussians = ' num2str(mostLikelyGaussians) '\n']);
			fprintf(['^^^ actual_cutoffs      = ' num2str(actual_cutoffs     ) '\n']);

			chromSegment_peaks{              chrom}{segment} = peaks;
			chromSegment_mostLikelyGaussians{chrom}{segment} = mostLikelyGaussians;
			chromSegment_actual_cutoffs{     chrom}{segment} = actual_cutoffs;
			chromSegment_smoothed{           chrom}{segment} = smoothed;
		end;
	end;
end;
