# Berechnet die least-square differenz zwischen 2 vektoren.


function retval = specdiff( a, b)
  retval=0.0;
  if ( columns(a) == columns(b) )
    for i=1:columns(a)
      retval=retval+( abs(a(i)-b(i)) );
    endfor
  else
    printf ("Fehler: Laenge der Vektoren passt nicht\n");
    retval=-1;
  endif
endfunction

 