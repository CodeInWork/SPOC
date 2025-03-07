function [num, val] = splitstr(string)
  num=0;
  startpoint=1;
  val{1}="";
  
  if (columns(string)>0)
	start = 1;
	for spalte=1:columns(string)
		if ( string(spalte)==" " )
			num = num + 1;
			ende = spalte;
			val{num} = string(start:ende-1);
			start = ende+1;
		endif;
	endfor;
	num=num+1;
	val{num} = string(start:spalte);
  endif;
endfunction
