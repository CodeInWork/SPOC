#
# Prinzip:
#
# suche die 2 nächstliegenden realen Punkte für den benötigten wert
#
# Berechne lineare interpolation
#
# nutzt neue Spektrentypen:    	spektrum.wavenumbers(:)
#				spektrum.intensities(:)
# Erstmal nur die Primitive Version

function ergebnisspektrum = spec_make_compatible (spektrum, referenzspektrum)
    ergebnisspektrum.wavenumbers = referenzspektrum.wavenumbers;
    for i=1:length(referenzspektrum.wavenumbers)
	ergebnisspektrum.intensities(i) = spec_get_interpolated(spektrum, referenzspektrum.wavenumbers(i));
    endfor;
    ergebnisspektrum.intensities=ergebnisspektrum.intensities';
endfunction
