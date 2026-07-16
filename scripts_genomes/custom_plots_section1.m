	[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
	Aneuploidy = [];

	num_chroms  = length(chrom_sizes);

	for i = 1:num_chroms %%// Initialize some chromosome information variables.
		chrom_size(i)  = 0;
		cen_start(i) = 0;
		cen_end(i)   = 0;
	end;
	if (length(annotations) > 0)
		fprintf(['\nAnnotations for ' genome '.\n']);
		for i = 1:length(annotations)
			annotation_chrom(i)       = annotations(i).chrom;
			annotation_type{i}      = annotations(i).type;
			annotation_start(i)     = annotations(i).start;
			annotation_end(i)       = annotations(i).end;
			annotation_fillcolor{i} = annotations(i).fillcolor;
			annotation_edgecolor{i} = annotations(i).edgecolor;
			annotation_size(i)      = annotations(i).size;
			fprintf(['\t[' num2str(annotations(i).chrom) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' ...
			    annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
		end;
	end;
	for i = 1:length(figure_details)
		if (figure_details(i).chrom == 0) %%// Reserved for figure elements that are not a chromosome.
			if (strcmp(figure_details(i).label,'Key') == 1)
				key_posX   = figure_details(i).posX;
				key_posY   = figure_details(i).posY;
				key_width  = figure_details(i).width;
				key_height = figure_details(i).height;
			end;
		else
			if (str2num(figure_details(i).usechrom) > 0) %%// We only need to deal with chromosomes selected for use during genome setup.
				chrom_id         (figure_details(i).chrom) = figure_details(i).chrom;
				chrom_label      {figure_details(i).chrom} = figure_details(i).label;
				chrom_name       {figure_details(i).chrom} = figure_details(i).name;
				chrom_posX       (figure_details(i).chrom) = figure_details(i).posX;
				chrom_posY       (figure_details(i).chrom) = figure_details(i).posY;
				chrom_width      (figure_details(i).chrom) = figure_details(i).width;
				chrom_height     (figure_details(i).chrom) = figure_details(i).height;
				chrom_in_use     (figure_details(i).chrom) = str2num(figure_details(i).usechrom);
				chrom_figOrder   (figure_details(i).chrom) = str2num(figure_details(i).figOrder);
				chrom_figReversed(figure_details(i).chrom) = str2num(figure_details(i).figReversed);

				chrom_size       (figure_details(i).chrom) = chrom_sizes(figure_details(i).chrom).size;
				cen_start      (figure_details(i).chrom) = centromeres(figure_details(i).chrom).start;
				cen_end        (figure_details(i).chrom) = centromeres(figure_details(i).chrom).end;
			else
				%%// Reset values to zero for unused chromosomes.
				chrom_sizes   (figure_details(i).chrom).size  = 0;
				centromeres (figure_details(i).chrom).start = 0;
				centromeres (figure_details(i).chrom).end   = 0;
				chrom_in_use  (figure_details(i).chrom)       = 0;
			end;
		end;
	end;

