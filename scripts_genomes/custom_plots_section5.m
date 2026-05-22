				figure(Linear_fig);
				Linear_width = Linear_Chr_max_width*chr_size(chr)/Linear_genome_size;

				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_chr_gap;
				hold on;

				%%// linear : show centromere/outline.
				%if (chr_size(chr) < 20000)
				%	Centromere_format = 0;
				%else
					Centromere_format = Centromere_format_default;
				%end;

				x1       = cen_start(chr)/bases_per_bin;
				x2       = cen_end(chr)/bases_per_bin;
				leftEnd  = 0;                                   %// 0.5*(5000/bases_per_bin);
				rightEnd = chr_size(chr)/bases_per_bin;         %// chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
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
