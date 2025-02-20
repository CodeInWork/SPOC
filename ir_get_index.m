function [ index, real_wz ] = ir_get_index(wz, wzvector)
% function [ index, real_wz ] = ir_get_index (wz, wzvector)
%
%    liefert die Indexposition in wzvector, die der Wellenzahl wz entspricht
%    real_wz ist der genaue Wert
%    Ist der Wert mehrfach vorhanden, wird nur der 1. Eintrag
%    geliefert

	dv = (wzvector-wz).^2;

	index = find(dv==min(dv))(1);
	real_wz = wzvector(index)(1);

endfunction
