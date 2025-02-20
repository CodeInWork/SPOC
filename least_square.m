# Berechnet die Least-square-Referenz 2er spektren

function retval = least_square( spectrum1, spectrum2 );
    difference_int = spectrum2 - spectrum1;
    retval = sumsq(difference_int);
endfunction
