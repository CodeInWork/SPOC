# Aus einer Datei werden IR-Spektren in eine Matrix eingelesen
#
# Format der Listendatei:
#	timestamp	irspektrum
#
# Rueckgabewerte:
#	wzvector: enthaelt die Wellenzahlinformation
#	kineticsx: entrhält die Zeitinformation
#	irdate:    die Spektraldaten als Spaltenvektor

function [wzvector, kineticsx, irdata] = load_ir_files(listenname)

  global global_error;
  
  liste = fopen (listenname,"r");
  
  if (liste!=-1)
  # ----------------------------------------------------------------
  i=0;
  do
    i++;
    [c(i).time, c(i).name]=fscanf(liste,"%f %s","C");
    kineticsx(i)=c(i).time;
    % printf("%d -- %f -> %s --\n", i, c(i).time, c(i).name);
  until ( feof(liste) );
  fclose(liste);
  nrliste = i;


  printf ("%d Listeneintraege werden bearbeitet, bitte warten.\n", nrliste);

  # 1. Datei der Liste einlesen
  # Groesse der Matrix berechnen
  # Wellenzahlen aus 1. Datei in die Variable wzvector speichern

  # TODO
  #   bei jedem neu hinzukommenden Vektor die Wellenzahlen pruefen
  #   bei fehlender Uebereinstimmung Warnung ausgeben und dann interpolieren

  % printf (" Berechne Matrixgroesse...");

  file1=fopen(c(1).name,"r");

  i=0;

  do
    i++;
    %printf("Eintrag: %d\n",i); fflush(stdout);
    wzvector(i) = fscanf(file1,"%f %s","C");
    %printf("->%f\n",wzvector(i)); fflush(stdout);
  until (feof(file1));

  fclose(file1);

  spectrasize=i;

  % printf(" irdata(i,j)=irdata(%d, %d).\n", nrliste, spectrasize);

  % printf(" Erzeuge die Matrix.\n");
  #irdata=zeros(nrliste, spectrasize);

  # Liest alle Files ein und Speichert die Intensitäten als Matrix
  # Spektren als Spaltenvektoren
  #

  i=0;
  do
    i++;
    # printf ("Schritt: %d von %d\n",i, nrliste);

    irfile=fopen(c(i).name,"r");

    # printf ("Lese: %s\n",c(i).name);
    j=0;
    dummy=0.0;
    do
      j++;
      # Liest als Zeilenmatrix
      [dummy, irdata(j,i)]=fscanf(irfile,"%f %f","C");
      if ( j == 1 )
        wzvector(j) = dummy;
      else
        if ( dummy != wzvector(j) )
	  printf("Warnung: keine Wellenzahluebereinstimmung an Pos. %d: %f <-> %f\n", j, dummy, wzvector(j));
	  printf("         Das Ergebnis ist möglicherweise fehlerhaft.\n");
	endif
      endif
    until (feof(irfile));
    fclose(irfile);
    #printf("Beendet: Schritt %d von %d\n", i, nrliste);
  until (i == nrliste);

  wzvector=wzvector';
  kineticsx=kineticsx';
  # TODO: prüfen, ob die Matrix OK ist!  --> ok.
  
  % printf ("Fertig, Matrix erstellt.\n");
  else
    global_error=1;
  #--------------------------------------------------------------------------------
  endif;
endfunction
