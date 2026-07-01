function [] = cartoon_plot(main_dir,genomeUser,genome,kmerLength,kmerStep);
addpath([pwd() '/../']);
addpath([pwd() '/../scripts_seqModules/']);
addpath([pwd() '/../scripts_seqModules/scripts_WGseq/']);

% hide figures during construction.
set(0,'DefaultFigureVisible','off');

%% ========================================================================

Centromere_format_default   = 3;
Yscale_nearest_even_ploidy  = true;
ChrNum                      = true;
show_annotations            = true;
analyze_rDNA                = true;
Standard_display            = true;
Linear_display              = true;


%%=========================================================================
% Control variables.
%--------------------------------------------------------------------------
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];

fprintf(['\n$$$ main_dir   : ' main_dir   '\n']);
fprintf([  '$$$ genomeUser   ' genomeUser '\n']);
fprintf([  '$$$ genome     : ' genome     '\n']);
fprintf([  '$$$ genomeDir  : ' genomeDir  '\n']);

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir 'users/' genomeUser '/genomes/' genome '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir 'users/' genomeUser '/genomes/' genome '/figure_options.txt'],'\t',1);

	option         = figure_options{4,1};
	if strcmp(option,'False')
		Make_cartoon = false;
	else
		Make_cartoon = true;
	end;
else
	Make_cartoon = true;
end;

