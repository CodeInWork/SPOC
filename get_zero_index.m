function startindex = get_zero_index(timevec)
%  startindex = get_zero_index(timevec)
%  liefert den Index des ersten Wertes in timevec, der >= 0 ist
	index = 0;
	do
	until (  (timevec(++index)>=0)  || (index==length(timevec)) )
	if ( index == length(timevec) )
		index = 0; 
	end;
	startindex = index;
endfunction;
