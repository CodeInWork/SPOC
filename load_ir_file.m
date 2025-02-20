function [wzvector, irdata] = load_ir_file(filename)
% function [wzvector, irdata] = load_ir_file(filename)
% loads an ASCII x-y file as infrared spectrum
% the data and the frequencies are returnes as a column vector.
  global global_error;
  datei = fopen (filename,"r");
  wzvector(1)=-1.1234; irdata(1)=-1.1234; % not needed; just for error handling
  global_error=0;
  if (datei==-1)
    global_error="load_ir_file: File not found";
    printf("File (%s) not found.\n", filename);
  else
    i=0;
    do
      i++;
      [wzvector(i), irdata(i)]=fscanf(datei,"%f %f","C");
    until ( feof(datei) );
    fclose(datei);
    wzvector=wzvector';
    irdata=irdata';
  endif
endfunction
