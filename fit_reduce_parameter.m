function [ wavenumbers, paramneu ] = fit_reduce_parameter( fit, parameternr, stddevval )
%
% function [ wavenumbers, fitneu ] = fit_reduce( fit, stddevval )
%    liefert nur die Werte zurück, bei denen der Standardfehler unter stddevval liegt
%
    j=1;
    for i=1:length(fit)
	std_actual = sum( abs( fit(i).stdresid ) );
	if ( (std_actual < stddevval) && (fit(i).convergence==1) )
	    paramneu(j) = fit(i).parameters(parameternr);
	    wavenumbers(j) = fit(i).wavenumber;
	    j=j+1;
	endif;
    endfor;
endfunction;
