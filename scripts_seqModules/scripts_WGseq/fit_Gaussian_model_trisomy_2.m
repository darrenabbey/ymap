function [p1_a,p1_b,p1_c, p2_a,p2_b,p2_c, p3_a,p3_b,p3_c, p4_a,p4_b,p4_c, skew_factor] = fit_Gaussian_model_trisomy_2(workingDir, saveName, data,locations,init_width,func_type)
	% attempt to fit a 4-gaussian model to data.

	show = false;
	p1_a = nan;   p1_b = nan;   p1_c = nan;
	p2_a = nan;   p2_b = nan;   p2_c = nan;
	p3_a = nan;   p3_b = nan;   p3_c = nan;
	p4_a = nan;   p4_b = nan;   p4_c = nan;
	skew_factor = 1;

	if isnan(data)
		% fitting variables
		return
	end;

	% find max height in data.
	datamax = max(data);
	%datamax(data ~= max(datamax)) = [];

	% if maxdata is final bin, then find next highest p
	if (find(data == datamax) == length(data))
		data(data == datamax) = 0;
		datamax = data;
		datamax(data ~= max(datamax)) = [];
	end;

	% a = height; b = location; c = width.
	p1_ai = datamax;   p1_bi = locations(1);   p1_ci = init_width;
	p2_ai = datamax;   p2_bi = locations(2);   p2_ci = init_width;
	p3_ai = datamax;   p3_bi = locations(3);   p3_ci = init_width;
	p4_ai = datamax;   p4_bi = locations(4);   p4_ci = init_width;

	initial = [p1_ai,p1_ci,p2_ai,p2_ci,p3_ai,p3_ci,p4_ai,p4_ci, skew_factor,skew_factor,skew_factor,skew_factor];
	options = optimset('Display','off','FunValCheck','on','MaxFunEvals',100000);
	time= 1:length(data);

	[Estimates,~,exitflag] = fminsearch(@fiterror, ...   % function to be fitted.
	                                    initial, ...     % initial values.
	                                    options, ...     % options for fitting algorithm.
	                                    time, ...        % problem-specific parameter 1.
	                                    data, ...        % problem-specific parameter 2.
	                                    func_type, ...   % problem-specific parameter 3.
	                                    locations, ...   % problem-specific parameter 4.
	                                    show ...         % problem-specific parameter 5.
	                            );
	if (exitflag > 0)
		% > 0 : converged to a solution.
	else
		% = 0 : exceeded maximum iterations allowed.
		% < 0 : did not converge to a solution.
		% return last best estimate anyhow.
	end;
	p1_a         = abs(Estimates(1));
	p1_b         = locations(1);
	p1_c         = abs(Estimates(2));

	p2_a         = abs(Estimates(3));
	p2_b         = locations(2);
	p2_c         = abs(Estimates(4));

	p3_a         = abs(Estimates(5));
	p3_b         = locations(3);
	p3_c         = abs(Estimates(4));

	p4_a         = abs(Estimates(7));
	p4_b         = locations(4);
	p4_c         = abs(Estimates(2));

	skew_factor1 = abs(Estimates(9));
	skew_factor2 = abs(Estimates(10));
	skew_factor3 = 2-abs(Estimates(10));
	skew_factor4 = 2-abs(Estimates(9));

	if (skew_factor1 < 0); skew_factor1 = 0; end; if (skew_factor1 > 2); skew_factor1 = 2; end;
	if (skew_factor2 < 0); skew_factor2 = 0; end; if (skew_factor2 > 2); skew_factor2 = 2; end;
	if (skew_factor3 < 0); skew_factor3 = 0; end; if (skew_factor3 > 2); skew_factor3 = 2; end;
	if (skew_factor4 < 0); skew_factor4 = 0; end; if (skew_factor4 > 2); skew_factor4 = 2; end;
	c1_  = p1_c/2 + p1_c*skew_factor1/(100.5-abs(100.5-p1_b))/2;
	p1_c = p1_c*p1_c/c1_;
	c2_  = p2_c/2 + p2_c*skew_factor2/(100.5-abs(100.5-p2_b))/2;
	p2_c = p2_c*p2_c/c2_;
	c3_  = p3_c/2 + p3_c*skew_factor3/(100.5-abs(100.5-p3_b))/2;
	p3_c = p3_c*p3_c/c3_;
	c4_  = p4_c/2 + p4_c*skew_factor4/(100.5-abs(100.5-p4_b))/2;
	p4_c = p4_c*p4_c/c4_;
end

