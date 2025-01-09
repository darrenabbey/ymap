% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
Xscale = 4;
dx = cen_tel_Xindent*Xscale;
dy = maxY/5;			 % cen_tel_Yindent;
xcen = (x1+x2)/2;

if (x1 != 0)
	% draw white trapezoids for centromeres.
	patch([x1-dx,  x1,  x2,  x2+dx], [maxY,  maxY-dy,  maxY-dy,  maxY], 'facecolor', 'w', 'edgecolor', 'w');
	patch([x1-dx,  x1,  x2,  x2+dx], [0,     dy,       dy,       0   ], 'facecolor', 'w', 'edgecolor', 'w');
end;

% draw white triangles at corners.
patch([leftEnd,  leftEnd,  leftEnd+dx ], [maxY-dy, maxY, maxY], 'facecolor', 'w', 'edgecolor', 'w');
patch([leftEnd,  leftEnd,  leftEnd+dx ], [0,       dy,   0   ], 'facecolor', 'w', 'edgecolor', 'w');
patch([rightEnd, rightEnd, rightEnd-dx], [maxY-dy, maxY, maxY], 'facecolor', 'w', 'edgecolor', 'w');
patch([rightEnd, rightEnd, rightEnd-dx], [0,       dy,   0   ], 'facecolor', 'w', 'edgecolor', 'w');

	% draw outlines of chromosome cartoon.
	if (xcen != 0)
	if (xcen < dx)
		xdelta = xcen/2;
		ydelta = xdelta*dy/dx;
		plot([leftEnd   leftEnd   xcen-xdelta      xcen      xcen+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   xcen+dx   xcen   xcen-xdelta   leftEnd], ...
		     [dy        maxY-dy   maxY-dy+ydelta   maxY-dy   maxY      maxY          maxY-dy    dy         0             0         dy     dy-ydelta     dy     ], ...
		    'Color',[0 0 0]);
	elseif (xcen > rightEnd-dx)
		xdelta = (rightEnd-xcen)/2;
		ydelta = xdelta*dy/dx;
		plot([leftEnd   leftEnd   leftEnd+dx   xcen-dx   xcen      xcen+xdelta      rightEnd   rightEnd   xcen+xdelta   xcen   xcen-dx   leftEnd+dx   leftEnd], ...
		     [dy        maxY-dy   maxY         maxY      maxY-dy   maxY-dy+ydelta   maxY-dy    dy         dy-ydelta     dy     0         0            dy     ], ...
		    'Color',[0 0 0]);
	else
		plot([leftEnd   leftEnd   leftEnd+dx   xcen-dx   xcen      xcen+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   xcen+dx   xcen   xcen-dx   leftEnd+dx   leftEnd], ...
		     [dy        maxY-dy   maxY         maxY      maxY-dy   maxY      maxY          maxY-dy    dy         0             0         dy     0         0            dy     ], ...
		    'Color',[0 0 0]);
	end;
else
	plot([leftEnd   leftEnd   leftEnd+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   leftEnd+dx   leftEnd], ...
	     [dy        maxY-dy   maxY         maxY          maxY-dy    dy         0             0            dy     ], ...
	    'Color',[0 0 0]);
end;
