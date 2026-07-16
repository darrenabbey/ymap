box off;
set(gca,'visible','off');

%// Make my own x-axis tick labels
XTickValues = 0:(40*(5000/bases_per_bin)):(chrom_size(chrom)/bases_per_bin);   %// limits tic values to size of chromosome in figure.
XTickValLength = length(XTickValues)
tickPercent = 0.75;
if (length(annotations) > 0)
	y = zeros(size(XTickValues))-maxY/10*(1.5+tickPercent);
else
	y = zeros(size(XTickValues))-maxY/10*1.5;
end;

XTickLabels = cell(1,XTickValLength);
for i = 1:XTickValLength
	XTickLabels{i} = num2str((i-1)*0.2, "%5.1f");
end;

%// Make my own x-axis ticks.
if (length(annotations) > 0)
	for i = 1:length(XTickValues)
		plot([XTickValues(i) XTickValues(i)], [-maxY/10*1.5 -maxY/10*(1.5+tickPercent)], 'Color', [0 0 0]);
	end;
else
	for i = 1:length(XTickValues)
		plot([XTickValues(i) XTickValues(i)], [0 -maxY/10*tickPercent], 'Color', [0 0 0]);
	end;
end;

%// configuration of chromosome cartoon curves.
res    = 64;
Xscale = 7 * 2/ploidyBase;	%// Arbitrary value that results in smooth curved cartoons. Linear view needs a different number.
dy     = cen_tel_Yindent;
dx     = dy*Xscale;
xcen   = (x1+x2)/2;

