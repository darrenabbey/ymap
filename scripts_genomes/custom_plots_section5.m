				figure(Linear_fig);
				Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;

				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
				hold on;

				%%// linear : show centromere/outline.
				%if (chrom_size(chrom) < 20000)
				%	Centromere_format = 0;
				%else
					Centromere_format = Centromere_format_default;
				%end;

				x1       = cen_start(chrom)/bases_per_bin;
				x2       = cen_end(chrom)/bases_per_bin;
				leftEnd  = 0;                                   %// 0.5*(5000/bases_per_bin);
				rightEnd = chrom_size(chrom)/bases_per_bin;         %// chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_0.m']);
				elseif (Centromere_format == 1)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_1.m']);
				elseif (Centromere_format == 2) %// sausage! (linear plot)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_2.m']);
				elseif (Centromere_format == 3) %// improved sausage!
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_3.m']);
				end;
				%%// linear : end show centromere/outline.
