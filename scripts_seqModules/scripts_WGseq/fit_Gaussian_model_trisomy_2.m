function [p1_a,p1_b,p1_c, p2_a,p2_b,p2_c, p3_a,p3_b,p3_c, p4_a,p4_b,p4_c, Rsquared] = fit_Gaussian_model_trisomy_2(workingDir, descriptionString, data,locations,init_width,func_type, makeFitFigures)
	% attempt to fit a 4-gaussian model to data.

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

	% Pre-calculate initial gaussian fit terms. a = height; b = location; c = width.
	p1_ai = max([data(round(locations(1))) data(round(locations(1))+1)])/max(data);		p1_bi = locations(1);	p1_ci = init_width/4;
	p2_ai = data(round(locations(2)))/max(data);						p2_bi = locations(2);	p2_ci = init_width;
	p3_ai = data(round(locations(3)))/max(data);						p3_bi = locations(3);	p3_ci = init_width;
	p4_ai = max([data(round(locations(4))) data(round(locations(4))-1)])/max(data);		p4_bi = locations(4);	p4_ci = init_width/4;
	skew = 0;

	initial = [p1_ci,p2_ai,p2_ci,p3_ai, skew];
	options = optimset('Display','off','FunValCheck','on','MaxFunEvals',200000);
	time= 1:200;

        [Estimates,~,exitflag] = fminsearch(@(x) fiterror(x, time, data, func_type, locations), initial, options);

	% Estimates(1):homozygous should always be narrower than Estimates(3):heterozygous.
	if (abs(Estimates(3)) < abs(Estimates(1)))
		% swap them
		temp         = Estimates(3);
		Estimates(3) = Estimates(1);
		Estimates(1) = temp;
	end;

	% Final Parameter Extraction (Outer peaks alpha = 0)
	p1_a = p1_ai;			p1_b = p1_bi;	p1_c = abs(Estimates(1));
	p2_a = abs(Estimates(2));	p2_b = p2_bi;	p2_c = abs(Estimates(3));	alpha_2 = Estimates(5);
	p3_a = abs(Estimates(4));	p3_b = p3_bi;	p3_c = abs(Estimates(3));	alpha_3 = -Estimates(5);
	p4_a = p4_ai;			p4_b = p4_bi;	p4_c = abs(Estimates(1));

	% Minimum variance safety threshold floor bounds
	widths = [p1_c, p2_c, p3_c, p4_c];
	widths(widths < 2) = 2;
	p1_c=widths(1); p2_c=widths(2); p3_c=widths(3); p4_c=widths(4);

	%%% Generate mixed curve evaluations.
	%------------------------------------
	p1_fit = gaussian(time, p1_a, p1_b, p1_c);
	p2_fit = skew_gaussian(time, p2_a, p2_b, p2_c, alpha_2);
	p3_fit = skew_gaussian(time, p3_a, p3_b, p3_c, alpha_3);
	p4_fit = gaussian(time, p4_a, p4_b, p4_c);
	fitted = p1_fit + p2_fit + p3_fit + p4_fit;
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
		title(['SNP Gaussian model trisomy; ' descriptionString]);
		if (Rsquared != 0)
			plot(p1_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p2_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p3_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p4_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
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
		saveName = [workingDir 'SNP_GaussFit.' descriptionString '.trisomy.png'];
		saveas(fig, saveName, 'png');
		delete(fig);
	end;
	%----------------------------------------------------------------------
end

function sse = fiterror(params,time,data,func_type,locations)
	data = data(:)';

	% params(1):homozygous should always be narrower than params(3):heterozygous.
	if (abs(params(3)) < abs(params(1)))
		params(3) = abs(params(1));
	end;

	% Base location & optimized width settings; mode-stabilized Skew Profile Amplitudes Lookups. (height, location, relative width)
	p1_a = max([data(round(locations(1))) data(round(locations(1))+1)])/max(data);		p1_b = locations(1);	p1_c = abs(params(1));
	p2_a = abs(params(2));									p2_b = locations(2);	p2_c = abs(params(3));	alpha_2 = params(5);
	p3_a = abs(params(4));									p3_b = locations(3);	p3_c = abs(params(3));	alpha_3 = -params(5);
	p4_a = max([data(round(locations(4))) data(round(locations(4))-1)])/max(data);		p4_b = locations(4);	p4_c = abs(params(1));

	% Minimum variance safety threshold floor bounds.
	widths = [p1_c, p2_c, p3_c, p4_c];
	widths(widths < 2) = 2;
	p1_c=widths(1); p2_c=widths(2); p3_c=widths(3); p4_c=widths(4);

	% Generate components (Outer symmetric, Inner mode-stabilized skew)
	p1_fit = gaussian(time, p1_a, p1_b, p1_c);
	p2_fit = skew_gaussian(time, p2_a, p2_b, p2_c, alpha_2);
	p3_fit = skew_gaussian(time, p3_a, p3_b, p3_c, alpha_3);
	p4_fit = gaussian(time, p4_a, p4_b, p4_c);
	fitted = p1_fit + p2_fit + p3_fit + p4_fit;

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

function y = skew_gaussian(x, a, b, c, alpha, align_type)
	% x: Time/Bin Vector coordinate axis array (e.g. 1:200).
	% a: Desired maximum amplitude peak height.
	% b: Desired fixed target coordinate index peak location (center).
	% c: Distribution scale parameter (width).
	% alpha: Skew term.
	% align_type: Optional string choice: "mode", "median", or "mean" (defaults to "mode").

	% Set default alignment type if not provided
	if nargin < 6
		align_type = "mode";
	end

	if alpha == 0
		y = a * exp(-0.5 * ((x - b) ./ c).^2);
	else
		% Calculate delta parameter from alpha skewness.
		delta = alpha / sqrt(1 + alpha^2);

		% Determine the appropriate offset based on user selection
		switch lower(align_type)
		    case "mode"
			offset = delta * sqrt(2 / pi) - (delta^3 * (4 - pi) / (2 * pi * sqrt(2 * pi)));
		    case "median"
			offset = (0.786922 * delta) + (0.045610 * delta^3) - (0.148078 * delta^5);
		    case "mean"
			offset = delta * sqrt(2 / pi);
		    otherwise
			error('Invalid align_type. Use "mode", "median", or "mean".');
		end

		% Shift the center position by the selected offset
		shifted_center = b - (c * offset);

		% Compute standard skew-normal probability distribution parts.
		z = (x - shifted_center) ./ c;
		pdf_part = exp(-0.5 * z.^2);
		cdf_part = 0.5 * (1 + erf((alpha * z) / sqrt(2)));
		raw_skew = pdf_part .* cdf_part;

		% Force scaling normalization at the true target center location b
		z_peak = (b - shifted_center) ./ c;
		raw_peak = exp(-0.5 * z_peak^2) * 0.5 * (1 + erf((alpha * z_peak) / sqrt(2)));

		y = a * (raw_skew ./ raw_peak);
	end;
end