%%// Calculate cartoon outlins and draw white patches to erase cartoon exterior.
if (xcen != 0)
	if (xcen-dx < dx)
		%%// Centromere is close enough to the left end such that the cartoon outline needs to be drawn as one curve.
		xdelta = xcen/2;
		ydelta = xdelta*dy/dx;

		%// cen-top-left-to-leftEnd (curve).
		poly_ctl   = circleToPolygon([xcen-xdelta maxY-dy xdelta], res);
		poly_ctl_x =  poly_ctl(1:(res/2+1),1);
		poly_ctl_y = (poly_ctl(1:(res/2+1),2)-(maxY-dy))/Xscale+(maxY-dy);
		poly_ctl_y = (poly_ctl(1:(res/2+1),2)-(maxY-dy))/Xscale+(maxY-dy)+(maxY-max(poly_ctl_y));
		patch([0; poly_ctl_x; xcen], [maxY; poly_ctl_y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// cen-bottom-left-to-leftEnd (curve).
		poly_cbl   = circleToPolygon([xcen-xdelta dy xdelta], res);
		poly_cbl_1        = poly_cbl(:,1);
		poly_cbl_2        = poly_cbl(:,2);
		poly_cbl_1(res+1) = poly_cbl_1(1);
		poly_cbl_2(res+1) = poly_cbl_2(1);
		poly_cbl_x =  poly_cbl_1((res/2+1):(res+1));
		poly_cbl_y = (poly_cbl_2((res/2+1):(res+1))-(dy))/Xscale+(dy);
		poly_cbl_y = (poly_cbl_2((res/2+1):(res+1))-(dy))/Xscale+(dy)-min(poly_cbl_y);
		patch([0; poly_cbl_x; xcen], [0; poly_cbl_y; 0], 'facecolor', 'w', 'edgecolor', 'w');
	else
		%// left-bottom corner (curve).
		poly1  = circleToPolygon([leftEnd+dy dy dy], res);
		poly1x = poly1((res/2+1):(res/4*3+1),1)*Xscale;
		poly1y = poly1((res/2+1):(res/4*3+1),2);
		patch([poly1x; leftEnd], [poly1y; 0], 'facecolor', 'w', 'edgecolor', 'w');

		%// left-top corner (curve).
		poly2  = circleToPolygon([leftEnd+dy maxY-dy dy], res);
		poly2x = poly2((res/4+1):(res/2+1),1)*Xscale;
		poly2y = poly2((res/4+1):(res/2+1),2);
		patch([poly2x; leftEnd], [poly2y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// cen-top-left (curve).
		poly_ctl   = circleToPolygon([xcen-dy maxY-dy dy], res);
		poly_ctl_x = (poly_ctl(1:(res/4+1),1)-xcen)*Xscale+xcen;
		poly_ctl_y =  poly_ctl(1:(res/4+1),2);
		patch([poly_ctl_x; xcen], [poly_ctl_y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// cen-bottom-left (curve).
		poly_cbl = circleToPolygon([xcen-dy dy dy], res);
		poly_cbl_1        = poly_cbl(:,1);
		poly_cbl_2        = poly_cbl(:,2);
		poly_cbl_1(res+1) = poly_cbl_1(1);
		poly_cbl_2(res+1) = poly_cbl_2(1);
		poly_cbl_x        = (poly_cbl_1((res/4*3+1):(res+1))-xcen)*Xscale+xcen;
		poly_cbl_y        =  poly_cbl_2((res/4*3+1):(res+1));
		patch([poly_cbl_x; xcen], [poly_cbl_y; 0], 'facecolor', 'w', 'edgecolor', 'w');
	end;
	if (xcen+dx > rightEnd-dx)
		%%// Centromere is close enough to the right end such that the cartoon outline needs to be drawn as one curve.
		xdelta = (rightEnd-xcen)/2;
		ydelta = xdelta*dy/dx;

		%// cen-top-right-to-rightEnd (cruve).
		poly_ctr   = circleToPolygon([xcen+xdelta maxY-dy xdelta], res);
		poly_ctr_x =  poly_ctr(1:(res/2+1),1);
		poly_ctr_y = (poly_ctr(1:(res/2+1),2)-(maxY-dy))/Xscale+(maxY-dy);
		poly_ctr_y = (poly_ctr(1:(res/2+1),2)-(maxY-dy))/Xscale+(maxY-dy)+(maxY-max(poly_ctr_y));
		patch([rightEnd; poly_ctr_x; xcen], [maxY; poly_ctr_y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// cen-bottom-right-to-rightEnd (curve).
		poly_cbr   = circleToPolygon([xcen+xdelta dy xdelta], res);
		poly_cbr_1        = poly_cbr(:,1);
		poly_cbr_2        = poly_cbr(:,2);
		poly_cbr_1(res+1) = poly_cbr_1(1);
		poly_cbr_2(res+1) = poly_cbr_2(1);
		poly_cbr_x =  poly_cbr_1((res/2+1):(res+1));
		poly_cbr_y = (poly_cbr_2((res/2+1):(res+1))-(dy))/Xscale+(dy);
		poly_cbr_y = (poly_cbr_2((res/2+1):(res+1))-(dy))/Xscale+(dy)-min(poly_cbr_y);
		patch([xcen; poly_cbr_x; rightEnd], [0; poly_cbr_y; 0], 'facecolor', 'w', 'edgecolor', 'w');
	else
		%// right-bottom corner (curve).
		poly3          = circleToPolygon([rightEnd-dy dy dy], res);
		poly3_1        = poly3(:,1);
		poly3_2        = poly3(:,2);
		poly3_1(res+1) = poly3_1(1);
		poly3_2(res+1) = poly3_2(1);
		poly3x         = (poly3_1((res/4*3+1):(res+1))-rightEnd)*Xscale+rightEnd;
		poly3y         = poly3_2((res/4*3+1):(res+1));
		patch([poly3x; rightEnd], [poly3y; 0], 'facecolor', 'w', 'edgecolor', 'w');

		%// right-top corner (curve).
		poly4          = circleToPolygon([rightEnd-dy maxY-dy dy], res);
		poly4x         = (poly4(1:(res/4+1),1)-rightEnd)*Xscale+rightEnd;
		poly4y         = poly4(1:(res/4+1),2);
		patch([poly4x; rightEnd], [poly4y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// cen-top-right (curve).
		poly_ctr   = circleToPolygon([xcen+dy maxY-dy dy], res);
		poly_ctr_x = (poly_ctr((res/4+1):(res/2+1),1)-xcen)*Xscale+xcen;
		poly_ctr_y =  poly_ctr((res/4+1):(res/2+1),2);
		patch([xcen; poly_ctr_x], [maxY; poly_ctr_y], 'facecolor', 'w', 'edgecolor', 'w');

		%// cen-bottom-right (curve).
		poly_cbr   = circleToPolygon([xcen+dy dy dy], res);
		poly_cbr_x = (poly_cbr((res/2+1):(res/4*3+1),1)-xcen)*Xscale+xcen;
		poly_cbr_y =  poly_cbr((res/2+1):(res/4*3+1),2);
		patch([xcen; poly_cbr_x], [0; poly_cbr_y], 'facecolor', 'w', 'edgecolor', 'w');
	end;
else
	%%// No centromere is indicated.
	if (rightEnd < dx*2)
		%%// Contig/chromosome is so short that cartoon outline can't be drawn as two segments for top or bottom.
		%%// Centromere is close enough to the right end such that the cartoon outline needs to be drawn as one curve.
		xdelta = (rightEnd)/2;
		ydelta = xdelta*dy/dx;

		%// top-left-to-rightEnd (cruve).
		poly_top   = circleToPolygon([xdelta maxY-dy xdelta], res);     %// circle [X Y radius];
		poly_top_x =  poly_top(1:(res/2+1),1);
		poly_top_y = (poly_top(1:(res/2+1),2)-(maxY-dy))/Xscale+(maxY-dy);
		poly_top_y = (poly_top(1:(res/2+1),2)-(maxY-dy))/Xscale+(maxY-dy)+(maxY-max(poly_top_y));
		patch([0; poly_top_x; rightEnd], [maxY; poly_top_y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// bottom-left-to-rightEnd (curve).
		poly_bot          = circleToPolygon([xdelta maxY-dy xdelta], res);
		poly_bot_1        = poly_bot(:,1);
		poly_bot_2        = poly_bot(:,2);
		poly_bot_1(res+1) = poly_bot_1(1);
		poly_bot_2(res+1) = poly_bot_2(1);
		poly_bot_x        =  poly_bot_1((res/2+1):(res+1));
		poly_bot_y        = (poly_bot_2((res/2+1):(res+1))-(dy))/Xscale+(dy);
		poly_bot_y        = (poly_bot_2((res/2+1):(res+1))-(dy))/Xscale+(dy)-min(poly_bot_y);
		patch([0; poly_bot_x; rightEnd], [0; poly_bot_y; 0], 'facecolor', 'w', 'edgecolor', 'w');
	else
		%// left-bottom corner (curve).
		poly1  = circleToPolygon([leftEnd+dy dy dy], res);
		poly1x = poly1((res/2+1):(res/4*3+1),1)*Xscale;
		poly1y = poly1((res/2+1):(res/4*3+1),2);
		patch([poly1x; leftEnd], [poly1y; 0], 'facecolor', 'w', 'edgecolor', 'w');

		%// left-top corner (curve).
		poly2  = circleToPolygon([leftEnd+dy maxY-dy dy], res);
		poly2x = poly2((res/4+1):(res/2+1),1)*Xscale;
		poly2y = poly2((res/4+1):(res/2+1),2);
		patch([poly2x; leftEnd], [poly2y; maxY], 'facecolor', 'w', 'edgecolor', 'w');

		%// right-bottom corner (curve).
		poly3          = circleToPolygon([rightEnd-dy dy dy], res);
		poly3_1        = poly3(:,1);
		poly3_2        = poly3(:,2);
		poly3_1(res+1) = poly3_1(1);
		poly3_2(res+1) = poly3_2(1);
		poly3x         = (poly3_1((res/4*3+1):(res+1))-rightEnd)*Xscale+rightEnd;
		poly3y         = poly3_2((res/4*3+1):(res+1));
		patch([poly3x; rightEnd], [poly3y; 0], 'facecolor', 'w', 'edgecolor', 'w');

		%// right-top corner (curve).
		poly4          = circleToPolygon([rightEnd-dy maxY-dy dy], res);
		poly4x         = (poly4(1:(res/4+1),1)-rightEnd)*Xscale+rightEnd;
		poly4y         = poly4(1:(res/4+1),2);
		patch([poly4x; rightEnd], [poly4y; maxY], 'facecolor', 'w', 'edgecolor', 'w');
	end;
end;

%%// Draw cartoon outlines.
if (xcen != 0)
	if (xcen-dx < dx)
		plot(poly_ctl_x,poly_ctl_y, 'Color', [0 0 0]);						%// cen-top-left-to-leftEnd (curve).
		plot([xcen xcen], [poly_ctl_y(end) maxY-dy], 'Color', [0 0 0]);				%// curve offset top.
		plot(poly_cbl_x,poly_cbl_y, 'Color', [0 0 0]);						%// cen-bottom-left-to-leftEnd (curve).
		plot([xcen xcen], [poly_cbl_y(1) dy], 'Color', [0 0 0]);				%// curve offset bottom.
		plot([0 0], [poly_ctl_y(end) poly_cbl_y(1)], 'Color', [0 0 0]);				%// left edge (line)
	else
		plot(poly1x,     poly1y,     'Color', [0 0 0]);						%// left-bottom-corner (curve).
		plot(poly2x,     poly2y,     'Color', [0 0 0]);						%// left-top-corner (curve).
		plot(poly_ctl_x, poly_ctl_y, 'Color', [0 0 0]);						%// cen-top-left (curve).
		plot(poly_cbl_x, poly_cbl_y, 'Color', [0 0 0]);						%// cen-bottom-left (curve).
		plot([poly2x(1) poly_ctl_x(end)], [maxY      maxY       ], 'Color', [0 0 0]);		%// top, left of cen (line).
		plot([poly2x(1) poly_ctl_x(end)], [0         0          ], 'Color', [0 0 0]);		%// bottom, left of cen (line).
		plot([0         0              ], [poly1y(1) poly2y(end)], 'Color', [0 0 0]);		%// left edge (line)
	end;
	if (xcen+dx > rightEnd-dx)
		plot(poly_ctr_x,poly_ctr_y, 'Color', [0 0 0]);						%// cen-top-right-to-rightEnd (curve).
		plot([xcen xcen], [poly_ctr_y(1) maxY-dy], 'Color', [0 0 0]);				%// curve offset top.
		plot(poly_cbr_x,poly_cbr_y, 'Color', [0 0 0]);						%// cen-bottom-right-to-rightEnd (curve).
		plot([xcen xcen], [poly_cbr_y(end) dy], 'Color', [0 0 0]);				%// curve offset bottom.
		plot([rightEnd rightEnd], [poly_ctr_y(1) poly_cbr_y(end)], 'Color', [0 0 0]);		%// right edge (line).
	else
		plot(poly3x,     poly3y,     'Color', [0 0 0]);						%// right-bottom-corner (curve).
		plot(poly4x,     poly4y,     'Color', [0 0 0]);						%// right-top-corner (curve).
		plot(poly_ctr_x, poly_ctr_y, 'Color', [0 0 0]);						%// cen-top-right (curve).
		plot(poly_cbr_x, poly_cbr_y, 'Color', [0 0 0]);						%// cen-bottom-right (curve).
		plot([poly_ctr_x(1) poly4x(end)], [maxY        maxY       ], 'Color', [0 0 0]);		%// top, right of cen (line).
		plot([poly_ctr_x(1) poly4x(end)], [0           0          ], 'Color', [0 0 0]);		%// bottom, right of cen (line).
		plot([rightEnd      rightEnd   ], [poly3y(end) poly4y(1)  ], 'Color', [0 0 0]);		%// right edge (line).
	end;
else
	if (rightEnd < dx*2)
		plot(poly_top_x,poly_top_y, 'Color', [0 0 0]);						%// top (curve).
		plot(poly_bot_x,poly_bot_y, 'Color', [0 0 0]);						%// bottom (curve).
		plot([0         0          ], [poly_top_y(1) poly_bot_y(end)], 'Color', [0 0 0]);	%// left edge (line).
		plot([rightEnd  rightEnd   ], [poly_top_y(1) poly_bot_y(end)], 'Color', [0 0 0]);	%// right edge (line).
	else
		plot(poly1x,poly1y, 'Color', [0 0 0]);							%// left-bottom-corner (curve).
		plot(poly2x,poly2y, 'Color', [0 0 0]);							%// left-top-corner (curve).
		plot(poly3x,poly3y, 'Color', [0 0 0]);							%// right-bottom-corner (curve).
		plot(poly4x,poly4y, 'Color', [0 0 0]);							%// right-top-corner (curve).
		plot([poly2x(1) poly4x(end)], [maxY        maxY       ], 'Color', [0 0 0]);		%// top edge (line).
		plot([poly2x(1) poly4x(end)], [0           0          ], 'Color', [0 0 0]);		%// bottom edge (line).
		plot([0         0          ], [poly1y(1)   poly2y(end)], 'Color', [0 0 0]);		%// left edge (line).
		plot([rightEnd  rightEnd   ], [poly3y(end) poly4y(1)  ], 'Color', [0 0 0]);		%// right edge (line).
	end;
end;
