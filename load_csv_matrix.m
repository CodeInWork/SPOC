function [yvector, xvector, intensity_data, type_of_file] = load_csv_matrix(listenname)
% Funktion laedt eine ASCII-Datei
% Format:
%
% USE read_data instead!!!
%
% bezeichner  [x1] [x2] [x3] ...
% [y1]       [val1,1] [val1,2] [val1,3] ...
% [y2]       [val2,1] [val2,2] [val2,3] ...
%  ...           ...      ...      ...
% TODO:
% 	-make this thing work when only dTime is given
%
  global global_error;

  liste = fopen (listenname,"r");

  if (liste!=-1)
    % bezeichner einlesen
    type_of_file = fscanf(liste,"%s","C");
    printf("Dateityp: %s\n", type_of_file);
    fflush(stdout);

    % a=input("weiter");
    
    % die 1. Zeile lesen (xvector)
    firstrow = fgets(liste);

    %size(firstrow)
    %firstrow(1:20)
    %a=input("weiter");
    
    i=1; lz=0; lastindex=0;		% Wird benutzt um doppelte Feldtrenner zu eliminieren
    %
    % TODO: bei Sequenz double(firstrow(x)) = 32 13 10
    % ist eine Spalte weniger; abziehen
    % Prüfen, ob voriges Zeichen schon Feldtrenner war
    do
	if ( ( (double(firstrow(i))==32) || (double(firstrow(i))==9)) )
		if (lastindex == 0); lz++; end;
		lastindex = 1;
	else
		lastindex = 0;
	end;
	i++;
    until ( i==length(firstrow) );
    
    spalten = lz;					% nur die echten Daten zaehlen, 1. Spalte abziehen
							% lz am Ende noch rausnehmen
    printf("Spalten: %f\n", spalten); fflush(stdout);
    
    fseek(liste, 0, SEEK_SET);			% zurück an den Anfang
    
    zeilen = 0;
    do							% hier noch lz am Ende rausnehmen!!
      firstrow = fgets(liste);
      zeilen++;
    until ( feof(liste) );
    
    zeilen = zeilen - 1;
							% so stoppt das auch bei einer Leerzeile.
    if ( (double(firstrow(1)) == 13) || (double(firstrow(1)) == 10) ) ; zeilen = zeilen - 1; end;	% Leerzeichen oä am Ende rausnehmen
    printf("Zeilen: %f\n", zeilen); fflush(stdout);
    
    fseek(liste, 0, SEEK_SET);			% zurück an den Anfang
        
    bezeichner = fscanf(liste,"%s","C");	% 1 Wort weiter
    
    						% 1. Zeile lesen; ist die Beschriftung
    for i=1:spalten
      xvector(i) = str2num(fscanf(liste, "%s","C"));
      %printf("Einlesen: xvector %f\n", xvector(i)); fflush(stdout);
    end;

    ipz = 100.0 / zeilen;
    pc2 = 0;
    pc10 = 0;
    percent=0;

    j=1;
    do						% Beginn Hauptschleife
	yv = str2num(fscanf(liste,"%s","C"));
	%printf("Lese %f\n", yv);
	%fflush(stdout);
        yvector(j) = yv;
	for i=1:spalten					% und einlesem
	  % printf("-%d: ",i);
	  intensity_data(j, i) = str2num(fscanf(liste,"%s","C"));
	  % printf(" %f\n",intensity_data(j,i));
	end;
	% printf("%d/%d\n",j, zeilen); fflush(stdout);
	j++;
	
	pc2+=ipz;
	pc10+=ipz;
	if (pc2>2)
	  printf("."); fflush(stdout);
	  pc2=0;
	end;
	if (pc10>10)
	  percent+=10;
	  printf("%d%%", percent); fflush(stdout);
	  pc10=0;
	end;
    until (j>zeilen);
    
    printf ("\n%dx%d Matrix eingelesen.\n", j, i);
    fclose(liste);
  
    yvector=yvector';
  else
    global_error = 1;
  endif;
endfunction

