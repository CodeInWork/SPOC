function [ index, val ] = get_index(vin, vvector)
% function [ index, val ] = get_index (vin, vvector)
%
%    liefert die Indexposition in vvector, die der Wellenzahl vin entspricht
%    val ist der genaue Wert
%    Ist der Wert mehrfach vorhanden, wird nur der 1. Eintrag
%    geliefert

	dv = (vvector - vin).^2;

	index = find(dv==min(dv))(1);
	val = vvector(index)(1);

endfunction
