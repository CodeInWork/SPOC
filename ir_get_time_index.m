#
# ir_get_time_index
#
#    liefert die Indexposition in wzvector, die der Wellenzahl wz entspricht
#    real_wz ist der genaue Wert
#
#    Funktion für nichtaequidistante Abstände
#    NUR FÜR AUFSTEIGENDE WERTE, allg. s. ir_get_index_old	

function [ index, real_time ] = ir_get_time_index (timeval, timevec)
% function [ index, real_wz ] = ir_get_index (wz, wzvector)
%	
  global global_error;
  
  printf("  FUNKTION NICHT VERWENDEN!!!\n");
  sleep(2);
  
  
  dimension = length(timevec);
  increment = timevec(2) - timevec(1);

  if (increment < 0) 
    printf("  ir_get_time_index ist nicht für absteigende vektoren definiert\n");
  endif

  index = 0;
  do
	index = index + 1;
  until ( (timeval <= timevec(index)) | (index > dimension) );  

  if (index > 1)
	diff_down = abs(timeval - timevec(index-1));
	diff_up = abs( timevec(index) - timeval );
	if (diff_down < diff_up)
	    index=index-1;
	endif;
  endif;
  
  real_time = timevec(index);
  
endfunction
