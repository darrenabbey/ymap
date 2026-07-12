function [p1_a,p1_b,p1_c, p2_a,p2_b,p2_c, Rsquared] = fit_Gaussian_model_monosomy_2(workingDir, descriptionString, data,locations,init_width,func_type, makeFitFigures)
	% attempt to fit a 2-gaussian model to data.

	if isempty(data) || any(isnan(data))
		return
	end;
	data = data(:)';

	% find max height in data.
	datamax = max(data);

	% if maxdata is final bin, then find next highest p
	if (find(data == datamax) == length(data))
		data(data == datamax) = 0;
		datamax = data;
		datamax(data ~= max(datamax)) = [];
	end;

	% a = height; b = location; c = width.
	p1_ai = max([data(round(locations(1))) data(round(locations(1))+1)])/max(data);		p1_bi = locations(1);	p1_ci = init_width/4;
	p2_ai = max([data(round(locations(2))) data(round(locations(2))+1)])/max(data);		p2_bi = locations(2);	p2_ci = init_width/4;

	initial = [p1_ci];
	options = optimset('Display','off','FunValCheck','on','MaxFunEvals',200000);
	time= 1:200;

	[Estimates,~,exitflag] = fminsearch(@(x) fiterror(x, time, data, func_type, locations), initial, options);

	if (exitflag > 0)
		% > 0 : converged to a solution.
	else
		% = 0 : exceeded maximum iterations allowed.
		% < 0 : did not converge to a solution.
		% return last best estimate anyhow.
	end;

	% Final Parameter Extraction (Outer peaks alpha = 0)
	p1_a = p1_ai;	p1_b = p1_bi;	p1_c = abs(Estimates(1));
	p2_a = p4_ai;	p2_b = p2_bi;	p4_c = abs(Estimates(1));

	% Minimum variance safety threshold floor bounds.
	widths = [p1_c, p2_c];
	widths(widths < 2) = 2;
	p1_c=widths(1); p2_c=widths(2);

	%%% Calculate R^2 for fit line.
	%------------------------------------
	p1_fit = gaussian(time, p1_a, p1_b, p1_c);
	p2_fit = gaussian(time, p2_a, p2_b, p2_c);
	fitted = p1_fit+p2_fit;
	%------------------------------------
	SSres    = sum((data-fitted).^2);
	dataMean = data*0+mean(data);
	SStot    = sum((data-dataMean).^2);
	Rsquared = 1 - SSres/SStot;
	if isnan(Rsquared) || isinf(Rsquared)
		Rsquared = 0;
	end;

	%----------------------------------------------------------------------
	% show fitting result.
	if (makeFitFigures)
		fig = figure(123);
		plot(data,'o' , 'color',[0.50 0.50 1.00]);
		hold on;
		title(['SNP Gaussian model monosomy; ' descriptionString]);
		if (Rsquared != 0)
			plot(p1_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p2_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(fitted,'-','color',[0 0.00 0.00],'lineWidth',2);
			text(100,0.5,['R^2 = ', num2str(Rsquared)],"interpreter", "latex");
		end;
		hold off;

		filesToDelete = glob([workingDir 'SNP_GaussFit.' descriptionString '.*.png']);
		if ~isempty(filesToDelete)
			for i = 1:numel(filesToDelete)
				delete(filesToDelete{i});
			end;
		end;
		saveName = [workingDir 'SNP_GaussFit.' descriptionString '.monosomy.png'];
		saveas(fig, saveName, 'png');
		delete(fig);
	end;
	%----------------------------------------------------------------------
end

function sse = fiterror(params,time,data,func_type,locations)
	data = data(:)';

	% Base location & optimized width settings; mode-stabilized Skew Profile Amplitudes Lookups. (height, location, relative width)
	p1_a = max([data(round(locations(1))) data(round(locations(1))+1)])/max(data);		p1_b = locations(1);	p1_c = abs(params(1));
        p2_a = max([data(round(locations(2))) data(round(locations(2))-1)])/max(data);		p2_b = locations(2);	p2_c = abs(params(1));

	% Minimum variance safety threshold floor bounds.
	widths = [p1_c, p2_c];
	widths(widths < 2) = 2;
	p1_c=widths(1); p2_c=widths(2);

	% Generate components.
	p1_fit = gaussian(time, p1_a, p1_b, p1_c);
	p2_fit = gaussian(time, p2_a, p2_b, p2_c);
	fitted = p1_fit+p2_fit;

	switch(func_type)
		case 'cubic'
			Error_Vector = (fitted).^2 - (data).^2;
			sse  = sum(abs(Error_Vector));
		case 'linear'
			Error_Vector = (fitted) - (data);
			sse  = sum(Error_Vector.^2);
		case 'log'
			fitted(fitted <= 0) = 0.0001;
			data(data <= 0)     = 0.0001;
			Error_Vector = log(fitted) - log(data);
			sse  = sum(abs(Error_Vector));
		case 'fcs'
			Error_Vector = (fitted) - (data);
			sse  = sum(Error_Vector.^2);
		otherwise
			error('Error: choice for fitting not implemented yet!');
			sse  = 1;
	end;
	if isnan(sse) || isinf(sse) || ~isreal(sse)
		sse = 1e12;
	end;
end

function y = gaussian(x, a, b, c)
	% x: Time/Bin Vector coordinate axis array (e.g. 1:200).
	% a: Desired maximum amplitude peak height.
	% b: Desired fixed target coordinate index peak location (center).
	% c: Distribution scale parameter (width).

	y = a * exp(-0.5 * ((x - b) ./ c).^2);
end
