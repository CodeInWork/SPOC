function [ wavenumbers, fitneu ] = fit_reduce( fit, stddevval )
%
% function [ wavenumbers, fitneu ] = fit_reduce( fit, stddevval )
%    liefert nur die Werte zurück, bei denen der Standardfehler unter stddevval liegt
%
    j=1;
    for i=1:length(fit)
	std_actual = sum( abs( fit(i).stdresid ) );
	if ( std_actual < stddevval )
	    fitneu(j) = fit(i);
	    wavenumbers(j) = fitneu(j).wavenumber;
	    j=j+1;
	endif;
    endfor;
endfunction;
