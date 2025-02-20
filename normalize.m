function [o_spectrum, o_scale, o_offset] = normalize(wzs, spectrum, wzr, reference, start, stop)
% function [o_spectrum, o_scale, o_offset] = normalize(wzs, spectrum, wzr, reference, start, stop)
%
% A spectrum, consisting of wavenumbers wzs and intensity data spectrum, is normalized to a reference
% spectrum reference using the spectral area between wavelength start and stop as reference for
% least square fitting. The spectrum is interpolated to fit the datapoints at wzr of reference.
% o_spectrum = spectrum*scale+offset
% 
% TODO:
% 		...spectrum might be a matrix....

	spe = interp1(wzs, spectrum, wzr);

	inorm1=ir_get_index(start, wzr);
	inorm2=ir_get_index(stop, wzr);
	if ( inorm1>inorm2 )
		h=inorm1; inorm1=inorm2;inorm2=h;
	end;
	normspecref=reference(inorm1:inorm2);
	normspecspec=spectrum(inorm1:inorm2);
	normpar=[1,0];

	[normf, normp] = leasqr(normspecspec,normspecref,normpar,@norm_func);				% Normierungsfaktor und Offset aus Bereich holen
	o_spectrum=spectrum.*normp(1).+normp(2);									% Normierung + Offsetabgeich durchführen
	o_scale = normp(1);
	o_offset = normp(2);
end;
