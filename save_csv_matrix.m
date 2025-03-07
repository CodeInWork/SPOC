# Funktion speichert eine ASCII-Datei
# Format:
#
# bezeichner  [start1] [start2] [start3] ...
# [wz1]       [val1,1] [val1,2] [val1,3] ...
# [wz2]       [val2,1] [val2,2] [val2,3] ...
#  ...           ...      ...      ...
# TODO:
# 	-make this thing work when only dTime is given
#



function save_csv_matrix(listenname, yvector, xvector, data)
%
% function save_csv_matrix(listenname, yvector, xvector, data)
% for infrared, use:
%	wzvector, kineticsx, irdata
%
%
  global global_error;

  liste = fopen (listenname,"w");

  if (liste!=-1)
    xl = length(xvector);
    yl = length(yvector);
    fprintf(liste,"dTime");
    for x=1:xl
	fprintf(liste," %e", xvector(x));
    end;
    fprintf(liste,"\n");
    for j=1:yl
	fprintf(liste,"%e", yvector(j));
	for i=1:xl
	  fprintf(liste," %e", data(j,i));
	end;
	fprintf(liste,"\n");
    end;
    fclose(liste);
  else
    global_error = 1;
  end;
endfunction;  
  
  
