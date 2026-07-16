				%%// make standard chrom cartoons.
				figure(Standard_fig);
				left   = chrom_posX(chrom);
				bottom = chrom_posY(chrom);
				width  = chrom_width(chrom);
				height = chrom_height(chrom);
				fprintf(['chrom' num2str(chrom) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
				subplot('Position',[left bottom width height]);
				hold on;

				%%// Hide axis lines.
				box off;

				%% standard : show centromere.
				Centromere_format = Centromere_format_default;
				x1       = cen_start(chrom)/bases_per_bin;
				x2       = cen_end(chrom)/bases_per_bin;
				leftEnd  = 0;                                   %// 0.5*(5000/bases_per_bin);
				rightEnd = chrom_size(chrom)/bases_per_bin;         %// chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_0.m']);
				elseif (Centromere_format == 1)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_1.m']);
				elseif (Centromere_format == 2) %// sausage! (standard plot)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_2.m']);
				elseif (Centromere_format == 3) %// improved sausage!
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_3.m']);
				end;
				%%// standard : end show centromere.

