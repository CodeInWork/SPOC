function vals = fminsearch_fun(ffunction, fparams, fparams_lower, fparams_upper, xdata, ydata)
% Parametertransformation für den Einsatz mit fminsearch
% Transformation z.B. über eine sigma-Funktion
% y = lower + upper * 10.^x./10.^x+10.^start 
% x von -inf bis +inf
% y von lower bis upper
% y auf x umsetzen
    for i=1:length(fparams)
	