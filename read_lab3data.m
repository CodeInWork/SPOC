## Copyright (C) 2023 Paul
## 
## 
##
##
##
## @deftypefn {} {@var{[wzvector, kineticsx, irdata, filetype_name]} =} read_lab3data (@var{listenname}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Paul Fischer
## Created: 2023-11-20

function [wzvector, kineticsx, irdata, filetype_name] = read_lab3data (listenname)
  
  
  time_unit_factor = 10^6;
  
  datamatrix = dlmread(listenname);
  
  filetype_name="#lab3data";
  datamatrix=dlmread(listenname);              
  wzvector = datamatrix(1,2:end)';        
  kineticsx = datamatrix(2:end,1)';
  kineticsx = kineticsx./time_unit_factor;  
  irdata = datamatrix(2:end,2:end)';
  
  
endfunction
