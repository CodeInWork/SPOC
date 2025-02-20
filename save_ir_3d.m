function save_ir_3d(filename, wzvector, kineticsx, irdata, modus)
% function save_ir_3d(filename, wzvector, kineticsx, irdata, modus)
% writes an IR matrix as an ASCII-file
% format:
%
% dcoord    [start1] [start2] [start3] ...
% [wz1]       [val1,1] [val1,2] [val1,3] ...
% [wz2]       [val2,1] [val2,2] [val2,3] ...
%  ...           ...      ...      ...
%
% Modus: 1 - wie oben
%	 2 - Mesh (speichert X-Vektor, Y-Vektor, DatenVektor)

    liste = fopen (filename,"w");

    if ( nargin < 5 ), modus = 1; end;
  
    fprintf(liste, "dcoord");
    for i=1:rows(kineticsx)
	fprintf(liste, " %f", kineticsx(i));
    endfor;
    fprintf(liste,"\n");
    
    for i=1:rows(wzvector)
	fprintf(liste, "%f", wzvector(i) );
	for j=1:rows(kineticsx)
	    fprintf(liste," %f", irdata(i,j));
	endfor
	fprintf(liste, "\n");
    endfor;
  


    fclose(filename);
    
endfunction