function sse = fiterror(params,time,data,func_type,locations,show)
	% params(2):homozygous should always be narrower than params(4):heterozygous.
	if (abs(params(4)) < abs(params(2))) {
		% swap them
		temp      = params(4);
		params(4) = params(2);
		params(2) = temp;
	}

	p1_a         = abs(params(1)); % height.
	p1_b         = locations(1);   % location.
	p1_c         = abs(params(2)); % width.

	p2_a         = abs(params(3)); % height.
	p2_b         = locations(2);   % location.
	p2_c         = abs(params(4)); % width.

	p3_a         = abs(params(5)); % height.
	p3_b         = locations(3);   % location.
	p3_c         = abs(params(4)); % abs(params(6)); % width.

	p4_a         = abs(params(7)); % height.
	p4_b         = locations(4);   % location.
	p4_c         = abs(params(2)); % abs(params(8)); % width.

	skew_factor1 = abs(params(9));
	skew_factor2 = abs(params(10));
	skew_factor3 = 2-abs(params(10));
	skew_factor4 = 2-abs(params(9));

	if (p1_c == 0); p1_c = 0.001; end;
	if (p2_c == 0); p2_c = 0.001; end;
	if (p3_c == 0); p3_c = 0.001; end;
	if (p4_c == 0); p4_c = 0.001; end;
	if (skew_factor1 < 0); skew_factor1 = 0; end; if (skew_factor1 > 2); skew_factor1 = 2; end;
	if (skew_factor2 < 0); skew_factor2 = 0; end; if (skew_factor2 > 2); skew_factor2 = 2; end;
	if (skew_factor3 < 0); skew_factor3 = 0; end; if (skew_factor3 > 2); skew_factor3 = 2; end;
	if (skew_factor4 < 0); skew_factor4 = 0; end; if (skew_factor4 > 2); skew_factor4 = 2; end;
	if (p1_c < 2);   p1_c = 2;   end;
	if (p2_c < 2);   p2_c = 2;   end;
	if (p3_c < 2);   p3_c = 2;   end;
	if (p4_c < 2);   p4_c = 2;   end;
	time1_1 = 1:floor(p1_b);
	time1_2 = ceil(p1_b):200;
	if (time1_1(end) == time1_2(1));time1_1(end) = [];  end;
	time2_1 = 1:floor(p2_b);
	time2_2 = ceil(p2_b):200;
	if (time2_1(end) == time2_2(1));time2_1(end) = [];  end;
	time3_1 = 1:floor(p3_b);
	time3_2 = ceil(p3_b):200;
	if (time3_1(end) == time3_2(1));time3_2(1) = [];end;
	time4_1 = 1:floor(p4_b);
	time4_2 = ceil(p4_b):200;
	if (time4_1(end) == time4_2(1));time4_2(1) = [];end;
	c1_  = p1_c/2 + p1_c*skew_factor1/(100.5-abs(100.5-p1_b))/2;
	p1_c = p1_c*p1_c/c1_;
	c2_  = p2_c/2 + p2_c*skew_factor2/(100.5-abs(100.5-p2_b))/2;
	p2_c = p2_c*p2_c/c2_;
	c3_  = p3_c/2 + p3_c*skew_factor3/(100.5-abs(100.5-p3_b))/2;
	p3_c = p3_c*p3_c/c3_;
	c4_  = p4_c/2 + p4_c*skew_factor4/(100.5-abs(100.5-p4_b))/2;
	p4_c = p4_c*p4_c/c4_;
	p1_fit_L = p1_a*exp(-0.5*((time1_1-p1_b)./p1_c).^2);
	p1_fit_R = p1_a*exp(-0.5*((time1_2-p1_b)./p1_c/(skew_factor1/(100.5-abs(100.5-p1_b))) ).^2);
	p2_fit_L = p2_a*exp(-0.5*((time2_1-p2_b)./p2_c).^2);
	p2_fit_R = p2_a*exp(-0.5*((time2_2-p2_b)./p2_c/(skew_factor2/(100.5-abs(100.5-p2_b))) ).^2);
	p3_fit_L = p3_a*exp(-0.5*((time3_1-p3_b)./p3_c/(skew_factor3/(100.5-abs(100.5-p3_b))) ).^2);
	p3_fit_R = p3_a*exp(-0.5*((time3_2-p3_b)./p3_c).^2);
	p4_fit_L = p4_a*exp(-0.5*((time4_1-p4_b)./p4_c/(skew_factor4/(100.5-abs(100.5-p4_b))) ).^2);
	p4_fit_R = p4_a*exp(-0.5*((time4_2-p4_b)./p4_c).^2);
	p1_fit = [p1_fit_L p1_fit_R];
	p2_fit = [p2_fit_L p2_fit_R];
	p3_fit = [p3_fit_L p3_fit_R];
	p4_fit = [p4_fit_L p4_fit_R];
	fitted = p1_fit+p2_fit+p3_fit+p4_fit;

if (show ~= 0)
%----------------------------------------------------------------------
% show fitting in process.
figure(show);
% show data being fit.
plot(data,'x-','color',[0.75 0.75 1]);
hold on;
title('trisomy');
% show fit lines.
plot(p1_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
plot(p2_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
plot(p3_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
plot(p4_fit,'-','color',[0 0.75 0.75],'lineWidth',2);
plot(fitted,'-','color',[0 0.50 0.50],'lineWidth',2);
hold off;
%----------------------------------------------------------------------
end;

	width = 0.5;
	switch(func_type)
		case 'cubic'
			Error_Vector = (fitted).^2 - (data).^2;
			sse  = sum(abs(Error_Vector));
		case 'linear'
			Error_Vector = (fitted) - (data);
			sse  = sum(Error_Vector.^2);
		case 'log'
			Error_Vector = log(fitted) - log(data);
			sse  = sum(abs(Error_Vector));
		case 'fcs'
			Error_Vector = (fitted) - (data);
			%Error_Vector(1:round(G1_b*(1-width))) = 0;
			%Error_Vector(round(G1_b*(1+width)):end) = 0;
			sse  = sum(Error_Vector.^2);
		otherwise
			error('Error: choice for fitting not implemented yet!');
			sse  = 1;
	end;
end
