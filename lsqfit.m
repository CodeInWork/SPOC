function [new_spectrum, contribs, residuals] = lsqfit(x, datamatrix, basematrix, options)
%	function [new_spectrum, contribs, residuals] = lsqfit(x, datamatrix, basematrix)
%	Jedes Spektrum von datamatrix als Linearkombination der Spektren on basematrix darstellen;
	if ( nargin < 4 )
		options = [0, 1e-8];
	end;
	printf("  Options:\n");
	options
	base = columns(basematrix);
	todo = columns(datamatrix);
	params = ones(1, base+1);
	minfunc=@lin_fit_lsq;
	fivepct = todo / 20;
	pb = zenity_progress("Completion", "auto-close");
	ctr=0;
	for i=1:todo
		[fitpar(:,i), fitfun(:,i)] = fminsearch(minfunc, params, options, 1, x, datamatrix(:,i), basematrix);
		residuals(:,i) = datamatrix(:,i)-fitfun(:,i);
		zenity_progress(pb, i * 100 / todo);
	end;
	%  zenity_progress(pb,100);
	new_spectrum = fitfun;
	contribs = fitpar;
endfunction
