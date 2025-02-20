function [wzo, kino, dato] = time_make_compatible(wz,kin,dat, wzr, kinr, datr)
% Datensaetze ggf interpolieren
	% Grenzen bestimmen
	if ( sum(wz==wzr)==length(wz) )
		for i=1:length(wz)				% interpolate timecourse for each WL
			dato(i,:) = interp1(kin, dat, kinr, "spline");
		endfors 
	else
		printf("Error: time_make_compatible: wavenumbers are not equal\n");
	endif;
endfunction