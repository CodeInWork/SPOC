#
# get_interpolated
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


function [retval, interpolation_error] = get_interpolated(wzvector, wzdata, position)
  retval=-1;
  interpolation_error=0;

  wzstart=wzvector(1); wzstop=wzvector(rows(wzvector)); wzstep=wzvector(2)-wzvector(1);
#
#
# position suchen:
#    pos_wz=wzstart+wzstep*(index-1)

# Die "wahre" Position
  position_index = ((position - wzstart)/wzstep)+1;

  if ( (position_index < 1) | (position_index > length(wzdata)) )
#    printf ("    Wert ausserhalb des Bereiches %d\n", position_index);
     interpolation_error=interpolation_error+1;
    retval=0;
  else
    printf("Suche Indexpos. %d\n", position_index);

# die beiden nächstliegenden Werte 
    index_low=rounddown(position_index);
    index_high=roundup(position_index);
# Lineare Interpolation
# Steigung und Nulldurchgang berechnen
  
    if (index_low != index_high)
      m = (wzdata(index_high)-wzdata(index_low))/(index_high-index_low);
      n = wzdata(index_low) - (m*index_low);
  # Interpolieren
      retval = m * position_index + n;  
    else
      retval = wzdata(index_low);
    endif
  endif
#  printf("Index: %f < %f < %f\n",index_low,position_index,index_high);
#  printf("Wert: %f < %f < %f\n",wzdata(index_low),retval,wzdata(index_high));
  
endfunction