[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
Aneuploidy = [];  % later loaded from Load_dataset_information(projectDir) after ChARM algorithm is used.
num_chrs   = length(chr_sizes);

for i = 1:num_chrs
	chr_size(i)  = 0;
	cen_start(i) = 0;
	cen_end(i)   = 0;
end;
for i = 1:num_chrs
	chr_size(chr_sizes(i).chr)    = chr_sizes(i).size;
	cen_start(centromeres(i).chr) = centromeres(i).start;
	cen_end(centromeres(i).chr)   = centromeres(i).end;
end;
if (length(annotations) > 0)
	fprintf(['\nAnnotations for ' genome '.\n']);
	for i = 1:length(annotations)
		annotation_chr(i)       = annotations(i).chr;
		annotation_type{i}      = annotations(i).type;
		annotation_start(i)     = annotations(i).start;
		annotation_end(i)       = annotations(i).end;
		annotation_fillcolor{i} = annotations(i).fillcolor;
		annotation_edgecolor{i} = annotations(i).edgecolor;
		annotation_size(i)      = annotations(i).size;
		fprintf(['\t[' num2str(annotations(i).chr) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
	end;
end;
for i = 1:length(figure_details)
	if (figure_details(i).chr == 0)
		if (strcmp(figure_details(i).label,'Key') == 1)
			key_posX   = figure_details(i).posX;
			key_posY   = figure_details(i).posY;
			key_width  = figure_details(i).width;
			key_height = figure_details(i).height;
		end;
	else
		chr_id         (figure_details(i).chr) = figure_details(i).chr;
		chr_label      {figure_details(i).chr} = figure_details(i).label;
		chr_name       {figure_details(i).chr} = figure_details(i).name;
		chr_posX       (figure_details(i).chr) = figure_details(i).posX;
		chr_posY       (figure_details(i).chr) = figure_details(i).posY;
		chr_width      (figure_details(i).chr) = figure_details(i).width;
		chr_height     (figure_details(i).chr) = figure_details(i).height;
		chr_in_use     (figure_details(i).chr) = str2num(figure_details(i).useChr);
		chr_figOrder   (figure_details(i).chr) = str2num(figure_details(i).figOrder);
		chr_figReversed(figure_details(i).chr) = str2num(figure_details(i).figReversed);
	end;
end;


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

if (Make_cartoon)
	fprintf([  '$$$ Making cartoon figure.\n']);

	%%
	source([pwd() '/custom_plots_section1.m']);
	%%


	%%=========================================================================
	% Load/process external data.
	%--------------------------------------------------------------------------

	%--------------------------------------------------------------------------
	% End external data load/process.
	%%=========================================================================


	%%
	source([pwd() '/custom_plots_section2.m']);
	%%

	% Draw chromosomes in order defined in figure_definitions.txt file.
	for chr_to_draw  = 1:length(chr_order)
		chr = chr_order(chr_to_draw);
		if (chr_in_use(chr) == 1)
			if (Standard_display)

	%%
	source([pwd() '/custom_plots_section3.m']);
	%%


				%%==================================================================================
				%% custom stacked plot section.
				%% end plot section.
				%%==================================================================================


	%%
	source([pwd() '/custom_plots_section4.m']);
	%%

			end;

			%% Linear figure draw section
			if (Linear_display)

	%%
	source([pwd() '/custom_plots_section5.m']);
	%%

				%%==================================================================================
				%% custom linear plot section.
				%% end plot section.
				%%==================================================================================

	%%
	source([pwd() '/custom_plots_section6.m']);
	%%

			end;

			if (Standard_display)
				% shift back to main figure generation.
				figure(Standard_fig);
				hold on;

				set(gca,'FontSize',gca_stacked_font_size);
				if (chr == find(chr_posY == max(chr_posY)))
					title([ genome ' Chromosome Cartoons'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;

			first_chr = false;
		end;
	end;

	if (Standard_display)
		% Save primary genome figure.
		set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
		saveas(Standard_fig, [genomeDir 'fig.cartoon.1.eps'], 'epsc');
		saveas(Standard_fig, [genomeDir 'fig.cartoon.1.png'], 'png');
		delete(Standard_fig);

		%% change permissions of figures.
		system(['chmod 774 ' genomeDir 'fig.cartoon.1.eps']);
		system(['chmod 774 ' genomeDir 'fig.cartoon.1.png']);
	end;

	if (Linear_display)
		% Save horizontal aligned genome figure.
		set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
		saveas(Linear_fig,   [genomeDir 'fig.cartoon.2.eps'], 'epsc');
		saveas(Linear_fig,   [genomeDir 'fig.cartoon.2.png'], 'png');
		delete(Linear_fig);

		%% change permissions of figures.
		system(['chmod 774 ' genomeDir 'fig.cartoon.2.eps']);
		system(['chmod 774 ' genomeDir 'fig.cartoon.2.png']);
	end;

	fprintf([  '$$$ Cartoon figures saved.\n']);

	%%=========================================================================
	%%= Process the generated linear chromosome cartoon into fragments. =======
	%%=========================================================================
	img = imread( [genomeDir 'fig.cartoon.2.png'] );
	if size(img, 3) == 3
		gray = rgb2gray(img);
	else
		gray = img;
	end
	[img_height, img_width] = size(gray);

	% Mask to white vs non-white.
	is_white_full = (gray == 255);

	% Get y-coordinates where white changes to non-white or vice-versa.
	v_transitions = (is_white_full(2:end, :) ~= is_white_full(1:end-1, :));

	% initialize line trackers.
	L1_all = zeros(1, img_width);
	L2_all = zeros(1, img_width);
	valid_columns = false(1, img_width);

	% Scan every column from bottom to top
	for x = 1:img_width
		% Get row indices for transitions in this column (+1 adjustment for diff offset)
                rows_trans_col = find(v_transitions(:, x)) + 1;

		% Sort descending to establish true bottom-to-top tracking sequence
		rows_trans_col = sort(rows_trans_col, 'descend');
		total_trans_col = length(rows_trans_col);

		% Each column must have enough transitions to be evaluable
		if total_trans_col > 1
			valid_columns(x) = true;

			% Check if 3 lines are present (each line creates 2 transitions)
			if total_trans_col >= 5
				% 3 lines present: Skip the bottom line (indices 1 and 2)
				%       Line 2 uses the 3rd transition.
				L2_all(x) = rows_trans_col(3);
				%       Line 1 uses the 6th transition (fallback to max available if text noise cuts it short)
				target_idx_L1 = min(6, total_trans_col);
				L1_all(x) = rows_trans_col(target_idx_L1);
			else
				% 2 lines present: Keep both lines
				%       Line 2 uses the 1st transition.
				L2_all(x) = rows_trans_col(1);
				%       Line 1 uses the 4th transition (fallback to max available if needed)
				target_idx_L1 = min(4, total_trans_col);
				L1_all(x) = rows_trans_col(target_idx_L1);
			end;
		end;
	end;

	% Ensure we found structural data on at least some columns before fragmenting
	if any(valid_columns)
		% Filter out un-evaluable columns to ensure accurate math
		L1_valid = L1_all(valid_columns);
		L2_valid = L2_all(valid_columns);

		% -----------------------------------------------------------------
		% RESOLVE GLOBAL THRESHOLDS BASED ON LARGER VERTICAL DISTANCE
		% -----------------------------------------------------------------
		% Calculate the exact vertical cartoon gap height for every single column
		gaps = abs(L1_valid - L2_valid);

		% Find the column index that yields the absolute largest gap profile
		[max_gap, max_idx] = max(gaps);

		% Assign the global flat clipping horizons from the winning column
		L1 = L1_valid(max_idx);
		L2 = L2_valid(max_idx);

		% -----------------------------------------------------------------
		% 5. Fragment Image parts (Slicing from 'img' to preserve color)
		% -----------------------------------------------------------------
		% Fragment Image 1) Top: White pixels above the upper line threshold
		frag1 = img(1 : (L1-1), :, :);
		imwrite(frag1, [genomeDir 'fig.cartoon.2.top.png']);

                % Fragment Image 2) Middle: White pixels captured within the line thresholds
		frag2 = img(L1 : (L2-1), :, :);
		imwrite(frag2, [genomeDir 'fig.cartoon.2.middle.png']);

		% Fragment Image 3) Bottom: White pixels below the lower line threshold
		frag3 = img(L2 : img_height, :, :);
		imwrite(frag3, [genomeDir 'fig.cartoon.2.bottom.png']);

		printf('$$$ Cartoon figure fragments made.\n');
	else
		fprintf('$$$ Error: No valid structural transitions discovered across the image.\n');
	end;
else
	printf([  '$$$ Not making cartoon figures.\n']);
end;

end
