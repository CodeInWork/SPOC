function [wzvector, kineticsx, irdata, filetype_name] = read_data ( listenname );
%  [wzvector, kineticsx, irdata] = read_data ( listenname );
%	requires io
% last modified: 08/10/25
%
  global global_error;
  i=columns(listenname)+1;
  j=i;
  condition1=0;
  condition2=0;
  extension="";
  filetype_name="unknown";
  do
    i=i-1;
    if ( listenname(i) == "." )
      condition1=1;
    else
      extension(j-i)=listenname(i);
    endif
  until ( (i==1) | condition1 );
  if ( strcmp(extension,"tsil") )
    condition2=1;
  endif

  if ( condition1 && condition2 )
    %printf("Matrix wird aus Dateien konstruiert\n");
    [wzvector, kineticsx, irdata] = load_ir_files(listenname);
  else
    if ( is_filetype(listenname,"dStart_time") )
        filetype_name="dStart_time";
        %printf("OPUS Typ I\n"); fflush(stdout);
        %[wzvector, kineticsx, irdata] = load_ir_matrix(listenname);
        datamatrix=dlmread(listenname);
        k1 = datamatrix(1:2,2:end);
        kineticsx = mean(k1,1);
        wzvector = datamatrix(3:end,1);
        irdata = datamatrix(3:end,2:end);
    elseif ( is_filetype(listenname, "CARY2"))   %Paul Fischer für bestimmte CARY-Dateien
        [kineticsx, wzvector, irdata] = csv2x3d(listenname);
    elseif ( is_filetype(listenname, "dTime") )
        filetype_name="dTime";
        %printf("OPUS Typ I (1 Zeitwert)\n"); fflush(stdout);
        % 1. Spalte sind die Wellenzahlen
        datamatrix=dlmread(listenname);
        kineticsx = datamatrix(1,2:end);
        wzvector = datamatrix(2:end,1);
        irdata = datamatrix(2:end,2:end);
    elseif ( is_filetype(listenname, "#OPUS") )
        %printf("OPUS Typ II\n"); fflush(stdout);
        % 1. Zeile sind die Wellenzahlen
        filetype_name="#OPUS";
        datamatrix=dlmread(listenname);
        wzvector = datamatrix(1,2:end)';
        kineticsx = datamatrix(2:end,1)';
        irdata = datamatrix(2:end,2:end)';
        %[kineticsx, wzvector, irdata] = load_csv_matrix(listenname);
        %kineticsx=kineticsx';
        %wzvector=wzvector';
        %irdata=irdata';
    elseif ( is_filetype(listenname, "#OPUSL") )
        %printf("OPUS Typ III\n"); fflush(stdout);
        % 1. Zeile sind die Wellenzahlen
        filetype_name="#OPUSL";
        datamatrix=dlmread(listenname);
        wzvector = datamatrix(1,2:end)';
        kineticsx = ((datamatrix(2:end,2)').-(datamatrix(2:end,1)'))./2;
        irdata = datamatrix(2:end,3:end)';					% Check this!!!
    elseif ( is_filetype(listenname, "OLIS-3D-ASCII") )
        filetype_name="OLIS-3D-ASCII";
        % Frequenzen in 1. Spalte.
        % printf("Olis 3D Ascii\n"); fflush(stdout);
        datamatrix = dlmread(listenname);
        kineticsx = datamatrix(1,2:end);
        wzvector = datamatrix(2:end,1);
        irdata = datamatrix(2:end,2:end);	
        %[wzvector, kineticsx, irdata, filetype_name] = load_csv_matrix(listenname);
        %kineticsx=kineticsx';
    elseif ( is_filetype(listenname, "CARY_KIN") )
        filetype_name="CARY_KIN";
        % printf("Cary kinetics File\n"); fflush(stdout);
        [kineticsx, wzvector, irdata] = caryread(listenname); 
    else
        printf("Datentyp unbekannt\n");
        printf("Bitte Zuordnung der Achsen ueberpruefen!\n");
        filetype_name = "unknown";
        datamatrix = dlmread(listenname);
        kineticsx = datamatrix(1,2:end);
        wzvector = datamatrix(2:end,1);
        irdata = datamatrix(2:end, 2:end);
        % [wzvector, kineticsx, irdata, filetype_name] = load_csv_matrix(listenname);
    end	
  endif
	% Reset_timebase u.Ã¤. eliminieren
	% Process_data besser im Hauptprogramm aufrufen, u.a. zur Behandlung von Sprüngen!!
	%  [ wzvector, kineticsx, irdata ] = process_data(wzvector, kineticsx, irdata);
	% printf("  read_data: Datei geladen. process_data zum Bearbeiten\n");

endfunction
