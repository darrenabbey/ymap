				%%// make standard chr cartoons.
				figure(Standard_fig);
				left   = chr_posX(chr);
				bottom = chr_posY(chr);
				width  = chr_width(chr);
				height = chr_height(chr);
				fprintf(['chr' num2str(chr) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
				subplot('Position',[left bottom width height]);
				hold on;

				%%// Hide axis lines.
				box off;


				%%// standard : show centromere.
				%if (chr_size(chr) < 4000)
				%	Centromere_format = 0;
				%else
					Centromere_format = Centromere_format_default;
				%end;

				x1       = cen_start(chr)/bases_per_bin;
				x2       = cen_end(chr)/bases_per_bin;
				leftEnd  = 0;                                   %// 0.5*(5000/bases_per_bin);
				rightEnd = chr_size(chr)/bases_per_bin;         %// chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_0.m']);
				elseif (Centromere_format == 1)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_1.m']);
				elseif (Centromere_format == 2) %// sausage! (standard plot)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_2.m']);
				elseif (Centromere_format == 2) %// improved sausage!
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_stacked_3.m']);
				end;
				%%// standard : end show centromere.

