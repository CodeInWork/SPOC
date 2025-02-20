function apropos(fname)
  if ( strcmp(fname,"ALL") )
    printf("-Die Kommandos:\n");
    printf("==================\n");
    printf("	#			Kommandos zur Bearbeitung mehrerer geladener Dateien\n");
    printf(" align			Die Zeitachse chronologisch machen (f. reset timebase)\n");
    printf("	apropos		F: Hilfe zum Kommando\n");
    printf("	av			F: Mitteln von Spektren (ueber Zeitkoordinate)\n");
    printf("	avi			Mitteln von Spektren (ueber Index)\n");
    printf("	backup			Sicherheitskopie erstellen\n");
    printf("	baseline, bl		Grundlinienkorrektur\n");
    printf("	bf			Basisspektren fuer Fits laden\n");
    printf("	block			3 Leerzeilen einfügen\n");
    printf("	bg			Basisvektoren aus Globalfit als neue Basis für Fits\n");
    printf("	br			Basisvektoren einer Rotation als neue Basis für Fits\n");
    printf("	bs			Basisvektoren einer SVD-Zerlegung als neue Basis für Fits\n");
    printf("	bzero			Eine evtl. geladene Basis auf 0 verschieben\n");
    printf("	cls			Bildschirm loeschen\n");
    printf(" color			Farbe fuer Plots aendern\n");
    printf("	cut			3D-Block zurechtschneiden (Zeitachse)\n");
    printf("	cutwz			3D-Block zurechtschneiden (Wellenzahl/laenge)\n");
    printf("	detrend			Grundlinienkorrektur über Detrend-Funktion\n");
    printf("	dglfit			Ergebnisse einer least-square Anpassung an ein kinetisches Modell fitten\n");
    printf("	dzero			Nullpunktverschiebung Intensität\n");
    printf("	exit			Programm beenden\n");
    printf("	filt			Datenglaettung (Savitzky-Golay-Filter)\n");
    printf("	fit			Datenanpassungen (2D/3D)\n");
    printf("	freqidx			Indexwert eines Frequenzwertes ausgeben\n");
    printf("	globalfit, gf		Globalfit starten\n");
    printf(" gfl				Globalfit, Levenberg-Marquardt\n");
    printf(" globalfit_init, gfi	Parameter f�r GF eingeben und ggf starten\n");
    printf("	gnuplot			Grafikprogramm \"gnuplot\" einstellen\n");
    printf("	grace			Grafikprogramm \"Grace\" einstellen\n");
    printf("	grid			Modus fuer 3D-Plots\n");
    printf("	info			Informationen zum Datenblock\n");
    printf("	install			Schreibt eine Installationsdatei\n");
    printf("	invert			Die Intensitätsachse des Datenblocks invertieren\n");
    printf("  integ     Integriert Bandenbereich �ber 3D-Datensatz\n");
    printf("	join			2 Datensätze aus verschiedenen Speicherbereichen zusammenführen\n");
    printf("  joinwz   Joins data sets #1 und #2\n   w1 - statistical weight of set 1\n w2 - statistical weight of set 2. If omitted, w1 will be relative to w2\n");
    printf(" kinetics		F: Zeitspur extrahieren\n");
    printf("	live			Schaltet den Live-Modus (graph. Anzeige während der Berechnung) ein/aus\n");
    printf("	load			Ladefunktion\n");
    printf("	logscale		Die Daten auf logarithmische Zeitachse umrechnen (Interpolation)\n");
    printf(" logtime		Darstellung der Zeitachse logarithmisch (Daten werden nicht ver�ndert)\n");
    printf(" lsqfit		F: Matrix oder Spektrum an Basisspektren Fitten");
    printf(" macro		Makrofunktionen\n");
    printf(" mapply		Ein Makro auf mehrere Dateien anwenden\n");
    printf(" mrun		ein Makro starten (nur fuer die aktuelle Datei)\n");
    printf(" normalize		Alle Spektren normieren; normiert wird auf das Spektrum bf1\n");
    printf("	plot, p			Grafik erzeugen\n");
    printf(" pp			Letzte Grafik als Metafile (emf) speichern\n");
    printf("	pretime			automatische Suche des Reaktionsbeginns\n");
    printf(" process		Anfangskorrekturen am Datensatz (bei reset timebase verwenden)\n");
    printf("	quit			Programm beenden\n");
    printf("	recomp			3D-Matrix wieder erzeugen\n");
    printf("	removewz		einen spektralen Bereich entfernen\n");
    printf("	restore			Daten aus Sicherheitskopie wiederherstellen\n");
    printf("	resample		Daten äquidistant interpolieren/reduzieren\n");
    printf("	reset_time		Zeitachse korrigieren (fortlaufende Werte)\n");
    printf("	rotation		Daten aus SVD rotieren\n");
    printf("	rotkill			Komponenten der Rotation löschen\n");
    printf("	rotswap			Komponenten der Rotation vertauschen\n");
    printf(" run			Eine history-Datei ausfuehren\n");
    printf("	save			Speicherfunktion (Daten als ASCII, Grafiken, Movie, aktuelle Befehlsfolge)\n");
    printf("       save_ir_file		Ein einzelnes Spektrum als ASCII speichern\n");
    printf("	save_prefs		Aktuelle Einstellungen speichern\n");
    printf(" savg			Spektren mitteln\n");
    printf("	secure 			Einstellung zu automatischen Backups ändern");
    printf("	select_path		Einen neuen Suchpfad hinzufügen\n");
    printf("	set			allgemeine Einstellungen vornehmen\n");
    printf("	sf			Datensatz an Basisspektren anfitten\n");
    printf("	show			Parameter anzeihen\n");
    printf("	smooth			Datenglättung\n");
    printf("	split			Einen Datensatz in 2 Teilbereiche aufspalten\n");
    printf(" splitzero            Einen Datensatz mit n Zeitspruengen in n Intervalle Spalten; Zentrum jedes Intervalls ist der Zeitsprung\n");
    printf("	surface			Modus für 3D-Plots\n");
    printf("	svd			SVD-Zerlegung berechnen\n");
    printf("	svdkill                 Hoehere Komponenten einer SVD-Zerlegung loeschen\n");
    printf("	svdswap                 2 Komponenten der SVD-Zerlegung vertauschen\n");
    printf("	tgi			Den Indexwert eines bestimmten Messzeitpunktes ausgeben\n");
    printf("	timeshift		Die Zeitachse um definierten Betrag ändern, oder so, dass Reaktion bei 0 startet.\n");
    printf("  to_abs    in Absorptionsspektrum umwandlen\n");
    printf("	undo			letzte Änderung rückgängig\n");
    printf("	unset			gesetzte Parameter löschen\n");
    printf("	wgi			Indexwert eines Frequenzpunktes\n");
    printf("	zero			Nullpunktverschiebung (Zeitachse)\n");
    printf("\n-Die Variablen und Schalter:\n");
    printf("===============================\n");
    printf("	timevec, freqvec, mdata Diese Variablen speichern die bearbeiteten Datensätze\n");
    printf("	BL_SPLINE               Stützstellen für das B-spline zur Grundlinienkorrektur.\n");
    printf("		= [ start1, stop1, mw1, start2, stop2, mw2, ...];\n");
    printf("	LIVE_MODE		Live-Anzeige bei Berechnungen, z.B. Grundlinienkorrektur\n");
    printf("	wavenumber_axis, time_axis, intensity_axis, arbitrary_axis, parameter_axis\n");
    printf("	gf_k_start, gf_k_stop	Begrenzungen der Parameter für GlobalFit\n");
    printf("	gf_ITERATIONS		Intervalleinteilungen für Parametersuche beim GlobalFit\n");
    printf("	GLOBALFIT_PRECISION	Genauigkeitseinstellung für fminsearch\n");
    printf(" REACTION_START_INDEX	Nummer des Datenpunktes, bei dem die Reaktion startet\n");
    printf(" LOG_KINETICS		Zeitachse in SVD, ROT und Globalfit logarithmisch plotten\n");
    printf(" PLOT_WITH_OFFSET	Beim Plotten von mehreren Spektren Verschiebung auf der Y-Achse einschalten\n");
    printf("\nAndere Kommandos werden als Octave-Kommandos interpretiert.\n");
  elseif ( strcmp(fname,"#") )
    printf("#				listet alle geladenen Dateien\n");
    printf("# <nr>			laedt die gespeicherte Datei zum Bearbeiten\n");
    printf("				die vorherige Datei wird dabei zurueckgeschrieben (Springt auf Slot <nr>\n");
    printf("# + <nr>\n");
    printf("# - <nr>			um <nr> Pl�tze vor- und zur�ckspringen\n");
    printf("#average oder \n");
    printf("#avg oder \n");
    printf("#av <Nr. 1> <Nr. 2>		Die Dateien von Nr. 1 bis Nr.2 mitteln. Neuen Speicherplatz erzeugen\n");
    printf("#save			Die aktuell bearbeitete Datei zurückspeichen bzw. Aenderungen uebernehmen\n");
    printf("				es werden keine Daten auf die Festplatte geschrieben\n");
    printf("\nSiehe auch: split, join\n");
  elseif ( strcmp(fname,"cls") )
    printf("cls				löscht den Bildschirm\n");
  elseif ( strcmp(fname,"gfl") )
    printf("gfl				Globalfit (least-square) starten; Parameter werden abgefragt\n");
    printf("gfl <Komponenten>\n");
    printf("gfl <Komponenten> <Iterationen>\n");
    printf("gfl <Komponenten> <Startparameter#1> <Startparameter#2> ...\n");
  elseif ( strcmp(fname,"svd"))
    printf("svd				SVD-Zerlegung des Datensatztes\n");
    printf("svd silent			keine graph. Anzeige der Ergebnisse\n");
    printf("  siehe auch: rotation, globalfit\n");
  elseif ( strcmp(fname,"live"))
    printf("live [on|off]               Den Live-Modus schalten (Ohne Argument wird umgeschaltet\n");
  elseif ( strcmp(fname,"save_prefs"))
    printf("save_prefs                  Speichert aktuelle Einstellungen (Pfade etc.) in ~/.spocrc\n");
  elseif ( strcmp(fname,"set"))
    printf("set                         nimmt allgemeine Einstellungen vor\n");
    printf("set pretime <wert>		Einstellen des Reaktionsbeginns\n");
    printf("set pretime			Automatische Suche des Reaktionsbeginns\n");
  elseif ( strcmp(fname,"pretime") )
    printf("pretime			Automatische Suche des Reaktionsstartes\n");
    printf("				jeweils 4 Spektren vor und nach dem Reaktionsstart werden angezeigt\n");
    printf("  siehe auch: set\n");
  elseif ( strcmp(fname,"pp") || strcmp(fname,"pj") || strcmp(fname,"pg") )
    printf("pp | pj | pg [Dateiname]			Das jeweils letzte Bild speichern (emf, jpg oder png)\n");
  elseif ( strcmp(fname,"unset") )
    printf("unset pretime		löscht eine gesetzte Vorperiode\n");
  elseif ( strcmp(fname,"plot") )
    printf("plot <Optionen>		Grafische Ausgabe von Daten via Gnuplot | grace\n");
    printf("     <o>				Datensatz als 3D-Oberfläche\n");
    printf("     <ok [wz]>			Intensität bei wz als Funktion der Zeit\n");
    printf("     <o [Zeit]>			Spektrum zu einem Zeitpunkt\n");
    printf("     <avg [Zeit1] [Zeit2]>		Spektren im Zeitbereich gemittelt\n");
    printf("     <svd>				Ergebnisse der letzten SVD\n");
    printf("     <rot>				Ergebnisse der letzten Rotation\n");
    printf("     <exp | x> [a] b [label]  Ausdruecke plotten\n");
    printf("                Beispiel: plot exp rotation_kinetics2.dat timevec v_rot(:,2)\n");
    printf("     <globalfit>			Ergebnisse des letzten Globalfits\n");
    printf("     <fit <Optionen>>		Ergebnisse der Datenanpassung\n");
    printf("          <parameter [nr]>\n");
    printf("          <stddev>\n");
    printf("          <values>\n");
    printf("     <lsqfit>                       Ergebnisse des letzten Fits an Basisspektren\n");
    printf("     <dglfit>                       Ergebnisse des Fits der Kinetikvektoren an kinetisches Modell\n");
    printf("     <pretime>                      Die Spektren um den durch PRE_TIME (Beginn der Reaktion)\n");
    printf("                                    definierten Bereich anzeigen.\n");
    printf("  siehe auch: scale, print, view\n");
  elseif (strcmp(fname,"resample"))
    printf("resample w <nr>\n");
    printf("         t <nr>             Für Wellenlänge (w) oder Zeitachse (t) <nr> Datenpunkte erzeugen\n");
    printf("  siehe auch: logscale\n");
  elseif (strcmp(fname,"dgl_function"))
    printf("dgl_function=@fname		Zuweisung eines Modells für kinetische Fits\n");
  elseif (strcmp(fname,"bf"))
    printf("bf <file1> <file2> ...	Die angegebenen Dateien werden als Basisspektren für Fits (least-square oder an DGL-Systeme geladen\n");
    printf("bf				Laden über Dateidialog\n");
    printf("bf zero			Eine Nullinie wird zusätzlich hinzugefügt\n");
    printf("bf spectra #1 #2 ...   Die angegebenen Spektren eines Blocks als Basisspektren verwenden\n");
    printf("bf times #1 #2 ...      Die Spektren zu den angegebenen Zeiten als Basisspektren verwenden\n");
    printf("*bf swap <nr#1> <nr#2>	Vertauscht die angegebenen Basisspektren (* n.i,)\n");
    printf("  siehe auch: sf, dglfit\n");
  elseif (strcmp(fname,"dglfit"))
    printf("dglfit init			Startparameter fuer Fit an Modell einstellen\n");
    printf("dglfit select		Auswahl eines Modells\n");
    printf("dglfit show			Parameter anzeigen\n");
    printf("dglfit run			Den Fit starten\n");
    printf("	dgl_k, dgl_initvals	enthalten die gefundenen Ratenkonstanten und Anfangswerte\n");
    printf("    res			Maß für die Güte des Fits (je kleiner, desto besser)\n");
    printf("	DAT			die rechnerisch ermittelten Daten\n");
  elseif (strcmp(fname,"sf"))
    printf("sf				Der Datensatz wird an die geladenen Basisspektren angepasst, jedes Spektrum als LK der Basisspektren\n");
    printf("				Das Ergebnis steht in \"fitmatrix\"\n");
    printf("  siehe auch: bf, dglfit\n");
  elseif (strcmp(fname,"logscale"))
    printf("logscale <pts>		Die Zeitachse in eine logarithmische Einteilung umrechnen\n");
    printf("				<pts> ist die Anzahl der Datenpunkte der neuen Achse\n");
    printf("				Standardwert: 50\n");
  elseif (strcmp(fname,"save"))
    printf("save <Optionen>\n");
    printf("     <mat7 [Dateiname]>	als Mathematica7-Datei\n");
    printf("     <data [Dateiname]>	als ASCII-Tabelle\n");
    printf("     <igor [Dateiname]>	3 Dateien fuer Igor-Import\n");
    printf("     <ds [Dateiname]>	alle bearbeiteten Daten (Octave-Binary)\n");
    printf("     <globalfit [Dateiname]>\n");
    printf("     <gffiles [Dateiname]\n		Ergebnisse des Globalfit als einzelne Dateien\n");
    printf("     <state [Dateiname]>	alles speichern (Den Zustand des Systems\n");
    printf("     <avg [Zeit1] [Zeit2] [Dateiname]>	Spektren im Zeitbereich gemittelt; Dateiname ist optional\n");
    printf("     <kin [frequenz] [Dateiname]>	Den Zeitverlauf bei einer einzelnen Wellenl�nge speichern\n");
    printf("     <fileset [Dateiname]>  die Spektren des 3D-Blocks als einzelne Dateien\n");
    printf("                            speichern (<name>_<nr des spektrums>_<zeitwert>.dat)");
    printf("     <movie <Optionen>>	Animiertes GIF-Bild o. MPEG\n");
    printf("       <kin> <frames> <nam> Speichert die zeitl. Entwicklung des Spektrums (Animated GIF)\n");
    printf("       <frames> <nam>       Rotation der 3D-Oberfläche\n");
    printf("     <lsq>			Resultate des Least-Square-Fits\n");
    printf("     <history [Dateiname]>	Die Befehlsfolge\n");
    printf("     <rotspec> <nr> <name>		n-tes Spektrum der Rotation speichern\n");
    printf("     <rotkin> <nr> <name>		n-te Kinetische Komponente der Rotation speichern\n");
    printf("     <exp [Dateiname] [xAxis] [yAxis]\n		Ausdruecke speichern, s. plot exp\n");
    printf("  siehe auch: load\n");
  elseif ( strcmp(fname,"cut") | strcmp(fname,"cutwz") )
    printf("cut <Optionen>		3D Datenblöcke zurechtschneiden (Zeitachse)\n");
    printf("     <Startwert>		Von Startwert bis zum Datenende (z.B. Entfernen einer Vorperiode)\n");
    printf("     <Startwert Endwert>    Bereich verwenden\n");
    printf("     <- Endwert>		Bereich vom Datenbeginn bis Endwert\n");
    printf("cutwz <Optionen>		3D Datenbloecke zurechtschneiden (Wellenlaenge|Wellenzahl)\n");
    printf("      <Startwert Endwert>   Bereich von Startwert bis Endwert\n");
    printf("  siehe auch: zero, dzero\n");
  elseif ( strcmp(fname,"filt") )
    printf("filt     <ordnung> <laenge> Savitzky-Golay Filterung der Daten\n");
    printf("  siehe auch: smooth\n");
  elseif ( strcmp(fname,"smooth") )
    printf("smooth   <Order>            Datenglättung (Median)\n");
    printf("  siehe auch: filt\n");
  elseif ( strcmp(fname,"save_ir_file") )
    printf("function save_ir_file(filename, wzvector, spectrum)                Externe Funktion\n");
  elseif ( strcmp(fname,"baseline") | strcmp(fname,"bl"))
    printf("baseline <Optionen>		Grundlinienkorrektur\n");
    printf("         <avspec>		Der Mittelwert des gesamten Spektrums wird vom jeweiligen Spektrum abgezogen\n");
    printf("         <area>             Der Mittelwert eines Frequenzbereiches wird vom jeweiligen Spektrum abgezogen\n");
    printf("         <spec1>		Verwendet das 1. Spektrum des Blocks\n");
    printf("         <specs a b>        Verwendet die Spektren Nr. a bis Nr. b (Mittelwert)\n");
    printf("		<spec a>			Das Spektrum Nr. a (Indexwert) wird abgezogen\n");
    printf("         <specsabs a b>     log(I0/I); I0=<a, b>\n");
    printf("         <specsquot a b>    Division statt Subtraktion\n");
    printf("         <time a b>         Angabe über Zeitachse\n");
    printf("         <timequot a b>     Division statt Subtraktion\n");
    printf("         <timeabs a b>      log(I0/I); I0=<a,b>\n");
    printf("         <absorbance>       Berechnung des Extinktionsspektrums, Blank wird aus pretime berechnet\n");
    printf("         <pretime>          Vorperiode wird approximiert durch lineare Funktion\n");
    printf("		<prespline>		Die Spektren der Vorperiode werden durch eine Splinefunktion gefittet,\n");
    printf("						die dann anteilig von den Spektren der Hauptperiode subtrahiert wird\n");
    printf("						Das Spline wird bestimmt durch BL_SAMPLINGPOINTS (100)\n");
    printf("						PRESPLINE_FUNCTION (@linear_zero) bestimmt die Art des Fits (optional @linear)\n");
    printf("         <speclin>          Die Spektren werden jeweils einzeln durch eine Lineare Funktion gefittet und diese abgezogen\n");
    printf("		<linear>		Wie speclin, aber Bereiche zur Geradenberechnung durch  BL_LINEAR_1_IDX1,  BL_LINEAR_1_IDX2,\n");
    printf("					       BL_LINEAR_2_IDX1,  BL_LINEAR_2_IDX2 definiert\n");
    printf("         <spline>           Jedes Spektrum wird durch ein B-Spline korrigiert. Stützstellen: BL_SPLINE\n");
    printf("		<rhodopsin>     <prespline>+linear\n");
    printf("  siehe auch: BL_SPLINE\n");
    printf("		<fftkin>		Fourier transformation along time axis to remove unwanted periodic artifacts\n");
  elseif ( strcmp(fname,"BL_SPLINE") )
    printf("BL_SPLINE                   = [ Start1, Ende1, Wert1,\n");
    printf("                                Start2, Ende2, Wert2,\n");
    printf("                                         ...\n");
    printf("                            Stützstellen für Grundlinienkorrektur mittels eines B-Splines.\n");
    printf("                            Der Bereich zwischen <Start> und <Ende> wird gemittelt und auf <Wert> bezogen\n");
    printf("                            zur Konstruktion des Splines benutzt\n");
  elseif ( strcmp(fname,"svdswap") )
    printf("svdswap  <a> <b>            Vertauscht die Komponenten a und b einer SVD-Zerlegung\n");
    printf("  siehe auch: rotswap, svd, rotation, svdkill\n");
  elseif ( strcmp(fname,"show") )
    printf("show time                   Zeigt die Einteilung der Zeitachse an\n");
  elseif ( strcmp(fname,"removewz") )
    printf("removewz <wl1> <wl2>	Entfernt den Bereich zwischen <wl1> und <wl2> in allen Spektren\n");
  elseif ( strcmp(fname,"fit") )
    printf("fit <funktion> <wz1> ...    Die Intensitäten bei einer bestimmten Wellenzahl fitten\n");
    printf("    <funktion>              exp, expdx, linexp, lin, 2exp, 3exp\n");
    printf("               <wz>         Die Wellenzahl(en) bei der/denen gefittet wird.\n");
    printf("                            <all> fittet das gesamte Spektrum.\n");
    printf("                            plot fit stellt die Fits dar\n");
    printf("  siehe auch: plot, show\n");
  elseif ( strcmp(fname,"svdkill") )
    printf("svdkill <n>                 Loescht alle Komponenten ab <n> einer SVD\n");
  elseif ( strcmp(fname,"load") )
    printf("load                        Zeigt Dateidialog (mit Zenity)\n");
  elseif ( strcmp(fname,"globalfit") )
    printf("globalfit <nr>		Globalfit mit den ersten <nr> Komponenten einer Rotation oder SVD-Zerlegung\n");
    printf("  siehe auch: svd, rotation, rotkill, rotswap, recomp\n");
  elseif (strcmp(fname,"macro") )
    printf("macro define mak1 7 8 19 6 2		definiert ein Makro mit dem Namen mak1 und den angegebenen\n");
    printf("								Kommendozeilen als Befehle\n");
    printf("macro record					Makroaufzeichnung starten oder beenden; 1. Aufruf startet, 2. Aufruf beendet und speichert.\n");
    printf("macro list						Zeigt definierte Makros\n");
    printf("macro load | save <<makroname>>	Laden und Speichern\n");
    printf("mrun <<macroname>>			Makro starten\n");
    printf("mapply <<macroname>>			Eine Dateiauswahl wird angezeigt, und das Makro wird anschliessend\n");
    printf("								auf alle ausgewaehlen Files angewendet\n");
    printf("Die Makrokommandos sind in den Variablen macro{i} gespeichert. Z.Zt. wird nur die Instanz command{j} genutzt\n");
  elseif (strcmp(fname,"integ") )
    printf("integ <Wellenzahl1> <Wellenzahl2>  integriert den Bandenbereich f�r jedes Spektrum im 3D-Datensatz \n");
    printf("und plottet das Ergebnis. Als Grundlinie dient eine lineare Interpolation zwischen den Grenzen.\n");
  elseif (strcmp(fname, "join") )
    printf("  Benutzung: join <#1> <#2> [Set2_offset | i | a]\n") ;
    printf("Verbindet die Datensaetze #1 und #2\n   i - Interaktive Abfrage der Verschiebung des 2. Sets, a - automtisch\n");
  elseif (strcmp(fname, "joinwz") )
    printf("  Usage: join <#1> <#2> [w1 | w2]\n");
    printf("  Joins data sets #1 und #2\n   w1 - statistical weight of set 1\n");
    printf("  w1 - statistical weight of set 1\n");
    printf("  w2 - statistical weight of set 2. If omitted, w1 will be relative to w2\n");
  else
    printf("Sorry, zu diesem Thema existiert noch keine Information.\n");
    printf("Bugreport: mailto: eglof.ritter@charite.de\n");
    printf("apropos(\"ALL\") zeigt alle verfuebaren Funktionen an.\n");
  endif;
endfunction;
