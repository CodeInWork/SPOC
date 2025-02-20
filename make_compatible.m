#
# make_compatible
#
# Ein Spektrum wird durch Interpolation an ein anderes angepasst
#
#

#
# wzvector1/wzdata1 sind die Referenzdaten
#  wzdata2 wird an diese Referenzdaten angepasst und in retval ein
#  neuer Vektor übergeben, der sich auf wzvector_ref bezieht.
#
# nutzt Die Funktion get_interpolated


function retval = make_compatible(wzvector_ref, wzvector_fit, wzdata_fit)
  retval=-1;
  
  dest_len = length(wzvector_ref);
  dest_increment=0;
  dest_increment1=wzvector_ref(2)-wzvector_ref(1);
  for i=2:dest_len
    dest_increment=dest_increment + (wzvector_ref(i)-wzvector_ref(i-1));
  endfor;
  dest_increment=dest_increment/(dest_len-1);  
  if ( dest_increment != dest_increment1 )
    printf("    make_compatible: Warnung: Schrittweite der Referenz evtl. ungleichmaessig. (%f/%f)\n", dest_increment, dest_increment1);
  endif

  src_len = length(wzvector_fit);
  src_increment=0;
  src_increment1=wzvector_fit(2)-wzvector_fit(1);
  for i=2:src_len
    src_increment=src_increment + (wzvector_fit(i)-wzvector_fit(i-1));
  endfor;  
  src_increment=src_increment/(src_len-1);
  if ( src_increment != src_increment1 )
    printf("    make_compatible: Warnung: Schrittweite der Daten evtl. ungleichmaessig. (%f/%f)\n", dest_increment, dest_increment1);
  endif

#  retval=zeros(..)
  for i=1:length(wzvector_ref)
    [retval(i), interpol_error] = get_interpolated(wzvector_fit, wzdata_fit, wzvector_ref(i));
    if ( interpol_error != 0 )
      printf ("    Fehler in make_compatible, Position: %d\n",i);
    endif
  endfor
  
  # TODO    
  # Prüfen, ob anpassen möglich ist
  # Anpassen ist noch möglich, wenn 2>1, aber nicht mehr als die Schrittweite von 1
  # Interpolieren oder Reduzieren
  
endfunction
