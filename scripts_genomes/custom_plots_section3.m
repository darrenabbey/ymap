				%axes labels etc.
				hold off;

				% standard : limit x-axis to range of chromosome.
				xlim([0,chr_size(chr)/bases_per_bin]);

				% modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY]);
				else
					ylim([0,maxY]);
				end;

				set(gca,'TickLength',[TickSize 0]);
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

				%% chromosome cartoon titles for standard figure.
				if (chr_figReversed(chr) == 0)
					text(-50000/5000/2*3, maxY/2, chr_label{chr}, 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chr_font_size);
				else
					text(-50000/5000/2*3, maxY/2, [chr_label{chr} '\fontsize{' int2str(round(stacked_chr_font_size/2)) '}' char(10) '(reversed)'], 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize',stacked_chr_font_size);
				end;

				% show annotation locations (standard)
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*0.75 -maxY/10*0.75],'color',[0 0 0]);
					annotation_location = (annotation_start+annotation_end)./2;
					for i = 1:length(annotation_location)
						if (annotation_chr(i) == chr)
							annotationCenter = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
							annotationStart  = annotation_start(i)/bases_per_bin-0.5*(5000/bases_per_bin);
							annotationEnd    = annotation_end(i)/bases_per_bin-0.5*(5000/bases_per_bin);
							if (strcmp(annotation_type{i},'dot') == 1)
								plot([annotationStart,annotationEnd],[-maxY/10*0.75, -maxY/10*0.75], ...
								     'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
								     'MarkerFaceColor', annotation_fillcolor{i}, ...
								     'MarkerSize',      annotation_size(i));
								if (round(annotationEnd-5) > round(annotationStart+5))
									for position = round(annotationStart+5):round(annotationEnd-5)
										plot(position,-maxY/10*0.75, ...
										     'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
										     'MarkerFaceColor', annotation_fillcolor{i}, ...
										     'MarkerSize',      annotation_size(i));
									end;
								end;
							elseif (strcmp(annotation_type{i},'block') == 1)
								fill([annotationStart annotationStart annotationEnd annotationEnd], ...
									[-maxY/10*0.75+0.75 -maxY/10*0.75-0.75 -maxY/10*0.75-0.75 -maxY/10*0.75+0.75], ...
									annotation_fillcolor{i}, ...
									'edgecolor',    annotation_edgecolor{i});
							elseif (strcmp(annotation_type{i},'arrowL') == 1)
								fill([annotationStart annotationStart annotationEnd annotationEnd], ...
									[-maxY/10*0.75 -maxY/10*0.75 -maxY/10*0.75-0.75 -maxY/10*0.75+0.75], ...
									annotation_fillcolor{i}, ...
									'edgecolor',       annotation_edgecolor{i});
							elseif (strcmp(annotation_type{i},'arrowR') == 1)
								fill([annotationStart annotationStart annotationEnd annotationEnd], ...
									[-maxY/10*0.75+0.75 -maxY/10*0.75-0.75 -maxY/10*0.75 -maxY/10*0.75], ...
									annotation_fillcolor{i}, ...
									'edgecolor',       annotation_edgecolor{i});
							end;
						end;
					end;
					hold off;
				end;
				% end show annotation locations (standard)
			end;

			%% Linear figure draw section
			if (Linear_display)
				figure(Linear_fig);
				Linear_width = Linear_Chr_max_width*chr_size(chr)/Linear_genome_size;
				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_chr_gap;
				hold on;

				%% linear : show centromere/outline.
				if (chr_size(chr) < 100000)
					Centromere_format = 0;
				else
					Centromere_format = Centromere_format_default;
				end;
				x1       = cen_start(chr)/bases_per_bin;
				x2       = cen_end(chr)/bases_per_bin;
				leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
				rightEnd = chr_size(chr)/bases_per_bin;         % chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_0.m']);
				elseif (Centromere_format == 1)
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_1.m']);
				elseif (Centromere_format == 2) % sausage! (linear plot)
					%source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_2.m']);
					source([pwd() '/../scripts_seqModules/scripts_WGseq/cartoon_linear_3.m']);
				end;
				%% linear : end show centromere/outline.
