function [G1_a, G1_b, G1_c, Rsquared] = fit_Gaussian_model2(workingDir, data, location, func_type, show_fitting, ploidy1x, makeFitFigures, descriptionString)
	graphics_toolkit gnuplot;

	%%%================================================================================================
	%%% Attempt to fit a single-gaussian model to data.
	%%% Used to help determine copy number estimates for chromosome segments.
	%%%------------------------------------------------------------------------------------------------

	time     = 1:length(data);
	G1_a     = nan;
	G1_b     = nan;
	G1_c     = nan;
	Rsquared = nan;

	if isnan(data)
		% fitting variables
		return
	end

	%%% find max height in data as initial copy number guess.
	datamax = max(data);
	%datamax(data ~= max(datamax)) = [];

	%%% if maxdata is final bin, then find next highest bin.
	if (find(data == datamax) == length(data))
		data(data == datamax) = 0;
		datamax = data;
		datamax(data ~= max(datamax)) = [];
	end;

	%%% a = height
	%%% b = location
	%%% c = width.
	G1_ai = datamax;
	G1_bi = location;

	%%% find G1_ci; width of G1 at halfmax.
	dd = data;
	dd(data < max(data)/2) = 0;
	c1 = find(dd,1,'first');
	G1_ci = (G1_bi-c1)/sqrt(2*log(2));

	initial = [G1_ai, G1_bi, G1_ci];
	options = optimset('Display','off','FunValCheck','on','MaxFunEvals',10000);

	[Estimates,~,exitflag] = fminsearch(@fiterror, ...    % function to be fitted.
	                                    initial, ...      % initial x-value.
	                                    options, ...      % options for fitting algorithm.
	                                    time, ...         % problem-specific parameter 1.
	                                    data, ...         % problem-specific parameter 2.
	                                    func_type, ...    % problem-specific parameter 3.
	                                    show_fitting, ... % problem-specific parameter 4.
	                                    ploidy1x ...      % problem-specific parameter 5.
	                            );
	if (exitflag > 0)
		% > 0 : converged to a solution.
		G1_a = abs(Estimates(1));
		G1_b = Estimates(2);
		G1_c = abs(Estimates(3));
	else
		% = 0 : exceeded maximum iterations allowed.
		% < 0 : did not converge to a solution.
		% return last best estimate anyhow.
		G1_a = abs(Estimates(1));
		G1_b = Estimates(2);
		G1_c = abs(Estimates(3));
	end;

	%%% Calculate R² for fit line.
	%------------------------------------
	G1_fit   = G1_a*exp(-0.5*((time-G1_b)./G1_c).^2);
	fitted   = G1_fit;
	%------------------------------------
	SSres    = sum((data-fitted).^2);
	dataMean = data*0+mean(data);
	SStot    = sum((data-dataMean).^2);
	Rsquared = 1 - SSres/SStot;

	%----------------------------------------------------------------------
	% show fitting result.
	if (makeFitFigures)
		fig = figure(123);
		plot(data,'o' , 'color',[0.50 0.50 1.00]);
		hold on;
		title(['CNV Gaussian model; ' descriptionString]);
		plot(fitted,'-','color',[0.00 0.50 0.50],'lineWidth',2);
		text(100,0.5,['R² = ', num2str(Rsquared)],"interpreter", "latex");
		hold off;
		figVers = 1;
		saveName = [workingDir 'CNV_GaussFit.' num2str(figVers,'%03.f') '.png'];
		while (exist(saveName,'file'))
			figVers += 1;
			saveName = [workingDir 'CNV_GaussFit.' num2str(figVers,'%03.f') '.png'];
		end;
		saveas(fig, saveName, 'png');
		delete(fig);
	end;
	%----------------------------------------------------------------------
end

function sse = fiterror(params,time,data,func_type, show_fitting,ploidy1x)
	G1_a = abs(params(1));       % G1_height.
	G1_b = params(2);            % G1_location.
	G1_c = abs(params(3));       % G1_width.
	if (G1_c == 0)
		G1_c = 0.001;
	end;
	% a = height.
	% b = location.
	% c = width.

	G1_fit = G1_a*exp(-0.5*((time-G1_b)./G1_c).^2);
	fitted = G1_fit;

	if (show_fitting == 1)
		%------------------------------------------------------------------
		% show fitting in process.
		figure(1);
		% show data being fit.
		plot(data,'x-','color',[0.75 0.75 1]);
		hold on;
		% show fit curve.
		plot(fitted,'-','color',[0 0.5 0.5],'lineWidth',2);
		% show ploidy lines.
		line([ploidy1x*1  ploidy1x*1 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*2  ploidy1x*2 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*3  ploidy1x*3 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*4  ploidy1x*4 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*5  ploidy1x*5 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*6  ploidy1x*6 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*7  ploidy1x*7 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*8  ploidy1x*8 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*9  ploidy1x*9 ],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		line([ploidy1x*10 ploidy1x*10],[0 max(data)],'color',[0 0 0],'lineWidth',2);
		hold off;
		%------------------------------------------------------------------
	end;

	width = 0.5;
	switch(func_type)
		case 'cubic'
			Error_Vector = (fitted).^2 - (data).^2;
			sse          = sum(abs(Error_Vector));
		case 'linear'
			Error_Vector = (fitted) - (data);
			sse          = sum(Error_Vector.^2);
		case 'log'
			Error_Vector = log(fitted) - log(data);
			sse          = sum(abs(Error_Vector));
		case 'fcs'
			Error_Vector = (fitted) - (data);
			%Error_Vector(1:round(G1_b*(1-width))) = 0;
			%Error_Vector(round(G1_b*(1+width)):end) = 0;
			sse          = sum(Error_Vector.^2);
		otherwise
			error('Error: choice for fitting not implemented yet!');
			sse = 1;
	end;
end
