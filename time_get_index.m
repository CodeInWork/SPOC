function [index, realval] = time_get_index (timval, kineticvector)
% function index = time_get_index (timval, kineticvector)
%    liefert die Indexposition in kineticsx, die der Zeit t entspricht
%    real_t ist der genaue Wert
%    ist der gesuchte Wert mehrfach vorhanden, wird nur der erste Eintrag
%    geliefert

	dv = (kineticvector-timval).^2;

	index = find(dv==min(dv))(1);
	realval = kineticvector(index)(1);

endfunction

