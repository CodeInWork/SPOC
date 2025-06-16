## -*- texinfo -*-
## @deftypefn {Function File} {} specnorm (@var{normparams})
## Funktion zur Normierung von Spektren auf einen Bandenbereich. Die Differenz der Flaechen unter den Banden wird minimiert.
## Ein moeglicher Offset wird berruecksichtigt.
##


## Author: Paul Fischer

%Normierungsfunktion mit Beruecksichtigung eines etwaigen Offset
  function y=specnorm(x,p)
	  y = p(1)*x+p(2);
  end;
