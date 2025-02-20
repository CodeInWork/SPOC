# prüft, ob 2 Wellenzahlvektoren zueinander Kompatibel sind
#
# TODO: optimieren!!

function retval = is_compatible(wzvector1, wzvector2)
  retval = 1;
  increment1=wzvector1(2)-wzvector1(1);
  increment2=wzvector2(2)-wzvector2(1);
  if (length(wzvector1) != length(wzvector2))
    retval=0;
  endif;
  if (increment1 != increment2)
    retval=0;
  endif
  for i=1:length(wzvector1)
    if ( wzvector1(i) != wzvector2(i) )
      retval = 0;
    endif
  endfor
endfunction
