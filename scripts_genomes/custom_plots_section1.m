	[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
	Aneuploidy = [];

	num_chrs  = length(chr_sizes);

	for i = 1:num_chrs %%// Initialize some chromosome information variables.
		chr_size(i)  = 0;
		cen_start(i) = 0;
		cen_end(i)   = 0;
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
			fprintf(['\t[' num2str(annotations(i).chr) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' ...
			    annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
		end;
	end;
	for i = 1:length(figure_details)
		if (figure_details(i).chr == 0) %%// Reserved for figure elements that are not a chromosome.
			if (strcmp(figure_details(i).label,'Key') == 1)
				key_posX   = figure_details(i).posX;
				key_posY   = figure_details(i).posY;
				key_width  = figure_details(i).width;
				key_height = figure_details(i).height;
			end;
		else
			if (str2num(figure_details(i).useChr) > 0) %%// We only need to deal with chromosomes selected for use during genome setup.
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

				chr_size       (figure_details(i).chr) = chr_sizes(figure_details(i).chr).size;
				cen_start      (figure_details(i).chr) = centromeres(figure_details(i).chr).start;
				cen_end        (figure_details(i).chr) = centromeres(figure_details(i).chr).end;
			else
				%%// Reset values to zero for unused chromosomes.
				chr_sizes(figure_details(i).chr).size    = 0;
				centromeres(figure_details(i).chr).start = 0;
				centromeres(figure_details(i).chr).end   = 0;
			end;
		end;
	end;

