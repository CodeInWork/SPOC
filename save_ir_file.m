function save_ir_file(filename, wzvector, spectrum)
% function save_ir_file(filename, wzvector, spectrum)
% This saves a X-Y ASCII (CSV-) table with the data of wzvector in the first column and the data of
% spectrum in the second column.
% The data need not to be column vectors
  datei = fopen (filename,"w");
  for i=1:max(size(wzvector))
    fprintf(datei,"%f %f\n", wzvector(i), spectrum(i));
  end;
  fclose(datei);
  
endfunction
