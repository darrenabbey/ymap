function [p1_a,p1_b,p1_c, p2_a,p2_b,p2_c, p3_a,p3_b,p3_c, p4_a,p4_b,p4_c, p5_a,p5_b,p5_c, p6_a,p6_b,p6_c, p7_a,p7_b,p7_c, p8_a,p8_b,p8_c, p9_a,p9_b,p9_c, Rsquared] = fit_Gaussian_model_octasomy_2(workingDir, descriptionString, data,locations,init_width,func_type, makeFitFigures)
	% attempt to fit a 9-gaussian model to data.

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
	p1_ai = max([data(round(locations(1))) data(round(locations(1))+1)])/max(data);		p1_bi = locations(1);   p1_ci = init_width/4;
	p2_ai = data(round(locations(2)))/max(data);						p2_bi = locations(2);   p2_ci = init_width;
	p3_ai = data(round(locations(3)))/max(data);						p3_bi = locations(3);   p3_ci = init_width;
	p4_ai = data(round(locations(4)))/max(data);						p4_bi = locations(4);   p4_ci = init_width;
	p5_ai = data(round(locations(5)))/max(data);						p5_bi = locations(5);   p5_ci = init_width;
	p6_ai = data(round(locations(6)))/max(data);						p6_bi = locations(6);   p6_ci = init_width;
	p7_ai = data(round(locations(7)))/max(data);						p7_bi = locations(7);   p7_ci = init_width;
	p8_ai = data(round(locations(8)))/max(data);						p8_bi = locations(8);   p8_ci = init_width;
	p9_ai = max([data(round(locations(9))) data(round(locations(9))-1)])/max(data);		p9_bi = locations(9);   p9_ci = init_width/4;
	skew1 = 0;
	skew2 = 0;
	skew3 = 0;

	initial = [p1_ci,p2_ai,p2_ci,p3_ai,p4_ai,p5_ai,p6_ai,p7_ai,p8_ai,skew1,skew2,skew3];
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

	% height, location, width.
	p1_a = p1_ai;			p1_b = p1_bi;	p1_c = abs(Estimates(1));
	p2_a = abs(Estimates(2));	p2_b = p2_bi;	p2_c = abs(Estimates(3));	alpha_2 = Estimates(10);
	p3_a = abs(Estimates(4));	p3_b = p3_bi;	p3_c = abs(Estimates(3));	alpha_3 = Estimates(11);
	p4_a = abs(Estimates(5));	p4_b = p4_bi;	p4_c = abs(Estimates(3));	alpha_4 = Estimates(12);
	p5_a = abs(Estimates(6));	p5_b = p5_bi;	p5_c = abs(Estimates(3));
	p6_a = abs(Estimates(7));	p6_b = p6_bi;	p6_c = abs(Estimates(3));	alpha_6 = -Estimates(12);
	p7_a = abs(Estimates(8));	p7_b = p7_bi;	p7_c = abs(Estimates(3));	alpha_7 = -Estimates(11);
	p8_a = abs(Estimates(9));	p8_b = p8_bi;	p8_c = abs(Estimates(3));	alpha_8 = -Estimates(10);
	p9_a = p9_ai;			p9_b = p9_bi;	p9_c = abs(Estimates(1));

	% Minimum variance safety threshold floor bounds
	widths = [p1_c, p2_c, p3_c, p4_c, p5_c, p6_c, p7_c, p8_c, p9_c];
	widths(widths < 2) = 2;
	p1_c=widths(1); p2_c=widths(2); p3_c=widths(3); p4_c=widths(4); p5_c=widths(5); p6_c=widths(6); p7_c=widths(7); p8_c=widths(8); p9_c=widths(9);

	%%% Generate mixed curve evaluations.
	%------------------------------------
	p1_fit = gaussian(time, p1_a, p1_b, p1_c);
	p2_fit = skew_gaussian(time, p2_a, p2_b, p2_c, alpha_2);
	p3_fit = skew_gaussian(time, p3_a, p3_b, p3_c, alpha_3);
	p4_fit = skew_gaussian(time, p4_a, p4_b, p4_c, alpha_4);
	p5_fit = gaussian(time, p5_a, p5_b, p5_c);
	p6_fit = skew_gaussian(time, p6_a, p6_b, p6_c, alpha_6);
	p7_fit = skew_gaussian(time, p7_a, p7_b, p7_c, alpha_7);
	p8_fit = skew_gaussian(time, p8_a, p8_b, p8_c, alpha_8);
	p9_fit = gaussian(time, p9_a, p9_b, p9_c);
	fitted = p1_fit+p2_fit+p3_fit+p4_fit+p5_fit+p6_fit+p7_fit+p8_fit+p9_fit;
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
		title(['SNP Gaussian model octasomy; ' descriptionString]);
		if (Rsquared != 0)
			plot(p1_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p2_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p3_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p4_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p5_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p6_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p7_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p8_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
			plot(p9_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
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
		saveName = [workingDir 'SNP_GaussFit.' descriptionString '.octasomy.png'];
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

	% height, location, relative width.
	p1_a = max([data(round(locations(1))) data(round(locations(1))+1)])/max(data);		p1_b = locations(1);	p1_c = abs(params(1));
	p2_a = abs(params(2));									p2_b = locations(2);	p2_c = abs(params(3));	alpha_2 = params(10);
	p3_a = abs(params(4));									p3_b = locations(3);	p3_c = abs(params(3));	alpha_3 = params(11);
	p4_a = abs(params(5));									p4_b = locations(4);	p4_c = abs(params(3));	alpha_4 = params(12);
	p5_a = abs(params(6));									p5_b = locations(5);	p5_c = abs(params(3));
	p6_a = abs(params(7));									p6_b = locations(6);	p6_c = abs(params(3));	alpha_6 = -params(12);
	p7_a = abs(params(8));									p7_b = locations(7);	p7_c = abs(params(3));	alpha_7 = -params(11);
	p8_a = abs(params(9));									p8_b = locations(8);	p8_c = abs(params(3));	alpha_8 = -params(10);
	p9_a = max([data(round(locations(9))) data(round(locations(9))-1)])/max(data);		p9_b = locations(9);	p9_c = abs(params(1));

	widths = [p1_c, p2_c, p3_c, p4_c, p5_c, p6_c, p7_c, p8_c, p9_c];
        widths(widths < 2) = 2;
        p1_c=widths(1);  p2_c=widths(2);  p3_c=widths(3);  p4_c=widths(4);  p5_c=widths(5);
        p6_c=widths(6);  p7_c=widths(7);  p8_c=widths(8);  p9_c=widths(9);

	p1_fit = gaussian(time, p1_a, p1_b, p1_c);
	p2_fit = skew_gaussian(time, p2_a, p2_b, p2_c, alpha_2);
	p3_fit = skew_gaussian(time, p3_a, p3_b, p3_c, alpha_3);
	p4_fit = skew_gaussian(time, p4_a, p4_b, p4_c, alpha_4);
	p5_fit = gaussian(time, p5_a, p5_b, p5_c);
	p6_fit = skew_gaussian(time, p6_a, p6_b, p6_c, alpha_6);
	p7_fit = skew_gaussian(time, p7_a, p7_b, p7_c, alpha_7);
	p8_fit = skew_gaussian(time, p8_a, p8_b, p8_c, alpha_8);
	p9_fit = gaussian(time, p9_a, p9_b, p9_c);
	fitted = p1_fit+p2_fit+p3_fit+p4_fit+p5_fit+p6_fit+p7_fit+p8_fit+p9_fit;

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
