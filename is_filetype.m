# Liefert das 1. Wort einer ASCII-Datei
# Format:
#
# bezeichner  [start1] [start2] [start3] ...
# [wz1]       [val1,1] [val1,2] [val1,3] ...
# [wz2]       [val2,1] [val2,2] [val2,3] ...
#  ...           ...      ...      ...
# TODO:
# 	-make this thing work when only dTime is given
#

function [ rv ] = is_filetype (listenname, typ)

  global global_error;
  rv = 0;

  liste = fopen (listenname,"r");

  if (liste!=-1)
    % bezeichner einlesen
    if (strcmp(typ,"CARY_KIN"))				% 2te Zeile lesen
        typ2 = "Wavelength";
        rtyp = fscanf(liste,"%s","C");
        rtyp = fscanf(liste,"%s","C");
        rv = strcmp(typ2, rtyp);
    else
        rtyp = fscanf(liste,"%s","C");
        rv = strcmp(typ, rtyp);
    end;
    fclose(listenname);
  else
    global_error = 1;
  endif;
endfunction

