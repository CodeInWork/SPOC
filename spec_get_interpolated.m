#
# spec_get_interpolated
#
# Der Wert eines Spektrums an der Position x
# wird geliefert, auch wenn dort kein Wert existiert.
# Notfalls Interpolation
#

#
# wzvector1/wzdata1 sind die Referenzdaten
#  wzdata2 wird an diese Referenzdaten angepasst und in retval ein
#  neuer Vektor übergeben.
#
#  liegt der gesuchte Wert ausserhalb des Bereiches, wird interpolation_error 
#  gesetzt und 0 zurückgeliefert

# nutzt neue Spektrentypen:    	spektrum.wavenumbers(:)
#				spektrum.intensities(:)


function intensity = spec_get_interpolated( spektrum, position )

    step = spektrum.wavenumbers(2) - spektrum.wavenumbers(1);
    indexval = rounddown( ( ( position - spektrum.wavenumbers(1) ) / step) + 1);
    offset = position - spektrum.wavenumbers(1) - (indexval-1) * step;
    offset = offset / step;

#    if ( step < 0 )
#	offset = abs(offset);
#    endif;
    
#    printf("Indexval: %f, Offset: %f\n", indexval, offset);

    # Lineare regression zwischen i und i+1
    
    if ( indexval < 1 )			# Linker Rand
	intensity = spektrum.intensities(1);
#	printf ("  Warnung: spec_get_interpolated: Wert ausserhalb des Bereiches!\n");
    elseif ( indexval > length(spektrum.wavenumbers)-1 )
	intensity = spektrum.intensities(length(spektrum.wavenumbers));
#	if ( indexval > length(spektrum.wavenumbers) )
#	    printf ("  Warnung: spec_get_interpolated: Wert ausserhalb des Bereiches!\n");
#	endif;
    else
	x1 = spektrum.wavenumbers(indexval);
	x2 = spektrum.wavenumbers(indexval+1);
	y1 = spektrum.intensities(indexval);
	y2 = spektrum.intensities(indexval+1);
	m = (y2 - y1) / (x2 - x1);
	n = y1 - (m * x1);

	intensity = m * position + n;
    endif;
endfunction
