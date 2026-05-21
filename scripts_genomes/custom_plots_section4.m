			%% show annotation locations (linear)
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
								fill([annotationCenter-5 annotationCenter-5 annotationCenter+5 annotationCenter+5], ...
									[-maxY/10*0.75+0.25 -maxY/10*0.75-0.25 -maxY/10*0.75-0.25 -maxY/10*0.75+0.25], ...
									annotation_fillcolor{i}, ...
									'edgecolor',    annotation_edgecolor{i});
							elseif (strcmp(annotation_type{i},'box2') == 1)
								fill([annotationStart annotationStart annotationEnd annotationEnd], ...
									[-maxY/10*0.75+0.25 -maxY/10*0.75-0.25 -maxY/10*0.75-0.25 -maxY/10*0.75+0.25], ...
									annotation_fillcolor{i}, ...
									'edgecolor',    annotation_edgecolor{i});
							elseif (strcmp(annotation_type{i},'arrowL') == 1)
								fill([annotationCenter-5 annotationCenter+5 annotationCenter+5], ...
									[-maxY/10*0.75 -maxY/10*0.75-0.25 -maxY/10*0.75+0.25], ...
									annotation_fillcolor{i}, ...
									'edgecolor',       annotation_edgecolor{i});
							elseif (strcmp(annotation_type{i},'arrowR') == 1)
								fill([annotationCenter-5 annotationCenter-5 annotationCenter+5], ...
									[-maxY/10*0.75+0.25 -maxY/10*0.75-0.25 -maxY/10*0.75], ...
									annotation_fillcolor{i}, ...
									'edgecolor',       annotation_edgecolor{i});
                                                        end;
						end;
					end;
					hold off;
				end;
				%% end show annotation locations (linear)

				%% Final formatting stuff.
				xlim([0,chr_size(chr)/bases_per_bin]);

				% modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY]);
				else
					ylim([0,maxY]);
				end;

				set(gca,'TickLength',[Linear_TickSize 0]);
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				%set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTick',[]);
				set(gca,'XTickLabel',[]);
				%% end final reformatting.

				% Adding chromosome titles above the middle of the chromosome cartoons.
				% note: adding title is done in the end since if placed earlier in the code somehow the plot function changes the title position.
				if (rotate == 0 && chr_size(chr) ~= 0 )
					if (chr_figReversed(chr) == 0)
						title(chr_label{chr},'Interpreter','none','FontSize',linear_chr_font_size,'Rotation',rotate);
					else
						title([chr_label{chr} '\fontsize{' int2str(round(linear_chr_font_size/2)) '}' char(10) '(reversed)'],'Interpreter','tex','FontSize',linear_chr_font_size,'Rotation',rotate);
					end;
				else
					if (chr_figReversed(chr) == 0)
						text((chr_size(chr)/bases_per_bin)/2,maxY+0.25,chr_label{chr},'Interpreter','none','FontSize',linear_chr_font_size,'Rotation',rotate);
					else
						text((chr_size(chr)/bases_per_bin)/2,maxY+0.25,[chr_label{chr} '\fontsize{' int2str(round(linear_chr_font_size/2)) '}' char(10) '(reversed)'],'Interpreter','tex','FontSize',linear_chr_font_size,'Rotation',rotate);
					end;
				end;
			end;

			if (Standard_display)
				% shift back to main figure generation.
				figure(Standard_fig);
				hold on;

				set(gca,'FontSize',gca_stacked_font_size);
				if (chr == find(chr_posY == max(chr_posY)))
					title([ genome ' Repetitiveness map'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;

			first_chr = false;
		end;
	end;
