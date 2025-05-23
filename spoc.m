#!/usr/bin/octave
%
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
%
% Copyright (C) 2007-2016 Eglof Ritter

% 	notwendige Pakete:	io, optim
%
%	empfohlene Pakete:	general, graceplot, spline-gcvspl(Fuer Spline-Grundlinienkorrektur)
%				zenity (teilw. graph. Menues)

%
% spoc - SPectra calculation tool for OCtave
%  "#"
%
% if used in Visual Studio Code under Win:
% add to Windows environmental variables:
%    	"QT_PLUGIN_PATH"="C:/Octave/Octave-5.1.0.0/mingw64/qt5/plugins"
%    	"PATH"="C:/Octave/Octave-5.1.0.0/mingw64/bin"
%
% and modify launch.json:
% 		"octave": "D:\\Octave\\Octave-5.1.0.0\\mingw64\\bin\\octave-gui"


global LAST_MODIFIED = "21.02.25";
global VERSION = "1.00.01";
global PID=getpid();
global SYSINFO;
SYSINFO=sprintf("spoc Version: %s\\nlast modified: %s\\n\\nThere are news.\\n",VERSION,LAST_MODIFIED);
global VERBOSITY_LEVEL=0;

% Put here all packages to be loaded
pkg load optim
pkg load signal
pkg load splines


%
%	TODO:

#   - write apropos for: cuspline, timelin, interpolate, etc.

%   - konsistent machen fuer alle isfield() Funktionen...
%   - infofield durch infofield.type, infofield.info etc. ersetzen. genauere informationen speichern
%   - mdata, freqvec und timevec sowie alle anderen Parameter in eine Klasse
%		- Moeglichkeit, Startparameters�tze zu laden und zu speichern
%		- Datenspeichern: "save 3ddata" speichert unter aktuellem Namen. "save 3ddata auto" f�gt noch Kommando Nr an
%		- Variablen einf�hren, z.b. schwarz=1; color $schwarz; Dazu die Eingabezeile direkt vor der Ausf�hrung auf $ scannen
%		- Wenn ein Befehl einen Fehler verursacht, diesen aus der History entfernen. *Kompatibilit�t mit anderen Kommandos?*
%		- VERBOSITY_LEVEL durchgehend beachten!
%		- Wenn im Makro, keine History schreiben und keine Hinweise ausgeben...
%		- infofield und infofield_a �berall konistent machen!
%		- M�glichkeit f�r benutzerdefinierten Label einf�hren
%		- Speicherfunktionen konsistent machen: save avg und save kin
%		- run ohne argument zeigt men�
%		- ggf. muss run nicht angegeben werden um ein *.hist script zu starten
%		- in der Kommandozeile jeden Ausdruck mit $ als Variable nehmen
%		- THIS als Kurzzeiger auf den Basename der aktuellen Datei (erm�glicht dann z.B. s gffiles $THIS)
%		rudimentaeres Grace Interface fuer neuere Octave versionen.
%		Logischen Ausdruck(s. p x ) in nach grace pipen
%		als erstes Konfigurationsdatei einlesen, dann mit if (exist(...)) variablen abfragen und ggf setzen
%		Mehrere Datensätze in parallelen Slots verwalten
%		# <nr> schalten zwischen ihnen um. Dann können mehrere Dateien in 1 Grafik geplottet werden
%		resample über interp1 in 2 Dimensionen
%		resample t <nr>
%		resample w <nr>
%		resample t <nr>	w <nr>
%		load blank ....			Ein Spektrum als Hintergrund laden/setzen
%               to_abs				% in Absorptions/Transmissionsspektrum umwandeln
%		to_trans
%
%		Spektrenrechner: Syntax calc <spec1> <spec2> <operation>
%		beim Laden einer History-File fragen, ob die Bearbeitungen mit dem letzten
%		gespeicherten oder mit einem anderen Datensatz durchgeführt werden sollen.
%		evtl. auch Eingabe eines Verzeichnisses, in dem dann alle Spektren bearbeitet werden.
%
%		SVD-Komponenten werden aus dem gesamten Spektrum berechnet, fuer Globalfit wird aber nur ein
%		bestimmter (begrenzter) Bereich genutzt
%
%		Splineglättung auch, wenn der Datensatz kleiner als das Spline ist

%		Als Octave-Binary laden, wenn extension *.spoc-state heisst					OK

%		Bei mehrfachverwaltung frühere Möglichkeit zum Rückschreiben einführen

%		Alle Rechnungen nehmen immer Reaktionsstart bei 0 an. Alle Daten davor sind automatisch Vorperiode
%		Kompatibilität mit reset timebase in Opus
%		PRE_TIME und PRE_INDEX beseitigen! (z.B. auch für baseline pretime...
%		Für Globalfit werden dann einfach alle daten >0 verwendet
%		dh. Vor Globalfit die Originaldaten prüfen; eventuell <0 abschneiden

%		Änderung der Undo-Funktion:
%		Backups werden automatisch erstellt und als Datei im /tmp Ordnet abgelegt
%		Dateibenennung über die Nummer des Befehls und die PID (Kommando "getpid")
%		Ein/ Ausschalten über secure on / off
%		Make this stuff more performant, i.e. only when put/ get or an octave command is requested

%		Neue PRE_TIME funktionen:
%		die eigentliche Reaktion startet immer bei 0; alles davor ist PRE_TIME
%		-ALLE Baseline Funktionen anpassen
%		-set pretime sucht nach Sprung in den Daten und führt Nullpunktverschiebung durch
%		-Variable PRE_TIME entfernen
%		-globalfit: Wenn Werte unter 0 existieren, werden diese beim Fit nicht berücksichtigt
%				der Fit läuft immmer von 0:end
%		-Alle FIT-Funktionen: immer von 0 Fitten, Werte davor ignorieren
%
%		-Workaround: nur vor GF process_data durchf�hren, ansonsten pretime nuzten...
%		-Globalfit und info geben eine Warnung aus, wenn der Reaktionsstart nicht gesetzt ist ( !!! = REACTION_START_INDEX = 0 !!!)
%
%		-Funktion find_start: zun�chst wird ein Startindex vorgeschlagen. In 2 Fenstern Kinetik und Spektren davor+danach
%		zeigen und interaktiv manuelle Korrektur des Wertes erlauben
%		dar�ber wird Reaction_start_index gesetzt. Wenn gesetzt, sind alle Angaben f�r GF erf�llt
%
%		Globale Variable: reverse_frequency_axis;
%		wird beim Einlesen der Daten gesetzt, alle Commands a la
%			if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca(),"XDir","reverse"); end;
%		ersetzen!!!!
%
%
% CHANGELOG
%
% 180821    added gf_reconstruct
% 171129    started function SNR -- calculates the SNR (over the kinetics) for each WL
% 171110    baseline fftkin  --  FFT Filterung der Kinetiken
% 160520    introduced "p k r a b" which plots ratio between a and b
% 130301	introduced parameter boundaries for fitting with "gfl"
%			introduced new command "gfl_init" to assign initial parameters and parameter boundaries
%


% **** Replace zenity_bindings with octave gui tools:
% This is for compatibility; todo: Replace fully with uigetfile

%message = @zenity_message;
message = @msgbox;
% file_selection = @zenity_file_selection;
file_selection = @sui_file_selection;





global	  command_ctr=1;			% Anzahl der Abgearbeiteten + Abzuarbeitenden Befehle
global	  mak_nr=0;				% Anzahl definierter Makros

% hier den Pfad des Programmes eintragen. Wird bei install in die .octaverc geschrieben.
%global SPOC_PATH = "D:/OctaveSkripte/SPOC";
global SPOC_PATH = fileparts(mfilename('fullpath'));
global SPOC_HISTORY_PATH = "C:/Temp"
global DEFAULT_DATA_PATH = "C:/Data"

% Sicherer Modus (dafuer aber langsamer...)
global SECURITY_MODE = 0;

% Beschreibung der Datentypen...
global UVVIS = 1;
global IR = 2;
global IRABS = 3;
global IRTRS = 4;
global RAMAN = 5;

global DATA_TYPE = IR;

global LM_order;					% F�r Globalfit via leasqr!
global REACTIONS;
global OBSERVABLES;
global GF_REJECT_LAST=1;  	% dont use last component of SVD for Fitting
global time_exclude_to=0;
global time_exclude_from=0;

global loaded_files = 0;
global in_bench = 0;

# Vectors for frequency calibration
global is;
global should;

%global DEFAULT_PLOTTER="gnuplot";
global DEFAULT_PLOTTER="qt";
%global DEFAULT_PLOTTER="fltk";
global FRAME_DELAY=500;

global DEFAULT_COLOR = "b";			% Blue
global AUTO_FIGURE = 1;				  % Programmgesteuerte Ausgabe   TODO

global CALIBRATION_FIGURE = 5;  # shows frequency calibration

% activate chosen graphics toolkit
graphics_toolkit(DEFAULT_PLOTTER);


if ( !ispc() )
    if ( max( size( file_in_path("~/",".spocrc")  )  ) > 0)
	    printf("Loading global configuration\n");
	    load("~/.spocrc");
    end;
    if ( max( size( file_in_path("./",".spocrc")  )  ) > 0)
	    printf("Loading local configuration\n");
	    load("./.spocrc");
    end;
else
    printf(" Warning: Configuration files are currently not supported under MS Windows.\n");
endif




% the following should be replaced

if ( command_ctr == 1 )								% nur beim 1. Lauf erforderlich
    printf("  Neue Sitzung wird gestartet...\n");
    if ( exist("SEARCHPATH","var") )
	for i=1:columns(SEARCHPATH)
		addpath(SEARCHPATH{i});
		printf("  Suchpfad %s hinzugefuegt.\n", SEARCHPATH{i});
	end
    end;
else										%
    printf("Bestehende Sitzung wird fortgesetzt...\n");
end;

% _____________________________________________________________________________________________Variablen zur Grafiksteuerung

if (!exist("LOGSCALE_OFFSET","var")); LOGSCALE_OFFSET = 5; end;

% Zwischenergebnisse w�hrend Fits plotten
if (!exist("LIVE_MODE","var")); global LIVE_MODE=0; end;

% Bar-Plot nach Rotation
if (!exist("PLOT_ROT_HISTOGRAMS", "var")); global PLOT_ROT_HISTOGRAMS=0; end;

%
%	Verschiedene Einstellungen
%

global USE_GUI=1;			% zenity
global grace_started=0;
global USE_MULTICORE=0;

global DETECTION_LEVEL = 5;		% Zahlenwert fuer die Feststellung von Zeitspruengen oder z.B. Peak_Pick


global BL_SAMPLINGPOINTS=100;
%global PRESPLINE_FUNCTION = @linear_zero;
global PRESPLINE_FUNCTION = @linear;
% Einstellungen fuer Grundlinienkurrektur mittels Geraden
global BL_LINEAR_1_VAL1 = 1003;
global BL_LINEAR_1_VAL2 = 1050;
global BL_LINEAR_2_VAL1 = 1785;
global BL_LINEAR_2_VAL2 = 1800;



global listenname_a;
global timevec_a;
global freqvec_a;
global mdata_a;
global wavenumber_axis_a;
global time_axis_a;
global infofield_a;
global startindex_a;
global loaded_files;
global number_a=0;		% Speicherplatz f�r geladene Dateien
global CORR_MODE=1;


#
#	Achsenbeschriftungen
#

#global wavenumber_axis = '{\fontsize{15}wavenumber [1/cm]}';
global wavenumber_axis = 'wavenumber [cm^{-1}]';
global inverse_wavenumber_axis = 1;
global time_axis = 'time [s]';
global intensity_axis = 'absorbance change';
global arbitrary_axis = 'arbitrary units';
global parameter_axis = 'parameter value';
global s_x_axis = 'singular value no.';
global s_y_axis = 'value';

% Logarithmische t-Achse
global LOG_KINETICS = 0;
print_together = 0;
print_bspec_only = 0;
print_kin_only = 0;



# Calibration data for calibrating frequency axis
# 1. Value: current freq value (Is)
# 2. Value: desired freq value (Should)

cal=  [1599,   1636,
  1582,   1617,
  1630,   1617,
  1640,   1630];


%
% Stützstellen fuer BL-Korrektur
%
% Format:	Start Ende Wert
%
% Automatische Berechnung: 1. Wert: on/off
%                          2. Wert: number of nodes
%



is = [1506, 1517, 1541, 1556, 1633, 1640];
should = [1514, 1527, 1530, 1549, 1617, 1629];

global BL_SPLINE_AUTO = [ 1, 10];
global BL_SPLINE_FERY = [    1057,   1070,   1057,
   1060,   1080,   1070,
   1080,   1100,   1090,
   1079,   1125,   1102,
   1125,   1170,   1148,
   1288,   1350,   1224,
   1272,   1413,   1343,
   1413,   1531,   1472,
   1509,   1595,   1557,
   1593,   1644,   1618,
   1644,   1695,   1670,
   1695,   1746,   1720,
   1746,   1796,   1773,
   1746,   1796,   1796

];
global BL_SPLINE_FERY2 = [
   1102,   1180,   1128,
   1102,   1180,   1185,
   1169,   1220,   1205,
   1179,   1233,   1217,
   1249,   1285,   1256,
   1274,   1326,   1276,
   1272,   1413,   1343,
   1413,   1531,   1472,
   1509,   1595,   1557,
   1593,   1644,   1618,
   1644,   1695,   1670,
   1695,   1746,   1720,
   1746,   1796,   1773,
   1746,   1796,   1796
];

global BL_SPLINE_FERY3 = [    1101,   1150,   1125,
   1125,   1175,   1150,
   1150,   1200,   1175,
   1188,   1216,   1201,
   1199,   1267,   1220,
   1249,   1285,   1256,
   1274,   1326,   1276,
   1272,   1413,   1343,
   1413,   1531,   1472,
   1509,   1595,   1557,
   1593,   1644,   1618,
   1644,   1695,   1670,
   1695,   1746,   1720,
   1746,   1796,   1773,
   1746,   1796,   1796
];

global BL_SPLINE_FERY_BR=[1058,1100,1062;1076,1122,1111;1269,1379,1306;1362,1469,1434;1700,1788,1740];
global BL_SPLINE_AEQUI = [ 901,		1000,		950,
			    1000,	1100,		1050,
			    1100,	1200,		1150,
			    1200,	1300,		1250,
			    1300,	1400,		1350,
			    1400,	1500,		1450,
			    1500,	1600,		1550,
			    1600,	1700,		1650,
			    1700,	1799,		1750 ];

global BL_SPLINE_RHODOPSIN = [	901, 	917, 	901,
				917,	935,	935,
    				987,	1033,	1010,
				1033,	1079,	1056,
				1079,	1125,	1102,
				1125,	1170,	1148,
				1272,	1413,	1343,
				1413,	1531,	1472,
				1509,	1595,	1557,
				1593,	1644,	1618,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1746,	1798,	1773,
				1746,	1798,	1798  ];

global BL_SPLINE_RGCCGMP = [	901,    1100,    973,
        1006,   1022,   1013,
        1070,   1196,   1131,
        1125,	1170,	1148,
        1272,	1413,	1343,
        1413,	1531,	1472,
        1509,	1595,	1557,
        1593,	1644,	1618,
        1644,	1695,	1670,
        1695,	1746,	1720,
        1746,	1798,	1773,
        1746,	1798,	1798  ];

global BL_SPLINE_KANALRHODOPSIN = [	901,	1100	950,
				917,	935,	935,
    				987,	1033,	1010,
				1033,	1079,	1056,
				1079,	1125,	1102,
				1125,	1170,	1148,
				1272,	1413,	1343,
				1413,	1531,	1472,
				1509,	1595,	1557,
				1593,	1644,	1618,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1746,	1798,	1773,
				1746,	1798,	1798  ];

global BL_SPLINE_RHODOPSIN3 = [	901, 	917, 	901,
				917,		923,		920,
				925,		930,		927,
				930,		940,		935,
				940,		960,		950,
				960,		980,		970,
				980,		1000,	990,
				1000,	1020,	1010,
				1020,	1040,	1030,
				1040,	1060,	1050,
				1060,	1080,	1070,
				1080,	1100,	1090,
				1079,	1125,	1102,
				1125,	1170,	1148,
				1272,	1413,	1343,
				1413,	1531,	1472,
				1509,	1595,	1557,
				1593,	1644,	1618,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1746,	1798,	1773,
				1746,	1798,	1798  ];

global BL_SPLINE_RHODOPSIN4 = [	901, 	917, 	901,
				902,		915,		907,
				913,		934,		922,
				925,		930,		927,
				930,		940,		935,
				1000,	1020,	1010,
				1020,	1040,	1030,
				1040,	1060,	1050,
				1060,	1080,	1070,
				1080,	1100,	1090,
				1079,	1125,	1102,
				1125,	1170,	1148,
				1288,	1350,	1224,
				1272,	1413,	1343,
				1413,	1531,	1472,
				1509,	1595,	1557,
				1593,	1644,	1618,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1746,	1798,	1773,
				1746,	1798,	1798  ];

global BL_SPLINE_RHGCD2O = [1000,	1020,	1010,
				1020,	1040,	1030,
				1040,	1060,	1050,
				1060,	1080,	1070,
				1080,	1100,	1090,
				1079,	1125,	1102,
				1125,	1170,	1176,
        1198, 1265, 1230,
				1270,	1320,	1288,
				1272,	1413,	1343,
        1325, 1390, 1363,
				1416,	1477,	1454,
				1509,	1595,	1557,
				1593,	1644,	1618,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1746,	1798,	1773,
				1746,	1798,	1798];

global BL_SPLINE_BackSubD2O_old = [1000,	1020,	1010,
				1020,	1040,	1030,
				1040,	1060,	1050,
				1060,	1080,	1070,
				1080,	1100,	1090,
				1079,	1125,	1102,
				1125,	1170,	1176,
        1198, 1265, 1230,
				1270,	1320,	1288,
				1272,	1413,	1343,
        1325, 1390, 1363,
				1416,	1477,	1454,
				1509,	1595,	1557,
				1593,	1644,	1618,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1746,	1797,	1773,
				1746,	1797,	1797];

global BL_SPLINE_BackSubD2O = [1000,	1020,	1010,
				1020,	1040,	1030,
				1040,	1060,	1050,
				1060,	1080,	1070,
				1080,	1100,	1090,
				1100, 1171, 1150,
        1171, 1251, 1210,
        1251, 1310, 1260,
        1310, 1370, 1331,
        1370, 1430, 1412,
        1430, 1486, 1458,
        1486, 1549, 1501,
        1549, 1592, 1560,
        1592, 1630, 1618,
        1630, 1693, 1640,
				1693,	1746,	1720,
				1746,	1797,	1773,
				1746,	1797,	1797];

global BL_SPLINE_GC = [1094,	1104,	1100,
        1104,	1124,	1114,
				1124,	1142,	1130,
				1142,	1172,	1150,
				1172,	1186.8,	1180,
				1176,	1186.8,	1186.8];

global BL_SPLINE_PALD2O = [1591,	1610,	1600,
        1610,	1630,	1620,
				1644,	1695,	1670,
				1695,	1746,	1720,
				1726,	1749,	1739,
				1736,	1749,	1749];

global BL_SPLINE_1480_1578 = [1480, 1504, 1480,
        1480, 1510, 1490,
        1510,	1564,	1540,
        1564,	1578,	1570,
        1570,	1578,	1578];

global BL_SPLINE_DESCD2O_old = [1484, 1504, 1494,
        1504,	1524,	1514,
        1591,	1612,	1600,
        1620,	1640,	1630,
        1644,	1665,	1660,
        1652, 1682, 1672,
				1675,	1682,	1682];

global BL_SPLINE_DESCD2O_A = [1487, 1494, 1490,
        1494, 1515, 1505,
        1515, 1532, 1520,
        1532, 1556, 1540,
        1556, 1582, 1565,
        1582, 1593, 1593];

global BL_SPLINE_DESCD2O_FTIR = [1487, 1504, 1494,
        1484, 1545, 1524,
        1545, 1600, 1576,
        1600, 1656, 1629,
        1656, 1682, 1665,
        1656, 1682, 1682];

global BL_SPLINE_DESCD2O_B = [1573.5, 1588, 1573.5,
        1588, 1630, 1615,
        1630, 1656, 1632,
        1640, 1666, 1660,
        1666, 1688, 1665,
        1686, 1697.5, 1697];

global BL_SPLINE_DESCD2O_C = [1551.5, 1570, 1552.5,
        1560, 1581, 1567,
        1581, 1613, 1600,
        1613, 1625, 1617,
        1625, 1652, 1641,
        1652, 1670, 1660,
        1662, 1670, 1670];

global BL_SPLINE_DESCD2O_D = [1514, 1530, 1514,
        1520, 1551, 1530,
        1551, 1583, 1560,
        1583, 1605, 1595,
        1605, 1626, 1610,
        1610, 1626, 1626];

global BL_SPLINE_DESCD2O_E = [1578, 1588, 1578,
        1588, 1630, 1615,
        1630, 1656, 1632,
        1640, 1666, 1660,
        1666, 1688, 1675,
        1688, 1703, 1703];

global BL_SPLINE = BL_SPLINE_DESCD2O_D;

% *******************************  Definitionen, vordefiniertes Macro
%global macro;
macro{1}.name="mm1";
macro{1}.nr_commands=11;
macro{1}.command{1}="pd";
macro{1}.command{2}="# + 1";
macro{1}.command{3}="ad auto";
macro{1}.command{4}="baseline prespline";
macro{1}.command{5}="baseline linear";
macro{1}.command{6}="cutwz 940 1810";
macro{1}.command{7}="svd";
macro{1}.command{8}="gfl 2";
macro{1}.command{9}="p gf";
macro{2}.name="mm1r";
macro{2}.nr_commands=15;
macro{2}.command{1}="pd";
macro{2}.command{2}="# + 1";
macro{2}.command{3}="ad auto";
macro{2}.command{4}="baseline prespline";
macro{2}.command{5}="baseline linear";
macro{2}.command{6}="cutwz 940 1810";
macro{2}.command{7}="svd";
macro{2}.command{8}="rotation 1 - 10";
macro{2}.command{9}="rotkill 3";
macro{2}.command{10}="recomp";
macro{2}.command{11}="svd";
macro{2}.command{12}="gfl 2";
macro{2}.command{13}="p gf";
macro{3}.name="sav2";
macro{3}.command{1}="p svd";
macro{3}.command{2}="pp";
macro{3}.command{3}="p gf";
macro{3}.command{4}="pp";
macro{3}.command{5}="save gffiles";
macro{4}.name="bl1";
macro{4}.command{1}="pd";
macro{4}.command{2}="# + 1";
macro{4}.command{3}="ad auto";
macro{4}.command{4}="baseline prespline";
macro{4}.command{5}="baseline linear";
macro{4}.command{6}="cutwz 940 1810";
macro{4}.command{7}="save 3ddata auto";
macro{5}.name="r2";
macro{5}.command{1}="ad auto";
macro{5}.command{2}="svd";
macro{5}.command{3}="rotation 2 - 10";
macro{5}.command{4}="rotkill 3";
macro{5}.command{5}="recomp";
macro{5}.command{6}="svd";
macro{5}.command{7}="gfl 2";
macro{6}.name="import_bochum";
macro{6}.command{1}="timevec=(x/1000)';";
macro{6}.command{2}="freqvec=y;";
macro{6}.command{3}="mdata=z;";
mak_nr=6;



% NOTHING TO CHANGE BELOW THIS LINE!
%--------------------------------------------------------------------------------


%addpath(program_path);		Steht in .octaverc

global    listenname;
global    freqvec = 0;
global    timevec = 0;
global 	  mdata = 0;
% shortcuts:
%f_ = @freqvec;
%t_ = @timevec;
%m_ = @mdata;


global infofield;
infofield.info="n.d.";
global	  freqvec_old=0;
global	  timevec_old=0;
global	  mdata_old=0;
global	  freqvec_bak=0;
global	  timevec_bak=0;
global	  mdata_bak=0;
global    PRE_TIME = 0; 					# Zeitpunkt an dem die eigentliche Messung beginnt
global    PRE_TIME_START = 0;				% Wenn die Reaktion nicht bei 0 startet...
global    REACTION_START_INDEX = 1;		% verweist auf den ersten Messpunkt nach Ausl�sen der Reaktion
global	  PRE_INDEX = 0;
global    u=0; global s=0; global v=0;
global    global_error=0;
global    is_svd=0;
global    is_rotation=0;
global    speichermodus=0;
global    basespectrum;
global	  is_fit=0;
global    works_on="o";
global    TO_DO;
global    command_position=1;			# Aktuelle Position des Interpreters
global    BACKUP_CMD=1;
global	  SVD_FIT=0;				# Speichert, wieviel SVD-Komponenten gefittet wurden.
global    dhistory;
global    RESTRICT_RSQUARE=0;			# nur Werte plotten, deren r_square groesser ist
global	  autocorr_to_plot=20;			# gibt an, bis zu welcher ordnung die AK-Funktionen angezeigt werden (plot s)
global	  baseline=0;
global	  baseline_info='no baseline';
global	  vals_to_plot = 5;			# fr die Rotation
global	  macro_record_start=0;

global    SVD=1;
global    ROTATION=2;
global	  ROTATION_ORDER = 1;

global    PUT_LEVEL = 0;
global    MAX_UNDO_LEVEL = 10;
global    undo_buffer;

global    FIT_ITERATIONS = 5;			% Wie oft wird ein Fit mit verschiedenen Startparametern ausgeführt??


global    is_datafit=0;				% Fit der Originaldaten an Basisspektren
global    fitmatrix;

global    select;				% bezeichnet die Nr des aktuell ausgew. Spektrums.

%*********3D Plotting options
global    XRES_3D = 100;				% Auflösung für 3D - plots plot o
global    YRES_3D = 100;
global    AZ_3D = 45;
global    EL_3D = 45;
global    shading_3D = "faceted";

% Parameters for Printout
global    PRINTOUT_SIZE="";
global    PRINTOUT_FONT="";

# PlotFenster f�r verschiedene Ansichten
global	  FIG = 1;			# Für alles mögliche....
global	  FIG_SURFACE = 2;
global    FIG_SPECTRA = 3;
global	  FIG_KINETICS = 4;
global    FIG_FIT_KINETICS = 5;
global    FIG_U = 6;
global    FIG_V = 7;
global	  FIG_LSQFIT = 8;
global	  FIG_BASESPECTRA = 9;
global    FIG_SINGULAR = 10;
global    FIG_SVD = 11;
global    FIG_SVDFIT = 12;
global	  FIG_GLOBALFIT = 13;
global    FIG_GLOBALFIT_RESULT = 14;
global	  FIG_AUTOCORR = 15;
global    FIT_STDDEV=19;
global    FIT_PARAMETER = 20;          # + folgende 10 Reserviert f�r die Parameter des Fits; FIT_PARAMETER+parameter, wobei parameter die Nummer ist (1-x)
global    FIG_LIVE = 21;
global	  FIG_DGLFIT = 22;
global	  FIG_BENCH = 23;
global    FIG_CORRELATION = 24;
global    FIG_MISC = 50;		         # + folgende Reserviert f�r weiter Fenster FIG_MISC+n

%					Voreinstellungen Farbgebung (automatisch bei p o)
global col = [ 0 0 1 ];			% default blue
global colincr = [0.2 0 -0.2];		% Farbtabelle

% Nach Anwendung einer Rotation Histogramme plotten?
PLOT_ROT_HISTOGRAMS=0;

# Standardformat fuer Ausgabe
global    OUTPUT_FORMAT = "eps";

global PLOT_WITH_OFFSET = 0;
global AUTO_COLOR = 1;
global AUTO_COLOR_NUM = 20;

global PLOT_SVD_STYLE = 1;


# Nutzerdefinierbares Plotkommando
user_plot=@plot;

# Für 3D-surfaces
plot3d=@mesh;
corplot=@contourf;
# plot3d=@surface;

#Vordefinierte k's beim Globalfit verwenden
global KMatrix_predefined=[10,1,0.1];

% Standardwerte für Ks beim Globalfit
global gf_k_start=[0,0,0,0,0,0,0,0,0,0];
global gf_k_stop=[100,100,100,100,100,100,100,100,100,100];


% Globalfit Optionen fuer Fit mittels gfl

%global gfl_options.bounds=[-Inf,Inf];				% Todo: this has to be redefined; function ie gfl_prepare

global gfl_tmp_components=3;
global gfl_tmp_params = [1,100,10; 0.01,0.1,0.1; 0.0001,0.001,0.001];
for i=4:100
  gfl_tmp_params(i,1)=0;
  gfl_tmp_params(i,2)=0;
  gfl_tmp_params(i,3)=0;
endfor;
global gfl_tmp_params_adjusted = 0;

global	  gf_ITERATIONS=2;				# Wieviel Intervalleinteilungen beim Globalfit

TO_DO = 0;

global	gf_PRECISION = 1e-6;

global	gf_METHOD="unknown";
global	gf_INITIAL_PARAMETERS="not saved";
global	gf_KONVERGENCE="not saved";
global	gf_STDRESID="not saved";
global	gf_R2="not saved";

% Weitere Parameter für Multicore-Berechnung
global  globalfit_minfunc;
global options_g;
global kineticfun_g;
global components_g;
global weights_g;


% "D Correlation settings
global  cos_eps = 0.01;       1% treshold
global  cos_dx = 1;
global  cos_dy = 1;


options = [0,1e-6];

global SECURITY_LEVEL = 1;		% 1 .. normal, 2 .. alles sichern
global SECURITY_PATH = "/tmp";

% figure neu definieren

function put()
%
% put() und undo() sind die automatischen Sicherheitskopie-Versionen
%	aktuelle Verschachtelungstiefe:		PUT_LEVEL
%	max. Tiefe:				MAX_UNDO_LEVEL
%
    global mdata;
    global freqvec;
    global timevec;
    global undo_buffer;
    global PUT_LEVEL;
    global MAX_UNDO_LEVEL;
    global REACTION_START_INDEX;

    if (PUT_LEVEL == 0) ; PUT_LEVEL = 1; end;

    % This makes problems with octave 3.2.2
    undo_buffer{PUT_LEVEL}.mdata = mdata;
    undo_buffer{PUT_LEVEL}.freqvec = freqvec;
    undo_buffer{PUT_LEVEL}.timevec = timevec;
    undo_buffer{PUT_LEVEL}.reaction_start = REACTION_START_INDEX;
    %printf("Sicherkeitskopie Ebene %d erstellt\n",PUT_LEVEL);

    PUT_LEVEL += 1;
    if ( PUT_LEVEL > MAX_UNDO_LEVEL) ; PUT_LEVEL = 1; end;

end

function undo()
    global mdata;
    global freqvec;
    global timevec;
    global undo_buffer;
    global PUT_LEVEL;
    global MAX_UNDO_LEVEL;
    global REACTION_START_INDEX;

    PUT_LEVEL-=1;
    if (PUT_LEVEL == 0)
      printf("  Nichts rückgängig zu machen.\n");
      PUT_LEVEL = 1;
    else
      timevec = undo_buffer{PUT_LEVEL}.timevec;
      freqvec = undo_buffer{PUT_LEVEL}.freqvec;
      mdata = undo_buffer{PUT_LEVEL}.mdata;
      REACTION_START_INDEX = undo_buffer{PUT_LEVEL}.reaction_start;
      printf("Daten aus Ebene %d wiederhergestellt\n", PUT_LEVEL);
    end;
end


cont=0;
global is_svd=0;
global is_basis=0;
ende=0;
global speichermodus=0;
global base_matrix=0;
% Startparameter fuers Fittem
pin = [-0.4, 0.1, 0.5, 0.1, 0.05, -0.1, 0.005];
% Parametergrenzen; defaults für 3x exp
pin_constraints = [ 0,0; 0,0; 0,inf; 0,0; 0,inf; 0,0; 0,inf ];

% Parameter fuer 2DCos
global COS_TRESHOLD_SYN = 0.01;     % 1%
global COS_TRESHOLD_ASYN = 0.01;     % 1%

function helpfunc()
  printf ("How to get help:\n");
  printf (" <?>        ... show all commands\n");
  printf (" <? name>   ... show more detailed information about <name>\n");
  printf (" <??>       ... show information about available commands\n");
  printf (" <info>     ... information about the current dataset\n\n");
endfunction


%	backup & restore 	bearbeitet genau eine manuelle Kopie
%	put & undo		ist die automatischer Version
%    todo:			Ist unn�tig, entferenen!
function backup()
    global mdata;
    global freqvec;
    global timevec;
    global mdata_bak;
    global freqvec_bak;
    global timevec_bak;
    global command_ctr;
    global BACKUP_CMD;
    global REACTION_START_INDEX;
    mdata_bak = mdata;
    freqvec_bak = freqvec;
    timevec_bak = timevec;
    BACKUP_CMD = command_ctr-1;
    printf("  Daten gesichert (mdata_bak, freqvec_bak, timevec_bak)\n  restore zum wiederherstellen benutzen.\n");
end

function restore()
    global mdata;
    global freqvec;
    global timevec;
    global mdata_bak;
    global freqvec_bak;
    global timevec_bak;
    global REACTION_START_INDEX;
    mdata = mdata_bak;
    freqvec = freqvec_bak;
    timevec = timevec_bak;
end

function fig(f)
    global AUTO_FIGURE;
    if ( AUTO_FIGURE==1 )
        figure(f);
    endif;
end


function menu()        # Umwandeln: Kontextsensitive Hilfe
  global speichermodus;
  global is_svd;
  global is_basis;
  printf("\n\n\n");
  printf("    <1> .. Neue Datei laden\n    <2> .. Glaetten\n    <svd> .. SVD\n");
  printf("    <dzero> .. Nullabgleich der Daten (anhand 1. Spur)\n");
  printf("    <saveall> .. alle Daten als Einzelspektren Speichern");
  printf("\n    Basisspektren:\n");
  if ( is_basis > 0 )
    printf("      %d Basisspektren geladen.\n", is_basis);
    printf("         <bd> .. Basis loeschen\n");
    printf("         <sf> .. Daten an Basis anpassen\n");
    printf("         <bw> .. Basisvektoren mit SV invers wichten\n");
    printf("         <bp> .. Basis anzeigen\n");
    printf("         <lsqprint> .. Ergebnis des LSQ-Fits zeigen\n");
    printf("         <lsqsave> .. LSQ Anpassung speichern\n");
    printf("         <bzero> .. Alle Basisvektoren auf y=0 verschieben\n");
  else
    printf("    Basis liegt nicht vor.\n");
    printf("       <bf> .. Dateien laden\n");
    if ( is_svd > 0 )
      printf("       <bs [nr1] [nr2] ...> .. SVD Daten als Basisspektren übernehmen\n");
      printf("       <bg>                 .. Daten des Globalfits als Basisspektren laden\n");
    endif
    printf("\n");
  endif
  printf("    Anzeigemodi: <o> - Originalspektren, <ot> - Kinetiken\n");
  printf("                 <o3d> - Originalspektren als 3D grid\n");
  printf("       im Anzeigemodus:\n");
  printf("                 <save>, <s> - Aktuelles Spektrum speichern\n");
  if ( is_svd )
    printf("          <u>, <s>, <v> - Daten der SVD-Zerlegung zeigen\n");
    printf("          <u3d>, <v3d> - Plotten als 3D grid\n");
    printf("          <svdsave> - SVD-Zerlegung speichern (*.U, *.S, *.V)\n");
    printf("	      <lsasave> - speichert die Originaldaten + SVD-Zerlegung\n");
    printf("                      für fitten mit lsq\n");
  else
    printf("           SVD liegt nicht vor.\n");
  endif
  printf(" <w> - Speichermodus ein/aus ");
  if ( speichermodus == 0)
    printf(" (Speichermodus ist aus.)            #\n");
  else
    printf(" (Speichermodus ist  an.)            #\n");
  endif
  printf("   <x>, <quit> - Programmende\n");
  printf("\n\n");
endfunction


function info()
  global mdata;
  global freqvec;
  global timevec;
  global listenname;
  global is_svd;
  global is_basis;
  global basespectrum;
  global PRE_TIME;
  global baseline_info;
  global time_axis;
  global wavenumber_axis;
  global is_datafit;
  global fitmatrix;
  global REACTION_START_INDEX;
  global infofield;
  printf ("\n\n");
  printf ("Filename:                %s\n\n\n", listenname);
  printf ("Data (mdata, ZxS):       %dx%d\n", rows(mdata), columns(mdata));
  printf ("Time (timevec, in %s):   %dx%d	%f - %f, Step: %f\n", time_axis, rows(timevec), columns(timevec), timevec(1), timevec(columns(mdata)), timevec(2)-timevec(1));
  printf ("REACTION_START_INDEX):   %f=timevec(%d)\n", timevec(REACTION_START_INDEX), REACTION_START_INDEX);
  printf ("Frequency (freqvec):     %dx%d	%f - %f %s, Schrittweite: %f\n", rows(freqvec), columns(freqvec), freqvec(1), freqvec(rows(mdata)), wavenumber_axis, freqvec(2)-freqvec(1));
  printf ("Max/Min:                 %f/ %f\n", max(max(mdata)), min(min(mdata)));
  printf ("Additional info:\n");
  infofield
  if ( is_svd )
    printf("    SVD-Zerlegung liegt vor.\n");
  endif;
  if ( is_basis>0 )
    printf ("    %d Basisspektren geladen.\n", is_basis);
    for i=1:is_basis
	printf("  %d. Spektrum: %s\n", i, basespectrum(i).name);
    endfor;
  endif;
  if (is_datafit>0)
    printf("	Fit an die Basisspektren liegt vor (fitmatrix: %dx%d)\n", rows(fitmatrix), columns(fitmatrix));
  end;
  printf ("    Baseline: %s\n",baseline_info);
  printf ("\n");
endfunction


function add_to_history(new_command)
    global command_position;
    global command_ctr;
    global dhistory;
    dhistory(command_ctr++).name = sprintf("%s",new_command);
#    printf("  At %d: Setting Additional command Nr. %d->%d: %s\n", command_ctr, TO_DO, command_ctr+TO_DO, dhistory(command_ctr+TO_DO).name);
#    fflush(stdout);
endfunction;

##############################################################################################
#
# Datenfits an DGL-Systeme:	Funktionen und Parameter
#
# Die Aktionen zielen auf:	fitmatrix (Ergebnis des Fits der Daten an Basisspektren
#
global dgl_k = [1;1;1];
global dgl_initvals = [1;0;0];
global dgl_function;

%		Verschiedene Modelle
function xdot = dgl_irrev(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                k1    k2\n");
	xdot=sprintf("%sdgl_irrev:   X1 -> X2 -> X3\n", xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2);
	xdot(3) = dgl_k(2)*x(2);
    end;
end;

function xdot = dgl_lastrev(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                  k1     k2\n");
	xdot=sprintf("%sdgl_lastrev:   X1 -> X2 <-> X3\n", xdot);
	xdot=sprintf("%s                         k3\n", xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) + dgl_k(3)*x(3);
	xdot(3) = dgl_k(2)*x(2) - dgl_k(3)*x(3);
    end;
end;

function xdot = dgl_firstrev(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                   k1    k3\n");
	xdot=sprintf("%sdgl_lastrev:   X1 <-> X2 -> X3\n", xdot);
	xdot=sprintf("%s                   k2\n", xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1)+dgl_k(2)*x(2);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(3)*x(2);
	xdot(3) = dgl_k(3)*x(2);
    end;
end;

function xdot = dgl_allrev(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                   k1     k3\n");
	xdot=sprintf("%sdgl_lastrev:   X1 <-> X2 <-> X3\n", xdot);
	xdot=sprintf("%s                   k2     k4\n", xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1)+dgl_k(2)*x(2);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(3)*x(2);
	xdot(3) = dgl_k(3)*x(2);
    end;
end;

function xdot = dgl_trirev(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                           k1\n");
	xdot=sprintf("%sdgl_trirev:   x1 <-----------> x2\n",xdot);
	xdot=sprintf("%s              k6\\   k2      k4/\n",xdot);
	xdot=sprintf("%s                 \\           /\n",xdot);
	xdot=sprintf("%s                  \\k5       / k3\n",xdot);
	xdot=sprintf("%s                   \\       /\n",xdot);
	xdot=sprintf("%s                      x3\n",xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1)+dgl_k(2)*x(2) - dgl_k(5)*x(1) + dgl_k(6)*x(3);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(3)*x(2) + dgl_k(4)*x(3);
	xdot(3) = dgl_k(5)*x(1) - dgl_k(6)*x(3) + dgl_k(3)*x(2) - dgl_k(4)*x(3);
    end;
end;

function xdot = dgl_fourrev(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                   k1     k3     k5\n");
	xdot=sprintf("%sdgl_lastrev:   X1 <-> X2 <-> X3 <-> X4\n",xdot);
	xdot=sprintf("%s                   k2     k4     k6\n",xdot);
    else
	xdot =  zeros(4,1);
	xdot(1) = dgl_k(2)*x(2) - dgl_k(1)*x(1);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(3)*x(2) + dgl_k(4)*x(3);
	xdot(3) = dgl_k(3)*x(2) - dgl_k(4)*x(3) + dgl_k(6)*x(4) - dgl_k(5)*x(3);
	xdot(4) = dgl_k(5)*x(3) - dgl_k(6)*x(4);
    end;
end;

function xdot = dgl_squarescheme(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                     k1\n");
	xdot=sprintf("%sdgl_lastrev:   X1 <-----> X2\n",xdot);
	xdot=sprintf("%s                ^    k2    ^\n",xdot);
	xdot=sprintf("%s                |          |\n",xdot);
	xdot=sprintf("%s              k3|k4      k5|k6\n",xdot);
	xdot=sprintf("%s                |          |\n",xdot);
	xdot=sprintf("%s                v    k7    v\n",xdot);
	xdot=sprintf("%s               x3 <-----> X4\n",xdot);
	xdot=sprintf("%s                     k8\n\n",xdot);
	% printf("%s\n", xdot);
    else
	xdot =  zeros(4,1);
	xdot(1) = -dgl_k(1)*x(1)+dgl_k(2)*x(2) - dgl_k(4)*x(1) + dgl_k(3)*x(3);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(6)*x(2) + dgl_k(5)*x(4);
	xdot(3) = dgl_k(4)*x(1) - dgl_k(3)*x(3) - dgl_k(7)*x(3) + dgl_k(8)*x(4);
	xdot(4) = dgl_k(7)*x(3) - dgl_k(8)*x(4) + dgl_k(6)*x(2) - dgl_k(5)*x(4);
    end;
end;

function xdot = dgl_squarecross(x,t)
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                              k1\n");
	xdot=sprintf("%sdgl_squarecross X1 <-------------> X2\n",xdot);
	xdot=sprintf("%s                 ^    k2           ^\n",xdot);
	xdot=sprintf("%s               k3|               k5|\n",xdot);
	xdot=sprintf("%s                 | k10\\    /k12    |\n",xdot);
	xdot=sprintf("%s                 |     \\ /         |\n",xdot);
	xdot=sprintf("%s                 |      \\          |\n",xdot);
	xdot=sprintf("%s                 |     / \\ k9      |\n",xdot);
	xdot=sprintf("%s                 |k4   k11         |k6\n",xdot);
	xdot=sprintf("%s                 v           k7    v\n",xdot);
	xdot=sprintf("%s                x3 <-------------> X4\n",xdot);
	xdot=sprintf("%s                      k8\n\n",xdot);
	% printf("%s\n", xdot);
    else
	xdot =  zeros(4,1);
	xdot(1) = -dgl_k(1)*x(1)+dgl_k(2)*x(2) - dgl_k(4)*x(1) + dgl_k(3)*x(3) - dgl_k(9)*x(1) + dgl_k(10)*x(4);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(6)*x(2) + dgl_k(5)*x(4) - dgl_k(11)*x(2) + dgl_k(12)*x(3);
	xdot(3) = dgl_k(4)*x(1) - dgl_k(3)*x(3) - dgl_k(7)*x(3) + dgl_k(8)*x(4) - dgl_k(12)*x(3) + dgl_k(11)*x(2);
	xdot(4) = dgl_k(7)*x(3) - dgl_k(8)*x(4) + dgl_k(6)*x(2) - dgl_k(5)*x(4) - dgl_k(10)*x(4) + dgl_k(9)*x(1);
    end;
end;

function xdot = dgl_tri_firstrev(x,t)     %PF
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                           k1\n");
	xdot=sprintf("%sdgl_tri_firstrev x1 <-----------> x2\n",xdot);
	xdot=sprintf("%s                  \\   k2     /\n",xdot);
	xdot=sprintf("%s                   \\        /\n",xdot);
	xdot=sprintf("%s                    \\k4    / k3\n",xdot);
	xdot=sprintf("%s                     \\    /\n",xdot);
	xdot=sprintf("%s                       x3\n",xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1)+ dgl_k(2)*x(2) + dgl_k(4)*x(3);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(3)*x(2);
	xdot(3) = -dgl_k(4)*x(3) + dgl_k(3)*x(2);
    end;
end;

function xdot = dgl_tri_concerted(x,t)     %PF
    global dgl_k;
    if ( nargin==0 )
	xdot="";
	xdot=sprintf("                           k1\n");
	xdot=sprintf("%stri_concerted:x1 <-----------> x2\n",xdot);
	xdot=sprintf("%s               \\|   k2     /\n",xdot);
	xdot=sprintf("%s              k3\\\        /\n",xdot);
	xdot=sprintf("%s                 \\\k4    / k3\n",xdot);
	xdot=sprintf("%s                  |\\    |\n",xdot);
	xdot=sprintf("%s                     x3\n",xdot);
    else
	xdot =  zeros(3,1);
	xdot(1) = -dgl_k(1)*x(1)+ dgl_k(2)*x(2) + dgl_k(4)*x(3) - dgl_k(3)*x(2)*x(1);
	xdot(2) = dgl_k(1)*x(1) - dgl_k(2)*x(2) - dgl_k(3)*x(2)*x(1);
	xdot(3) = -dgl_k(4)*x(3) + 2*dgl_k(3)*x(2)*x(1);
    end;
end;

%		Startwert
dgl_function = @dgl_irrev;

%		Zu Minimierende Funktion:
global dgl_options=[0;1e-9];
function [sse, y_calc] = dgl_fit(params, x, y)
    global LIVE_MODE;
    global dgl_k;		% Die globalen Variablen werden hier auf entsprechende Werte gesetzt, da lsode keine Parameter kennt--
    global dgl_initvals;    % y ist y(t, nr)
    global dgl_function;
    dgl_k = params(length(dgl_initvals)+1:end);			% Parameter laufen global
    dgl_iv = params(1:length(dgl_initvals));
    y_calc = lsode(dgl_function, dgl_iv, x);

	  plot(x,y_calc, x, y);
	  drawnow();

    % TODO:
    % hier reingehen und bei y_calc evtl. 1. Reihe Weglassen...
    y_diff = y - y_calc(:,1+(columns(y_calc)-columns(y)):end);
    sse = sum(sum( y_diff.^2 ));
endfunction;

% Funktion f�r Fit mit leasqr;  PF
function y_calc = dgl_fit_leasqr(x, params)
    global LIVE_MODE;
    global dgl_k;		% Die globalen Variablen werden hier auf entsprechende Werte gesetzt, da lsode keine Parameter kennt--
    global dgl_initvals;    % y ist y(t, nr)
    global dgl_function;
    dgl_k = params(length(dgl_initvals)+1:end);			% Parameter laufen global
    dgl_iv = params(1:length(dgl_initvals));
    y_calc = lsode(dgl_function, dgl_iv, x);
    y_calc=y_calc(:,2:end);       %Dark state is not contained in difference spectra dataset
endfunction;




##############################################################################################
#
# Funktionen f�r allgemeine Datenanpassung
#

function [sse, FittedSpectrum] = lin_fit(params, x, y)
    global FIG_LIVE;
    FittedSpectrum = params(1)*x+params(2);
    ErrorSpectrum = FittedSpectrum - y;
    sse = sum( (ErrorSpectrum.^2) );
%    if ( graphicmode & !fastgraphics )
%	fig(FIG_LIVE);
%	plot(x, FittedSpectrum, x, y);
	%plot(x, ErrorSpectrum);
%	drawnow();
%    end;
end

% Immer jeweils 2 Versionen:
%  1 für leasqr
%  1 für fminsearch

function y = fit_monoexponential(x,p)		# Die Parameter p(x) dieser Funktion werden gefittet
  y=p(1)+p(2)*(1-exp(-p(3)*x));
endfunction

function [ sse, FittedCurve ] = exp_fit(params, x, y)
    FittedCurve = params(1)*(1-exp(-params(2)*x))+params(3);
    ErrorCurve = FittedCurve - y;
    sse = sum( (ErrorCurve.^2) );
end;

function [ sse, FittedCurve ] = twoexp_fit(params, x, y)
    FittedCurve = params(1)*(1-exp(-params(2)*x)) + params(3)*(1-exp(-params(4)*x)) + params(5);
    ErrorCurve = FittedCurve - y;
    sse = sum( (ErrorCurve.^2) );
end;

function y = fit_monoexponential_dx(x,p)	# Die Parameter p(x) dieser Funktion werden gefittet
    for i=1:length(x)
	if ( x(i) > p(4) )
	    y(i)=p(1)+p(2)*(1-exp(-p(3)*(x(i)-p(4))));
	else
	    y(i)=p(5);
	endif;
    endfor;
    y=y';
endfunction

function y = fit_lin_exponential(x,p)		# Die Parameter p(x) dieser Funktion werden gefittet
  y=p(1)+p(2)*(1-exp(-p(3)*x))+p(4)*x;
endfunction

function y = fit_lin(x,p)			% Die Parameter p(x) dieser Funktion werden gefittet
  y=p(1)+p(2)*x;
endfunction

% function y = fit_solo(x,p)


function y = fit_2exp(x,p)			# Die Parameter p(x) dieser Funktion werden gefittet
  y=p(1)+p(2)*(1-exp(-p(3)*x))+p(4)*(1-exp(-p(5)*x));
endfunction

%function y = fit_3exp(x,p)			# Die Parameter p(x) dieser Funktion werden gefittet
%  y = p(1) + p(2)*(1-exp(-p(3)*x)) + p(4)*exp(-p(5)*x) + p(6)*exp(-p(7)*x);
%endfunction

function y = fit_3exp(x,p)			# Die Parameter p(x) dieser Funktion werden gefittet
  y = p(1) + p(2)*(1-exp(-p(3)*x)) + p(4)*(1-exp(-p(5)*x)) + p(6)*(1-exp(-p(7)*x));
endfunction

function y = fit_4exp(x,p)
  y = p(1) + p(2)*(1-exp(-p(3)*x)) + p(4)*(1-exp(-p(5)*x)) + p(6)*(1-exp(-p(7)*x)) + p(8)*(1-exp(-p(9)*x));
endfunction

function y = fit_hendersonhasselbalch1(x,p)		%% Fit an die Henderson-Hasselbalch-Gleichung; Daten hier als Funktion des pH
										%% Funktion ggf. 1, 2 oder 3 Parameter
	y = (10.^(-x))./(10.^(-p(1))+10.^(-x));
endfunction

function y = fit_hendersonhasselbalch2(x,p)		%% Fit an die Henderson-Hasselbalch-Gleichung; Daten hier als Funktion des pH
										%% Version with alkaline Endpoint (p(2)), pk=p(1), normalized
	y = (p(2)+10.^(p(1)-x))./(1+10.^(p(1)-x));
endfunction

function y = fit_hendersonhasselbalch3(x,p)		%% Fit an die Henderson-Hasselbalch-Gleichung; Daten hier als Funktion des pH
										%% Version with alkaline Endpoint (p(2)), pk=p(1), normalized (p(3))
	y = p(3).*(p(2)+10.^(p(1)-x))./(1+10.^(p(1)-x));
endfunction

#
#
#
##############################################################################################

##############################################################################################
#			    Global Fit Funktion
#				TODO : make this generic
#			x und y sind Spaltenvektoren

function [sse, FittedMatrix] = gfit_expfun_area_wt(params,x,y,order, weights)			% TODO: Der Fit wird nur in dem Bereich ab PRE_TIME durchgeführt
    %  This is probably obsolete
    %	Bei dieser Funktion wird das Ergebnis zusätzlich mit einer abfallenden e-Funktion gewichtet
    %   TODO: Anfangswerte überprüfen: Wo wird gesagt, dass x bei 0 startet??
    global PRE_TIME;
    global PRE_INDEX;
    if ( nargin<6 ), normalization = 0; end							% PRE_TIME ist dann 0
    if ( nargin<4 ), order = 3; end								% allgemeine Version fr Globalfit
    AMatrix=params(1:order*order);
    AMatrix=reshape(AMatrix,order,order);
    KMatrix=params(order*order+1:order*order+order);
    OMatrix=params(order*(order+1)+1: (order*(order+1)+order))';

    x=x(PRE_INDEX:end);

    for i=1:order
      FittedMatrix(:,i) = zeros(rows(x),1) + OMatrix(i);
      %printf("FittedMatrix: ");
      %size(FittedMatrix)
      for j=1:order
          FittedMatrix(:,i) += AMatrix(i,j) * (1-exp(-KMatrix(j)*x));
      end
    end

    %printf("y: ");
    y=y(PRE_INDEX:end,:);
    %size(y)

    %FittedMatrix = AMatrix*(1-exp(-(KMatrix')*(x'))) + OMatrix;
    %size (FittedMatrix)
    %ErrorMatrix = FittedMatrix - y';

    ErrorMatrix = FittedMatrix - y;
%    size(ErrorMatrix)
    % Aufsummieren  + wichten
    sse = sum( weights .* sum(ErrorMatrix.^2) );
end

function [sse, FittedMatrix] = gfit_expfun_con(params,x,y,order,k_predef)	% K wird nicht variiert
    % Achtung: Andere Reihenfolge der Parameter erforderlich!!
    % Params enthält nur AMatrix,Offsetvektor
    if ( nargin<4 ), order = 3; end
    AMatrix=params(1:order*order);
    AMatrix=reshape(AMatrix,order,order);
    KMatrix=k_predef;
    OMatrix=params(order*order+1:order*order+order)';
    OMatrix=repmat(OMatrix,1,length(x));
    FittedMatrix = AMatrix*(1-exp(-(KMatrix')*(x'))) + OMatrix;
    ErrorMatrix = FittedMatrix - y';
    sse = sum(sum(ErrorMatrix .^ 2));
end

##############################################################################################
#
#		For spectra fitting		TODO
#

function y = specfit_leasqr(x, params)
    y = zeros(rows(x),1);
    for i=1:columns(x)
	    y = y + params(i).*x(:,i);
    end
end

function [sse, FittedSpectrum] = specfit(params, x, y, base)

    FittedSpectrum = zeros(rows(y),1);
    for i=1:columns(base)
	    FittedSpectrum = FittedSpectrum + params(i).*base(:,i);
    end
    ErrorSpectrum = FittedSpectrum - y;



    sse = sum(abs(ErrorSpectrum));

    plot(x, FittedSpectrum, x, y, x, ErrorSpectrum);
    drawnow();

end

function [sse, FittedSpectrum] = specfit_silent(params, x, y, base)

    FittedSpectrum = zeros(rows(y),1);
    for i=1:columns(base)
	    FittedSpectrum = FittedSpectrum + params(i)*base(:,i);
    end
    ErrorSpectrum = FittedSpectrum - y;
    sse = sum(ErrorSpectrum .^ 2);
end


#
################################################################################################
#
#		Für fmins bei rotation:
#		find rj's mit maximierter Autokorreletion
#		y ist eine neue v-Matrix, die nur die zu rotierenden V-Vektoren enthält
function [sse, data] = linear_combination(params, x, y)
    data = zeros(rows(y),1);
    for i=1:columns(y)
	    data = data + params(i) * y(:,i);
    end
    ac = svd_autocorr(data);
    % Optimierung für fminsearch, aber eigentlich max. gesucht, also:
    sse = -ac;
end
#
################################################################################################
#
#		Die Rotationsfunktion
#
#
function [R,l]=rotate_matrix(V, rotation_order)
    if (nargin<2) ; rotation_order = 1; end;
    for i=1:min(size(V))
      for j=1:min(size(V))
          X(i,j) = 0;
              for k=1:(max(size(V))-rotation_order)
                X(i,j) = X(i,j) + V(k,i)*V(k+rotation_order,j);
              end
      end
    end
    Xs=(X+X')./2;

    [R1,l1]=eig(Xs);

    R = fliplr(R1);
    l = flipud(fliplr(l1));
end





% Weitere Funktionen

function fliptime()
    global mdata;
    put();
    mdata = fliplr (mdata);
end


% Umschalten der Grafikfunktionen
function switch_gnuplot_on()
	global DEFAULT_PLOTTER;
	DEFAULT_PLOTTER = "gnuplot";
	if (exist("use_grace_state","var"))
		if (strcmp(use_grace_state,"on")) toggle_grace_use ; end;
	end;
	% delay(1);
end;

function switch_grace_on()
	global DEFAULT_PLOTTER;
	if (exist("use_grace_state","var"))
		if (strcmp(use_grace_state,"off")); toggle_grace_use ; end;
		% delay(2);
		% sleep(2);
		if (strcmp(use_grace_state,"on"))
			DEFAULT_PLOTTER = "grace";
		else
			DEFAULT_PLOTTER = "gnuplot";
			printf("  Fehler beim Initialisieren von Graceplot\n");
		end;
	else
		printf("  Initialisiere Grace\n");
		toggle_grace_use;
		%delay(2);
		% sleep(2);
		if (strcmp(use_grace_state,"on"))
			DEFAULT_PLOTTER = "grace";
		else
			DEFAULT_PLOTTER = "gnuplot";
			printf("  Fehler beim Initialisieren von Graceplot\n");
		end;
	end;
end;

function OLD = select_plotter(name)
	global DEFAULT_PLOTTER;
	OLD = DEFAULT_PLOTTER;
	if ( strcmp(name,"grace") )
		switch_grace_on();
	else
		switch_gnuplot_on();
	end;
end;

function flipx()
	global DEFAULT_PLOTTER;
	global wavenumber_axis;
	global inverse_wavenumber_axis;
	if ((inverse_wavenumber_axis==1) && (strcmp(DEFAULT_PLOTTER,"gnuplot"))); set(gca(),"XDir","reverse"); end;
end;



function [reaction_start, reaction_start_index] = get_pretime(freqvec, timevec, mdata)
	diffmatrix = zeros(1,(length(timevec)-1));
	for i=1:length(freqvec)
		diffmatrix = diffmatrix + abs(diff(mdata(i,:)));
	end;
	[ maxval, maxpos ] = max(diffmatrix);
	%printf("  %f (%d)\n", timevec(maxpos), maxpos);
	reaction_start = timevec(maxpos);
	reaction_start_index = maxpos;
end;


function adjust_display(los)
	global timevec;
	global freqvec;
	global mdata;
	global REACTION_START_INDEX;
	global FIG_MISC;
	%	Die Spektren Plotten
	OLD = select_plotter("gnuplot");
	fig(FIG_MISC);
	clf();
	hold on;
	plot(freqvec, (mdata(:,los-1)+max(mdata(:,los-1))) );
	plot(freqvec,mdata(:,los));
	plot(freqvec,(mdata(:,los+1)-max(mdata(:,los+1))));
	% 	Die Kinetiken plotten
	fig(FIG_MISC+1);
	clf();
	stai = los - 40;
	if (stai<1), stai=1; end;
	stoi = los + 40;
	if (stoi>length(timevec) ), stoi = length(timevec); end;
	plot(timevec(stai:stoi), sum(abs(mdata(:,stai:stoi)),1));					% Plottet die Summe der Betr�ge aller Wellenl�ngen
	hold on;
	a=[timevec(los), timevec(los)];
	b=[min(sum(abs(mdata(:,stai:stoi)),1)), max(sum(abs(mdata(:,stai:stoi)),1))];
	plot(a,b,"r");															% 1. Datenpunkt nach Reaktionsstart (red)
																		% Zeichnet Linien vorher und hinterher
	if (los > 1)
		a=[timevec(los-1), timevec(los-1)];										% vorhergehender Datenpunkt
		b=[min(sum(abs(mdata(:,stai:stoi)),1)), max(sum(abs(mdata(:,stai:stoi)),1))];
		plot(a,b,"b");
		a=[timevec(los+1), timevec(los+1)];									% 2. Datenpunkt der Kinetik
		b=[min(sum(abs(mdata(:,stai:stoi)),1)), max(sum(abs(mdata(:,stai:stoi)),1))];
		plot(a,b,"b");
		a=[0,0];															% die Echte 0-Linie
		b=[min(sum(abs(mdata(:,stai:stoi)),1)), max(sum(abs(mdata(:,stai:stoi)),1))];
		plot(a,b,"y");
	end;
	% select_plotter(OLD);
end;


function rv=adjust_data()					% Baustelle: den aktuellen Datensatz f�r GF vorberiten und alle n�tigen globalen Vaiablen setzen
	global timevec;				 		% Der Reaktionsstart soll mit 0 zusammenfallen
	global freqvec;						% TODO: nur mit gnuplot, argument in der Klammer: keine Abfragen
	global mdata;						% TODO: pr�fen, ob Punkte links und rechts von 0 gleich verteilt. ggf. letzten Punkt der Vorperiode ranziehen!
	global REACTION_START_INDEX;
	global FIG_MISC;
	if ( timevec(1) < 0)						% In Opus wurde "Reset timebase" gesetzt. Der Reaktionsstart ist bekannt.
		printf("  Reaktionsstart aus Datensatz ermittelt.\n");
		los = get_zero_index(timevec);
		% if (los>1), los=los-1; end;			% Reaktion startet von 0 an
		printf("  Reaktionsstart aus Datensatz: timevec(%d)=%f\n", los, timevec(los));
		do
			adjust_display(los);
			los2 = input(" Korrekturmodus - Neuer Indexwert (0..fertig): ");
			printf("  Neuer Wert: timevec(%d)=%f\n", los, timevec(los));
			if (los2>0), los=los2; end;
		until ( los2<1 );
	else
		printf("  Manuelle Eingabe des Startwertes:\n");
		printf("  Hier zun�chst 1. Indexwert der Reaktion festlegen.\n  Der Nullpunkt wird sp�ter gesetzt\n");
		[losval, los] = get_pretime(freqvec, timevec, mdata);
		printf("  Automatisch bestimmt: timevec(%d)=%f\n", los, timevec(los));
		do												% TODO: hier noch den exakten 0 - Wert vorschlagen
			adjust_display(los);
			los2 = input("  Neuer Indexwert (0..fertig): ");
			printf("  Neuer Wert: timevec(%d)=%f\n", los, timevec(los));
			if (los2>0), los=los2; end;
		until ( los2<1 );
		printf("  Erster Datenpunkt nach Reaktionsstart bei timevec(%d)=%f\n", los, timevec(los));
		step = timevec(los+1)-timevec(los);
		printf("  Reaction start definition - Set new zero time point?\n");
		printf("  Proposed change: dt = %f\n", timevec(los)-step);
		jnc = input("  [k]eep, [m]anual, [n]o change?","s");
		if ( jnc=="m")
			np = input("  Set new time zero index ([0]: no change) - new value >");
		elseif ( jnc == "k")
			np = timevec(los)-step;
			printf("  Proposed zero time is applied\n");
		else
			% Do nothing
			np=0.0;
			printf("  Time axis remains unchanged\n");
		end;
		timevec = timevec-np;
	end;
	REACTION_START_INDEX = los;				% Festlegen und Zeitachse transformieren
	rv = los;
	timevec=timevec-timevec(REACTION_START_INDEX);
end;

function rv=adjust_data_auto()		% Baustelle: den aktuellen Datensatz f�r GF vorberiten und alle n�tigen globalen Vaiablen setzen
	global timevec;				% Der Reaktionsstart soll mit 0 zusammenfallen
	global freqvec;				% TODO: nur mit gnuplot, argument in der Klammer: keine Abfragen
	global mdata;					% TODO: pr�fen, ob Punkte links und rechts von 0 gleich verteilt. ggf. letzten Punkt der Vorperiode ranziehen!
	global REACTION_START_INDEX;
	global FIG_MISC;
	if ( timevec(1) < 0)						% In Opus wurde "Reset timebase" gesetzt. Der Reaktionsstart ist bekannt.
		los = get_zero_index(timevec);
		% if (los>1), los=los-1; end;			% Reaktion startet von 0 an
		printf("  Reaktionsstart aus Datensatz: timevec(%d)=%f\n", los, timevec(los));
	else
		[losval, los] = get_pretime(freqvec, timevec, mdata);
		printf("  Automatisch bestimmt: timevec(%d)=%f\n", los, timevec(los));
		printf("  Erster Datenpunkt nach Reaktionsstart bei timevec(%d)=%f\n", los, timevec(los));
		step = timevec(los+1)-timevec(los);
		printf("  Vorgeschlagene �nderung wird uebernommen: dt = %f\n", timevec(los)-step);
		np = timevec(los)-step;
		timevec = timevec-np;
	end;
	REACTION_START_INDEX = los;				% Festlegen und Zeitachse transformieren
	rv = los;
	%timevec=timevec-timevec(REACTION_START_INDEX);
end;

function rv = in_script()
	global command_position;
	global command_ctr;
	rv = 0;
	if (command_position < command_ctr), rv=1; end;
end;


% Baustelle
% TODO:
%     weiter nachhinten setzen, damit octave binary Laden fehlerfrei ausgeführt wird...
%     für alte Position hiernach suchen
%     xvcggdhdg

if ( ispc() )
	nargin=0;
	printf ("You are running this program under MS Windows - Scripting might not work in this environment.");
end;

printf ("Spectroscopy for Octave Vs. %s\n\n  Last change: %s\n", VERSION, LAST_MODIFIED);
hint();
helpfunc();

% TODO: Bearbeitung Infofield: entweder n.d. oder auf dem Basename setzen, damit Konvertierung alter Files funktioniert.
% Funktionen, um nur einen Datenstz binaer zu speichern
% save bin
% load bin
% S=load("filename","options", DATASET.NAME)

if ( nargin > 0 )
    printf("  Executing script...\n");
else
    do
	if ( command_ctr == 1 )
	    global_error = 0;
	    go_further = 0;
	    do
		if ( USE_GUI == 1 )


      		[listenname, foldername] = uigetfile("*","Load File", sprintf("%s/",DEFAULT_DATA_PATH));
			if (length(foldername)>1)
					cd (foldername);
			else
				printf("\n  Warning: No filename assigned.\n  You have to manually specify mdata, freqvec and timevec!\n\n");
				%foldername="not specified";
				%listenname="not specified";
			end;
		else
		  listenname = input ("Dateiname der Matrix (*.*) oder Liste (*.list): ","s");
		end;
		if ( length(listenname) != 0)
		  if ( strcmp(listenname,"ls") )
		    ls *.csv;
		    ls *.dat;
		    ls *.mat;
		  else
		    % hier vorher prüfen ob Extension *.spoc_state
		    if ( strcmp(fileextension(listenname), "spoc-state" ) )
				% Als Octave Binary / Status laden
				printf("  Spoc - Status wird geladen\n");
				load(listenname);
				printf("  ausgefuehrt\n");
		    elseif ( strcmp(fileextension(listenname), "spoc-dataset" ) )
				% Als Octave Binary / Status laden
				printf("  Datensatz wird geladen\n");
				load(listenname);
				printf("  ausgefuehrt\n");
				go_further = 1;
		    elseif ( strcmp(fileextension(listenname), "spd" ) )
				% New File format
				printf("  Spoc dataset (*.spd) will be loaded\n");
				load(listenname,"dataset");
				mdata=dataset.mdata;
				freqvec=dataset.freqvec;
				timevec=dataset.timevec;
				time_axis=dataset.time_axis;
				wavenumber_axis=dataset.wavenumber_axis;
				infofield=dataset.infofield;            % listenname is overwritten %BUG%
				printf("  ...done\n");
				go_further = 1;
		    elseif ( strcmp(fileextension(listenname), "spoc-data" ) )
				% Als Octave Binary / Status laden
				printf("  Datensatz wird geladen\n");
				load(listenname);
				printf("  ausgefuehrt\n");
				go_further = 1;
		    elseif ( strcmp(fileextension(listenname), "dpt") )		% Workaround fuer OPUS
				[freqvec, timevec, mdata] = read_opus_ascii(listenname);
				filetype_name="OPUS_ASCII";
				go_further = 1;
		    else
				[freqvec, timevec, mdata, filetype_name] = read_data(listenname);
				% Check for time jumps and shift if necessary
				idummy = get_timesteps(timevec);
				if (length(idummy)>1), printf("  Die Datei enthaelt einen Zeitsprung und/oder ist mehrteilig.\n  <<pd>> verwenden, um neu zu ordnen\n"); end;
				put();
				if (global_error==1)
					printf("  Datei %s existiert nicht oder ist nicht kompatibel.\n",listenname);
					printf("\n");
					ls *.csv;
					ls *.dat;
					ls *.mat;
					ls *.o3a;
					printf("\n");
				else
					if ( strcmp(filetype_name,"OLIS-3D-ASCII"))
						wavenumber_axis = 'wavelength [nm]';
						inverse_wavenumber_axis = 0;
						intensity_axis = 'absorbance';
						DATA_TYPE = UVVIS;
					elseif ( strcmp(filetype_name,"#OPUS"))
						wavenumber_axis = 'wavenumber [1/cm]';
						inverse_wavenumber_axis = 1;
						intensity_axis = "delta abs.";
						DATA_TYPE = IR;
					else						% Datentyp raten
						if ( max(freqvec) < 1000 )
							wavenumber_axis = 'wavelength [nm]';
							inverse_wavenumber_axis = 0;
							intensity_axis = 'absorbance';
							printf("  Warnung: Unbekannter Datentyp. UV/Vis (nm) wird angenommen.\n");
							printf("  wavenumber_axis und intensity_axis werden gesetzt.\n");
							DATA_TYPE = UVVIS;
						else
							wavenumber_axis = 'wavenumber [1/cm]';
							inverse_wavenumber_axis = 1;
							intensity_axis = "delta abs.";
							printf("  Warnung: Unbekannter Datentyp. Schwingungsspektrum (1/cm) wird angenommen.\n");
							printf("  wavenumber_axis und intensity_axis werden gesetzt.\n");
							DATA_TYPE = IR;
						end;
					endif;
					go_further = 1;
				endif;
		    endif;
		  endif;
		else

		    printf("\n");
		    printf("   Dateneingabe uebersprungen!\n");
		    printf("   Bitte ggf. Werte manuell zuweisen:\n");
		    printf("		mdata		- Matrix mit Spektren als Spaltenvektoren\n");
		    printf("		freqvec		- Vektor der Wellenzahlen\n");
		    printf("		timevec		- Vektor der Messzeiten\n");
		    printf("\n");
			foldername="not specified";
			listenname="not specified";
		    go_further = 1;
		endif;
	    until (go_further);
	endif;
    until ( global_error==0 );
endif;


% For Files in old format: change infofield to infofield.info
try
    s=infofield.info;
catch
    clear infofield;
    infofield.info=s;
    printf("  Converting old-style data\n");
end_try_catch;
if ( isfield(infofield,"freqaxis") )
    wavenumber_axis = infofield.freqaxis;
endif;
if ( isfield(infofield,"timeaxis") )
    time_axis = infofield.timeaxis;
endif;
if ( isfield(infofield,"inversefreq") )
    inverse_wavenumber_axis = infofield.inversefreq;
endif;
if ( isfield(infofield,"intensity") )
    intensity_axis = infofield.intensity;
endif;



TO_DO=0;
select=1;

%	Automatisch Gnuplot einstellen (sollte eigentlich nicht notwendig sein)
%if ( exist("use_grace_state","var") )
%	if ( strcmp(use_grace_state,"on"))
%		toggle_grace_use ;
%	end;
%end;

% File fuer Manipulation der history erstellen

khistory_name = sprintf("%s/spoc-history-%d",SPOC_HISTORY_PATH, PID)
khistory_handle = fopen(khistory_name,"a");
khistory_command = sprintf("history -r %s", khistory_name);
fprintf(khistory_handle,"spoc started\n");
fclose(khistory_handle);

printf("\nProgramm gestartet, PID: %d\n\n",PID);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Main Loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig(FIG_KINETICS);
% einmalig auf ein haeufig benutztes Bild schalten, damit ishold() nicht fig(1) oeffnet...

do

 try                                        % trycatch
  if ( command_position >= command_ctr )		% Interaktiver Modus - TODO: hinterher speichern, damit

    if ( (length(infofield.info)>1) )
        fil_prom_ident = infofield.info;
    else
        fil_prom_ident=basename(listenname);
        if (length(fil_prom_ident)>20)
          fil_prom_ident=sprintf("%s...",fil_prom_ident(1:20));
        end;
    end;

	  printf("#%d/%d/%d:F%dH%d:[%s]", command_ctr, PUT_LEVEL-1, BACKUP_CMD, gcf(), ishold(), fil_prom_ident);
	  % printf("#%d/%d/%d:F%d:[%s]", command_ctr, PUT_LEVEL-1, BACKUP_CMD, gcf(), basename(listenname));
	  % IsHold �ffnet ein Fenster; nicht unbedingt gew�nscht....
	  % History neu schreiben, damit Pfeil up die letzten spoc-kommandos wiederholt

	  eval(khistory_command);

	  if ( SECURITY_MODE == 1 )
	    eingaben = input("+> ","s");
	  else
	    eingaben = input("-> ","s");
	  end;

    if ( length(eingaben)==0), eingaben="nop"; end;
	  dhistory(command_ctr).name = sprintf("%s", eingaben);	% do this only if correct command?...
	  % history updaten
	  khistory_handle = fopen(khistory_name,"a");
	  fprintf(khistory_handle,"%s\n", eingaben);
	  fclose(khistory_handle);

	  history_reference = command_ctr;
	  command_position++;
	  command_ctr++;
  else														% script
	    eingaben = sprintf("%s", dhistory(command_position).name);
	    if (VERBOSITY_LEVEL)
		    printf("  [Skript: %d/%d]->%s\n", command_position, command_ctr, eingaben);
		    fflush(stdout);
	    end;
      command_position++;
  endif;

  % Doppelte Leerzeichen entfernen
  eingaben = compress_ws(eingaben);

% jetzt in eingaben $XXX$ durch den Inhalt der Variablen XXX ersetzen
%  eing_pos=1;
% eingaben_bearbeitet="";
% do
%	if (eingaben(eing_pos)=='$')
%		eing_pos++;
%		changename="";
%		do
%			changename = sprintf("%s%s",changename,eingaben(eing_pos));
%			eing_pos++;
%		until ((eingaben(eing_pos)=='$') || eing_pos > length(eingaben))
%		if ( exist(changename) )
%			eingaben_bearbeitet = sprintf("%s%f",eingaben_bearbeitet,changename);
%	else
%		eingaben_bearbeitet=sprintf("%s%s",eingaben_bearbeitet,eingaben(eing_pos));
%		eing_pos++;
%	end;
%  until (eing_pos > length(eingaben));


  % Bereichsangaben korrigieren
  % eingaben = realign_commandline(eingaben);
  % hier nicht, da dann z.B. cut -10 100 in cut - 10 100 ge�ndert w�rde!
  % solche Korrektur nur direkt bei Rotation
  % wird daher nur f�r bestimmte Befehle ausgef�hrtn DERZEIT NUR ROTATION.

  [ eing_num, eingabe ] = splitstr(eingaben);
  u_choice = eingabe{1};

  % Paranoide Sicherheitseinstellung: Immer alles speichern
  if ( SECURITY_MODE == 1 )
    	    new_filename = sprintf("/tmp/spoc-tmp-%d-%d.spoc-state", PID, command_ctr);
	    save("-binary", new_filename, "*");
  end;


  switch u_choice

	case {"help" "h"}
		menu();

	case {"info"}
		if ( eing_num == 1 )
			info();
		elseif ( strcmp(substring(eingaben,2),"svd") )
			if is_svd
				printf("  SVD-Fits: \n");
				for i=1:length(SVD_FIT)
					if (SVD_FIT(i)==1)
						printf ("Komponente %d (SV=%f): [",i, s(i,i));
						for j=1:length(svdfit(i).parameters)
							printf("  %f", svdfit(i).parameters(j));
						end
						printf("]\n");
					end
				endfor
			else
				printf("  SVD-Zerlegung liegt nicht vor.\n");
			end
		end

	case {"?"}
    if (eing_num==1)
      printf("\n");
      apropos("ALL");
      printf("\n");
    else
      printf("\n");
      apropos(substring(eingaben,2));
      printf("\n");
    end;

  case {"secure"}
    %	if ( strcmp(substring(eingaben,2),"on") )
    %		SECURITY_MODE = 1;
    %	elseif ( strcmp(substring(eingaben,2),"off") )
    %		SECURITY_MODE = 0;
    %	else
    %		printf("  Benutzung: secure on | off\n");
    %	end;

  case{"which"}
    printf ("  %s\n", works_on);
    printf ("Ok.\n");

  case{"setinfo"}
    infofield.info = substring(eingaben,3);

  case {"clf"}
	  if ( eing_num>1 )
		  fig(str2num(substring(eingaben,2)));
	  end;
	  clf;

  case {"color" "c"}
    if (eing_num > 1)
      if (strcmp(substring(eingaben,2),"black") || strcmp(substring(eingaben,2),"k") || strcmp(substring(eingaben,2),"1"))
        DEFAULT_COLOR="k";
        col = [ 0 0 0];
      elseif (strcmp(substring(eingaben,2),"red") || strcmp(substring(eingaben,2),"r") || strcmp(substring(eingaben,2),"2"))
        DEFAULT_COLOR="r";
        col = [ 1 0 0];
      elseif (strcmp(substring(eingaben,2),"green") || strcmp(substring(eingaben,2),"g") || strcmp(substring(eingaben,2),"3"))
        DEFAULT_COLOR="g";
        col = [ 0 1 0];
      elseif (strcmp(substring(eingaben,2),"blue") || strcmp(substring(eingaben,2),"b") || strcmp(substring(eingaben,2),"4"))
        DEFAULT_COLOR="b";
        col = [ 0 0 1];
      elseif (strcmp(substring(eingaben,2),"magenta") || strcmp(substring(eingaben,2),"m") || strcmp(substring(eingaben,2),"5"))
        DEFAULT_COLOR="m";
        col = [ 1 0 1];
      elseif (strcmp(substring(eingaben,2),"cyan") || strcmp(substring(eingaben,2),"c") || strcmp(substring(eingaben,2),"6"))
        DEFAULT_COLOR="c";
        col = [ 0 1 1];
      elseif (strcmp(substring(eingaben,2),"white") || strcmp(substring(eingaben,2),"w") || strcmp(substring(eingaben,2),"7"))
        DEFAULT_COLOR="w";
        col = [1 1 1];
      else
        printf("  Sytax: color black (k,1) | red (r,2) | green (g,3) | blue (b,4) | magenta (m,5) | cyan (c,6) | white (w,7)\n");
        printf("  col = [ 0..1 0..1 0..1]\n");
      end;
    else
      printf("  Sytax: color black | red | green | blue | magenta | cyan | white\n");
      printf("  Sytax: c k | r | g | b | m | c | w\n");
    end;

  case {"select_path"}
    nr_paths = length(SEARCHPATH);
    printf("  %d Suchpfade existieren:\n", nr_paths);
    for i=1:nr_paths
      printf("  %d. %s\n", i, SEARCHPATH{i});
    end;
    if ( exist("message") > 0 )
      SEARCHPATH{nr_paths+1} = uigetdir();
    else
      SEARCHPATH{nr_paths+1} = input("  Neuer Suchpfad: ","C");
    end;
    printf("  Pfad hinzugefügt\n");
    printf("  saveconfig zum Speichern benutzen\n");

  case {"saveconfig"}		% Einstellungen speichern
    save "~/.spocrc" SEARCHPATH LIVE_MODE     	%ZENITY_PATH SPLINEPATH1 SPLINEPATH2 GRACEPATH1 GRACEPATH2 GRACEPATH3 LIVE_MODE
    printf("  ~/.spocrc geschrieben\n");

  case {"install"}
    if ( eing_num > 1 )
      if ( strcmp(substring(eingaben, 2),"all" ) )
          progpath=pwd();
          fd2=fopen("~/.octaverc","a");
          fprintf(fd2,"addpath(\'%s\')", progpath);
          fclose(fd2);
          printf("  ~/.octaverc geschrieben\n");
          save "~/.spocrc" SEARCHPATH LIVE_MODE          % SPLINEPATH1 SPLINEPATH2 GRACEPATH1 GRACEPATH2 GRACEPATH3
          printf("  ~/.spocrc geschrieben\n");
      else
          printf("  Unbekannter Befehl.\n");
      end;
    else
      printf("____________________________________________________________\n\n");
      printf("Benoetigte Pakete:\n");
      printf("	io\n	optim\n	gcvspl\n	zenity\n	plot\n	graceplot\n");
      printf("Pakete ggf. installieren und Pade einrichten\n");
    end;

  case {"bench"}				% ein einfacher Benchmark über svd, rotation, gf
    if (eing_num == 1)
      if (in_bench==0)
          if ( 0==message("Einen Benchmarktest starten? Geladene Daten werden geloescht!","question") )
        loaded_files = 0;				% Multi-Modus ggf. rücksetzen
        % add_to_history("load 3ddata benchtest.x3d");
        [freqvec, timevec, mdata, filetype_name] = read_data("benchtest.x3d");
        gf_ITERATIONS=3;
        gf_k_start = [ 0, 0, 0 ];
        gf_k_stop = [ 100, 100, 100];
        add_to_history("svd");
        add_to_history("rotation 1 - 3");
        add_to_history("globalfit 3");
        add_to_history("bench");
        in_bench = 1;
        tic();
	    else
		    printf("  Abgebrochen.\n");
	    end;
    else
      in_bench = 0;
      bench_time = toc();
      printf("  Benchmark beendet. Berechnung dauerte %f Sekunden.\n", bench_time);
      bench_system=inputdlg("Please enter a name:","System Information");
      try
        load "spoc.benches"
      catch
        printf ("  Noch keine getesteten Systeme vorhanden\n");
      end_try_catch;
      if ( exist ("bench_info") )
        bench_position = length(bench_info)+1;
      else
        bench_position = 1;
      end;
      bench_info{bench_position}.name = bench_system;
      bench_info{bench_position}.time = bench_time;
      save "spoc.benches" bench_info
    end;
  else						% Plotten
    load "spoc.benches";
    fig (FIG_BENCH);
    clf();
    for i=1:length(bench_info)
      bench_bt(1,i)=bench_info{i}.time;
      bench_bt(2,i)=0;
      bench_lg{i}=sprintf("%s (%d s)",bench_info{i}.name, bench_info{i}.time);
    end;
    bar(bench_bt);
    legend(bench_lg);
    xlabel("System");
    ylabel("Zeit (s)");
    title("Time for gf");
  end;

  case {"live"}
		LIVE_MODE = LIVE_MODE + 1;
		if (LIVE_MODE==2), LIVE_MODE=0; end;
		if (LIVE_MODE==0)
			printf("  Live-Modus aus\n");
		else
			printf("  Live-Modus ein\n");
		end;

  case {"logtime" }
		LOG_KINETICS = LOG_KINETICS + 1;
		if (LOG_KINETICS==2), LOG_KINETICS=0; end;
		if (LOG_KINETICS==0)
			printf("  Dekadische Zeitachse\n");
		else
			printf("  Logarithmische Zeitachse\n");
		end;

% included by Paul Fischer
% reduces the data set with increasing stepswidth
  case {"reduce"}
    if(eing_num == 1)
      put();
      [mdata, timevec, new_reactionStartIdx] = reduceData(mdata, timevec, REACTION_START_INDEX);
    elseif(eing_num == 2)
      put();
      [mdata, timevec, new_reactionStartIdx] = reduceData(mdata, timevec, REACTION_START_INDEX, str2num( substring(eingaben,2) ));
    elseif(eing_num >= 3)
      put();
      [mdata, timevec, new_reactionStartIdx] = reduceData2(mdata, timevec, str2num( substring(eingaben,2) ), str2num( substring(eingaben,3) ));
    endif;
    if(new_reactionStartIdx)
      REACTION_START_INDEX=new_reactionStartIdx;
    endif;

% included by Paul Fischer
% calculates Difference spectra by taking averaged dark period (t<0) as reference I0
% using Lambert-Beer-Law Diff=log10(I0/I)->bl absorbance
  case {"diffspec"}
    if ( eing_num == 1 )
      put();
      mdata = makeDiffSpec(mdata, timevec);
    elseif ( eing_num == 2 )
      file_num = str2num( substring(eingaben,2) );
      baseline_IR = mdata_a{file_num};
      if isvector(baseline_IR)
        baseline_WZ = freqvec_a{file_num};
        [mdata, freqvec] = subtractBL(mdata, freqvec, baseline_IR, baseline_WZ);
      else
        printf("  baseline Spectrum has to be one dimensional (single spectrum\n)");
      endif;
    endif

  case {"reset_time"}			% Zeitachse immer aufsteigend
    time_axis_index_position=timevec(1);		% bei reset_timebase werden alle vorherigen Werte negativ
    one_timestep = 0;						% sollte in read_data integriert werden
    for i=2:length(timevec)					% i.e. über process_data
      if ( timevec(i) <= time_axis_index_position )
        one_timestep++;
        if (one_timestep>1); printf("  Warnung: reset timebase mehrfach vorhanden\n"); end;
        for j=1:(i-1)				% vorhergehende Zeiten alle negativ
          timevec(j)=timevec(j)-time_axis_index_position;
        end;
        printf("  Info: Die Zeitachse wurde verschoben: Wert: -%f\n", time_axis_index_position);
      end;
      time_axis_index_position = timevec(i);
    end;

  case {"splitzero" }			% Den aktuellen Datensatz spalten
     [ fdummy, tdummy, mdummy, splits ] = process_data(freqvec, timevec, mdata);
     %  Jetzt aufspalten in splits unterbereiche; jeweils der Bereich links und rechts eines Zeitsprunges wird mitgenommen
     if ( length(splits) > 1 )
        kkv = timevec(1:splits(2)-1);
        ddm = mdata(:,1:splits(2)-1);
        dummy = sprintf("Part %d (%d-%d, Jump: %d) of %s", 1, 1, splits(2)-1, splits(1), basename(listenname));
        store_data(freqvec, kkv, ddm, dummy);
        printf("  Bereich %d: %d - %d\n", 1, 1, splits(2)-1);
        if ( length(splits)>2 )
            for i=2:length(splits)-1
                kkv = timevec(splits(i-1):splits(i+1)-1);
                ddm = mdata(:,splits(i-1):splits(i+1)-1);
                dummy = sprintf("Part %d (%d-%d, Jump: %d) of %s", i,splits(i-1),splits(i+1)-1, splits(i), basename(listenname));
                store_data(freqvec, kkv, ddm, dummy);
                printf("  Bereich %d: %d - %d\n", i, splits(i-1), splits(i+1)-1);
            end;
        else
          i=2;
        end;
        kkv = timevec(splits(i):end);
        ddm = mdata(:,splits(i):end);
        dummy = sprintf("Part %d (%d-%d, Jump: %d) of %s", i+1, splits(i), length(timevec), splits(i),basename(listenname));
        store_data(freqvec, kkv, ddm, dummy);
        printf("  Bereich %d: %d - %d\n", i+1, splits(i), length(timevec));
    end;


  case {"align" "al"}
	% Zeitspr�nge entfernen; die Zeitachse wird einfach sequentiell angeordnet
	  [freqvec,timevec,mdata,splits]=process_data(freqvec,timevec,mdata,1);


  case {"ad" }
    if ( eing_num == 1 )
        clear dummy;
        dummy=adjust_data();
        printf("  Setting REACTION_START_INDEX=%d\n",dummy);
        dummy2=sprintf("ad %d",dummy);								% ersetzen for Skript TODO or NOT
        dhistory(history_reference).name=dummy2;
    elseif ( strcmp(substring(eingaben,2),"auto") )
        clear dummy;
        dummy=adjust_data_auto();
        printf("  Setting REACTION_START_INDEX=%d\n",dummy);
    else
      REACTION_START_INDEX = str2num(substring(eingaben,2));
    end;
    if (VERBOSITY_LEVEL)
        printf("Vorschlag Naechster Schritt:\n");
        printf("      Grundlinienkorrektur zur Entfernung von Drifts oder Temperaturschwankungen.\n");
        printf("      fuer Einzelheiten: ? baseline\n");
    end;

  case {"process" "pd"}			% Der aktuelle Datensatz wird angepasst:		Baustelle
      % ggf. Aufspalten, ggf. Nullpunktverschiebung, etc.
      splits = get_timesteps(timevec);
      if ( length(splits) ==  1)
          printf("  Die Zeitachse ist gueltig. <<ad>> zur Nullpunkteinstellung verwenden\n");
      elseif ( length(splits) == 2 )												% 1  - kein Zeitsprung, 2 - 1 Zeitsprung, no split necessary
          printf("  Die Daten enthalten 1 Zeitsprung. Die Zeitachse wird korrigiert.\n");
          printf("  <<ad>> zur Nullpunkteinstellung verwenden\n");
          [ freqvec, timevec, mdata, dsplits ] = process_data(freqvec, timevec, mdata);
      else
          printf("  Mehrere Zeitspruenge vorhanden. Datei wird aufgeteilt.\n");
          for i=2:length(splits)-1
              ptimevec = timevec(splits(i-1):splits(i+1)-1);
              pmdata = mdata(:,splits(i-1):splits(i+1)-1);
              [freqvec, ptimevec, pmdata] = process_data(freqvec, ptimevec, pmdata);
              % dummy = sprintf("Section_%d_(%d_to_%d_ Change_%d)_of_File_%s", i-1,splits(i-1),splits(i+1)-1, splits(i), basename(listenname));
              dummy = sprintf("%s_Section_%d_Pts_%d_to_%d_Jp_%d.x3d", basename(listenname),i-1,splits(i-1),splits(i+1)-1,splits(i));
              printf("%s\n",dummy);
              store_data(freqvec, ptimevec, pmdata, dummy);
          end;
          i=i+1;
          ptimevec = timevec(splits(i-1):end);
          pmdata = mdata(:,splits(i-1):end);
          [freqvec, ptimevec, pmdata] = process_data(freqvec, ptimevec, pmdata);
          dummy = sprintf("Section_%d_(%d_to_%d_Change_%d)_of_File_%s", i-1,splits(i-1),length(timevec), splits(i), basename(listenname));
          printf("%s\n",dummy);
          store_data(freqvec, ptimevec, pmdata, dummy);
          if (VERBOSITY_LEVEL)
              printf("Vorschlag Naechster Schritt:\n");
              printf("      # <<nr>>                       ggf. auf den zu bearbeitenden Datensatz schalten\n");
              printf("      ad | adjust_data    Reaktionsbeginn festlegen\n");
          end;
      end;

  case {"get_average" }			% Lädt eine Liste von 3D-Spektren, bildet den Mittelwert und schreibt ihn in die globalen Variablen. Auf Wunsch mit automatischer Startdetektion
    specnum = 0;								% Baustelle
    if ( eing_num > 1 )				%
      % Liste aus der Zeile holen
      for i=2:eing_num
        av_filename{i}=substring(eingaben,i);
        specnum++;
      end;
    else
      % Zenity....
      %speclist = file_selection("Spektren eingeben","multiple", sprintf("%s/",pwd()));
      [speclist,specpath] = uigetfile("*","Select Files for average",".","MultiSelect","On")
      if ( max(size(isascii(speclist(1)))) > 1)
        specnum = max(size(speclist));
        for i=1:specnum
          av_filename{i} = sprintf("%s", speclist{i});
        end;
      else
        specnum = 1;
        av_filename{1} = sprintf("%s", speclist);
      end;
    end;
    printf("  %d Files werden bearbeitet.\n", specnum);
    min_pretime = 1e20;
    %	Files übereinanderlegen, so dass Reaktion immer zu gleichem Zeitpunkt startet
    %	Interpoliert wird auf das 1. Spektrum
    for i=1:specnum
        [m_freqvec{i}, m_timevec{i}, m_mdata{i}, m_filetype_name{i}] = read_data(av_filename{i});
        m_PRETIME{i} = get_pretime(m_freqvec{i}, m_timevec{i}, m_mdata{i});
        m_INDEX{i} = time_get_index(m_PRETIME{i}, timevec);
        if (m_PRETIME{i} < min_pretime)
          min_pretime = m_pretime{i};
        end;
        printf("  Spektrum %d von %d (%s) gelesen, Reaktionsstart: %f\n", i, specnum, av_filename{i}, m_PRETIME{i});
    end;
    printf("  fertig.\n");


  case {"calc" }
	  printf("  Noch nicht implementiert.\n");


  case {"unset" }
    if ( strcmp(substring(eingaben,2),"pretime") )
      PRE_TIME = 0;
      PRE_INDEX = 0;
    else
      printf("  Unbekannte Funktion.\n");
      apropos("unset");
    end;


  case {"set" }
    if ( eing_num > 1)
      if ( strcmp(substring(eingaben,2),"u") )
              works_on = "u";
      elseif ( strcmp(substring(eingaben,2),"s") )
              works_on = "s";
      elseif ( strcmp(substring(eingaben,2),"v") )
              works_on = "v";
      elseif ( strcmp(substring(eingaben,2),"o") )
              works_on = "o";
      elseif ( strcmp(substring(eingaben,2),"hold") )
              hold;
              gnuplot_hold=1;
      elseif ( strcmp(substring(eingaben,2),"print") )
              OUTPUT_FORMAT = substring(eingaben, 3);
      elseif ( strcmp(substring(eingaben,2),"spline"))
          printf("\n  Definierte Splinefunktionen:\n");
          whos BL_* ;
          BL_SPLINE = input("  Bitte ausw�hlen: ");
      elseif ( strcmp(substring(eingaben,2),"pretime") )
          if ( eing_num == 4 )
            PRE_TIME_START = str2num( substring(eingaben,3) );
            PRE_TIME = str2num( substring(eingaben,4) );
          elseif ( eing_num == 3 )
            PRE_TIME_START = timevec(1);
            PRE_TIME = str2num( substring(eingaben,3) );
          elseif ( eing_num == 2 )
            printf("  Warnung: Wert wird automatisch gesetzt. Bitte überprüfen (plot pretime)!\n");
            PRE_TIME = get_pretime(freqvec, timevec, mdata);

          else
            printf("  Benutzung: set pretime [<start> [<ende>]]\n");
          end;
              printf("  Reaktionsstart bei: %f(%d)\n", PRE_TIME, time_get_index(PRE_TIME, timevec));
      else
              printf("  Syntax: set u | s | v | o | hold | print <Dateityp>\n");
      endif;
    else
	    printf("  Syntax: set u | s | v | o | hold | print <Dateityp>\n");
    endif;

  case {"logscale" }		% Baustelle: process und adjust m�ssen vorher erfolgt ein
          put();
    if ( eing_num == 2 )
        resolution = str2num(substring(eingaben,2));
    else
        resolution = 50;
        printf("  Keine Vektorgroesse angegeben. Setze 50.\n");
    endif;
    % Todo: Logspace ab Pretime....
    % Umschreiben
    if ( timevec(REACTION_START_INDEX+1)>=0 )				% 1. Wert ist immer Original
      x_log_scale=logspace(log10(timevec(REACTION_START_INDEX+1)),log10(timevec(length(timevec))), resolution);
      x_neu(1:REACTION_START_INDEX) = timevec(1:REACTION_START_INDEX);
      mdata_neu(:,1:REACTION_START_INDEX) = mdata(:,1:REACTION_START_INDEX);
      for i=1:length(x_log_scale)-1
        x_neu(REACTION_START_INDEX+i) = mean(x_log_scale(i:i+1));
        t_i_start = time_get_index(x_log_scale(i),timevec);
        t_i_stop  = time_get_index(x_log_scale(i+1), timevec);
        %printf("Wert: %f Index von: %d bis %d\n", x_neu(x_neu_start_index+i), t_i_start, t_i_stop);
        mdata_neu(:,REACTION_START_INDEX+i) = mean(mdata(:,t_i_start:t_i_stop),2);
      end;
      mdata = mdata_neu;
      timevec = x_neu;
    else
      printf("  logscale: Fehler! Reaktion beginnt bei negativen Werten!\n");
      printf("  Bitte manuell korrigieren!\n");
    end;

  case { "smooth" }
    printf("  Please use tsmooth or fsmooth\n");

  case { "tsmooth" }
	  put();
	  if ( eing_num == 1 )
	    printf("  Keine Vektorgroesse angegeben, setze 4\n");
	    smooth_order = 4;
	  else
	    smooth_order = str2num(substring(eingaben, 2));
	  end
	  for i=1:length(freqvec)
	    mdata(i,:) = medfilt1(mdata(i,:),smooth_order);
	  end

  case {"fsmooth" }		% Baustelle: in der Frequenzachse glaetten...
	  put();
	  if ( eing_num == 1 )
	    printf("  Keine Vektorgroesse angegeben, setze 4\n");
	    smooth_order = 4;
	  else
	    smooth_order = str2num(substring(eingaben, 2));
	  end
	  for i=1:length(timevec)
	    mdata(:,i) = medfilt1(mdata(:,i),smooth_order);
	  end

  case {"resample" }		% TODO: - 	Mit Nutzung von Interp1, als extra Funktion....
    put();
    if ( eing_num == 3 )
        resample_counter = str2num(substring(eingaben,3));
        if ( strcmp(substring(eingaben, 2),"t") )
      starttime=timevec(1);
      stoptime=timevec(length(timevec));
      inctime=(stoptime-starttime)/resample_counter;
      timevec_new = [starttime:inctime:stoptime];
      mdata_new = zeros(length(freqvec),length(timevec_new));
      for i=1:length(freqvec)
          mdata_new(i,:) = interp1(timevec,mdata(i,:), timevec_new);
      end;
      timevec=timevec_new;
      mdata=mdata_new;
      clear mdata_new;
      clear timevec_new;
        elseif ( strcmp(substring(eingaben, 2),"w") )
      startwl=freqvec(1);
      stopwl=freqvec(length(freqvec));
      incwl=(stopwl-startwl)/resample_counter;
      freqvec_new = [startwl:incwl:stopwl];
      mdata_new = zeros(length(freqvec_new), length(timevec));
      for i=1:length(timevec)
          mdata_new(:,i) = interp1(freqvec,mdata(:,i),freqvec_new);
      end;
      freqvec=freqvec_new';
      mdata=mdata_new;
      clear freqvec_new;
      clear mdata_new;
        else
      printf("  resample t|w <nr>\n");
        endif;
    else
        printf("  resample t|w <nr>\n");
    endif;

  case {"freqidx" }
    [a,b] = ir_get_index(str2num(substring(eingaben,2)), freqvec);
    printf("  %d (%f)\n", a, b);

  case {"timeidx" }
    [a,b] = time_get_index(str2num(substring(eingaben,2)), timevec);
    printf("  %d (%f)\n", a, b);

  case {"timeshift" }			% die Kurve in der Zeitachse verschieben
    put();
    if ( eing_num==1 )						% Kein Argument: Reaktionsbeginn auf 0
		printf("  Noch nict verfügbar\n");
		value = get_pretime(freqvec, timevec, mdata);
		timevec = timevec - value;
		printf("  Reaktionsstart bei 0 - alter Wert: %f. Bitte prüfen!\n", value);
    else
		value = str2num(substring(eingaben,2));
		timevec = timevec - value;
    end;

  case {"zero" }			% Eine Verschiebung der Daten auf der X-Achse durchführen
    put();						% Baustelle: Bedeutung von PRE_TIME ändern
    if ( eing_num > 1)
      if ( strcmp(substring(eingaben,2),"pretime") )
    	    zeropoint = PRE_TIME;
      else
    	    zeropoint = str2num(substring(eingaben,2));
      end;
      # Die Variablen timevec und mdata anpassen.
      startidx = time_get_index(zeropoint, timevec);
      newlength = rows(timevec)-startidx;
      newtimevec = timevec(startidx:rows(timevec));
      newmdata = mdata(:,startidx:rows(timevec));
      newtimevec = newtimevec - zeropoint;
#      clear timevec; clear mdata;
      timevec = newtimevec;
      mdata = newmdata;
      clear newtimevec; clear newmdata;

    elseif (eing_num == 1)
      offset = timevec(1);
      timevec = timevec - offset;

    else
      apropos("zero");
    endif;

  case {"subtract" }
    put();
    if ( eing_num == 2 )
	    vektor = mdata(:,str2num(substring(eingaben,2)));
	  for i=1:columns(mdata)
	    mdata(:,i) = mdata(:,i) - vektor;
	  end
    else
	    printf("  Syntax: subtract <nr>            ... Spektrum <nr> abziehen\n");
	    printf("          subtract <nr1> <nr2>     ... Mittelwert abziehen\n");
    end

  case {"filt"}
    put();
    if ( eing_num == 4 )
	     filter_order = str2num(substring(eingaben,3));
	      filter_length = str2num(substring(eingaben,4));
	  if ( strcmp(substring(eingaben,2),"time") )
	    for i=1:rows(mdata)
	      mdata(i,:) = sgolayfilt(mdata(i,:),filter_order, filter_length);
	    endfor;
	  else
	    for i=1:columns(mdata)
	      mdata(:,i) = sgolayfilt(mdata(:,i),filter_order, filter_length);
	    endfor;
	  endif;
    else
	    printf("  Syntax: filt time|wz order length\n");
      printf("  applies sgolayfilt\n");
    endif;

  case {"ifilt"}       % Interactive FT-based Filter function
    printf("  Interactive filter adjustment.\n");
    freq_dummy = 1:length(freqvec);
    fig(FIG_MISC);
    plot(freq_dummy, mdata(:,1));
    fig(FIG_MISC+1);
    plot(real(fft(mdata(:,1))));
    yscale(input("Scale y from: "), input("Scale y to: "));
    do
        fig(FIG_MISC);
        f_centerfreq=str2num(input("  CenterFrequency ->","c"));
        f_freqwidth =str2num(input("  FrequencyWidth ->","c"));
        plot(freq_dummy, mdata(:,1), freq_dummy, FouFilter(mdata(:,1)',1,f_centerfreq,f_freqwidth,1,1));
        legend("original","filtered");
        go_on=input("Try other values? (y/n) ->","c");
    until (go_on=='n');
    if ( input("Apply? (y/n) -> ","c")=='y' )
        put();
        for i=1:columns(mdata)
          mdata(:,i) = FouFilter(mdata(:,i)',1,f_centerfreq,f_freqwidth,1,1);
        endfor
    else
      printf("  Changes discarded\n");
    end;

  case {"defringe"}
    if (eing_num == 2)
              % This calculates ( 1/2 * (mdata + 1/2*mdata- + 1/2*mdata+ ) )
              % where mdata- and mdata+ are the original dataset shifted by
              % +/- 1/2*fringelength
      fshift = str2num(substring(eingaben,2));
      d_freqvec_l = freqvec - 0.5*fshift;
      d_freqvec_r = freqvec + 0.5*fshift;
      d_freqstep=(freqvec(2)-freqvec(1))/2;      % Hochsamplen
      n_freqvec=freqvec(1):d_freqstep:freqvec(length(freqvec));
      [n_f, n_t, n_mdata]=wave_resample(freqvec,timevec,mdata,n_freqvec);
      [n_f, n_t, n_mdatal]=wave_resample(d_freqvec_l,timevec,mdata,n_freqvec);
      [n_f, n_t, n_mdatar]=wave_resample(d_freqvec_r,timevec,mdata,n_freqvec);
      n_mdata = 0.5 * (n_mdata + 0.5*n_mdatal + 0.5*n_mdatar);
      freqvec = n_freqvec;
      mdata = n_mdata;
      clear d_freqvec_l;
      clear d_freqvec_r;
      clear d_freqstep;
      clear n_mdata;
      clear n_mdatal;
      clear n_mdatar;
      printf("  Warning: Experimental Function might not work as expected\n");
    else
      printf("  Usage: defringe <#fringelength>\n");
      printf("  #fringelength is in units of the frequency axis\n");
      printf("  Experimental function for removing fringes from spectra.\n");
      printf("  Fringelength should be small compared to any bands to be observed\n");
      printf("  This is experimental code!\n");
    end;

  case {"import" }
        put();
	      mdata = ir_matrix;
	      freqvec = wavenumbers;
	      timevec = time;

  case {"timekill" "tk" }
    if (eing_num > 2)
      put();
      tfromi=time_get_index(str2num(substring(eingaben,2)), timevec);
      ttoi=time_get_index(str2num(substring(eingaben,3)),timevec);
      offset = timevec(ttoi+1) - timevec(tfromi);
      timevec(tfromi:ttoi)=[];
      timevec(tfromi:end)=timevec(tfromi:end)-offset;
      mdata(:,tfromi:ttoi)=[];
    else
      apropos("timekill");
    end;

  case {"remove" }
    if (eing_num > 2)
      put();
      tfromi=time_get_index(str2num(substring(eingaben,2)), timevec);
      ttoi=time_get_index(str2num(substring(eingaben,3)),timevec);
      %offset = timevec(ttoi+1) - timevec(tfromi);
      timevec(tfromi:ttoi)=[];
      %timevec(tfromi:end)=timevec(tfromi:end)-offset;
      mdata(:,tfromi:ttoi)=[];
    else
      apropos("remove");
    end;

  case { "freq_index" }
    if (eing_num > 1)
      printf("  Element No. %d\n", get_index(str2num(substring(eingaben,2)),freqvec));
    endif;

  case {"freq_remove" }
    if (eing_num > 2)
      put();
      ffromi=get_index(str2num(substring(eingaben,2)), freqvec);
      ftoi=get_index(str2num(substring(eingaben,3)), freqvec);
      %offset = timevec(ttoi+1) - timevec(tfromi);
      freqvec(min(ffromi,ftoi):max(ffromi,ftoi))=[];
      %timevec(tfromi:end)=timevec(tfromi:end)-offset;
      mdata(min(ffromi,ftoi):max(ffromi,ftoi),:)=[];
      printf("  Removed datapoints %d - %d\n", ffromi, ftoi);
    elseif (eing_num > 1)
      put();
      ffromi=get_index(str2num(substring(eingaben,2)), freqvec);
      freqvec(ffromi)=[];
      mdata(ffromi,:)=[];
      printf("  Removed datapoint %d\n", ffromi);
    else
      apropos("freq_remove");
    end;

  case {"freq_zero"}
    if (eing_num > 2)
      put();
      ffromi=get_index(str2num(substring(eingaben,2)), freqvec);
      ftoi=get_index(str2num(substring(eingaben,3)), freqvec);
      %offset = timevec(ttoi+1) - timevec(tfromi);
      %freqvec(min(ffromi,ftoi):max(ffromi,ftoi))=[];
      %timevec(tfromi:end)=timevec(tfromi:end)-offset;
      mdata(min(ffromi,ftoi):max(ffromi,ftoi),:)=0;
      printf("  datapoints %d - %d set to 0\n", ffromi, ftoi);
    else
      apropos("freq_zero");
    end;

  case {"limit"}    %PF
    if ( eing_num >= 3 )
      if( eing_num >= 5)
        upperTlim = str2num(substring(eingaben,4));
        lowerTlim = str2num(substring(eingaben,5));
        if(lowerTlim>upperTlim)
          tempT=lowerTlim;
          lowerTlim=upperTlim;
          upperTlim=tempT;
        endif;
        upperTind=time_get_index(upperTlim,timevec);
        lowerTind=time_get_index(lowerTlim,timevec);
      else
        upperTind=length(timevec);
        lowerTind=1;
      endif;

      put();
      add_to_history("limit");
      upperZlim=str2num(substring(eingaben,2));
      lowerZlim=str2num(substring(eingaben,3));
      if(lowerZlim>upperZlim)
          tempZ=lowerZlim;
          lowerZlim=upperZlim;
          upperZlim=tempZ;
      endif;

      for i=1:rows(mdata)
        for j=lowerTind:upperTind
          if (mdata(i,j)>upperZlim)
            mdata(i,j)=upperZlim;
          elseif(mdata(i,j)<lowerZlim)
            mdata(i,j)=lowerZlim;
          endif;
        endfor
      endfor;
    else
      apropos("limit");
    endif;

  case {"cut" }
      if ( eing_num >= 2 )
        put();
        add_to_history("unset pretime");
        if ( strcmp(substring(eingaben,2),"pretime") )


        else
    startparameter=substring(eingaben,2);
    if ( eing_num == 3 )
                stopparameter=substring(eingaben,3);
          else
      stopparameter="end";
        end;
    if ( strcmp(startparameter,"-") || strcmp(startparameter,"start") )
          start_index = 1;
          else
          start_area = str2num(substring(eingaben,2));
      if ( start_area < timevec(1) )
          start_index = 1;
      else
              start_index = time_get_index(start_area, timevec);
      end;
          endif;
          if ( strcmp(stopparameter,"-") || strcmp(stopparameter,"end"))
            stop_index = length(timevec);
          else
            stop_area  = str2num(substring(eingaben,3));
            stop_index = time_get_index(stop_area, timevec);
        endif;
          new_timevec = timevec(start_index:stop_index);
          new_mdata = mdata(:,start_index:stop_index);
  #      	clear timevec; clear mdata;
          timevec = new_timevec; mdata = new_mdata;
          clear new_timevec; clear new_mdata;
        end;
      else
        apropos("cut");
      endif;

  case {"extend" }
    if ( eing_num>=2 )				% extends the current dataset in time
      if (eing_num > 2) %			estimate spectrum as average
        start_area=time_get_index(str2num(substring(eingaben,2)),timevec);
        stop_area=time_get_index(str2num(substring(eingaben,3)),timevec);
        extend_until = str2num(substring(eingaben,4));
        extend_spectrum = mean(mdata(:,start_area:stop_area),2);
        % clear start_area; clear stop_area;
      else
        extend_spectrum = mdata(:,columns(mdata));		% if no range specified, use last spectrum
        extend_until = str2num(substring(eingaben, 2));
      endif;
      extend_step=timevec(length(timevec))-timevec(length(timevec)-1);
      i=length(timevec);
      do
        i++;
        timevec(i) = timevec(i-1)+extend_step;
        mdata(:,i) = extend_spectrum;
      until (timevec(i)>=extend_until);
      % clear extend_spectrum; clear extend_until; clear extend_step;
    else
      printf(" Usage: extend <endtime> OR extend av1 av2 endtime\n");
      apropos("extend");
    endif;

  case {"cutwz" }
    if (eing_num>=2)
      put();
      startparameter = substring(eingaben,2);
      stopparameter = substring(eingaben,3);
      [startwert, realsta_wz] = ir_get_index(str2num(startparameter),freqvec);
      [stopwert, realsto_wz] = ir_get_index(str2num(stopparameter),freqvec);
      if (stopwert<startwert)
          h=stopwert;
          stopwert=startwert;
          startwert=h;
      end;
      printf("  Bereich: %f - %f\n", realsta_wz, realsto_wz);
      new_freqvec = freqvec(startwert:stopwert);
      new_mdata=mdata(startwert:stopwert,:);
      freqvec = new_freqvec; mdata = new_mdata;
      clear new_freqvec; clear new_mdata;
    else
	apropos("cutwz");
  endif;

  case {"integ"}             %Integration einer Bande über 3D-Datensatz; Paul Fischer
    if (eing_num>=3)
      wz_border1 = str2num(substring(eingaben, 2));
      wz_border2 = str2num(substring(eingaben, 3));
      max_wz=max(freqvec); min_wz=min(freqvec);
      if (min_wz<wz_border1<max_wz) && (min_wz<wz_border2<max_wz)
        [in_border1, realwzbord1] = ir_get_index(wz_border1,freqvec);
        [in_border2, realwzbord2] = ir_get_index(wz_border2,freqvec);
        if (in_border2 < in_border1)
          clear h;
          h=in_border2;
          in_border2 = in_border1;
          in_border1 = h;
        endif;
        wz_t=[freqvec(in_border1),freqvec(in_border2)];
        for i=1:columns(mdata)
          ir_t=[mdata(in_border1,i),mdata(in_border2,i)];
          linint=interp1(wz_t, ir_t, freqvec(in_border1:in_border2));

          int(i)=sum(mdata(in_border1:in_border2,i)-linint);
          if i==columns(mdata)   %Test
            figure(FIG_LIVE);
            ptit=["Integrierte Bande für t = ",num2str(timevec(i))," s"];
            plot(freqvec,mdata(:,i),freqvec(in_border1:in_border2), linint);
            title(ptit);
            xlabel("Wellenzahl/[cm^{-1}]");
            ylabel("Intensität");
            hold on;
            x=freqvec(in_border1:in_border2);
            X=[x,fliplr(x)];
            Y=[linint,fliplr(mdata(in_border1:in_border2,i))];
            fill(X,Y,'r');
            hold off;
          endif;
        endfor;
        figure(FIG_LIVE+1);
        ptit=["Kinetik der Bande zwischen ",num2str(wz_border1), " und ",num2str(wz_border2), " cm^{-1}"];
        plot(timevec,int);
        title(ptit);
        xlabel("Zeit/s");
        ylabel("Bandenintegral");

        %Abfrage Speichern
        fflush(stdout);
        clear jn;
        printf("Soll Ergebnis gespeichert werden?\n");
        jn = input("[y/n] > ","c");
        if jn == "j"
          fflush(stdout);
          clear file;
          printf("Eingabe Dateiname:\n")
          file=input(" > ","c");
          save_ir_file(file,timevec,int)
        endif;
      else
        printf("Grenzen außerhalb des Frequenzbereichs\n");
        printf("Obergrenze:  %d \n",max_wz);
        printf("Untergrenze: %d \n",min_wz);
      endif;
    else
      apropos("integ");
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  case  {"calibration" "cal"}
    %Request calibration points
    jn="n";
    cal_count="n";
    if length(is) && length(should)
        fflush(stdout);
        clear jn;
        printf("  Found calibration data. Use it?\n");
        is
        should
        jn=input("[y/n] > ","s");
    endif

    # enter by hand
    if jn!="y"
      fflush(stdout);
      clear cal_count;
      printf("  Enter number of calibration points:\n");
      cal_count = input("> ");
      cal_count = cast(cal_count,'int8');
      if isinteger(cal_count)
        clear is;
        clear should;
        is=[];
        should=[];
        for i=1:cal_count
          fflush(stdout);
          printf("%d. IS value: \n", i);
          is(i)=input(" > ");
          printf("%d. SHOULD value: \n", i);
          should(i)=input(" > ");
        endfor
        fflush(stdout);
        clear jn;
        printf("  Calibration points entered. Proceed?\n");
        jn=input("[y/n] > ","s");
      else
        printf("Please enter an integer specifying the number of calibration points.\n");
      endif
    endif

    if jn=="y"
      params = [1,0];
      [fitfun, fitpar] = leasqr(is,should,params,@linear);
      figure(CALIBRATION_FIGURE);
      plot(is, should,"+", freqvec, freqvec*fitpar(1)+fitpar(2));
      fflush(stdout);
      clear jn;
      printf("Apply calibration?\n");
      jn=input("[y/n] > ","s");
      if jn=="y"
        put();
        freqvec=freqvec*fitpar(1)+fitpar(2);
        printf("  Calibration applied successfully\n");
      endif
    endif


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Baseline correction methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case {"baseline" "bl" }		# Basislinienkorrektrur anhand der PRE_TIME
    if ( eing_num >= 2 )
        switch ( substring(eingaben,2) )
	  case "avspec"						% jedes Spektrum wird einzeln auf die Nullinie verschoben
	    put();
	    mvals = mean(mdata,2);
	    az = repmat(mvals, rows(mdata) , 1);
	    mdata = mdata - az;
	    clear az;
	    clear mvals;
	  case "area"
	    put();
	    startindex = ir_get_index( str2num(substring(eingaben,3)), freqvec);
	    stopindex = ir_get_index( str2num(substring(eingaben,4)), freqvec);
	    if (startindex > stopindex)
	      h=startindex;
	      startindex=stopindex;
	      stopindex=h;
	    end;
	    for i=1:columns(mdata)
        avv = mean(mdata(startindex:stopindex, i));
        mdata(:,i)=mdata(:,i)-avv;
	    end;
	  case "spec1"						% 1. Spektrum abziehen
	    put();
	    baseline=mdata(:,1);
	    for i=1:columns(mdata)
		    mdata(:,i)=mdata(:,i)-baseline;
	    end
	    baseline_info='Spectrum No. 1';
	  case "specs"						% Indices geben Mittelung an
	    put();
	    startindex = str2num(substring(eingaben,3));
	    stopindex = str2num(substring(eingaben,4));
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=mdata(:,i)-baseline;
	    end
	    baseline_info=sprintf("Specs %d - %d",startindex,stopindex);
	  case "spec"
      put();
      index=str2num(substring(eingaben,3));
      baseline=mdata(:,index);
      for i=1:columns(mdata)
        mdata(:,i)=mdata(:,i)-baseline;
      end;
      baseline_info=sprintf("Spec %d",index);
	  case "specsquot"						% Als Absorbance (Division)
	    put();
	    startindex = str2num(substring(eingaben,3));
	    stopindex = str2num(substring(eingaben,4));
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=mdata(:,i)./baseline;
	    end
	    baseline_info=sprintf("Specs %d - %d",startindex,stopindex);
	  case {"specsabs"	"specabs" "specsab" "specabs"}					% Als Absorbance (Division)
	    put();
	    startindex = str2num(substring(eingaben,3));
	    stopindex = str2num(substring(eingaben,4));
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=log(baseline./mdata(:,i));
	    end
	    baseline_info=sprintf("Specs (Extinction) %d - %d",startindex,stopindex);
	  case "time"
	    put();
	    startindex = time_get_index(str2num(substring(eingaben,3)),timevec);
	    stopindex = time_get_index(str2num(substring(eingaben,4)),timevec);
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=mdata(:,i)-baseline;
	    end
	    baseline_info=sprintf("Timerange %f - %f", startindex, stopindex);
	  case "timequot"
	    put();
	    startindex = time_get_index(str2num(substring(eingaben,3)),timevec);
	    stopindex = time_get_index(str2num(substring(eingaben,4)),timevec);
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=1-(mdata(:,i)./baseline);
	    end
	    baseline_info=sprintf("Timerange %f - %f", startindex, stopindex);
	  case "timediv"
	    put();
	    startindex = time_get_index(str2num(substring(eingaben,3)),timevec);
	    stopindex = time_get_index(str2num(substring(eingaben,4)),timevec);
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=mdata(:,i)./baseline;
	    end
	    baseline_info=sprintf("Timerange %f - %f", startindex, stopindex);

	  case "timeabs"
	    put();
	    startindex = time_get_index(str2num(substring(eingaben,3)),timevec);
	    stopindex = time_get_index(str2num(substring(eingaben,4)),timevec);
	    baseline = mean(mdata(:,startindex:stopindex),2);
	    for i=1:columns(mdata)
		    mdata(:,i)=log(baseline./mdata(:,i));
	    end
	    baseline_info=sprintf("Timerange (Extinction) %f - %f", startindex, stopindex);

	  case "fit1"						% 1. Spektrum der Fitmatrix abziehen
	    put();
	    baseline=fitdata(:,1);
	    for i=1:columns(mdata)
		    mdata(:,i)=mdata(:,i)-baseline;
	    end
	    baseline_info="fitdata(:,1)";

	  case "absorbance"
	    put();
	    index_start = time_get_index(PRE_TIME_START,timevec);
	    index_stop = time_get_index(PRE_TIME,timevec);
	    baseline = mean(mdata(:, index_start:index_stop),2);	% E = log I0 / I
	    for i=1:columns(mdata)
		    mdata(:,i) = log(baseline / mdata(:,i));
	    end;
	    baseline_info=sprintf("Absorbance (Blank: %f-%f [Specs: %d-%d])", PRE_TIME_START, PRE_TIME, index_start, index_stop);

    case "timelin"
      put();
      index_start = REACTION_START_INDEX;
      if eing_num ==3
        index_stop = str2num(substring(eingaben,3));
      elseif eing_num ==4
        index_start = str2num(substring(eingaben,3));
        index_stop = str2num(substring(eingaben,4));
      else
        index_stop = length(timevec);
      endif
      for i=1:length(timevec)
        lincorr=interp1([timevec(index_start),timevec(index_stop)], [mdata(i,index_start),mdata(i,index_stop)], timevec);
        if (LIVE_MODE)
            fig(FIG_LIVE);
            plot(timevec,mdata(i,:), timevec, lincorr, timevec, mdata(i,:)-lincorr);
            plot_label=sprintf("%d/%d: %f", i, length(freqvec), freqvec(i));
            legend(plot_label);
            drawnow();
        end;
        mdata(i,:)=mdata(i,:)-lincorr;
      endfor


	  case "pretime"					% linear fit to baseline is extrapolated and subtracted from the whole set for each wavenumber
	    put();
	    index_start = 1;
      if ( REACTION_START_INDEX > 5 )
			  index_stop = REACTION_START_INDEX-1;		%  Bereich verkleinern, um sicherzugehen...
	    else
			  printf("  Ende der Vorperiode festlegen:\n");
			  adjust_data();
			  index_stop = REACTION_START_INDEX;
	    end;
	    printf("  Grundlinienkorrektur: t(%d)=%f - t(%d)=%f\n", index_start, timevec(index_start), index_stop, timevec(index_stop) );
	    x_fit=timevec(index_start:index_stop);
	    pretime_coeff=[0,0];
	    tic();
	    for i=1:length(freqvec)
        y_fit=mdata(i,index_start:index_stop);
        x_fit=x_fit(:);
        y_fit=y_fit(:);
        [fitfun, fitpar] = leasqr(x_fit,y_fit,pretime_coeff,@linear);
        % fitpar
        pretime_coeff = fitpar;
        if (LIVE_MODE)
            fig(FIG_LIVE);
            plot(timevec,mdata(i,:), timevec, (fitpar(1)*timevec + fitpar(2)));
            plot_label=sprintf("%d/%d: %f", i, length(freqvec), freqvec(i));
            legend(plot_label);
            drawnow();
        end;
        baseline_parameters_m(i)=fitpar(1);
        baseline_parameters_n(i)=fitpar(2);
        mdata(i,:) = mdata(i,:) - ( fitpar(1)*timevec + fitpar(2) );
        fflush(stdout);
	    end;
	    toc()
	    baseline_info = "Pretime linear";
	  case "speclin"							% Durch jedes Spektrum eine Gerade legen
	    put();									% Fit an gesamtes Spektrum
	    options=[0,1e-10];
	    minfunc=@lin_fit;
	    coeff=[1.0,0.0];
	    % zpb=zenity_progress("Please wait","auto-close");
      zpb=waitbar(0, "Please Wait","createcancelbtn","close (zpb)");
	    zpincr=100/length(timevec);
	    for i=1:length(timevec)
		    y_fit = mdata(:,i);
		    [ fitpar, fitfun ] = fminsearch(minfunc, coeff, options, 1, freqvec, y_fit);
		    %fitpar
		    mdata(:,i) = mdata(:,i) - (fitpar(1)*freqvec + fitpar(2));
		    if (LIVE_MODE)
		      fig(FIG_LIVE);
		      plot(freqvec, y_fit, freqvec, (fitpar(1)*freqvec+fitpar(2)), freqvec, mdata(:,i));
		      plot_label=sprintf("%d/%d: %f", i, length(timevec), timevec(i));
		      legend(plot_label);
		      drawnow();
		    end;
		    % zenity_progress(zpb,zpincr*i);
        waitbar(zpincr*i/100, zpb);    %WB%
		    fflush(stdout);
	    end;
      close(zpb);     %WB%
	    baseline_info = "speclin";
	  case "linear"								% Durch jedes Spektrum eine Gerade,
	    put();									% Fit nur aus 2 Bereichen
      % make anchor points for linear fit dynamic for different spectroscopic ranges; PF
      BL_LINEAR_1_VAL1 = min(freqvec);
      BL_LINEAR_2_VAL2 = max(freqvec);
      if (eing_num == 3)
        dist_low_lim = str2num(substring(eingaben,3));
        BL_LINEAR_1_VAL2 = BL_LINEAR_1_VAL1+dist_low_lim;
        if BL_LINEAR_1_VAL2 >= BL_LINEAR_2_VAL2
          BL_LINEAR_1_VAL2 = BL_LINEAR_1_VAL1+(BL_LINEAR_2_VAL2-BL_LINEAR_1_VAL1)/10;
        endif;
      elseif (eing_num >= 4)
        dist_low_lim = str2num(substring(eingaben,3));
        dist_up_lim = str2num(substring(eingaben,4));
        BL_LINEAR_1_VAL2 = BL_LINEAR_1_VAL1+dist_low_lim;
        BL_LINEAR_2_VAL1 = BL_LINEAR_2_VAL2-dist_up_lim;
        if BL_LINEAR_1_VAL2 >= BL_LINEAR_2_VAL2
          BL_LINEAR_1_VAL2 = BL_LINEAR_1_VAL1+(BL_LINEAR_2_VAL2-BL_LINEAR_1_VAL1)/10;
        endif;
        if BL_LINEAR_2_VAL1 <= BL_LINEAR_1_VAL1
          BL_LINEAR_2_VAL1 = BL_LINEAR_2_VAL2-(BL_LINEAR_2_VAL2-BL_LINEAR_1_VAL1)/10;
        endif
      else
        BL_LINEAR_1_VAL2 = BL_LINEAR_1_VAL1+(BL_LINEAR_2_VAL2-BL_LINEAR_1_VAL1)/10;
        BL_LINEAR_2_VAL1 = BL_LINEAR_2_VAL2-(BL_LINEAR_2_VAL2-BL_LINEAR_1_VAL1)/10;
      endif;

	    BL_LINEAR_1_IDX1 = min(get_index(BL_LINEAR_1_VAL1, freqvec),get_index(BL_LINEAR_1_VAL2, freqvec));
	    BL_LINEAR_1_IDX2 = max(get_index(BL_LINEAR_1_VAL2, freqvec),get_index(BL_LINEAR_1_VAL1, freqvec));
	    BL_LINEAR_2_IDX1 = min(get_index(BL_LINEAR_2_VAL1, freqvec),get_index(BL_LINEAR_2_VAL2, freqvec));
	    BL_LINEAR_2_IDX2 = max(get_index(BL_LINEAR_2_VAL2, freqvec),get_index(BL_LINEAR_2_VAL1, freqvec));
	    x1=mean([BL_LINEAR_1_VAL1,BL_LINEAR_1_VAL2]);
	    x2=mean([BL_LINEAR_2_VAL1,BL_LINEAR_2_VAL2]);
	    dx = x2-x1;

	    for i=1:length(mdata(1,:))
        y_fit = mdata(:,i);				% Vereinfachung, Berechnen y=p*x+q
        y1 = mean(y_fit(BL_LINEAR_1_IDX1:BL_LINEAR_1_IDX2));
        y2 = mean(y_fit(BL_LINEAR_2_IDX1:BL_LINEAR_2_IDX2));
        dy = y2-y1;
        p = dy / dx;
        q = y1 - p*x1;
        mdata(:,i) = mdata(:,i) - (p*freqvec + q);
        if (LIVE_MODE)
            fig(FIG_LIVE);
            plot(freqvec, y_fit, freqvec, (p.*freqvec+q), freqvec, mdata(:,i));
            plot_label=sprintf("%d/%d: %f", i, length(timevec), timevec(i));
            legend(plot_label);
            drawnow();
        end;
        fflush(stdout);
	    end;
	    baseline_info = "linear";

    case "cuspline"
      put();
      start_index = 0;
      stop_index = 0;
      area_spline=0;
      if eing_num >= 3
        smoothing_factor = str2num(substring(eingaben,3));
        if eing_num >= 5
          start_index = str2num(substring(eingaben,4));
          stop_index = str2num(substring(eingaben,5));
        endif
      else
        smoothing_factor = 0.005;
        printf("  Smoothing factor set to default value: 0.005\n");
        printf("  Use cuspline <smoothing_factor> to change value\n")
      endif

      if start_index && stop_index
        av = mean(mdata(:,start_index:stop_index),2);
        [spline, b] = csaps (freqvec, av, smoothing_factor, freqvec);
        area_spline = 1;
        bl_fit_startparameter = [1,0];
      endif

      for i=1:length(timevec)
        if area_spline
          [spline, fitpar] = leasqr(spline, mdata(:,i), bl_fit_startparameter, PRESPLINE_FUNCTION);
        else
          [spline, fitpar] = csaps (freqvec, mdata(:,i), smoothing_factor, freqvec);
        endif

        corrected_spec = mdata(:,i)-spline;

        if (LIVE_MODE)
          fig(FIG_LIVE);
          plot(freqvec, mdata(:,i), freqvec, spline, freqvec, corrected_spec);
          plot_label=sprintf("%d/%d: %f", i, length(timevec), timevec(i));
          legend(plot_label);
          drawnow();
        end;
        mdata(:,i) = corrected_spec;

      endfor


	  case "spline"		% Baseline
			% Baustelle
			% Das Spline �berpr�fen; automatisch, oder vordefiniert;
			% Wenn vordefiniert und nicht passt: automatisch, und Warnung ausgeben
			clear spline_x;
			clear spline_y;
			if ( (max(max(BL_SPLINE))>max(freqvec)) || (min(min(BL_SPLINE))<min(freqvec)) )
					printf("  Fehler: Splinefunktion ungeeignet. Umschalten auf Automatische Berechnung mit BL_SPLINE=BL_SPLINE_AUTO\n");
					printf("  Weitere vordefinierte Splines:\n");
					whos B_SPLINE*
			else
				put();
				if ( (length(BL_SPLINE)==2) && (BL_SPLINE(1)==1) )				% automatische Berechnung der Splinefunktion
					stuetzstellen = BL_SPLINE(2) +1;								        % overlapping intervals (-1), R�nder +2
					intervallbreite = (max(freqvec) - min(freqvec))/BL_SPLINE(2);
					LV = min(freqvec);
					UV = max(freqvec);
					BL_WORK_SPLINE = zeros(stuetzstellen, 3);					% Format: LB, UB, VAL
					BL_WORK_SPLINE(1,:) = [LV, LV+intervallbreite, LV+0.5*intervallbreite];		% test this!!
					for i=1:stuetzstellen-1
							BL_WORK_SPLINE(i+1,:) = [LV+(i-1)*intervallbreite, LV+(i+1)*intervallbreite, LV+i*intervallbreite];
					end;
					BL_WORK_SPLINE(stuetzstellen,:) = [UV-intervallbreite, UV, UV-0.5*intervallbreite];		% test this!!
					BL_SPLINE = BL_WORK_SPLINE;
				end;					% das Spline ist definiert, normal weitermachen
				stuetzstellen = rows(BL_SPLINE);

				for k=1:length(timevec)
					for i=1:stuetzstellen
						spline_x(i) = BL_SPLINE(i,3);
						[ startindex, dummy ] = ir_get_index(BL_SPLINE(i,1), freqvec);
						[ stopindex,  dummy ] = ir_get_index(BL_SPLINE(i,2), freqvec);
						if ( startindex > stopindex )
							h=startindex;
							startindex = stopindex;
							stopindex = h;
						end;
						spline_y(i) = mean(mdata(startindex:stopindex,k));
					end;
					flipped=0;
					if ( freqvec(1) > freqvec(2) )
						wzv = fliplr( freqvec' );
						spline_x = fliplr(spline_x);
						spline_y = fliplr(spline_y);
						flipped = 1;
					else
            wzv = freqvec';
          end;
					[ splval, pval ] = csaps (spline_x, spline_y, -1, wzv);			%	hier steht die Splinefunktion: Ersetzen prüfen!!
					if ( flipped )
						splval = fliplr(splval);
					end;
					if (LIVE_MODE)
						fig(FIG_LIVE);
						plot(freqvec, mdata(:,k), freqvec, splval', freqvec, (mdata(:,k)-splval'));
						plot_label=sprintf("%d/%d: %f", k, length(timevec), timevec(k));
						legend(plot_label);
						drawnow();
					end;
					mdata(:,k) = mdata(:,k) - splval';
				end;
				baseline_info="Splinefunction";
			end;

    case "tspline"                    % TODO: Spline Fit in der Zeitachse
        if (eing_num < 3)
          printf(" Usage: baseline tspline <points>\n");
        else
          put();
          stuetzstellen = str2num(substring(eingaben,3));
          clear spline_x;
          clear spline_y;

      endif

    case "lastspec"            % nimmt letztes Spektrum von mdata, fittet es an übrigen Datensatz und zieht Resultat ab:     PF
      if (eing_num == 4)    % area in which fit is conducted to correct for gaseous water. Recommended >1750
        put()
        norm1 = str2num(substring(eingaben,3));
        norm2 = str2num(substring(eingaben,4));
        % TODO: multiple areas
        inorm1=ir_get_index(norm1, freqvec);
        inorm2=ir_get_index(norm2, freqvec);
        if ( inorm1>inorm2 )
          h=inorm1; inorm1=inorm2;inorm2=h;
        end;
      else
        inorm1 = 1;
        inorm2 = length(freqvec);
      endif

      lastspec = mdata(:,length(timevec));

      % fit des Korrekturspektrums (Luftwasser etc.) an Datensatz.
      % fitfunction is a*x+b
      fitpar = [-0.1,0];
      for i=1:length(timevec)
        [normf, normp] = leasqr(lastspec(inorm1:inorm2), mdata(:,i)(inorm1:inorm2), fitpar, @specnorm);
        fitspec = (lastspec*normp(1)+normp(2));
        corrspec= mdata(:,i)-fitspec;


        if (LIVE_MODE)
          fig(FIG_LIVE);
          plot(freqvec, mdata(:,i), freqvec, fitspec, freqvec, corrspec);
          plot_label=sprintf("%d/%d: %f", i, length(timevec), timevec(i));
          legend(plot_label);
          drawnow();
        end;

        mdata(:,i) = corrspec;
      endfor

    case "trace"            % nimmt letztes Spektrum von mdata, fittet es an übrigen Datensatz und zieht Resultat ab:     PF
      if (eing_num>=3)

        if (eing_num == 3)    % area in which fit is conducted to correct for gaseous water. Recommended >1750
          put()
          norm1 = str2num(substring(eingaben,3));
          inorm1=ir_get_index(norm1, freqvec);
          trace = mdata(inorm1,:);
        elseif (eing_num >= 4)
          put()
          norm1 = str2num(substring(eingaben,3));
          norm2 = str2num(substring(eingaben,4));
          inorm1=ir_get_index(norm1, freqvec);
          inorm2=ir_get_index(norm2, freqvec);
          if ( inorm1>inorm2 )
            h=inorm1; inorm1=inorm2;inorm2=h;
          end;

          trace = mean(mdata(inorm1:inorm2),1);
        endif

        # fit der trace an datensatz
        fitpar = [-0.1,0];
        for i=1:length(freqvec)
          [normf, normp] = leasqr(trace, mdata(i,:), fitpar, @specnorm);
          fitspec = (trace*normp(1)+normp(2));
          corrtrace= mdata(i,:)-fitspec;


          if (LIVE_MODE)
            fig(FIG_LIVE);
            plot(timevec, mdata(i,:), timevec, fitspec, timevec, corrtrace);
            plot_label=sprintf("%d/%d: %f", i, length(freqvec), freqvec(i));
            drawnow();
          end;

          mdata(i,:) = corrtrace;
        endfor



      else
        printf(" Usage: baseline timetrace <time>\n");
      endif







    case "water"            % nimmt erstes Spektrum von mdata, fittet es an übrigen Datensatz und zieht Resultat ab: Zur Korrektur von Luftwasser     PF
      if (eing_num == 4)    % area in which fit is conducted to correct for gaseous water. Recommended >1750
        put()
        norm1 = str2num(substring(eingaben,3));
        norm2 = str2num(substring(eingaben,4));
        % TODO: multiple areas
        inorm1=ir_get_index(norm1, freqvec);
        inorm2=ir_get_index(norm2, freqvec);
        if ( inorm1>inorm2 )
          h=inorm1; inorm1=inorm2;inorm2=h;
        end;


        % load water spectrum
        [fn, fp] = uigetfile("*","Select water spectrum",".","MultiSelect","Off");
        newbase = [fp,fn];
        convertFileName=strtrim(strrep(strcat(sprintf("%s",newbase)), "\\", "/"));   %PF
		    printf("water spectrum %s is loaded\n", convertFileName);
		    [water_wave, water_data] = load_ir_file(convertFileName);
        water = interp1(water_wave, water_data, freqvec);

        if !exist("water", "var")
          water = mdata(:,1);
          printf(" Warning: first spectrum will taken as water spectrum \n");
        endif

        % fit des Korrekturspektrums (Luftwasser etc.) an Datensatz.
        % fitfunction is a*x+b
        water_clip = water(inorm1:inorm2);
        fitpar = [-0.1,0];
        for i=1:length(timevec)
          [normf, normp] = leasqr(water_clip, mdata(:,i)(inorm1:inorm2), fitpar, @specnorm);
          fitspec = (water*normp(1)+normp(2));
          corrspec= mdata(:,i)-fitspec;


          if (LIVE_MODE)
						fig(FIG_LIVE);
						plot(freqvec, mdata(:,i), freqvec, fitspec, freqvec, corrspec);
						plot_label=sprintf("%d/%d: %f", i, length(timevec), timevec(i));
						legend(plot_label);
						drawnow();
					end;

          mdata(:,i) = corrspec;
        endfor

      else
        printf(" Usage: baseline water <lower limit> <upper limit>\n");
      endif

	  case "prespline"
						% Die Vorperiode sinnvoll mitteln, daraus eine Splinefunktion ermitteln und diese gefittet
						% abziehen
	    put();
      start_index = 0;
      stop_index = 0;
      % 1. Vorperiode linear approximieren
      if (eing_num == 2)
        index_start = 1;
        index_stop = REACTION_START_INDEX;
      elseif (eing_num == 3)
        index_start = str2num(substring(eingaben,3));
        index_stop = REACTION_START_INDEX;
      elseif (eing_num >= 4)
        index_start = str2num(substring(eingaben,3));
        index_stop = str2num(substring(eingaben,4));
      endif;

      if index_stop < index_start
        temp = index_stop;
        index_stop = index_start;
        index_start = temp;
      endif


	    if ( index_stop == index_start )
			  printf("  Warning: Start and End indices of baseline are equal:\n");
	    end;


	    % printf("  Analysiere Vorperiode\n" ); fflush(stdout);
	    x_fit=timevec(index_start:index_stop);
	    pretime_coeff=[0,0];
	    tic();
	    %zpb=zenity_progress("Please wait","auto-close");
      %zpb = waitbar(0, "Please Wait","createcancelbtn","close (zpb)");
	    zpincr=100/length(freqvec);
	    for i=1:length(freqvec)
		    %zenity_progress(zpb,zpincr*i);
        %waitbar(zpincr*i/100, zpb);                                    PF
		    y_fit=mdata(i,index_start:index_stop);
		    x_fit=x_fit(:);
		    y_fit=y_fit(:);
		    [fitfun, fitpar] = leasqr(x_fit,y_fit,pretime_coeff,@linear);
		    % fitpar
		    pretime_coeff = fitpar;
%		    if (LIVE_MODE)
%		      fig(FIG_LIVE);
%		      plot(timevec,mdata(i,:), timevec, (fitpar(1)*timevec + fitpar(2)));
%			    plot(x_fit, y_fit, x_fit, (x_fit*fitpar(1)+fitpar(2)));
%		      plot_label=sprintf("%d/%d: %f", i, length(freqvec), freqvec(i));
%		      legend(plot_label);
%		      drawnow();
%		    end;
		    baseline_parameters_m(i)=fitpar(1);
		    baseline_parameters_n(i)=fitpar(2);
		    % mdata(i,:) = mdata(i,:) - ( fitpar(1)*timevec + fitpar(2) );
		    % Vorperiodenintensity berechnen in Bezug auf das Gesamtspektrum
		    spec_drift(i) = fitpar(1)*timevec(length(timevec))+fitpar(2);
		    fflush(stdout);
	    end;
      %close(zpb);                                                      PF
	    % jetzt das Spektrum durch eine Splinefunktion ann�hern (zum Gl�tten)
				% stuetzstellen = rows(BL_SPLINE);
				% Stuetzstellen Konstruieren
				% printf("  Konstruiere das Spline\n"); fflush(stdout);
				clear spline_x;
				clear spline_y;
        clear BL_SPLINE_SMOOTH;
				bl_lower = min(freqvec); bl_upper = max(freqvec); bl_sampling=BL_SAMPLINGPOINTS;

				bl_width = (bl_upper - bl_lower) / bl_sampling;

				for i=1:bl_sampling
					BL_SPLINE_SMOOTH(i,1) = bl_lower + (i-1)*bl_width;
					BL_SPLINE_SMOOTH(i,2) = BL_SPLINE_SMOOTH(i,1)+bl_width;
					BL_SPLINE_SMOOTH(i,3) = BL_SPLINE_SMOOTH(i,1)+(bl_width/2);
				end;



				stuetzstellen = rows(BL_SPLINE_SMOOTH);
				%for k=1:length(timevec)
					for i=1:stuetzstellen
						spline_x(i) = BL_SPLINE_SMOOTH(i,3);
						[ startindex, dummy ] = ir_get_index(BL_SPLINE_SMOOTH(i,1), freqvec);
						[ stopindex,  dummy ] = ir_get_index(BL_SPLINE_SMOOTH(i,2), freqvec);
						if ( startindex > stopindex )
							h=startindex;
							startindex = stopindex;
							stopindex = h;
						end;
						spline_y(i) = mean(spec_drift(startindex:stopindex));
					end;
					flipped=0;
					if ( freqvec(1) > freqvec(2) )
						wzv = fliplr( freqvec' );
						spline_x = fliplr(spline_x);
						spline_y = fliplr(spline_y);
						flipped = 1;
					else
            wzv = freqvec';
          endif;
					[ splval, pval ] = csaps (spline_x, spline_y, -1, wzv);			%	hier steht die Splinefunktion: Ersetzen pruefen!!
					if ( flipped )
						splval = fliplr(splval);
					end;
					spec_drift_smooth = splval';
				%end;

		% Spektren durchlaufen, fitten und subtrahieren
		% printf("  Grundlinie wird subtrahiert\n"); fflush(stdout);
		%zpb=zenity_progress("Please wait","auto-close");
		%zpb=waitbar(0, "Please Wait","createcancelbtn","close (zpb)");
    %zpincr=100/length(timevec);
		for k=1:length(timevec)
			%zenity_progress(zpb,zpincr*k);
       %waitbar(zpincr*k/100, zpb);
			bl_fit_startparameter = [0,1];
			bl_fit_to_fit = mdata(:,k);
			[bl_h_f, bl_h_p] = leasqr(spec_drift_smooth, bl_fit_to_fit, bl_fit_startparameter, PRESPLINE_FUNCTION);
			mdata(:,k) = mdata(:,k) - bl_h_f;
			if (LIVE_MODE)
				fig(FIG_LIVE);
				plot(freqvec,bl_fit_to_fit, freqvec, mdata(:,k), freqvec, bl_h_f);
				plot_label=sprintf("%d/%d: %f", k, length(timevec), timevec(k));
				legend(plot_label);
				drawnow();
			end;
		end;
	  %close (zpb);
	    toc()
	    baseline_info = "Pretime appoximation (prespline)";

  case "fftkin"         % Fourierfilterung der Kinetiken
    put();
    do
      figure(FIG_MISC);
      clf();
      zz=round(length(freqvec)/3);
      ff1=fft(mdata(zz,:));
      ff2=fft(mdata(zz*2,:));
      plot([1:length(ff1)],ff1,[1:length(ff2)],ff2);
      ex1=input("Exclude from: \n");
      ex2=input("Exclude to: \n");
      ex3=length(ff1)-ex2;
      ex4=length(ff1)-ex1;
      ff1(ex1:ex2)=0;
      ff1(ex3:ex4)=0;
      ff2(ex1:ex2)=0;
      ff2(ex3:ex4)=0;
      ffr1=ifft(ff1);
      ffr2=ifft(ff2);
      figure(FIG_MISC+1);
      clf();
      plot(timevec,mdata(zz,:),timevec,ffr1,timevec,mdata(zz*2,:),timevec,ffr2);
    until(input("Proceed (Y/N)","s")=="Y");
    printf("Applying to the dataset...\n");
    %stp10=length(freqvec)/10;
    %stp1=length(freqvec)/100;
    for i=1:length(freqvec)
      ff=fft(mdata(i,:));
      ff(ex1:ex2)=0;
      ff(ex3:ex4)=0;
      mdata(i,:)=ifft(ff);
    end;


	  otherwise
	    printf("  Unbekannte Funktion\n");
	    apropos("baseline");
        endswitch;
    else
	    apropos("baseline");
    endif;
    if (VERBOSITY_LEVEL)
      printf("Vorschlag Naechster Schritt:\n");
      printf("      svd    Singulaerwertezerlegung\n");
    end;
  case {"svdswap" }
    if ( eing_num == 3 )
      k1 = str2num( substring(eingaben,2) );
      k2 = str2num( substring(eingaben,3) );
      bu=u(:,k1);		%U
      u(:,k1)=u(:,k2);
      u(:,k2)=bu;
      bs=s(k1,k1);		%S
      s(k1,k1)=s(k2,k2);
      s(k2,k2)=bs;
      bv=v(:,k1);		%V
      v(:,k1) = v(:,k2);
      v(:,k2) = bv;
    else
      printf("  svdswap a b - 2 Komponenten der SVD-Zerlegung vertauschen\n");
    end;
  case {"svdkill" }
    if ( eing_num==2 )
      val=str2num( substring(eingaben,2) );
      s(val:end, val:end) = 0;
      u(:,val:end) = zeros(rows(u),columns(u)-val+1);
      v(:,val:end) = zeros(rows(v),columns(v)-val+1);
    else
	    printf("  svdkill nr - SVD-Komponenten ab nr loeschen\n");
    end
  case {"svdremove" }
    % 1 Komponente entfernen, der Platz wird mit den nachfolgenden K. aufgefüllt
    if (eing_num==2)
        idx=str2num( substring(eingaben,2) );
        u(:,idx)=[];
        v(:,idx)=[];
        s(idx,:)=[];
        s(:,idx)=[];
    else
        printf("svdremove <nr>\n");
    end
  case {"svdfit" }			# Die V-Matrix der SVD-Zerlegung fitten
    printf(" pin - Startparameter, pin_constraints - zulaessige Bereiche\n");
    if ( eing_num >= 2 )
	    fig(FIG_SVDFIT);
	    clf();
	    hold on;
	    trace_to_go = str2num(substring(eingaben,2));
	    y_to_fit = v(:,trace_to_go);
	    if ( eing_num == 2 ), fit_order = 3; else, fit_order = str2num(substring(eingaben,3)); end;
	    switch (fit_order)
		case 1
		    F = @fit_monoexponential;
		    fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*x))";	# Startparameter (noch automatisch zuweisen!!)
		case 2
		    F = @fit_2exp;
		    fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*x))+p(4)*exp(-p(5)*x)";
		case 3
		    F = @fit_3exp;
		    fit_info = "y = p(1) + p(2)*(1-exp(-p(3)*x)) + p(4)*(1-exp(-p(5)*x)) + p(6)*(1-exp(-p(7)*x))";
		otherwise
		    F = @fit_monoexponential;
		    fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*x))";	# Startparameter (noch automatisch zuweisen!!)
		    printf ("  Warnung: unbekannter Parameter!\n");
	  endswitch;
	  weiter = 0;
		clf();
		plot_label = sprintf("-;Trace no. %d;0", trace_to_go);
		plot(timevec, y_to_fit', plot_label);
		hold on;
		plot_label = sprintf("-;Startparameter;1");
		startfunc = F(timevec, pin);
		plot(timevec, startfunc, plot_label);
		xlabel(time_axis);
		ylabel(arbitrary_axis);

	  do
      printf("  Auswahl der Startparameter (f startet, x beendet): \n");
      printf(" Funktion: %s\n", fit_info);
      printf(" Parameter: pin = [");
		for i=1:(fit_order*2+1)
      printf("%f", pin(i));
      if( (i==1) | (i==3) | (i==5) ), printf("|"); else printf(", "); end;
		end;
      printf("]\n");
      printf("  SVDFit Trace Nr. %d ", trace_to_go);
      action=input("> ","s");
      if ( strcmp(action,"x") | strcmp(action,"quit") | strcmp(action,"exit") )
        weiter = 1;
      elseif ( strcmp(action,"fit") )
        clf();
        subplot(2,1,1);
        [f_f,f_p,f_kvg,f_iter,f_corp,f_covp,f_covr,f_stdresid,f_Z,f_r2] = leasqr2(timevec,y_to_fit',pin,F,pin_constraints);
        plot_label = sprintf("-;Trace no. %d;0", trace_to_go);
        plot(timevec, y_to_fit', plot_label);
        hold on;
        %plot_label = sprintf("-;Startparameter;1");
        %startfunc = F(timevec, pin);
        %plot(timevec, startfunc, plot_label);
        plot_label = sprintf("-;fit;3");
        plot(timevec, f_f, plot_label);
        subplot(2,1,2);
        plot_label = sprintf("-;residual;0");
        plot(timevec, (y_to_fit - f_f), plot_label);
        subplot(2,1,1);
        % Die Parameter sortieren:

        p_matrix=0;
        for i=1:fit_order
          p_matrix(i,1) = f_p((i-1)*2+2);		% 1. Parameter ist Y-Verschiebung
          p_matrix(i,2) = f_p((i-1)*2+3);
        end
        p_matrix = sort_matrix(p_matrix,2);			% nach k's sortieren
        for i=1:fit_order				% zurückschreiben
          f_p((i-1)*2+2) = p_matrix(i,1);
          f_p((i-1)*2+3) = p_matrix(i,2);
        end

        printf("**************************************************************************************\n");
        printf("  Funktion: %s\n", fit_info);
        printf(" Fitparameter: f_p = [");
        for i=1:(fit_order*2+1)
          printf("%f", f_p(i));
          if( (i==1) | (i==3) | (i==5) ), printf("|"); else printf(", "); end;
        end;
        printf("]\n");
        printf("  r_square: %f\n", f_r2);
        printf("**************************************************************************************\n");
      else
        eval(action);
        clf();
        plot_label = sprintf("-;Trace no. %d;0", trace_to_go);
        plot(timevec, y_to_fit', plot_label);
        hold on;
        plot_label = sprintf("-;Startparameter;1");
        startfunc = F(timevec, pin);
        plot(timevec, startfunc, plot_label);
        xlabel(time_axis);
        ylabel(arbitrary_axis);
      endif;
	    until (weiter);
	    SVD_FIT(trace_to_go) = 1;
	    % jetzt die Werte in den Report �bernehmen:
      svdfit(trace_to_go).values = f_f;				# die Werte
      svdfit(trace_to_go).parameters = f_p;			# Parameter als Spaltenmatrix (1. Spalte = 1. Parametersatz)
      svdfit(trace_to_go).convergence = f_kvg;			# Konvergenz ja/nein
      svdfit(trace_to_go).stdresid = f_stdresid;			# Die Residuen  DIE NOCH PLOTTEN!!
      svdfit(trace_to_go).confidence = f_Z;
      svdfit(trace_to_go).rsquare = f_r2;
      fit_report = sprintf("  SVD Komponente Nr. %d: %s\n", trace_to_go, fit_info);
      fit_report = sprintf("%s				Konvergenz: %d\n", fit_report, f_kvg);
      fit_report = sprintf("%s				Parameter: 	a1=%f\n", fit_report,f_p(1));
      for j=2:length(svdfit(trace_to_go).parameters)
          fit_report = sprintf("%s						a%d=%f\n", fit_report, j, f_p(j));
          if ( j==3 )
        fit_report = sprintf("%s						(t1/2(1)=%f)\n", fit_report, -log(0.5)/f_p(j));
          endif;
          if ( j==5 )
        fit_report = sprintf("%s						(t1/2(2)=%f)\n", fit_report, -log(0.5)/f_p(j));
          endif;
          if ( j==7 )
        fit_report = sprintf("%s						(t1/2(2)=%f)\n", fit_report, -log(0.5)/f_p(j));
          endif;
      endfor;
      svdfit(trace_to_go).report=fit_report;
      printf("%s\n", fit_report);
    else
      printf("  Syntax: svdfit <trace>\n");
      printf("	  svdfit <trace> <order>\n");
    endif;

  case {"fitspectra" }				% 	Wrapperfunktion f�r lsqfit; den aktuellen Datensatz an gegebende Basisspektren fitten
											% 	Baustelle
											% 	TODO: fitspectra svd | rotation | globalfit
    printf("  Fit erfolgt (fminsearch):\n");
    printf("  Anpassen der Basis:\n");
    [fit_mdata, fit_coefficients, fit_residuals] = lsqfit(freqvec, mdata, base_matrix,options);
    printf(" Fit durchgef�hrt. fit_mdata, fit_coefficients, fit_residuals erstellt,\n");
    % for i=1:length(fit_coefficients)
    %	for j=1:length(fit_coefficients{1})
    %		fit_pmatrix(i,j) = fit_coefficients{i}(j);
    %	end;
    % end;
    printf("  Ok.\n");
  case {"fitspectra2" }				% 	Wrapperfunktion f�r lsqfit; den aktuellen Datensatz an gegebende Basisspektren fitten
											% 	Baustelle
											% 	TODO: fitspectra svd | rotation | globalfit
    printf("  Fit erfolgt (fminsearch):\n");
    printf("  Anpassen der Basis:\n");
    [fit_mdata, fit_coefficients, fit_residuals] = lsqfit(freqvec, mdata, base_matrix,options);
    printf(" Fit durchgef�hrt. fit_mdata, fit_coefficients, fit_residuals erstellt,\n");
    % for i=1:length(fit_coefficients)
    %	for j=1:length(fit_coefficients{1})
    %		fit_pmatrix(i,j) = fit_coefficients{i}(j);
    %	end;
    % end;
    printf("  Ok.\n");

  case {"globalfit_init" "gfi" }			%	Startparameter fuer den Globalfit festlegen/aendern
    gf_cmpnts = input("  Anzahl der Komponenten: ");
    printf("  Eingabe der Startparameter:\n");
    for i=1:gf_cmpnts
      printf("  Parameter %d: ",i);
      gf_prmtr = input(" ");
      gf_k_start(i)=gf_prmtr/10;
      gf_k_stop(i)=gf_prmtr*10;
    end;

    dummy=sprintf("gf %d",gf_cmpnts);
    add_to_history(dummy);
    add_to_history("% Globalfit abgeschlossen.");
    add_to_history("% <<p gf>> zum Anzeigen verwenden");
    add_to_history("% <<pp filename>> speichert als WMF");

  case {"gfn" }
    % Globalfit der SVD-Daten
    printf("  Levenberg-Marquardt-Fit via leasqr\n");
    printf("  WARNUNG: Experimentelle Funktion!\n");
    printf("  Nur Daten der SVD!\n");
    % if ( laststep!= SVD)
    if (eing_num>1)
      components = str2num(substring(eingaben,2));
      LM_order = components;
      weights = zeros(1,components);
      for i=1:components
          kineticfun(:,i)=v(:,i);
          weights(i)=s(i,i)^2;			% Standardwichtung
      end

      model = @gfit_expfun_LM;							% y = f(x,p)
      kinetic_to_fit = kineticfun(REACTION_START_INDEX:end,:);
      timevec_to_fit = timevec(REACTION_START_INDEX:end);
      if (columns(timevec_to_fit)>rows(timevec_to_fit)), timevec_to_fit=timevec_to_fit'; end;		% Spaltenmatrix
      timevec_to_fit = repmat(timevec_to_fit,1,components);
      % Parametercodierung: A(1-exp(-kt))+o	A[components x components], k[components], o[components]
      parameters = ones(1, components*components + 2*components);						% Startparameter fertigmachen
  % 																								function [f,p,kvg,iter,corp,covp,covr,stdresid,Z,r2]=
  %                  																						leasqr(x,y,pin,F,{stol,niter,wt,dp,dFdp,options})
      [fun, fitparameter] = leasqr(timevec_to_fit, kinetic_to_fit, parameters, model);
      printf("  Fertig. Parameter:\n");
      fitparameter

    else
      printf("  Benutzung: gfn <components>\n");
    end;

%%%%%%%%%%%%%%%%%%%%%%%			Beginn globalfit leasqr (experimentell)
  case {"gfl_init" }					% Interaktive Zuordnung der Globalfitparameter           TODO!!! Options sind falsch gesetzt!!
    gfl_tmp_components = numinput("  Number of components: ",gfl_tmp_components);
    jn = input("  assign paramater initial values (y/n)? ","c");
    for i=1:gfl_tmp_components
      printf("Parameter %d:\n", i);
      gfl_tmp_params(i,1) = numinput("  parameter range START: ",gfl_tmp_params(i,1));
      gfl_tmp_params(i,2) = numinput("  parameter range STOP: ",gfl_tmp_params(i,2));
      if ( jn=='y' )
        gfl_tmp_params(i,3) = numinput("   parameter initial value: ", gfl_tmp_params(i,3));
      else
        gfl_tmp_params(i,3) = (gfl_tmp_params(i,1)+gfl_tmp_params(i,1))/2;
      end;
    end;
    jn = input("  exclude data from kinetics (y/n)? ","c");
    if (jn=='y')
      time_exclude=1;
      time_exclude_from = numinput("  exclude from: ",time_exclude_from);
      time_exclude_to = numinput("  exclude to: ",time_exclude_to);
      time_exclude_from_idx = get_index(time_exclude_from, timevec)-REACTION_START_INDEX+1;
      time_exclude_to_idx = get_index(time_exclude_to, timevec)-REACTION_START_INDEX+1;
    else
      time_exclude=0;
    endif
    printf("  Global fit parameters set. You can use <<gfl>> without arguments now.\n");
    %gfl_tmp_params=1;

  case {"gfl" }
    gf_METHOD="local least squares (gfl - leasqr)";
    gf_INITIAL_PARAMETERS="not saved";
    gf_STDRESID="not saved";
    gf_R2="not saved";
    gf_KONVERGENCE="not saved";

    printf("  Levenberg-Marquardt-Fit using leasqr\n");
    printf("  WARNING: Experimental function!\n");
    printf("  This ONLY uses data of the last SVD!\n");
    printf("  Usage: \n");
    printf("      gfl_init\n");
    printf("      gfl                 allows pre-definition of search area and starting values, 1 cycle\n");
    printf("      gfl <components>    no pre-definition, multiple cycles\n");
    printf("      gfl <components> <iterations>\n");
    printf("      gfl <components> <initial parameter #1> <initial parameter #2> ...\n");
    printf("  Use gfl_init to pre-define parameters and limits\n");
    iter = gf_ITERATIONS;
    % gfl_options.bounds=[];
    % Remove all variables which are to be defined later. This is just to be sure that nothing interferes...
    clear gfl_options;

	  if (eing_num==1)								% Parameter aus den ueber gfl_prepare gespeicherten Daten holen
      components=gfl_tmp_components;			% Das betrifft nur die Parameter fuer die k's!!!
      iter=0;
      gf_INITIAL_PARAMETERS="";
      for i=1:components
        gf_INITIAL_PARAMETERS=sprintf("%s %f", gf_INITIAL_PARAMETERS, gfl_tmp_params(i,3));
      end;
      if ( gfl_tmp_params_adjusted==0)
        printf("  Warning: This function performes global fitting using standard startparameter and boundaries.\n");
        printf("  These parameter should be adjusted using <<gfl_init>> BEFORE applying <<gfl>> without arguments\n");
        printf("  Do not expect reasonable results!\n");
      end;
      %gfl_options.bounds=gfl_tmp_params(:,1:2);
	  elseif (eing_num==2)
		    components=str2num(substring(eingaben,2));
    elseif (eing_num==3)
      components=str2num(substring(eingaben,2));
      iter=str2num(substring(eingaben,3));
    elseif (eing_num>3)
      iter=0;
      components=str2num(substring(eingaben,2));
      for i=3:eing_num, gf_k_start(i-2)=str2num(substring(eingaben,i)); end;
      gf_INITIAL_PARAMETERS="";
      for i=1:components
        gf_INITIAL_PARAMETERS=sprintf("%s %f", gf_INITIAL_PARAMETERS, gf_k_start(i));
      end;
    end;

    % Startparametermatrix erzeugen:
    REACTIONS = components;				% Normalfall; Anzahl der k's. ggf. auch fuer ueber/ unterbestimmte Systeme machen!
    OBSERVABLES = components;				% Anzahl der zu benutzenden V-Spuren
    num_parameters = REACTIONS+REACTIONS*OBSERVABLES+OBSERVABLES;
    % Parameterkonvention: [A; K; O] alle als Spaltenvektoren
    for i=1:num_parameters
      gfl_options.bounds(i,1:2)=[-Inf,Inf];
    end;
    if (iter>0)
      pmt = pvariation(gf_k_start(1:OBSERVABLES), gf_k_stop(1:OBSERVABLES), iter)';
      startparameter = ones(num_parameters, columns(pmt));
      startparameter(OBSERVABLES+1:OBSERVABLES+REACTIONS,:)=pmt;
    else							% Keine Variation der Startparameter
      startparameter = ones(num_parameters,1);
      for i=1:REACTIONS
        %startparameter(OBSERVABLES+i)=gf_k_start(i);							% This is probably wrong; it does not set the right k parameter boundaries!   TODO ERROR
        startparameter(REACTIONS*OBSERVABLES+i)=gfl_tmp_params(i,3);					% REACTIONS*OBSERVABLES+...
        gfl_options.bounds(REACTIONS*OBSERVABLES+i,1:2) = gfl_tmp_params(i,1:2);
      end;
    end;

    % zu fittenden Datensatz berechnen (ggf. Vorperiode rausnehmen)
    weights = zeros(1,components);
    clear kineticfun;
    clear weights;
    for i=1:components
      kineticfun(:,i)=v(:,i);
      weights(i)=s(i,i)^2;			% Standardwichtung
    end
    % V's sequentiell anordnen fuer LEASQR

    kinetic_to_fit = kineticfun(REACTION_START_INDEX:end,:);
    timevec_to_fit = timevec(REACTION_START_INDEX:end);

    if (VERBOSITY_LEVEL)
      printf("Erstelle Zeitachse....\n");
      fflush(stdout);
    end;

    lltime=timevec_to_fit(:);												% Umwandeln in Spaltenvektoren
    lltime=repmat(lltime,1,components);									% Fuer jede Komponente eine eigene Zeitspur erzeugen (f. leasqr benoetigt)
    ltime=reshape(lltime,columns(lltime)*rows(lltime),1);						% x-Achse komplett sequentiell anordnen (eigentlich nur fuer leasqr-Uebergabe noetig)

    printf("fertig....\n");
    fflush(stdout);


    lkinetic = kinetic_to_fit'(:);											% Test is this is correct? (wg. u*s*vt)

    if (columns(startparameter)==1)
      %% Test: for restricted fit, no weighting of the last kinetic component which is just return to the dark state:
      %% Test: highly experimental
      kinetic_weights=ones( size (lkinetic));
      if (time_exclude > 0)                                              % Bereiche aus den Einzelnen Kinetiken loeschen
        traces = size(lkinetic)/length(kinetic_to_fit);
        kinetic_weights(time_exclude_from_idx:time_exclude_to_idx)=0;
        for i=2:traces-1
          kinetic_weights(i*length(kinetic_to_fit)+time_exclude_from_idx:i*length(kinetic_to_fit)+time_exclude_to_idx) = 0;
        end
      endif
      if (GF_REJECT_LAST==1)
          kinetic_weights((size(lkinetic)-length(kinetic_to_fit)):end)=0;
          printf("  Warning: the last SVD component for Globalfit is not used for fitting.\n");
          printf("  Use n+1 components for fitting\n");
          printf("  Use GF_REJECT_LAST=0 to change this behaviour\n");
      endif;
      printf("  Doing restricted fit...\n"); fflush(stdout);
      [f1_f, f1_p, f1_kvg, f1_iter, f1_corp, f1_covp, f1_covr, f1_stdresid, f1_Z, f1_r2] = leasqr(ltime, lkinetic, startparameter, @gfit_expfun_leasqr, 0.0001, 20, kinetic_weights, .001*ones(size(startparameter)), 'dfdp', gfl_options);
      if (VERBOSITY_LEVEL), printf("  Refining restricted fit...\n"); end;

      fflush(stdout);
      [f1_f, f1_p, f1_kvg, f1_iter, f1_corp, f1_covp, f1_covr, f1_stdresid, f1_Z, f1_r2] = leasqr(ltime, lkinetic, f1_p, @gfit_expfun_leasqr, 0.0001, 20, kinetic_weights, .001*ones(size(f1_p)), 'dfdp', gfl_options);

    else
      printf("  Doing unrestricted fit...\n"); fflush(stdout);
      % Jede Startparameterspalte einzeln, dann den besten Wert nehmen (im Sinne von groestes r2)
      [f1_f, f1_p, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(ltime, lkinetic, startparameter(:,1), @gfit_expfun_leasqr);
      f1_p_best = f1_p;
      r2_best=r2;
      zpb=waitbar(0, "Please Wait","createcancelbtn","close (zpb)");
      for i=2:columns(startparameter)
        waitbar(i/columns(startparameter), zpb);
        printf("  initial guess: %d of %d\n", i, columns(startparameter)); fflush(stdout);
        [f1_f, f1_p, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(ltime, lkinetic, startparameter(:,i), @gfit_expfun_leasqr);
        if (r2>r2_best)
          f1_p_second = f1_p_best;
          f1_p_best = f1_p;
          r2_best=r2;
        end;
      end;
      close(zpb);
      if (VERBOSITY_LEVEL), printf("  Refining unrestricted fit...\n"); end;
      fflush(stdout);
      [f1_f, f1_p, f1_kvg, f1_iter, f1_corp, f1_covp, f1_covr, f1_stdresid, f1_Z, f1_r2] = leasqr(ltime, lkinetic, f1_p_best, @gfit_expfun_leasqr);
    end;

    [AMatrix,KMatrix,OMatrix] = get_leas_parameter(f1_p);

    % Rueckrechnen
    u_r = u(:,1:components);
    v_r = v(:,1:components);
    s_r = s(1:components,1:components);
    uu = u_r*s_r*AMatrix;
    vv=zeros(max(size(timevec_to_fit)),components);
    for i=1:components
          vv(:,i) = exp(-KMatrix(i)*timevec_to_fit);
    end

    if (VERBOSITY_LEVEL)
      printf("  B-spectra in uu(:,i); kinetics vectors vv(:,i)  (i=1..%d)\n", components);
      printf("  Use <<save globalfit>> to store the calculated data\n");				% MARK
      printf("  Please wait, plotting the result...\n");
    end;

    fig(FIG_GLOBALFIT_RESULT);
    clf();

    uu = -uu;									% Umdrehen wg. Formel

    for i=1:components
        subplot(components,2,(i-1)*2+1);
        plot(freqvec,uu(:,i));
        if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca(),"XDir","reverse"); end;
        subplot(components,2,(i-1)*2+2);
        plot(timevec_to_fit',vv(:,i));						% size(vv(:,1)) = 0??????  TODO: Change this to plot data and fit
        % user_plot(timevec,kineticfun(:,i), timevec, fv(:,i));		% Hier nicht nötig, weil das ja schon in einem anderen Fenster ist.
    end;


    %fig(100);
    fv=(AMatrix*exp(-KMatrix*timevec_to_fit)+repmat(OMatrix,1,length(timevec_to_fit)))';
    tvtf = repmat(timevec_to_fit',1,columns(kinetic_to_fit));
    %plot(tvtf,kinetic_to_fit, tvtf,fv);

    gf_METHOD="Levenberg-M.";
    gf_KONVERGENCE=sprintf("%d", f1_kvg);
    gf_R2=sprintf("%f",f1_r2);

    if ( gf_KONVERGENCE==0 )
      printf("  Warnung: Konvergenz wurde nicht erreicht.\n");
    end;

    add_to_history("p gf");

    printf("  Base spectra in uu(:,i), Kinetics in kineticfun(:,i)\n");

  % TODO: Notiz rausschreiben, in welchen Variablen die Ergebnisse zu finden sind ( f�r direktes Plotten)

  %	break;



%%%%%%%%%%%%%%%%%%%%%%%			End globalfit leasqr
  case {"gfl_reconstruct" "gfl_recomp" }
    printf("   !!!!Warning - Experimental Function. Original Data is overwritten\n");
    mdata=uu(:,1)*(1-vv(:,1)');
    for i=2:components
      mdata=mdata+uu(:,i)*(1-vv(:,i)');
    endfor;
    timevec = timevec_to_fit;



%%%%%%%%%%%%%%%%%%%%%%%             Beginn globalfit
  case {"globalfit" "gf" }
    % Global-Fit der SVD-Daten
    % Parameter: globalfit <nr komponenten> <keep|new|strict> <iterations>
    %	strict: Die k's werden nicht variiert
    % Vz,s = Cz,s*(1-exp(-k_i*t) + B0_s

    % TODO:
    % Parameter strict einf�hren;
    % wenn gesetzt, dann werden die k's nicht variiert.
    %
    % Fit erst mit auf 1 normierten V's zur K-Bestimmung, dann spaeter nochmal fitten mit korrekten Werten
    % u_gf und v_gf einfhren, mdata=u_gf*v_gf

    % globalfit recomp 	setzt neue Datenmatrix aus den Berechneten werten zusammen.

    gf_METHOD="fminsearch";
    gf_INITIAL_PARAMETERS="not saved";
    gf_STDRESID="not saved";
    gf_R2="not saved";
    gf_KONVERGENCE="not saved";

    printf("  Warning -  this fitting function is outdated and slow\n");
    printf("  It is used only for compatibility and verification and may be\n");
    printf("  removed in future versions!\n");

    if ( eing_num > 1 )
    components = str2num(substring(eingaben,2));	% Wieviel Komponenten einbeziehen?

    % Koeffizientenmatrix aufbauen (Startparameter)
    C=rand(1, components*(components+2));

    options = [0,gf_PRECISION];					%%  Möglicherweise ändern!!!!!!   TODO

    kineticfun=zeros(length(timevec),components);

    %%  				Funktionen zum Fitten, TODO: Wichtung mit R's^2R
    %%				Zu fittende Komponenten bestimmen und wichten
    %%
    %%				TODO: WICHTIG: hier die gek�rzten v-Vektoren rein (siehe unten...)
    %%

    switch (laststep)
        case ROTATION
      weights = zeros(1,components);
      printf("  building matrix of weights...\n"); fflush(stdout);
      if ( rows(s) < columns(vt_neu) )
          sadd = zeros( columns(vt_neu) - rows(s) , columns(vt_neu) );
          s=[s; sadd];
          printf("  warning: changed size of s-matrix!\n");
      end;
      wtmatrix = vt_neu'*(s(1:columns(vt_neu),1:columns(vt_neu)).^2)*vt_neu;		% TODO: s quadratisch machen
      printf("  fertig\n"); fflush(stdout);
      %v_w = wtmatrix * v_rot;
      for i=1:components
          % diag(R'S^2R)
          %kineticfun(:,i)=v_rot(:,i)*wtmatrix(i,i);
          kineticfun(:,i)=v_rot(:,i);
          %kineticfun(:,i)=v_rot(:,i) / ( max(v_rot(:,i))-min(v_rot(:,i))  );
          weights(i) = wtmatrix(i,i);
          %weights(i) = 1;
          %kineticfun(:,i)=kineticfun(:,i)/(max(kineticfun(:,i))-min(kineticfun(:,i)));
      end
      printf ("  Using rotation data\n"); fflush(stdout);
        case SVD
      weights = zeros(1,components);
      for i=1:components
          kineticfun(:,i)=v(:,i);
          weights(i)=s(i,i)^2;			% Standardwichtung
                  % TODO: hier noch Wichtung mit e-Funktion rein...
          %weights(i)=1/(max(v(:,i))-min(v(:,i)));
          %kineticfun(:,i)=kineticfun(:,i)/(max(kineticfun(:,i))-min(kineticfun(:,i)));
      end
      printf ("  Using SVD data\n");
        otherwise
      printf("  No SVD yet!\n");
    end;


    fig(FIG_GLOBALFIT);
    clf();

    bestfun = 1e10;


  %----------------------------------------------------------------------------------------------------------------------------------------
    % Hier nur die K's variieren. Alle anderen Parameter bekommen immer Startwert 0!
    num_parameters = components*(components+2);
    k_start = components*components+1;
    k_stop = components*components+components;
    clear p_start; clear p_stop; clear ptest_kmatrix; clear ptest_matrix;
    printf("   P�zision (gf_PRECISION): %f\n", gf_PRECISION);
    printf("   Suchbereich: (gf_k_start|gf_k_stop)\n");
    for i=1:components
      p_start(i) = gf_k_start(i);
      p_stop(i) = gf_k_stop(i);
      printf("      k%d: %f - %f\n", i, p_start(i), p_stop(i));
    end

    printf("   Intervallanzahl (gf_ITERATIONS): %d\n", gf_ITERATIONS);

    if gf_ITERATIONS==0
      ptest_kmatrix = p_start;		% nur die Startwerte verwenden
    else
      ptest_kmatrix = pvariation(p_start, p_stop, gf_ITERATIONS);
    end
    prematrix=zeros(rows(ptest_kmatrix), k_start-1);
    postmatrix=zeros(rows(ptest_kmatrix), num_parameters-k_stop);


    ptest_matrix=[prematrix, ptest_kmatrix, postmatrix];

    printf("   Parametermatrix (%dx%d) erstellt.\n", columns(ptest_matrix),rows(ptest_matrix)); fflush(stdout);

    % TODO				Berechnung passiert nur mit dem tatsächlichen Bereich ok.
    %					Immer mit gfit_expfun fitten; zum Fitten wird eine extra-Matrix erstellt
    %					Vmatrix kuerzen und neuen timevec einf�hren (immer!)
    %
    %					vn=v(PRE_TIME_INDEX:end,:); mdata_neu=u*s*vn' ist dann ok
    %
    %
    if ( PRE_TIME!=0 )
        PRE_INDEX = time_get_index(PRE_TIME, timevec);
        model = @gfit_expfun_area_m;		% Die Matrix - Version
        printf("  PRE_TIME definiert. Fit erfolgt an %f(%d)\n",PRE_TIME, PRE_INDEX);
    else
        model=@gfit_expfun;
    end;

    % Zeitvektoren k�rzen, Fit nur im Reaktionsbereich
    % TODO: Dies �berall ersetzten!
    %_______________________________________________________________________________
    kinetic_to_fit = kineticfun(REACTION_START_INDEX:end,:);
    timevec_to_fit = timevec(REACTION_START_INDEX:end);
    %_______________________________________________________________________________

    globalfit_minfunc = @gfit_expfun_area_silent;		% TODO: model rausschmeissen

    gf_counter = rows(ptest_matrix) / 10;
    gf_idx = 0;
    gf_percentage = 0;
    printf("   Scan laeuft (%d Iterationen)\n", rows(ptest_matrix));
    printf("   0..");

    % Fit starten
        tic();
        zpb = waitbar(0, "Please Wait","createcancelbtn","close (zpb)");
        for i=1:rows(ptest_matrix)			% diese Schleife ist im Multicore Modus parallelisiert
          gf_idx++;
          if gf_idx>gf_counter
            gf_idx=0;
            gf_percentage+=10;
            printf("%d%% ",gf_percentage); fflush(stdout);
            textdummy=sprintf("%d%% abgeschlossen", gf_percentage);
            %zenity_progress(zpb_handle, gf_percentage, textdummy);
            waitbar(gf_percentage/100, zpb, textdummy);
          end
          C = ptest_matrix(i,:);
          [fitparameter, fun] = fminsearch(model, C, options, 1, timevec_to_fit', kinetic_to_fit, components, weights);
          if ( fun < bestfun )					% TODO: Anpassen für PRE_TIME: richtig plotten!
            bestfun=fun;
            printf("*"); fflush(stdout);
            bestfit = fitparameter;
            subplot(2,1,1);
            [sse, fv] = model(fitparameter, timevec_to_fit', kinetic_to_fit, components,weights);
            if ( PRE_TIME != 0 )
                user_plot(timevec_to_fit,kinetic_to_fit, timevec_to_fit', fv);
                subplot(2,1,2);
                %diff_matrix = fv - kineticfun';
                diff_matrix = fv - kinetic_to_fit;
                user_plot(timevec_to_fit', diff_matrix);
                drawnow();
            else
                user_plot(timevec_to_fit,kinetic_to_fit, timevec_to_fit', fv);
                subplot(2,1,2);
                %diff_matrix = fv - kineticfun';
                diff_matrix = fv - kinetic_to_fit;
                user_plot(timevec_to_fit', diff_matrix);
                drawnow();
            end;
          end
          close (zpb);
        end
        gf_time_consumed = toc();




    printf(" Daten gescannt (%ds): vorlaeufiger Parametersatz\n", gf_time_consumed);
    bestfit
    % hier noch 1x mit dem besten Satz fitten
    C = bestfit;
    [fitparameter, fun] = fminsearch(model, C, options, 1, timevec_to_fit', kinetic_to_fit, components, weights);
    % zenity_progress(zpb_handle, 100);
    close(zpb);
    printf("fertig.\n");		% TODO: hier weiter anpassen...
    bestfit=fitparameter
    bestfun=fun;
          % Ergebnis plotten
    [sse, fv] = model(fitparameter, timevec_to_fit', kinetic_to_fit, components,weights);

          subplot(2,1,1);
          user_plot(timevec_to_fit,kinetic_to_fit, timevec_to_fit', fv);
          subplot(2,1,2);
          diff_matrix = fv - kinetic_to_fit;
          user_plot(timevec_to_fit', diff_matrix);
          drawnow();
    %----------------------------------------------------------------------------------------------------------------------------------------




    fitparameter = bestfit;

    % Parameter r�ckrechnen auf A*(1-exp(-kx))+B
    AMatrix=fitparameter(1:components*components);
    AMatrix=reshape(AMatrix,components,components);
    KMatrix=fitparameter(components*components+1: components*components+components);
    OMatrix=fitparameter(components*(components+1)+1: (components*(components+1)+components));

    printf("Globalfit abgeschlossen. Ergebnis:\n");
    AMatrix				% Sollte die Transformationsmatrix sein
    KMatrix
    OMatrix

    hold on;

    %	model=@gfit_expfun;
    %	[sse, fv] = model(fitparameter, timevec, kineticfun, components);

    %	diff_matrix = fv - kineticfun';		% gfit_expfun In Matrixschreibweise
    %	diff_matrix = fv - kineticfun;		% sonst

    % neue Basisspektren berechnen		TODO: change this if rotated
    % we need the new basis in uu, vv
    switch (laststep)
        case SVD
      u_r = u(:,1:components);
      v_r = v(:,1:components);
      s_r = s(1:components,1:components);
      %sm = diag(repmat(1,components,1));	% Diagonalmatrix mit 1sen
      uu = u_r*s_r*AMatrix;
      vv=zeros(max(size(timevec_to_fit)),components);
      for i=1:components
          vv(:,i) = (1-exp(-KMatrix(i)*timevec_to_fit));
      end
        case ROTATION
      uu = u_rot(:,1:components);
      uu = uu*AMatrix;
      vv=zeros(length(timevec_to_fit),components);				% TODO: verbessern
      for i=1:components
          vv(:,i) = (1-exp(-KMatrix(i)*timevec_to_fit));			% FEHLER??????????????????
      end
        otherwise
      printf("  Fehler: SVD liegt nicht vor.\n");
    end

    printf("  B-Spektren: uu(:,i); Kinetiken: vv(:,i)  (i=1..%d)\n", components);
    printf("  Hinweis: save globalfit speichert die Daten\n");				% MARK

    printf("  Daten werden geplottet...\n");

    % fig(FIG_GLOBALFIT_RESULT);
    % clf();
    %for i=1:components
    %   subplot(components,2,(i-1)*2+1);
    %    plot(freqvec,uu(:,i));
    %   if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca(),"XDir","reverse"); end;
    %    subplot(components,2,(i-1)*2+2);
    %   plot(timevec_to_fit',vv(:,i));						% size(vv(:,1)) = 0??????  TODO: Change this to plot data and fit
    %   % user_plot(timevec,kineticfun(:,i), timevec, fv(:,i));		% Hier nicht nötig, weil das ja schon in einem anderen Fenster ist.
    %end;
    add_to_history("p gf");
      else
          % Menügesteuerte Abfrage
    printf("  globalfit: keine Parameter angegeben.\n  Interaktive Abfrage erfolgt\n");
    clear cmpnts;
    cmpnts = str2num(inputdlg("Wieviel Komponenten?"){1});
    no_search_area = message("Bereich absuchen?","question");
    for i=1:cmpnts
      dummy=sprintf("%f",gf_k_start(i));
      dummy2=sprintf("Startwert Nr. %d",i);
      gf_k_start(i) = str2num(inputdlg(dummy2, dummy, 1, {dummy}){1});
      dummy3=sprintf("gf_k_start(%d)=%f;",i,gf_k_start(i));
      add_to_history(dummy3);
      if (no_search_area==0)
          dummy=sprintf("%f",gf_k_stop(i));
          dummy2=sprintf("Endwert Nr. %d",i);
          gf_k_stop(i) = str2num(inputdlg(dummy2, dummy, 1, {dummy}){1});
          dummy3=sprintf("gf_k_stop(%d)=%f;",i,gf_k_stop(i));
          add_to_history(dummy3);
      end;
    end;
    if (no_search_area==1)
      gf_ITERATIONS=0;
    else
      dummy=sprintf("%d", gf_ITERATIONS);
      gf_ITERATIONS = str2num(inputdlg("Suchtiefe",dummy,1,{dummy}){1});
    end;
    dummy3=sprintf("gf_ITERATIONS=%d;", gf_ITERATIONS);
    add_to_history(dummy3);
    dummy=sprintf("globalfit %d", cmpnts);
    add_to_history(dummy);
      end;			% if (eing_num>1)
      % add_to_history("p gf");						% Waehre hier rekursiv!?

  %%%%%%%%%%%%%%                                            End Globalfit

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%								Rotation der V-Matrix (v(:,i)) zur S/R Trennung
  %%										TODO
  %%						rotation_vektor(i) enthält die Nummer des Originalvektors von Pos. i
  %%						rotation_matrix(i) inst die Matrix, die rotiert wird
  case {"rotation" }
    if ( eing_num == 1 )
	    printf("  Syntax: rotation a b c d .... o n | rotation a - b o n\n");
	    printf("  Beispiel: rotation 1 2 4 8 o 3 rotiert die Vektoren 1,2,4,8 in der Ordnung 3\n");
    else
	    printf("Rotate V\n");

	    u_mode = 0;
    	if ( strcmp( substring(eingaben, eing_num-1),"o") )			# Set rotation order
		    ROTATION_ORDER = str2num(substring(eingaben,eing_num));
		    printf("  Warnung: ROTATION_ORDER=%d permanent gesetzt\n", ROTATION_ORDER);
		    rotation_vectors_num = eing_num - 3;
	    else
		    rotation_vectors_num = eing_num - 1;
	    end;
    	cont_r = 0;
      if (rotation_vectors_num == 3)		% Bereichsangabe?
		    if ( strcmp(substring(eingaben,3),"-") )
		      start_r = str2num(substring(eingaben,2));
		      stop_r = str2num(substring(eingaben,4));
		      rotation_vectors_num = stop_r - start_r + 1;
		      cont_r = 1;
		    end
	    end
	    rotation_vector = zeros(rotation_vectors_num);
	    rotation_matrix = zeros(rows(v), rotation_vectors_num);

	    for i=1:rotation_vectors_num
	      if ( cont_r == 1)
		      rotation_vector(i) = start_r + i - 1;
	      else
		      rotation_vector(i) = str2num( substring(eingaben, i+1) );
	      end
	      rotation_matrix(:,i) = v(:,rotation_vector(i));
	    end
	    % Calculate Rotation matrix
	    printf("  Rotation wird für %d Komponenten ausgefuehrt...\n",i); fflush(stdout);

	    [ tv, ew ] = rotate_matrix(rotation_matrix, ROTATION_ORDER);
	    % embed weights in identity matrix
	    vt_neu = eye(columns(v));

    	for zeile=1:rotation_vectors_num
	        for spalte=1:rotation_vectors_num
		        vt_neu(rotation_vector(zeile),rotation_vector(spalte)) = tv(zeile, spalte);
	        end
	    end

      %v transformieren:
	    v_rot=v*vt_neu;
	    u_rot=u*s*vt_neu;
	    u_alt=u*s;

	    % Wichtungsmatrix für die Fits Konstruieren
	    % analog bei SVD
	    % wtmatrix = vt_neu'*(s^2)*vt_neu;
	    add_to_history('plot rot');
	    printf("  Bearbeitete Daten in u_rot, v_rot ( mdata = u_rot (v_rot)T )\n");
	    printf("    rotswap a b 									... Vertauschen der Komponenten A und B\n");
	    printf("    rotkill a										... Komponenten ab a loeschen\n");
	    printf("    recomp										... Datenmatrix rueckrechnen\n");
	    printf("    save exp rotation_kinetics2.dat timevec v_rot(:,2)		... z.B. 2. Komponente der Rotation speichern\n");
	    laststep = ROTATION;
	    is_rotation = 1;
    end


  case {"u_rotation" }
    if ( eing_num == 1 )
	    printf("  Syntax: u_rotation a b c d .... [u] | urotation a - b\n");
    else
	    printf("Rotiere U\n");
	    u_mode = 1;
	    rotation_vectors_num = eing_num - 1;
	    cont_r = 0;
      if (rotation_vectors_num == 3)		% Bereichsangabe?
		    if ( strcmp(substring(eingaben,3),"-") )
		      start_r = str2num(substring(eingaben,2));
		      stop_r = str2num(substring(eingaben,4));
		      rotation_vectors_num = stop_r - start_r + 1;
		      cont_r = 1;
		    end
	    end
	    rotation_vector = zeros(rotation_vectors_num);
	    rotation_matrix = zeros(rows(u), rotation_vectors_num);
	    for i=1:rotation_vectors_num
	      if ( cont_r == 1)
		      rotation_vector(i) = start_r + i - 1;
	       else
		      rotation_vector(i) = str2num( substring(eingaben, i+1) );
	      end
	      rotation_matrix(:,i) = u(:,rotation_vector(i));
	    end
	    % Rotationsmatrix ausrechnen
	    printf("  u-rotation (order: %d for %d components...\n",ROTATION_ORDER,i); fflush(stdout);
	    [ tv, ew ] = rotate_matrix(rotation_matrix, ROTATION_ORDER);
    	ut_neu = eye(columns(u));
    	for zeile=1:rotation_vectors_num
	      for spalte=1:rotation_vectors_num
		      ut_neu(rotation_vector(zeile),rotation_vector(spalte)) = tv(zeile, spalte);
	      end
	    end
    	% TODO:		geht das so, wenn über U rotiert wird?
	    v_rot=ut_neu*s*v;
	    u_rot=u*ut_neu;
	    u_alt=u*s;
	    % u_neu=u*vt_neu;
	    % Wichtungsmatrix für die Fits Konstruieren
	    % analog bei SVD
	    % wtmatrix = vt_neu'*(s^2)*vt_neu;
	    % die ersten 5 Plotten
	    add_to_history('plot rot');
	    printf("  Bearbeitete Daten in u_rot, v_rot ( mdata = u_rot (v_rot)T )\n");
	    printf("    rotswap a b ... Vertauschen der Komponenten A und B\n");
	    printf("    rotkill a   ... Komponenten ab a löschen\n");
	    printf("    recomp	    ... Datenmatrix rückrechnen\n");
      printf("  THIS IS EXPERIMENTAL. IT IS UNLIKELY TO WORK\n");
	    laststep = ROTATION;
	    is_rotation = 1;
    end
  %%												Komponenten vertauschen
  case {"rotswap" }
    if ( eing_num == 3 )
      k1 = str2num( substring(eingaben,2) );
      k2 = str2num( substring(eingaben,3) );
      bu=u_rot(:,k1);		%U
      u_rot(:,k1)=u_rot(:,k2);
      u_rot(:,k2)=bu;
      bv=v_rot(:,k1);		%V
      v_rot(:,k1) = v_rot(:,k2);
      v_rot(:,k2) = bv;
    else
	    printf("  rotswap a b - 2 Komponenten vertauschen\n");
    end;
  %%                                                                                            Komponenten löschen (noise)
  case {"rotkill" }
    if ( eing_num==2 )
      val=str2num( substring(eingaben,2) );
      u_rot(:,val:end) = zeros(rows(u_rot),columns(u_rot)-val+1);
      v_rot(:,val:end) = zeros(rows(v_rot),columns(v_rot)-val+1);
    else
	    printf("  rotkill nr - Komponenten ab nr loeschen\n");
    end
  case {"recomp" }					% auch für reine SVD
    put();
    switch (laststep)
      case ROTATION
          printf("Verwende Daten der Rotation\n");
          mdata = u_rot*v_rot';
      case SVD
          mdata = u*s*v';
          printf("Verwende Daten der SVD\n");
    end

  case {"ffit"}			% Fit über fminsearch
    if (eing_num>2)
      if ( strcmp(substring(eingaben,2),"exp") )
          F = @exp_fit;
          pin = [1, 1, 1];			%
          pin(1)=max(mdata(1,:));
          pin(2)=1/timevec(length(timevec));
          pin(3)=min(mdata(1,:));
          options = [0, 1e-8];

          for i=1:length(freqvec)
            [ fitpar, fitfun ] = fminsearch(F, pin, options, 1, timevec, mdata(i,:));
            pin=fitpar;
            if (LIVE_MODE)
                fig(FIG_LIVE);
                plot( timevec, mdata(i,:), timevec, (fitpar(1)*(1-exp(-fitpar(2)*timevec)))+fitpar(3));
                drawnow();
            end;
          end;
      elseif ( strcmp(substring(eingaben,2),"2exp") )
          F = @twoexp_fit;
          pin = [1, 1, 1, 1, 1];
          % Sinnvolle Wahl der Startparameter:
          pin(1) = max( mdata(1,:) );
          pin(2) = 1/timevec(length(timevec));		% initial guess: change
          pin(3) = min( mdata(1,:) );
          pin(4) = 5/timevec(length(timevec));
          pin(5) = mdata(1,length(timevec));
          options = [0, 1e-6];

          for i=1:length(freqvec)
            [ fitpar, fitfun ] = fminsearch(F, pin, options, 1, timevec, mdata(i,:));
            ffit_data(i,:)=(fitpar(1)*(1-exp(-fitpar(2)*timevec))+fitpar(3)*(1-exp(-fitpar(4)*timevec))+fitpar(5));
            if (LIVE_MODE)
                fig(FIG_LIVE);
                plot( timevec, mdata(i,:), timevec, ffit_data(i,:));
                drawnow();
            end;
            parameters{i}=fitpar;
          end;
	        printf("  Fit abgeschlossen\n");
	    else
	      printf("  Unbekannte Funktion\n");
	    end;
    else
	    printf("  ? ffit für mehr Information\n");
    end;



  case {"fit"}			# Fitten der Originalmatrix
							% JEDER FIT WIRD FIT_ITERATIONS x durchgeführt,die Beste Variante
    if (eing_num > 2)
      if ( strcmp(substring(eingaben,2),"exp") )
        F = @monoexponential;			# Die Funktion
        pin = [1.0,1.0,1.0];
        fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*x))";	# Startparameter (noch automatisch zuweisen!!)
        printf("  Monoexponentieller Fit");
      elseif ( strcmp(substring(eingaben,2),"expdx") )
        F = @fit_monoexponential_dx;			# Die Funktion
        pin = [0.0,1.0,1.0,-0.00001,38.0];
        fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*(x-p(4))))";	# Startparameter (noch automatisch zuweisen!!)
        printf("  Exponentieller Fit mit dx");
      elseif ( strcmp(substring(eingaben,2),"linexp") )
        F = @fit_lin_exponential;			# Die Funktion
        pin = [0.0,1.0,1.0,0];
        fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*x))+p(4)*x";	# Startparameter (noch automatisch zuweisen!!)
        printf("  Linear-exponentieller Fit");
      elseif ( strcmp(substring(eingaben,2),"lin") )
        F = @fit_lin;			# Die Funktion
        pin = [0.0,1.0];
        fit_info = "y=p(1)+p(2)*x";	# Startparameter (noch automatisch zuweisen!!)
        printf("  Linearer Fit");
      elseif ( strcmp(substring(eingaben,2),"2exp") )
        F = @fit_2exp;			# Die Funktion
        pin = [-0.4, 0.4, 25, 0.4, 3.5];
        fit_info = "y=p(1)+p(2)*(1-exp(-p(3)*x))+p(4)*(1-exp(-p(5)*x))";	# Startparameter (noch automatisch zuweisen!!)
        printf("  2Phasig exponentieller Fit");
      elseif ( strcmp(substring(eingaben,2),"3exp") )
        F = @fit_3exp;			# Die Funktion
  %	    pin = [-0.4, 0.4, 25, 0.4, 3.5];
        fit_info = "y = p(1) + p(2)*(1-exp(-p(3)*x)) + p(4)*(1-exp(-p(5)*x)) + p(6)*(1-exp(-p(7)*x));";	# Startparameter (noch automatisch zuweisen!!)
        printf("  3Phasig exponentieller Fit");
      elseif ( strcmp(substring(eingaben,2),"henderson") )
        F = @fit_hendersonhasselbalch3;			# Die Funktion
        pin = [6.0, 0.001, 1];
        fit_info = "y = p(3).*(p(2)+10.^(p(1)-x))./(1+10.^(p(1)-x))";	# Startparameter (noch automatisch zuweisen!!)
        printf("  Henderson Hasselbakch");
      else
        printf("  Warnung: Fitfunktion nicht bekannt, nehme Exponentialfunktion an\n");
        F = @fit_monoexponential;		# Die Funktion
        fit_info = "p(1)+p(2)*(1-exp(-p(3)*x))";
        pin = [0.0,1.0,1.0];			# Startparameter (noch automatisch zuweisen!!)
      endif;

      if (strcmp(substring(eingaben,3), "file") )
		  printf("  Leider noch nicht verf�gbar\n");
		  apropos("fit");
	elseif (strcmp(substring(eingaben,3), "all") )			% Alle Kurven Fitten - Automatik
		traces_to_go = length(freqvec);
		fit_startindex = get_index(0, timevec);
		fit_x = timevec(fit_startindex:end);
		printf("  Please wait...\n");
		%zph = zenity_progress("Wait...","auto-close");
    zpb = waitbar(0, "Please Wait","createcancelbtn","close (zpb)");
		for fit_trace_to_go=1:traces_to_go
			fit_y = mdata(fit_trace_to_go, fit_startindex:end);
			[f_f,f_p,f_kvg,f_iter,f_corp,f_covp,f_covr,f_stdresid,f_Z,f_r2]=leasqr(fit_x,fit_y,pin,F);
			% zenity_progress(zph,fit_trace_to_go*100/traces_to_go);
      waitbar(fit_trace_to_go/traces_to_go, zpb);
			if (LIVE_MODE==1)
				fig(FIG_MISC);
				clf();
				plot(timevec,mdata(fit_trace_to_go,:), fit_x, f_f);		% MARK
				drawnow();
			end;
      close(zpb);
			fit_data(fit_trace_to_go, :) = f_f;
			fit_parameter(fit_trace_to_go,:) = f_p;				% TODO: rsquare mit speichern
		end;
		printf("  done.\n");
		printf("  Fitted data: fit_data\n");
		printf("  Fitted parameter: fit_parameter\n");
		printf("  Valied Axis: fit_x\n");

		dummy = sprintf("ParameterMatrix_of_%s", basename(listenname));
		dummy2 = sprintf("Parametermatrix of Fit %s",fit_info);
		store_data(freqvec, [1:columns(fit_parameter)], fit_parameter, dummy, dummy2);
		dummy = sprintf("FitMatrix_of_%s", basename(listenname));
		dummy2 = sprintf("Data fitted by %s",fit_info);
		store_data(freqvec, fit_x, fit_data, dummy, dummy2);

	elseif ( eing_num == 3 )							% Bei nur 1 Trace mit Angabe der Anfangswerte
		fit_trace_to_go = get_index(str2num(substring(eingaben,3)), freqvec);
		fit_startindex = get_index(0, timevec);			% von 0 an
		fit_x = timevec(fit_startindex:end);
		fit_y = mdata(fit_trace_to_go, fit_startindex:end);
		[f_f,f_p,f_kvg,f_iter,f_corp,f_covp,f_covr,f_stdresid,f_Z,f_r2]=leasqr(fit_x,fit_y,pin,F);
		fig(FIG_MISC);
		clf();
		plot(timevec,mdata(fit_trace_to_go,:), fit_x, f_f);		% MARK
		printf("  Fit abgeschlossen. Fitparameter in f_p. Details s. fit_info.\n");
	else
	  if ( strcmp(substring(eingaben,2),"init"))
      printf("Startparameter anpassen\n");
      % TODO: interaktives Auswählen der Startparameter.

	  else
		  printf("starting\n");
     	traces_to_go = eing_num - 2;
      for i=1:traces_to_go
          wz_to_fit(i) = str2num(substring(eingaben, 2+i));
          [ index_to_fit(i), real_index ] = ir_get_index(wz_to_fit(i), freqvec);
          printf("ok\n");
      endfor;
	  endif;
	endif;

    else
      apropos("fit");
    endif;

  case {"swap"}
    % swaps time and frequency axes if loaded wrong
    temp=timevec;
    timevec=freqvec;
    freqvec=temp;
    timevec=timevec';
    freqvec=freqvec';
    mdata=mdata';

  case {"saveall"}
    # Die Originaldaten als Einzelspektren speichern
    listenname_out = "";
    dateiname_out = "";
    listenname_out = input ("Dateiname für die Spektren: ","s");
    if (strcmp(works_on,"o"))
      printf("  Speichere Originaldaten...\n");
      for i=1:rows(timevec)
        dateiname_out = sprintf("%s.%d.dat",listenname_out,i);
        #printf("Speichere: [%s]\n", dateiname_out);
        save_ir_file(dateiname_out, freqvec, mdata(:, i));
      endfor
    elseif (strcmp(works_on,"u"))
      printf("  Speichere die neue Basis...\n");
      wieviel = input("Wieviel Basisspektren speichern? >");
      for i=1:wieviel
        dateiname_out = sprintf("base-%s.%d.dat",listenname_out,i);
	save_ir_file(dateiname_out, freqvec, u(:, i));
      endfor
    else
      printf("Funktion nicht implementiert.\n");
    endif
  case {"detrend" }
   do
    order = input("Ordnung (empf. 6, <0> beendet ): ");
    if ( order > 0 )
      id2 = detrend(mdata, order);
      baseline = mdata - id2;   % Speichert sicherheishalber die Baseline...
      plot (id2);
      mdata = id2;
    endif
   until ( order == 0 );
   mdata = id2;
  case {"svd" }
    %zpb_handle = zenity_progress("SVD - Bitte warten...","auto-close","pulsate");
    %zenity_progress(zpb_handle,30);
    % printf ("    Berechne SVD der Matrix: O = U S VT\n");
    [u,s,v] = svd(mdata);
    is_svd = 1;
    % Baustelle:
    % TODO: wenn im Skriptmodus, keine History anfügen
    if ( 0==in_script() )
	if ( eing_num > 1 )
		if ( !strcmp(substring(eingaben,2),"silent") )
			if ( !ispc() )
				if ( PLOT_ROT_HISTOGRAMS==1 )
					dummy = sprintf("plot s %d", vals_to_plot);			% TODO: vals_to_plot
					add_to_history(dummy);
				end;
			end;
			dummy = sprintf("plot svd %d", vals_to_plot);
			add_to_history(dummy);
		else
			printf("  Unbekannte SVD option.\n");
		end;
	else
		if ( PLOT_ROT_HISTOGRAMS==1 )
			dummy = sprintf("plot s %d", vals_to_plot);			% TODO: vals_to_plot
			add_to_history(dummy);
		end;
		dummy = sprintf("plot svd %d", vals_to_plot);
		add_to_history(dummy);
	end;
    end;
    for i=1:columns(v)						% kann das raus???
      SVD_FIT(i)=0;
    endfor;
    laststep = SVD;
    %zenity_progress(zpb_handle,100);
  case { "bf" }
    % Gespeicherte Spektren als neue Basisvektoren laden
    % is_basis = 0;
    if ( eing_num > 1 )
	if ( strcmp(substring(eingaben,2),"zero") )		% Setzt eine Nullinie vor die BS!
	    if ( is_basis > 0 )					% Das alles auch noch mit den Namen machen!!
		is_basis = is_basis + 1;
		i = is_basis;
		do
		    base_matrix(:,i) = base_matrix(:,i-1);
		    basespectrum(i).name = basespectrum(i-1).name;
		    i=i-1;
		until ( i==1 );
		base_matrix(:,1) = zeros(rows(base_matrix),1);
		basespectrum(1).name="All Zero";
	    else
		printf("  Load base spectra first!\n");
	    end;
	elseif (strcmp(substring(eingaben,2),"swap"))
	    i = str2num(substring(eingaben,3));
	    j = str2num(substring(eingaben,4));
	    hm = base_matrix(:,i);
	    base_matrix(:,i) = base_matrix(:,j);
	    base_matrix(:,j) = hm;
	    clear hm;
	    hm = basespectrum(i).name;
	    basespectrum(i).name = basespectrum(j).name;
	    basespectrum(j).name = hm;
	    clear hm;
	elseif(strcmp(substring(eingaben,2),"spectra"))
		base_matrix=zeros(length(freqvec), eing_num-2);
		for i=1:(eing_num-2)
			index = str2num(substring(eingaben, i+2));
			basespectrum(i).name = sprintf("%f", timevec(index));
			base_matrix(:,i) = mdata(:,index);
		end;
		is_basis = i;
	elseif(strcmp(substring(eingaben,2),"times"))
		printf("  Function not defined.\n");
	else
	    is_basis = 0;
	    base_matrix = zeros(length(freqvec), eing_num-1);
	    for i=1:(eing_num-1)
        	printf("Basisvektor %d wird eingelesen\n",i);
  		[bl_wave, bl_base] = load_ir_file(substring(eingaben,i+1));
		basespectrum(i).name = substring(eingaben,i+1);
		base_matrix(:,i) = interp1(bl_wave, bl_base, freqvec);
	    end;
	    is_basis = eing_num-1;
	end;
    else
	if ( USE_GUI == 1 )
	    is_basis = 0;
	    %newbase = file_selection("Basisspektren","multiple",sprintf("%s/",pwd()));
	    [fn, fp] = uigetfile("*","Select Base Spectra",".","MultiSelect","On");
      	is_basis = max(size(fn));
	    base_matrix = zeros(length(freqvec), is_basis);

	    for i=1:is_basis
			%newbase{i} = sprintf("%s%s",fp,fn{i});
			newbase{i} = [fp,fn{i}];
			convertFileName=strtrim(strrep(strcat(sprintf("%s",newbase{i})), "\\", "/"));   %PF
		    printf("Basisvektor %d (%s) wird eingelesen\n",i, convertFileName);
		    [bl_wave, bl_base] = load_ir_file(convertFileName);
		    basespectrum(i).name = newbase{i};
		    % Sicherstellen, dass die Skalierung gleich ist:
		    if ( (min(bl_wave) > min(freqvec)) | (max(bl_wave)<max(freqvec)) )
		      printf("  Warnung: Zu geringer Bereich der Basisspektren.\n");
		      printf("  Vorhanden (bl_wave):\n");
		      min(bl_wave)
		      max(bl_wave)
		      printf("  Erforderlich (freqvec):\n");
		      min(freqvec)
		      max(freqvec)
		      printf("  Bitte reskalieren (? cutwz)\n");
		    end;
		    %    printf("   Basisspektren zu klein. Wie soll weiter verfahren werden:\n"bf);
		    %    printf("   1 .. Originaldaten zuschneiden, 2 .. fehlende Werte mit 0 auffüllen\n");
		    %
		    %end;
		    base_matrix(:,i) = interp1(bl_wave, bl_base, freqvec);
	    end;
	else
	    printf("Bitte USE_GUI=1 setzen!\n");
	    printf("bf <f1> <f2> ... zum laden ohne GUI\n");
	end;
    end;
  case { "bp" }	# Besser!!
	fig (FIG_BASESPECTRA);
	hold off;
	boffset=0;
	for i=1:is_basis
	    plot_label=sprintf("-;%s;%d", basespectrum(i).name,i); # DAS FUNZT NUR MIT MAX 16 BASISSPEKTREN!!
	    plot_vector = base_matrix(:,i) + boffset;
	    plot(freqvec, plot_vector, plot_label);
	    boffset = boffset + min(plot_vector);
	    clear plot_vector;
	    if (i==1)
		hold on;
	    endif;
	endfor;
	xlabel (wavenumber_axis);
	ylabel (intensity_axis);
	%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
	 flipx();
  case { "bw" }	# die neue Basis wichten (invers mit den SV)
    for i=1:is_basis
      if ( s(i,i) != 0 )
        base_matrix(:,i)=base_matrix(:,i) / s(i,i);
      else
        printf ("Warnung: Wert %d ist 0. Wichtung nicht moeglich\n",s(i,i));
      endif
    endfor
  case { "normalize" }
	if (is_basis==0)
		printf("  Fuer diese Funktion muss mindestens ein Basisspektrum geladen sein (bf)!\n");
	else
		if ( eing_num > 1)
			if (eing_num == 2)
				norm1 = 1238.0;
				norm2 = 1254.0;
			else
				norm1 = str2num(substring(eingaben,2) );
				norm2 = str2num(substring(eingaben,3) );
				inorm1=ir_get_index(norm1, freqvec);
				inorm2=ir_get_index(norm2, freqvec);
				normdiff = base_matrix(inorm2,1)-base_matrix(inorm1,1);
				for i=1:columns(mdata)								% Daten normieren
					faktor = normdiff / (mdata(norm2,i)-mdata(norm1,i));
					mdata(:,i)=mdata(:,i).*faktor;
					offset = base_matrix(inorm2,1)-mdata(inorm2,i);
					mdata(:,i)=mdata(:,i)+offset;
				end;
				if (is_basis>1)
					for i=2:is_basis
						faktor = normdiff / (base_matrix(norm2,i)-base_matrix(norm1,i));
						base_matrix(:,i)=base_matrix(:,i).*faktor;
						offset = base_matrix(inorm2,1) - base_matrix(inorm2,i);
						base_matrix(:,i)=base_matrix(:,i)+offset;
					end;
				end;
			end;
		else
			printf("  Argument fehlt.\n");
			printf("  Syntax: normalize a b			(Normierung auf b-a)\n");
			printf("              normalize s			(Standardnormierung 1238-1254)\n");
		end;
	end;
  case { "bzero" }
    for i=1:is_basis
      basis_avg=mean(base_matrix(:,i));
      base_matrix(:,i) = base_matrix(:,i) - basis_avg;
    endfor

  case { "bnorm" }
	if ( eing_num < 2 )
		printf(" Usage: bnorm <<wavenumber>>\n");
	else
		bnorm_ind_pos = get_index(str2num(substring(eingaben,2)),freqvec);
		bnorm_ind_val = mdata(bnorm_ind_pos,1);
		for i=2:columns(mdata)
			bj = bnorm_index_val / mdata(bnorm_index_pos,i);
			mdata(:,i)=mdata(:,i).*bj;
		endfor
	endif

  case { "dzero" }
    put();
    data_avg=mean(mdata(:,1));
#    for i=1:columns(mdata)
#      mdata(:,i) = mdata(:,i) - data_avg;
#    endfor
    mdata = mdata - data_avg;
    printf ("  Daten verschoben: %f\n", data_avg);

  case { "invert" }
    put();
    mdata = -mdata;
  case { "restore" }
    put();
    restore();
  case { "bs" }     # Vektoren aus SVD Zerlegung übernehmen
	is_basis = 0;
	#base_matrix = 0; basespectrum = 0;
	if (eing_num > 1)
	    is_basis = eing_num-1;
	    base_matrix = zeros(rows(u), is_basis);
	    for i=1:is_basis
		base_matrix(:,i) = u(:,str2num(substring(eingaben,i+1)));
		basespectrum(i).name = sprintf("svdbase-%d", str2num(substring(eingaben,i+1)));
	    endfor;
	else
	    is_basis = input("Wieviel Vektoren übernehmen? ")
	    base_matrix = zeros(rows(u), is_basis);
	    for i=1:is_basis
    		base_matrix(:,i) = u(:,i);
    		basespectrum(i).name = sprintf("svdbase-%d", i);
	    endfor
	endif;

  case { "bg" }	# Die Globalfit-Daten als Basis
	is_basis = components;
	base_matrix = zeros(rows(u), is_basis);
	for i=1:is_basis
	    base_matrix(:,i)=uu(:,i);
	    basespectrum(i).name = sprintf("globalfit-%d",i);
	end
  case { "br" }
	printf("  Nicht implementiert\n");
  case { "pretime" }	% Findet den Beginn der Reaktion
	add_to_history("set pretime");
	add_to_history("plot pretime");
  case { "sfold" }	# Originaldaten an Basisspektren anpassen  ALTE VERSION
#    printf("Fit an Basisspektren\n");   # Kinetiken werden als Zeilen (!) in fitmatrix geschrieben
					# TODO: prüfen, ob die Dimensionen stimmen
    if (is_basis > 0)
      fitmatrix = zeros(columns(mdata), is_basis);
      printf ("     Starte Fit für %d Vektoren.\n", columns(mdata));
      fig(FIG);
      clf();
      coefficients = rand(1,is_basis);
      for i=1:columns(mdata)
        printf("    Gewichtete Anpassung Vektor %d von %d\n", i, columns(mdata)); fflush(stdout);
        %fitmatrix(i,:) = weighted_least_square_fit( mdata(:,i), base_matrix);
        fitmatrix(i,:) = least_square_fit( mdata(:,i), base_matrix);
	[ fitmatrix(i,:), fitfun ] = fminsearch('specfit', coefficients, options, 1, freqvec, mdata(:,i), base_matrix);
	fitmatrix(i,:)
	%plot(timevec, fitmatrix);
	[sse2, fittedfun] = specfit(fitmatrix(i,:),freqvec,mdata(:,i), base_matrix );

	plot(freqvec, mdata(:,i), freqvec, fittedfun);
	drawnow();
      endfor
    else
      printf ("    Zuerst muessen Basisspektren definiert werden.\n");
    endif;

  case { "sf" }
    if (is_basis > 0)
      if ( LIVE_MODE )
        figure(22);
        clf;
      endif
      % Pruefen, ob ein Fit geht (keine NAN's)
      % Basisspektren groesser als Daten -> wird schon bei bf beschnitten
      % der eigentliche Fit
      % TODO:
      %	-	gefittete Matrix exakt speichern
      %	-	Residuen-Spektren speichern
      %	-	Ergebnisse direkt als Datens�tze �bernehmen
      %minfunc = @specfit_silent;
      fitmatrix = zeros(columns(mdata), is_basis);
      weighmatrix = fitmatrix;
      startparams=rand(is_basis,1);
      printf ("     Starte Fit fuer %d Vektoren.\n", columns(mdata));
      for i=1:columns(mdata)
        printf("    Gewichtete Anpassung Vektor %d von %d\n", i, columns(mdata)); fflush(stdout);
	      %[fitpar, fitfun] = fminsearch(minfunc, startparams, options, 1, freqvec, mdata(:,i), base_matrix);
        [fitpar, fitfun, cvg, iter, corp, covp] = leasqr(base_matrix, mdata(:,i),startparams, @specfit_leasqr, 0.0001, 100);
        for k=1:length(fitfun)
          weightmatrix(i,k) = 1/sqrt(covp(k,k));          %weights for dglfit are calculated via 1/Error(parameter); Error is sqrt(diagonal element covariance matrix)
        endfor


        if ( LIVE_MODE )
          FittedSpectrum = zeros(rows(base_matrix),1);
          for j=1:length(fitfun)
            FittedSpectrum = FittedSpectrum+fitfun(j).*base_matrix(:,j);
          endfor

          ErrorSpectrum = FittedSpectrum - mdata(:,i);
          sse = sum(abs(ErrorSpectrum));
          plot(freqvec, FittedSpectrum, freqvec, mdata(:,i), freqvec, ErrorSpectrum);
          drawnow();
        endif
	% fitpar
	% fflush(stdout);
	      fitmatrix(i,:) = fitfun;
	%fit_mdata(i,:) = fitfun;
	%[ssf, fit_mdata(:,i)] = minfunc(fitfun, freqvec, mdata(:,i), base_matrix); 				% Rueckrechnen
        fit_mdata(:,i) = specfit_leasqr(base_matrix, fitfun);
	      fit_residuals(:,i) = mdata(:,i)-fit_mdata(:,i);									% Residuen berechnen
      end;
      printf ("    Die Datenmatrix wurde an die Basisspektren angepasst\n");
      printf("  Parametermatrix: fitmatrix(i,:)\n");
      printf("  Berechnete Spektren: fit_mdata\n");
      printf("  Residuen: fit_residuals\n");
      printf("  Die neuen Daten werden in freie Slots gesichert.\n");
      dummy = sprintf(" Fit an %d Basisspektren von Datei: %s - berechnete Werte", is_basis, listenname);
      store_data(freqvec, timevec, fit_mdata, dummy);
      dummy = sprintf(" Fit an %d Basisspektren von Datei: %s - Residuen", is_basis, listenname);
      store_data(freqvec, timevec, fit_residuals, dummy);
      is_datafit = 1;
    else
      printf ("    Zuerst muessen Basisspektren definiert werden.\n");
      printf ("    <bf> lade neue Basisspektren\n");
      printf ("    <bs> verwende Basisspektren aus SVD\n");
      printf ("    <bg> verwende Basisspektren aus Global Fit\n");
    end;
  case { "dglfit" }
    if (is_datafit == 1)
	if (eing_num>1)
	    if ( strcmp(substring(eingaben,2),"run") )
		% printf("  Fit wird an folgendes Modell ausgeführt:\n");
		% dgl_function
		% printf("  Startparameter:\n");
		% dgl_k
		% printf("  Anfangswerte:\n");					% Anfangswerte noch mitvariieren!!
		% dgl_initvals
		% printf("  Optionen (Progress, Präzision):\n");
		% dgl_options
		fig(FIG_DGLFIT);
		hold off;
    plot(timevec,fitmatrix);
    hold on;
		dgl_parameters = dgl_initvals;
		dgl_parameters(length(dgl_initvals)+1:length(dgl_initvals)+length(dgl_k))=dgl_k;	% Zuerst Anfangswerte, dann die k's.
    lsode_options("integration method","non-stiff");
		% printf("  Zu variierender Parametersatz:\n");
		% dgl_parameters
		%[fitpar, fitfun] = fminsearch(@dgl_fit, dgl_parameters, dgl_options, 1, timevec, fitmatrix);

    t_start=time_get_index(0,timevec);
    %lsode_options();
    [fitfun, fitpar] = leasqr(timevec(t_start:end), fitmatrix(t_start:end,:), dgl_parameters, @dgl_fit_leasqr, 0.0001, 40, weightmatrix(t_start:end,:));

		%[fitpar, fitfun] = fminsearch(minfunc, startparams, options, 1, freqvec, mdata(:,i), base_matrix);
    %[fitpar, fitfun] = leasqr(base_matrix, mdata(:,i),startparams, @specfit_leasqr, 0.0001, 20);

    printf("  Ergebnis:\n");
		printf("    Anfangswerte:\n");
		for i=1:length(dgl_initvals), printf("x0(%d)=%f\n", i, fitpar(i)); end;
		printf("    Ratenkonstanten:\n");
		for i=1:length(dgl_k), printf("k%d=%f\n", i, fitpar(length(dgl_initvals)+i)); end;
		[ res, dglfit_DAT ] = dgl_fit(fitpar, timevec(t_start:end), fitmatrix(t_start:end,:));		% Güte berechnen
		printf("***Residuum: %f\n", res);
	    elseif ( strcmp(substring(eingaben,2),"show") )
		printf("  Aktuelles Modell:\n");
		printf("%s",dgl_function());
		printf("  Ergebnis:\n");
		printf("    Anfangswerte:\n");
		for i=1:length(dgl_initvals), printf("x0(%d)=%f\n", i, fitpar(i)); end;
		printf("    Ratenkonstanten:\n");
		for i=1:length(dgl_k), printf("k%d=%f\n", i, fitpar(length(dgl_initvals)+i)); end;
		[ res, dglfit_DAT ] = dgl_fit(fitpar, timevec(t_start:end), fitmatrix(t_start:end,:));		% Güte berechnen
		printf("***Residuum: %f\n", res);
    figure()
	    elseif ( strcmp(substring(eingaben,2),"init") )		% TODO: Erweitern; hier müssen dann die Simulierten Kurven angezeigt werden
		printf("   Startparameter (k):\n");
		dgl_k
		printf("   Anfangswerte (x0):\n");
		dgl_initvals
		printf("  Optionen (Progress, Präzision):\n");
		dgl_options
		printf("   Modell:\n");
		printf("%s",dgl_function());
		% apropos("dgl_function");
		printf ("  Funktion wird für gegebenen Zeitvektor berechnet:\n");
		y_calc = lsode(dgl_function, dgl_initvals, timevec);
		fig(FIG_DGLFIT);
		hold off;
		plot(timevec, y_calc);
	    elseif ( strcmp(substring(eingaben,2),"select") )
		printf("  Modell auswählen:\n");
		printf("  3 Variablen:\n");
		printf("    1\n");
		printf("%s",dgl_irrev());
		printf("    2\n");
		printf("%s",dgl_lastrev());
		printf("    3\n");
		printf("%s",dgl_firstrev());
		printf("    4\n");
		printf("%s",dgl_allrev());
		printf("    5\n");
		printf("%s",dgl_trirev());
		printf("  4 Variablen:\n");
		printf("    6\n");
		printf("%s",dgl_fourrev());
		printf("    7\n");
		printf("%s",dgl_squarescheme());
		printf("    8\n");
		printf("%s",dgl_squarecross());
    printf("    9\n");
		printf("%s",dgl_tri_firstrev());
    printf("    10\n");
		printf("%s",dgl_tri_concerted());

		modell = str2num(input("  Modell: ","C"));
		if ( modell==1 )
		    dgl_function = @dgl_irrev;
		    dgl_k = [1;1];
		    dgl_initvals = [1;0;0];
		elseif ( modell==2 )
		    dgl_function = @dgl_lastrev;
		    dgl_k = [1;1;1];
		    dgl_initvals = [1;0;0];
		elseif ( modell==3 )
		    dgl_function = @dgl_firstrev;
		    dgl_k = [1;1;1];
		    dgl_initvals = [1;0;0];
		elseif ( modell==4 )
		    dgl_function = @dgl_allrev;
		    dgl_k = [1;1;1;1];
		    dgl_initvals = [1;0;0];
		elseif ( modell==5 )
		    dgl_function = @dgl_trirev;
		    dgl_k = [1;1;1;1;1;1];
		    dgl_initvals = [1;0;0];
		elseif ( modell==6 )
		    dgl_function = @dgl_fourrev;
		    dgl_k = [1;1;1;1;1;1];
		    dgl_initvals = [1;0;0;0];
		elseif ( modell==7 )
		    dgl_function = @dgl_squarescheme;
		    dgl_k = [1;1;1;1;1;1;1;1];
		    dgl_initvals = [1;0;0;0];
		elseif ( modell==8 )
		    dgl_function = @dgl_squarecross;
		    dgl_k = [1;1;1;1;1;1;1;1;1;1;1;1];
		    dgl_initvals = [1;0;0;0];
    elseif ( modell==9)
        dgl_function = @dgl_tri_firstrev;
        dgl_k = [1;1;1;1];
        dgl_initvals = [1;0;0];
    elseif ( modell==10)
        dgl_function = @dgl_tri_concerted;
        dgl_k = [1;1;1;1];
        dgl_initvals = [1;0;0];
		else
		    printf("  Eingabe unbekannt\n");
		end;
	    else
		printf("  unbekannter Befehl.\n");
	    end;
	else
      printf("  dglfit select ... Modell w�hlen\n");
	    printf("  dglfit run    ... Fit Starten\n");
	    printf("  dglfit init   ... Parameter ändern\n");
	end;
    else
	printf("  Fehler: Ein Datenfit liegt nicht vor.\n");
	printf("  ggf. Basisspektren mit \"bf\" laden\n");
	printf("  Datenfit mit \"sf\" ausführen\n");
    end;
  case { "lsqprint" }
#    Die Daten des Least square Fits ausgeben
#    einfach Fitmatrix plotten
#    plot (kinetikvektor, kinetikmatrix (die einzelnen Zeitspuren als Spaltenvektoren!)
#    es muss soviel linien im Diagramm geben wie spalten in der fitmatrix
#      plot(timevec, fitmatrix);
    fig(FIG_LSQFIT);
    for i=1:is_basis
	if (i==2)
	    hold on;
	endif;
	plot_label=sprintf("-;%s;%d", basespectrum(i).name,i); # DAS FUNZT NUR MIT MAX 16 BASISSPEKTREN!!
	plot(timevec, fitmatrix(:,i), plot_label);
    endfor;
    xlabel ("time");
    ylabel ("share of intermediate");
    hold off;

  case { "s" }
    # Singulaerwerte anzeigen
    if ( columns(s) < rows(s) )
      ctr=columns(s);
    else
      ctr=rows(s);
    endif;
    printf("Singulaerwerte:\n[");
    for i=1:ctr
      printf("%f,", s(i,i));
    endfor
    printf("]\n");

  case { "w" }
    # Speichermodus ein/aus
    if ( speichermodus == 0)
      speichermodus=1;
      printf("Speichermodus eingeschaltet\n");
    else
      speichermodus=0;
      printf ("Speichermodus ausgeschaltet\n");
    endif

  case {"u"}
    # U spaltenweise  (die neue Basis)
    nr=1;
    do
      do
        printf("    Nummer fuer Spaltenvektor (U; 1-%d; <0> beendet; <s> speichert %d):",columns(u),nr);
        nrs=input("","s");
        if (strcmp(nrs,"save"))
          printf("    Dateiname fuer Vektor u[%d]:>", nr);
	  fname=input("","s");
	  save_ir_file(fname,freqvec,u(:,nr));
        endif;
      until (!strcmp(nrs,"save"));
      nr = str2num (nrs);
      if ( nr > 0 )
       if ( nr < (columns(u)+1) )
        elements=rows(u);
# eigenes Fenster fr jeden BW
	fig(nr);
        plot (freqvec,u(:,nr));
	if (speichermodus == 1)
	  fname=input ("Speichern (Spaltenvektor U) - Dateiname:","s");
	  sfile = fopen(fname,"a");
	  for i=1:elements
	    fprintf(sfile,"%f %f\n", freqvec(i), u(i, nr));
	  endfor
	  fclose(sfile);
	endif;
       else
        printf ("Spalte ausserhalb des Bereichs (max. %d)\n", columns(u));
       endif;
      endif;
    until ( nr == 0 );

  case {"ut"}
    # U Zeilenweise; macht eigentlich keinen Sinn
    do
      nr=input("U - Nummer fuer Zeilenvektor (0 beendet): ");
      if ( nr > 0 )
       if ( nr < (rows(u)+1) )
        elements=columns(u);
        plot (freqvec,u(nr,:));
	if (speichermodus == 1)
	  fname=input ("Speichern (Zeilenvektor U) - Dateiname:","s");
	  sfile = fopen(fname,"a");
	  for i=1:elements
	    fprintf(sfile,"%f %f\n", freqvec(i), u(nr, i));
	  endfor
	  fclose(sfile);
	endif;
       else
        printf ("Zeile ausserhalb des Bereichs (max. %d)\n", columns(u));
       endif;
      endif;
    until ( nr == 0 );

  case {"u3d"}
    printf ("Anzahl der Komponenten des Plots (1 - %d):", rows(freqvec));
    k=input(">");
    if ( k>0 )
      mesh_u = zeros(k, freqvec);
      for i=1:k
        mesh_x(i) = freqvec(i);
	mesh_u(:,i) = u(:,i);
      endfor
	mesh(mesh_x, freqvec, mesh_u);
    else
      mesh(freqvec,freqvec,u);
    endif;

  case{"v3d"}
    mesh(timevec, timevec, v);

  case{"o"}
    # O spaltenweise  (die Originaldaten-spektren)
    do
      do
        printf("    Nummer (1-%d) oder Zahl (%f-%f) fuer Spaltenvektor (<0> beendet):",columns(mdata),timevec(1), timevec(rows(timevec)));
        nrs=input("","s");
        if (strcmp(nrs,"save"))
          printf("    Dateiname fuer Vektor O[ %d ]:>", nr);
	  fname=input("","s");
	  save_ir_file(fname,freqvec,mdata(:,nr));
        endif;
      until ( !strcmp(nrs,"save") );

#   !!! nrs Analysieren, ist ein Punkt drin?

      if ( strcmp(nrs,"exit") )
        nr=0;
      else
        nr = str2num (nrs);
      endif;

      if ( contains(nrs,".") )
        # In Vektor umrechnen (den Vektor suchen, der am besten passt)
	indexposition=1; differenzval=10000;
	for i=1:rows(timevec)
	  indexdifferenz=abs( timevec(i) - nr );
	  if ( indexdifferenz < differenzval )
	    differenzval=indexdifferenz;
	    indexposition=i;
          endif
	endfor
	nr=indexposition;
      endif
      if ( (nr > 0) & (nr < (rows(timevec)+1)) )
        elements=rows(mdata);
        for i=1:elements
          colvec_os(i)=mdata(i,nr);
        endfor
	printf ("    [Nr: %d, t=%f]\n", nr, timevec(nr));
        plot (freqvec,colvec_os);
	if (speichermodus == 1)
	  fname=input ("    Speichern (Spaltenvektor O) - Dateiname:","s");
	  sfile = fopen(fname,"a");
	  for i=1:elements
	    fprintf(sfile,"%f %f\n", freqvec(i), colvec_os(i));
	  endfor
	  fclose(sfile);
	endif;
      elseif ( nr > rows(timevec) )
        printf("    Nummer ausserhalb des zulaessigen Bereiches.\n");
	nr=1;
      endif;
    until ( nr == 0 );

  case{"ot"}
    # O zeilenweise  (die Originaldaten-Kinetik)
    do
      nr=input("Nummer (int) od. Wellenzahl (flt) fuer Zeilenvektor (0 beendet): ");
#      nrstring=sprintf("%f",nr);
      nrstring=num2str(nr,16);
#      printf("Suche: %f->[%s]\n",nr, nrstring);
      if ( contains(nrstring,".") )
        # In Vektor umrechnen (den Vektor suchen, der am besten passt)
        printf("Wellenzahl eingegeben, suche naechstliegenden Wert\n");
	indexposition=1; differenzval=10000000;
	for i=1:length(freqvec)
	  indexdifferenz=abs( freqvec(i) - nr );
	  if ( indexdifferenz < differenzval )
	    differenzval=indexdifferenz;
	    indexposition=i;
          endif
	endfor
	nr=indexposition;
      endif
      if ( nr > 0 )
        elements=columns(mdata);
        for i=1:elements
          colvec_oz(i)=mdata(nr,i);
        endfor
        plot (timevec,colvec_oz);
	printf ("[Nr: %d, WZ=%f\n", nr, freqvec(nr));
	if (speichermodus == 1)
	  fname=input ("Speichern (Zeilenvektor O) - Dateiname:","s");
	  sfile = fopen(fname,"a");
	  for i=1:elements
	    fprintf(sfile,"%f %f\n", timevec(i), colvec_oz(i));
	  endfor
	  fclose(sfile);
	endif;
      endif;
    until ( nr == 0 );

  case {"scan" }					% Die Datei entlang des Wellenzahlvektors "durchscannen"
	if ( eing_num > 1 )
		if (strcmp(substring(eingaben,2),"spec"))
			fig(FIG);
			hold off;
			scan_starttime = str2num(substring(eingaben,3));
			scan_stoptime = str2num(substring(eingaben,4));
			scan_startindex = time_get_index(scan_starttime, timevec);
			scan_stopindex = time_get_index(scan_stoptime, timevec);
			i=scan_startindex;
			do
				clf();
				plot(freqvec, mdata(:,i));
				drawnow();
				usleep(FRAME_DELAY);
			until (i++>=scan_stopindex);
		end
	else
		printf("  <Enter> für nächste Spur,\n  <q> beendet\n");
		i=1;
		fig(FIG);
		hold off;
		do
			clf();
			dummy = sprintf("-;%d/%d: %f;", i, length(freqvec), freqvec(i));
			plot(timevec, mdata(i,:), dummy);
			drawnow();
			printf("  Trace %d von %d: %f ", i, length(freqvec), freqvec(i));
			fflush(stdout);
			answ = input("> ","s");
		until ( i++>length(freqvec) || answ=="q" );
	endif;

#########################################################################################
#
#     Die Plotfunktion
#
  case {"plot" "p" }	# Zentrale Plotfunktion
    von=1; bis=1;
	  plot_active=1;
    if (eing_num>1)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%				<plot globalfit>
      if ( strcmp(substring(eingaben,2),"globalfit") || strcmp(substring(eingaben,2),"gf") || strcmp(substring(eingaben,2),"glf") )
        % Plottet die letzten Ergebnisse des Globalfits
        print_together = 0;
        print_bspec_only = 0;
        print_kin_only = 0;
        if ( eing_num==3 )
          if ( strcmp(substring(eingaben,3),"1") )
            print_together = 1;
          elseif (strcmp(substring(eingaben,3),"bspec"))
            print_bspec_only = 1;
            print_together = 1;
          elseif (strcmp(substring(eingaben,3),"kin"))
            print_kin_only = 1;
            print_together = 1;
          else
            printf("  plot globalfit		in separate Grafiken plotten\n");
            printf("  plot globalfit 1		in eine einzige Grafik plotten\n");
              printf("  plot globalfit bspec | kin\n");
              printf("  Geplottete Daten: uu(:,#nr)\n");
          endif;
        endif;

        printf("  Fit:\n"); fflush(stdout);
        %printf("  Konvergenz: %f\n", fun); fflush(stdout);

        printf("Ergebnis:\n");
        AMatrix				% Sollte die Transformationsmatrix sein
        KMatrix
        OMatrix
        % [sse, fv] = model(fitparameter, timevec, kineticfun, components, weights);
        %user_plot(timevec,fv);
        %subplot(2,1,2);
        %diff_matrix = fv - kineticfun;
        %user_plot(timevec, diff_matrix);

        % Ergebnisse plotten
        % Basisspektren berechnen
        % nach absteigenden k's sortieren:
        [kn, k_order] = sort(KMatrix,"descend");
        printf("  Globalfit - Order of Components:\n");
        for i=1:components
          printf("k(%d) = %f      t1/2(%d) = ln2/k = %f\n", k_order(i), KMatrix(k_order(i)), k_order(i), -log(2)/KMatrix(k_order(i)) );
        endfor;

        fig(FIG_GLOBALFIT_RESULT);
        %clf();
        %TODO:   kineticfun -> kinetic_to_fit, timevec -> timevec_to_fit
        %
        hold off;
        if ( print_together == 0 )
          for i=1:components
            subplot(components,2,(i-1)*2+1);
            plot(freqvec,uu(:,k_order(i)));
            legend_text = sprintf("k_%d = %f",i, KMatrix(k_order(i)));
            legend(legend_text);
            printf("  k_%d = %f (t au_%d = %f)\n", i, KMatrix(k_order(i)), i, 1/KMatrix(k_order(i)));
            %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca(),"XDir","reverse"); end;
            flipx();
            subplot(components,2,(i-1)*2+2);						% TODO: hier die echten Fits plotten
            % Alte version:
            % plot(timevec,vv(:,k_order(i)));						% Maybe the next line makes problems with grace...
            %legend_text = sprintf("k_%d = %f",i, KMatrix(k_order(i)));			% oder Legende irgendwie anders sinnvoll machen...
            %legend(legend_text);
            % Neue Version
            % Todo: Kinetiken mittels Semilogx plotten....
            if ( LOG_KINETICS == 0 )
              plot(timevec,kineticfun(:,i),"-b");		% aus SVD					% TODO: K's als legende zu den Basisspektren
            else
              semilogx(timevec,kineticfun(:,i),"-b");		% aus SVD					% TODO: K's als legende zu den Basisspektren
            endif;
            hold on;
            if ( LOG_KINETICS == 0 )
                plot(timevec_to_fit, fv(:,i),"-r");			% gefittet
            else
              semilogx(timevec_to_fit, fv(:,i),"-r");			% gefittet
            end;
          endfor;
          printf ("  Logarithmische t-Achse aus/einstellen: LOG_KINETICS\n");
          printf ("  In eine / mehrere Grafiken plotten: print_together\n");
          hold off;
          legend("SVD","globalfit");

        elseif (print_bspec_only==1)
          printf("  Bspec Plot\n");
          hold off;
          clf;
          for i=1:components
            color_text = sprintf("-%d",i);
            plot(freqvec,uu(:,k_order(i)),color_text);
            legend_text_a{i} = sprintf("bspec nr. %d; k=%f", i, KMatrix(k_order(i)));
            hold on;
          endfor;
          legend(legend_text_a);
          flipx();
          %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca(),"XDir","reverse"); end;
        elseif (print_kin_only==1)
          printf("  Kin Plot\n");
          hold off;
          for i=1:components
            if ( LOG_KINETICS == 0 )
              plot(timevec, kineticfun(:,k_order(i)));
              plot(timevec_to_fit,vv(:,k_order(i)));
            else
              semilogx(timevec, kineticfun(:,k_order(i)));
              semilogx(timevec_to_fit,vv(:,k_order(i)));
            endif;
            legend_text = sprintf("k_%d = %f",i, KMatrix(k_order(i)));
            legend("data",legend_text);
            printf ("  Logarithmische t-Achse aus/einstellen: LOG_KINETICS\n");
            printf ("  In eine / mehrere Grafiken plotten: print_together\n");
            printf("  k_%d = %f (tau_%d = %f)\n", i, KMatrix(k_order(i)), i, 1/KMatrix(k_order(i)));
            hold on;
          endfor;
        else
          subplot(1,2,1);
          hold off;
          for i=1:components
            plot(freqvec,uu(:,k_order(i)));
            hold on;
            flipx();
            %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca(),"XDir","reverse"); end;
          end;
          subplot(1,2,2);
          hold off;
          for i=1:components
            if ( LOG_KINETICS == 0 )
              plot(timevec, kineticfun(:,k_order(i)));
              plot(timevec_to_fit,vv(:,k_order(i)));
            else
              semilogx(timevec, kineticfun(:,k_order(i)));
              semilogx(timevec_to_fit,vv(:,k_order(i)));
            end;
            legend_text = sprintf("k_%d = %f",i, KMatrix(k_order(i)));
            legend("data",legend_text);
            printf ("  Logarithmische t-Achse aus/einstellen: LOG_KINETICS\n");
            printf ("  In eine / mehrere Grafiken plotten: print_together\n");
            printf("  k_%d = %f (tau_%d = %f)\n", i, KMatrix(k_order(i)), i, 1/KMatrix(k_order(i)));
            hold on;
          end;
        end;
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	    		</plot globalfit>
      elseif ( strcmp(substring(eingaben,2),"pretime" ) )
        fig(FIG);
        hold off;
        subplot(1,1,1);
        PRE_INDEX = time_get_index(PRE_TIME, timevec);
        START_PRE_INDEX = PRE_INDEX - 4;
        STOP_PRE_INDEX = PRE_INDEX + 4;
        if (START_PRE_INDEX < 1), START_PRE_INDEX = 1; end;
          offset = 0;
          printf("	Zeit		Index\n");
        for i=START_PRE_INDEX:STOP_PRE_INDEX
          printf("	%f	%d\n", timevec(i), i);
          preplotvec(:, i-START_PRE_INDEX+1) = mdata(:,i) - offset;
          prelegend{i-START_PRE_INDEX+1} = sprintf("%d.: %d (%f)", i-START_PRE_INDEX+1, i, timevec(i));
          %plot(freqvec, mdata(:, i) - offset);
          %hold on;
          offset = offset + abs(min(mdata(:,i)));
          if (i<STOP_PRE_INDEX), offset = offset + abs(max(mdata(:,i+1))); end;
        endfor;
        plot(freqvec, preplotvec);
        legend(prelegend);
        clear preplotvec;
        clear prelegend;

      elseif ( substring(eingaben,2) == "u" )					# SVD:      	U
        if (AUTO_FIGURE==1), fig(FIG_U); endif;
        if (eing_num==3)
          bis = str2num(substring(eingaben,3));
        else
          bis=input("  Plottet Matrix U 1-");
        endif;
        uplot=u(:,von:bis);
        for i=2:bis
          uplot(:,i) = uplot(:,i) - abs(min(uplot(:,i-1))) - abs(max(uplot(:,i)));
        endfor;
        xlabel(wavenumber_axis);
        ylabel(intensity_axis);
        hold off;
        for i=1:columns(uplot)
          plot_label = sprintf("-;Base %d;%d",i,mod(i,5));
          plot(freqvec, uplot(:,i), plot_label);
          if (i==1)
            hold on;
          endif;
        endfor;
        %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set (gca,"XDir","reverse"); end;
        flipx();
        xlabel(wavenumber_axis);
        ylabel(intensity_axis);
        hold off;
            #plot(freqvec,uplot(:,:));
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %
      %		Rotierte Matrix plotten
      elseif ( strcmp(substring(eingaben,2),"r"))
          fig(FIG_SVD);
          clf();
          if ( eing_num == 3 )
            vals_to_plot = str2num(substring(eingaben,3));
          else
            vals_to_plot = 5;
          endif
          printf("  vals_to_plot=%d\n", vals_to_plot);
          for komponente=1:vals_to_plot
            subplot(vals_to_plot,2,komponente*2-1);
            plot(freqvec, u_rot(:,komponente));
            subplot(vals_to_plot,2,komponente*2);
            if ( LOG_KINETICS==0)
              plot(timevec, v_rot(:,komponente));
            else
              semilogx(timevec, v_rot(:,komponente));
            endif;
          endfor
          S  = axes( 'visible', 'off', 'title', 'rotated' );

      elseif ( strcmp(substring(eingaben,2),"rot" ) )
          printf("  Info: \" plot r\" zum Plotten nur der rotierten Matrix verwenden!\n");
          fig(FIG_SVD);
          clf();
          if ( eing_num == 3 )
            vals_to_plot = str2num(substring(eingaben,3));
          else
            vals_to_plot = 5;
          endif;
          printf("  vals_to_plot=%d\n", vals_to_plot);
          for komponente=1:vals_to_plot
            subplot(vals_to_plot,2,komponente*2-1);
            plot(freqvec, u_alt(:,komponente), freqvec, u_rot(:,komponente));
            legend('original','rotated');
            subplot(vals_to_plot,2,komponente*2);
            if ( LOG_KINETICS==0)
              plot(timevec, v(:,komponente), timevec, v_rot(:,komponente));
            else
              semilogx(timevec, v(:,komponente), timevec, v_rot(:,komponente));
            endif;
          end
          legend('original','rotated', 'location', 'southeast');
          % Baustelle: wenn grace eingestellt ist, hier kurzzeitig auf gnuplot umstellen!
          if (PLOT_ROT_HISTOGRAMS==1)
            if (strcmp(DEFAULT_PLOTTER,"grace")); toggle_grace_use; endif;
            fig(FIG_AUTOCORR);
            clf();
            subplot (2,2,1);
            plotvec=zeros(1,vals_to_plot);
            for i=1:autocorr_to_plot
              plotvec(i,:) = svd_autocorr(u, vals_to_plot, i);
            endfor;
            bar (plotvec');
            title("Autocorrelation of U (orig)");
            xlabel('component number');
            ylabel('value');
            subplot (2,2,2);
            plotvec=zeros(1,vals_to_plot);
            for i=1:autocorr_to_plot
              plotvec(i,:) = svd_autocorr(u_rot, vals_to_plot, i);
            endfor;
            bar (plotvec');
            title("Autocorrelation of U (rot)");
            xlabel('component number');
            ylabel('value');
            subplot (2,2,3);
            plotvec=zeros(1,vals_to_plot);
            for i=1:autocorr_to_plot
              plotvec(i,:) = svd_autocorr(v, vals_to_plot,i );
            endfor;
            bar (plotvec');
            title("Autocorrelation of V (orig)");
            xlabel('component number');
            ylabel('value');
            subplot (2,2,4);
            plotvec=zeros(1,vals_to_plot);
            for i=1:autocorr_to_plot
              plotvec(i,:) = svd_autocorr(v_rot, vals_to_plot,i );
            endfor;
            bar (plotvec');
            title("Autocorrelation of V (rot)");
            xlabel('component number');
            ylabel('value');
            if (strcmp(DEFAULT_PLOTTER,"grace")); toggle_grace_use; endif;
          else
            printf("  Hinweis: Histogrammansicht kann mit PLOT_ROT_HISTOGRAMS=1 eingeschaltet werden.\n");
          end;
          printf("  Bearbeitete Daten in u_rot, v_rot ( mdata = u_rot (v_rot)T )\n");

          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      elseif ( strcmp(substring(eingaben,2),"svd" ) )
        if ( eing_num == 3 )
	        fig(FIG_SVD);
	        hold off;
	        bis = str2num(substring(eingaben,3));
	        for i=1:bis
		        subplot(bis,2,(i-1)*2+1);					       % Base Vector
		        plot_label = sprintf("SVD component: %d",i);
		        plot(freqvec, u(:,i));
            title(plot_label);
		        %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set (gca,"XDir","reverse"); end;
		        flipx();
		        if (i==bis)
		          xlabel(wavenumber_axis);
		        endif;
		        ylabel(intensity_axis);
		        subplot(bis,2,(i-1)*2+2);
		        plot_label=sprintf("Singular Value: %f", s(i,i));			% Data
		        if ( LOG_KINETICS==0 )
			        plot(timevec, v(:,i));
		        else
			        semilogx(timevec, v(:,i));
		        endif;
            title(plot_label);
		        if ( SVD_FIT(i) == 1 )
		            hold on;
		            plot_label=sprintf("-;k=%f;3", svdfit(i).parameters(3));
		            if ( LOG_KINETICS == 0 )
			              plot(timevec, svdfit(i).values);
		            else
			              semilogx(timevec, svdfit(i).values);
		            end;
                title(plot_label);
		            hold off;
		            printf("%s",svdfit(i).report);
		        endif;
		        if (i==bis)
		            xlabel (time_axis);
		        endif;

	      	endfor;
		elseif ( eing_num > 3 )							% Komponenten
			PLOT_SVD_STYLE = str2num(substring(eingaben,4));
			% entweder: plot svd 2 3 4 5 Komponenten Plotten, dann PLOT_SVD_STYLE>0
			% oder: plot svd 4 -1 dann z.B. alle 4 Komponenten plotten, kin + base jeweils in Extrafenster
			if (PLOT_SVD_STYLE > 0)
				fig(FIG_SVD);
				clf();
				hold off;
				#bis = str2num(substring(eingaben,3));
				to_do = eing_num - 2;
				for i=1:to_do
					subplot(to_do,2,(i-1)*2+1);
					to_plot = str2num(substring(eingaben,i+2));			# Base Vector
					plot_label = sprintf("-;Base %d;%d",to_plot,mod(i,5));
					plot(freqvec, u(:,to_plot), plot_label);
					%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set (gca,"XDir","reverse"); end;
					flipx();
					if (i==to_do)
						xlabel(wavenumber_axis);
					end;
					ylabel(intensity_axis);
					subplot(to_do,2,(i-1)*2+2);
					plot_label=sprintf("-;SV:%f;1", s(to_plot,to_plot));		# Data
					plot(timevec, v(:,to_plot), plot_label);
					if ( to_plot <= SVD_FIT )				# SVD Fits plotten, wenn ex.
						hold on;
						plot_label=sprintf("-;k=%f;3", svdfit(to_plot).parameters(3));
						plot(timevec, svdfit(to_plot).values, plot_label);
						hold off;
						printf("%s",svdfit(to_plot).report);
					endif;
					if (i==to_do)
						xlabel (time_axis);
					end;
					% ylabel (intensity_axis);
				endfor;
			elseif (PLOT_SVD_STYLE == -2)
				to_do = str2num(substring(eingaben,3));
				fig(FIG_SVD);
				clf();
				hold on;
				for i=1:to_do
					to_plot = i;
					plot_label = sprintf("-;Base %d;%d",to_plot,mod(i,5));
					plot(freqvec, u(:,to_plot), plot_label, 'LineWidth', 2);
				endfor;
				xlabel(wavenumber_axis);
				ylabel(intensity_axis);
				flipx();
				fig(FIG_SVD+1);
				clf();
				hold on;
				for i=1:to_do
					to_plot=i;
					plot_label=sprintf("-;SV:%f;%d", s(to_plot,to_plot), mod(i,5));		# Data
						plot(timevec, v(:,to_plot), plot_label, 'LineWidth',2);
				endfor;
				xlabel (time_axis);
				ylabel (intensity_axis);
			else
				printf(" plot svd: Unknown style.\n");
			endif;
		else
			printf("   Syntax: plot svd <components> <style>\n");
			printf("      style:  >0 - separate frames for spectra and kinetics, 1 window\n");
			printf("              -2 - plot all given components into 1 frame but 2 windows\n");
		endif;
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif ( substring(eingaben,2) == "v" )					# SVD:		V
		if (AUTO_FIGURE==1), fig(FIG_V); endif;
		clf();
		if (eing_num==3)
			bis = str2num(substring(eingaben,3));
		else
			bis = input("  Plottet Matrix V 1-");
		endif;
		von=1;
		plots = bis-von;
		pspalten = 3;
		pzeilen = roundup(plots / 3);
		if (strcmp(DEFAULT_PLOTTER,"grace"))
			% Mit Grace alles in 1 Diagramm plotten
			hold on;
			plot_legend = { "1", "2" };
			for i=von:bis
				plot_label=sprintf("%d", i);
				plot_legend( (i+1)-von ) = plot_label;
				plot(timevec, v(:,i));
				%legend (plot_label);
			endfor;
			legend (plot_legend);
			xlabel (time_axis);
			ylabel (intensity_axis);
			hold off;
		else
			for i=von:bis
				subplot(pzeilen, pspalten, ((i-von)+1) );
				plot_label=sprintf("-;%d;", i);
				plot(timevec, v(:,i), plot_label);
				xlabel (time_axis);
				ylabel (intensity_axis);
			endfor;
		endif;
			%%%%%%%%%%%%%%%%%%%%%                                  <Plot o>         Modifiziert PF
	elseif ( strcmp(substring(eingaben,2),"o" ) || strcmp(substring(eingaben,2),"t") )				# Testet einfachere Plotversion mit hold
		if (eing_num<=3) % ************************** 3D Surface
			x_resolution = XRES_3D;     # 30;			# Kinetik
			y_resolution = YRES_3D;     # 200;			# Wellenzahlen
			x_avg = round ( length(timevec) / x_resolution );
			y_avg = round ( length(freqvec) / y_resolution );
			clear plot_dat_1;clear plot_dat;clear plot_kin;clear plot_wzv;
			if(LOG_KINETICS)
				%scaling for logarithmic plot
				if (!REACTION_START_INDEX)
					REACTION_START_INDEX = 1;
				endif;
				if length(timevec)>x_resolution && length(timevec)>1+x_avg
					i=1; j=1;k=0;l=1;							% Kinetiken reduzieren
					printf("  Skaliert Kinetik...\n"); fflush(stdout);
					if(j+x_avg<REACTION_START_INDEX)
						do
							plot_kin(i) = mean(timevec(j:j+x_avg));
							plot_dat_1(:,i) = mean( mdata(:,j:j+x_avg),2 );
							j=j+x_avg+1;
							i=i+1;
						until ( j+x_avg >= REACTION_START_INDEX );
					endif;
					plot_kin(i) = mean(timevec(j:REACTION_START_INDEX));
					plot_dat_1(:,i) = mean( mdata(:,j:REACTION_START_INDEX),2 );
					j=REACTION_START_INDEX+1;
					i=i+1;
					do
						if(k<x_avg)
							plot_kin(i) = mean(timevec(j:j+k));
							plot_dat_1(:,i) = mean( mdata(:,j:j+k),2 );
							j=j+k+1;
							if(j>l^2*6)
								k++;
								l++;
							endif;
						else
							plot_kin(i) = mean(timevec(j:j+x_avg));
							plot_dat_1(:,i) = mean( mdata(:,j:j+x_avg),2 );
							j=j+x_avg+1;
						endif;
						i=i+1;
					until ( j+x_avg > length(timevec) );
				else
					plot_kin=timevec;
					plot_dat_1=mdata;
					printf("Maximale Auflösung der Kinetik\n");
				endif;
			else
				%scaling for linear plot
				if length(timevec)>x_resolution && length(timevec)>1+x_avg
					i=1; j=1;							% Kinetiken reduzieren
					printf("  Skaliert Kinetik...\n"); fflush(stdout);
					do
						plot_kin(i) = mean(timevec(j:j+x_avg));
						plot_dat_1(:,i) = mean( mdata(:,j:j+x_avg),2 );
						j=j+x_avg;
						i=i+1;
					until ( j+x_avg > length(timevec) );
				else
					plot_kin=timevec;
					plot_dat_1=mdata;
					printf("  Maximale Auflösung der Kinetik\n");
				endif;
			endif;
			%scale frequency for plot
			if length(freqvec)>y_resolution && length(freqvec)>1+y_avg
				i=1; j=1;
				printf("  Skaliert Spektren...\n"); fflush(stdout);		% WZ reduzieren (hier besser peak pick)
				do
					plot_wzv(i) = mean(freqvec(j:j+y_avg));
					plot_dat(i,:) = mean( plot_dat_1(j:j+y_avg,:));
					j=j+y_avg;
					i=i+1;
				until ( j+y_avg > length(freqvec) );
			else
				plot_wzv=freqvec;
				plot_dat=plot_dat_1;
				printf("  Maximale Spektrale auflösung\n");
			endif;

			printf(" Change view: AZ_3D, EL_3D\n");
			printf(" Change resolution: XRES_3D, YRES_3D\n");
			printf(" Change shading: shading_3D (flat, faceted, interp)\n");
			if (AUTO_FIGURE==1), fig(FIG_SURFACE); endif;

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% contour plotting option e.g. for uvvis data    Paul Fischer
			if (eing_num == 3 && sum(strcmp(substring(eingaben, 3), {"cont","contour"})))
				%plot3d=@surf;
				pcolor (plot_kin, plot_wzv, plot_dat);				% mesh oder surface
				%view(90,90);
				shading interp;
				colormap(jet);
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mesh plot
			else
				plot3d=@mesh;
				plot3d(plot_kin, plot_wzv, plot_dat);				% mesh oder surface
				view(AZ_3D, EL_3D);
				shading(shading_3D);
			endif;

			ylabel(wavenumber_axis);
			xlabel(time_axis);
			zlabel(intensity_axis);
			if (inverse_wavenumber_axis==1)
					set(gca(),"YDir","reverse");
			endif;
			if(LOG_KINETICS)
				set(gca(),"XScale","log");
			else
				set(gca(),"XScale","linear");
			endif;

		%%%%%%%%%%%%%% if eing_num > 3 : plot spectra of time interval tx - ty
		elseif ( strcmp(substring(eingaben,4),"-") )				% ******** Bereich
			sstart = get_index(str2num(substring(eingaben,3)),timevec);
			sstop = get_index(str2num(substring(eingaben,5)),timevec);
			dummy=mdata(:,sstart:sstop);
			if (AUTO_FIGURE==1), fig(FIG_SPECTRA); endif;

			if (eing_num==6)
				if (strcmp(substring(eingaben,6),"i"))
					printf("..inverse color plot\n");
					dummy=fliplr(dummy);
				else
					number_of_spectra_to_plot = str2num(substring(eingaben,6));  % TODO
				endif;
			endif;
			rainbow_plotter(freqvec,dummy);    % TODO: modify this to plot a smaller number
			xlabel(wavenumber_axis);
			ylabel(intensity_axis);
			if (inverse_wavenumber_axis==1)
					set(gca(),"XDir","reverse");
			endif;
			clear dummy;

		%%%%%%%%%%%%% plot with label
		else
			plot_label="";
			if ( (eing_num==4) && !(isdigit(substring(eingaben,4))(1)) )								% p k 1644 label
				plot_label=substring(eingaben,4);
			end;
			if ((length(plot_label)==0) && eing_num > 3 )						% ******** Mehrere Spektren plotten
				if (AUTO_FIGURE==1), fig(FIG_SPECTRA); end;		% ******** mit oder ohne AUTO_COLOR , AUTO_COLOR_NUM
				num_to_plot = eing_num - 2;
				offset=0.0;
				clear dummy;
				for i=1:num_to_plot
					[ to_plot(i), real_to_plot(i) ] = time_get_index(str2num(substring(eingaben,i+2)), timevec);
					plot_label{i} = sprintf("%f",real_to_plot(i));
					if ( PLOT_WITH_OFFSET == 1)
						dummy(:,i) = mdata(:, (to_plot(i))) + offset;
						offset = offset - abs( (min(mdata(:,to_plot(i)))));
					else
						dummy(:,i) = mdata(:, to_plot(i));
					endif;
				endfor;
				if ( num_to_plot < 4 )
					thickness=2;
				else
					thickness=1;
				endif;
				%rainbow_plotter(freqvec, dummy, plot_label, thickness);
				rainbow_plotter(freqvec, dummy);
				xlabel(wavenumber_axis);
				ylabel(intensity_axis);
				if (inverse_wavenumber_axis==1)
						set(gca(),"XDir","reverse");
				end;
				clear dummy; clear plot_label; clear to_plot; clear real_to_plot; clear thickness;
			else							% ******** Einzelne Spektren
				if (AUTO_FIGURE==1), fig(FIG_SPECTRA); end;		% ******** mit oder ohne AUTO_COLOR , AUTO_COLOR_NUM
				if ( AUTO_COLOR==1 )
					[col,colincr] = next_color(col,colincr);
				endif;
				offset=0.0;
				[ to_plot, real_to_plot] = time_get_index(str2num(substring(eingaben,3)), timevec);
				if (length(plot_label)==0)
					plot_label = sprintf("-;%f;",real_to_plot);
				else
					plot_label = sprintf("-;%s;",plot_label);
				endif;
				[a,b] = max(col);				% Prüfen ob col gültig
				if ( a>1 )
					col(b)=1;
				endif;
				[a,b] = min(col);
				if ( a<0 )
					col(b)=0;
				endif;
				if ( PLOT_WITH_OFFSET == 1)
					plot(freqvec, (mdata(:, (to_plot)) + offset), plot_label, "Color", col, "LineWidth", 2);
					offset = offset - abs( min(mdata(:, to_plot)) );
				else
					plot(freqvec, (mdata(:,(to_plot))), plot_label, "Color", col, "LineWidth", 2);
				endif;
				xlabel(wavenumber_axis);
				ylabel(intensity_axis);
				flipx();
			endif;
		endif;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     </plot o>
% TODO: indent from here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     </plot k>
	elseif ( strcmp(substring(eingaben,2),"ok" ) || strcmp(substring(eingaben,2),"k" ) )				% ZEITSPUREN PLOTTEN
		if (AUTO_FIGURE==1), fig(FIG_KINETICS); endif;	% Eingabe ist die WZ!!
		kin_plot_label="";
		if ( (eing_num==4) && !(isdigit(substring(eingaben,4))(1)) )								% p k 1644 labal
			kin_plot_label=substring(eingaben,4);
		end;
		if (eing_num==2)							% keine Angaben gemacht, alles abfragen
			subplot(1,1,1);
			printf("  Syntax:\n");
			printf("    plot ok\n");
			printf("    plot ok wl\n");
			printf("    plot ok wl1 wl2 wl3 ....\n");
			printf("    plot ok wl1 - wl2\n\n");
			von=input("  Plottet Kinetik von (WZ):");
			bis=input("                  bis (WZ):");
			[von_index, von_wz] = ir_get_index(von, freqvec);
			[bis_index, bis_wz] = ir_get_index(bis, freqvec);		# noch vertauschen. wenn n�tig....
			oplot=mdata(von_index:bis_index,:);
			oplot=oplot';
      % if plotted with offset
			%for i=2:(bis_index - von_index)
			%  oplot(:,i) = oplot(:,i) - abs(min(oplot(:,i-1))) - abs(max(oplot(:,i)));
			%endfor
			if ( LOG_KINETICS==0 )
				plot(timevec,oplot(:,:));
			else
				semilogx(timevec,oplot(:,:));
			end;
			xlabel(time_axis);
			ylabel(intensity_axis);

    elseif ( strcmp(substring(eingaben,3),"all") )          % Ratio plotten
      subplot(1,1,1);
      oplot=mdata';

      if ( LOG_KINETICS==0 )
        plot(timevec,oplot(:,:));
      else
        semilogx(timevec,oplot(:,:));
      endif;
      xlabel(time_axis);
      ylabel(intensity_axis);

    elseif ( (eing_num == 3) || length(kin_plot_label)>0)						% nur 1 WL plotten
      [von_index, von_wz] = ir_get_index(str2num(substring(eingaben,3)), freqvec);
      printf("  Vec %d (%f)\n", von_index, von_wz);
      if (length(kin_plot_label)==0)
        kin_plot_label=sprintf("%s-;%d cm^{-1};", DEFAULT_COLOR, von_wz);
      else
        kin_plot_label=sprintf("%s-;%s;", DEFAULT_COLOR, kin_plot_label);
      end;
      if ( LOG_KINETICS==0 )
        plot(timevec, mdata(von_index,:)', kin_plot_label,'linewidth',2);
      else
        semilogx(timevec, mdata(von_index,:)', kin_plot_label,'linewidth',2);
      end;
			xlabel(time_axis);
			ylabel(intensity_axis);

		elseif ( strcmp(substring(eingaben,3),"r") )          % Ratio plotten
			[von_index, von_wz] = ir_get_index(str2num(substring(eingaben,4)), freqvec);
			[von_index1, von_wz1] = ir_get_index(str2num(substring(eingaben,5)), freqvec);
			printf("  Vec %d (%f) / Vec %d (%f)\n", von_index, von_wz, von_index1, von_wz1);
			if (length(kin_plot_label)==0)
				kin_plot_label=sprintf("%s-;%d/%d cm^{-1};", DEFAULT_COLOR, von_wz, von_wz1);
			else
				kin_plot_label=sprintf("%s-;%s;", DEFAULT_COLOR, kin_plot_label);
			endif;
			if ( LOG_KINETICS==0 )
				plot(timevec, mdata(von_index,:)'./mdata(von_index1,:)', kin_plot_label,'linewidth',2);
			else
				semilogx(timevec, mdata(von_index,:)'./mdata(von_index1,:)', kin_plot_label,'linewidth',2);
			endif;
			xlabel(time_axis);
			ylabel(intensity_axis);
		else
			if ( strcmp(substring(eingaben,4),"-"))     				% TODO: in diesem Fall ebenfalls nur in eine Grafik plotten
				subplot(1,1,1);
				von = str2num(substring(eingaben,3));
				bis = str2num(substring(eingaben,5));
				[von_index, von_wz] = ir_get_index(von, freqvec);
				[bis_index, bis_wz] = ir_get_index(bis, freqvec);		# noch vertauschen. wenn n�tig....
				oplot=mdata(von_index:bis_index,:);
				oplot=oplot';
				for i=2:(bis_index - von_index)
					oplot(:,i) = oplot(:,i) - abs(min(oplot(:,i-1))) - abs(max(oplot(:,i)));
				endfor
				if ( LOG_KINETICS==0 )
					plot(timevec,oplot(:,:));
				else
					semilogx(timevec,oplot(:,:));
				endif;
				xlabel(time_axis);
				ylabel(intensity_axis);
			elseif ( strcmp(substring(eingaben,eing_num-3),"from") || strcmp(substring(eingaben,eing_num-3),"f") )				% nur bestimmten Zeitbereich plotten
				t_start = str2num(substring(eingaben,eing_num-2));										% darf nur bei eing_num>=4 ausgeführt werden
				t_stop  = str2num(substring(eingaben,eing_num));
				data_to_plot = eing_num - 6;
				t_von = time_get_index(t_start, timevec);
				t_bis = time_get_index(t_stop, timevec);
				for i=1:data_to_plot
					plot_wz = str2num(substring(eingaben,2+i));
					[plot_idx, plot_wz] = ir_get_index(plot_wz, freqvec);
					plot_label=sprintf("-;%d cm1;%d", plot_wz, mod(i,5));
						if ( LOG_KINETICS==0 )
							plot(timevec(t_von:t_bis), mdata(plot_idx,t_von:t_bis), plot_label);
						else
							semilogx(timevec(t_von:t_bis), mdata(plot_idx,t_von:t_bis), plot_label);
						endif;
					hold on;
				endfor;
				xlabel(time_axis);
				ylabel(intensity_axis);
			else						% 		verschiedene Wellenzahlen angegeben
				% clf();
				data_to_plot = eing_num - 2;
				von = 1;
				bis = data_to_plot;
				if ( bis <= 3 )
				pspalten = bis;
				pzeilen = 1;
				else
				pspalten = 3;
				pzeilen = roundup(bis / pspalten);
				endif;

				for i=von:bis
					[von_index, von_wz] = ir_get_index(str2num(substring(eingaben,2+i)), freqvec);
					printf("  Vec %d (%f)\n", von_index, von_wz);
					if ( strcmp(DEFAULT_PLOTTER,"grace") )
						hold on;
						%plot_label=sprintf("-;%d cm-1;%d", von_wz, mod(i,5));
						subplot(1,1,1);
						plot_label=sprintf("-;%d cm1;%d", von_wz, mod(i,5));
						plot(timevec, mdata(von_index,:)', plot_label);
					else
						subplot(pzeilen, pspalten, ((i-von)+1) );
						plot_label=sprintf("%d cm^{-1}", von_wz);
						if ( LOG_KINETICS==0 )
							plot(timevec, mdata(von_index,:)', 'linewidth', 2, 'color', [0.1,0.1,0.9]);
						else
							semilogx(timevec, mdata(von_index,:)', 'linewidth', 2, 'color', [0.1,0.1,0.9]);
						end;
						legend(plot_label);
					endif;
					xlabel(time_axis);
					ylabel(intensity_axis);
				endfor;
			endif;
		endif;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       </plot k>


      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif ( strcmp(substring(eingaben,2),"s" ))				# SVD - Singulaerwerte s
    if ( eing_num==3 )
			if (strcmp(DEFAULT_PLOTTER,"grace")); toggle_grace_use; end;
			if (AUTO_FIGURE==1), fig(FIG_SINGULAR); end;
			clf();
			hold off;
			for i=1:3
				subplot (3,1,1);
				clf();
			end
			subplot (3,1,1);
			vals_to_plot = str2num(substring(eingaben,3));
			printf("vals_to_plot=%d\n", vals_to_plot);
			plotvec=zeros(1,vals_to_plot);
			for i=1:vals_to_plot
				plotvec(i) = diag(s)(i);
			endfor;
			bar (plotvec);
			xlabel(s_x_axis);
			ylabel(s_y_axis);
			title("Singular Values");

			subplot (3,1,2);
			plotvec=zeros(1,vals_to_plot);
			for i=1:autocorr_to_plot
				plotvec(i,:) = svd_autocorr(u, vals_to_plot, i);
			end
			bar (plotvec');
			title("Autocorrelation of U");
			xlabel('component number');
			ylabel('value');
			subplot (3,1,3);
			plotvec=zeros(1,vals_to_plot);
			for i=1:autocorr_to_plot
				plotvec(i,:) = svd_autocorr(v, vals_to_plot,i );
			end
			bar (plotvec');
			title("Autocorrelation of V");
			xlabel('component number');
			ylabel('value');
			if (strcmp(DEFAULT_PLOTTER,"grace")); toggle_grace_use; end;
		else
	  		printf("  Syntax: plot s <nr>\n");
		endif;

	elseif ( strcmp(substring(eingaben,2),"fit" ))				# Die gefitteten Daten
		# plot(freqvec, fit_parameters(3,:)) plottet die Kinetiken.
		printf ("   Fit Plotten\n");
	    if ( is_fit > 0 )
			if (eing_num == 2)				# Einzelfits Plotten
							# noch Pr�fen dass nicht zuviel Fits vorliegen
		  	data_to_plot = is_fit;
		  	von = 1; bis = data_to_plot;

			if ( data_to_plot < 19 )
				pspalten = 3;
				pzeilen = roundup(bis/pspalten);
				if (AUTO_FIGURE==1), figure (FIG_FIT_KINETICS); end;
				hold off;
				for i=von:bis
					subplot(pzeilen, pspalten, ((i-von)+1) );
					line(timevec, mdata(index_to_fit(i),:), "linewidth", 1,"color", [0.1,0.1,0.8]);	# Daten Blau
					hold on;
					line(timevec, fit(i).values, "linewidth", 2,"color", [0.8,0.1,0.1]);	# Fit Rot
					l{1}=sprintf("%d cm^{-1}", wz_to_fit(i));
					l{2}=sprintf("k=%f", fit(i).parameters(3));
					legend(l);
					hold off;
					printf("%s",fit(i).report);
				endfor;
			else
				printf("  Es liegen zuviele Fits vor.\n  Bitte <<plot fit values wz1 wz2 wz3 ...>> benutzen!\n");
			endif;
		elseif ( strcmp(substring(eingaben,3),"3d") )			# Die Fitergebnisse als 3D Feld
		    # mesh ( timevec, freqvec, mdata);
		    for i=1:length(wz_to_fit)
		      	plotmatrix(i,:) = fit(i).values;
		    endfor;
		    mesh ( timevec, wz_to_fit, plotmatrix);
		    #clear plotmatrix;
		elseif ( strcmp(substring(eingaben,3),"parameter") )		# k's plotten
		  	if ( eing_num == 4 )
				%
				% TODO:     RESTRICT_RSQUARE!!
				%
				parameternr = str2num(substring(eingaben,4));
				printf("  Plottet Parameter Nr. %d\n",parameternr);
				if ( RESTRICT_RSQUARE > 0 )
					printf ("  r_square > %f\n", RESTRICT_RSQUARE);
				endif;
				#restrict_min=0; restrict_max=10;				# erstmal nur in dem Bereich
				fpp=0;
				wpp=0;
				j=1;							# noch pr�fen, ob der bereich stimmt
				for i=1:length(wz_to_fit)					# RESTRICTIONS kontrollieren!!
					if ( fit(i).rsquare > RESTRICT_RSQUARE )
						fpp(j) = fit(i).parameters(parameternr);
						wpp(j) = fit(i).wavenumber;
						j=j+1;
					endif;
				endfor;
				printf("  %d von %d Werten werden angezeigt\n", j, i);
				fig(FIT_PARAMETER+parameternr);
				plot(wpp, fpp, '1+-');
				xlabel (wavenumber_axis);
				ylabel (parameter_axis);
				flipx();
				%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
		  	elseif ( eing_num > 4 )                                       # dann alle in 1
				fig(FIT_PARAMETER);
				clf();
				hold on;
				for j=1:(eing_num-3)
				parameternr = str2num(substring(eingaben,4));
				clear fpp;							# noch pr�fen, ob der bereich stimmt
				for i=1:length(wz_to_fit)					# RESTRICTIONS kontrollieren!!
						fpp(j) = fit(j).parameters(parameternr);
				endfor;
					plot(wz_to_fit, fpp, '1+-');
				endfor;
				xlabel (wavenumber_axis);
				ylabel (parameter_axis);
				flipx();
				%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
		  	else
				printf("  Sytax: plot fit parameter <<nr>>\n");
				printf("  Parameter: 1 - %d\n", length(fit(1).parameters));
		  	endif;
		elseif ( strcmp(substring(eingaben,3),"stddev") )
		    if ( eing_num==3 )
			# F�r jede WL: Betraege der STDresid aufsummieren
			for i=1:length(wz_to_fit)
			  	residual(i)= sum( abs( fit(i).stdresid ) );
			endfor;
			figure (FIT_STDDEV);
			plot (wz_to_fit, residual);
			%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
			flipx();
			clear residual;
		    else
				printf ("  Syntax: plot fit stddev\n");
		    endif;
		elseif ( strcmp(substring(eingaben,3),"values") )
		    data_to_plot = eing_num - 3;
		    if ( data_to_plot > 0 )
		        if ( data_to_plot <= 3)
		    	    pspalten = data_to_plot;
			    	pzeilen = 1;
		    	else
					pspalten = 3;
					pzeilen = roundup(data_to_plot/pspalten);
		        endif;
				von = 1; bis = data_to_plot;
				figure (FIG_FIT_KINETICS);
				hold off;
				for i=von:bis
					subplot(pzeilen, pspalten, ((i-von)+1) );
					[ index_to_plot(i), wz_to_plot(i) ] = ir_get_index( str2num(substring(eingaben,i+3)),  freqvec);
					plot_label=sprintf("-;%d;1", wz_to_plot(i));
					plot(timevec, mdata(index_to_plot(i),:),plot_label);
					hold on;
					plot_label=sprintf("-;k=%f;3", fit(index_to_plot(i)).parameters(3));
					plot(timevec, fit(index_to_plot(i)).values,plot_label);
					xlabel (time_axis);
					ylabel (intensity_axis);
					printf("%s",fit(index_to_plot(i)).report);
					hold off;
				endfor;
		    else
		      	printf("  Syntax: plot fit values wz1 wz2 wz3 ...\n");
		    endif;
		else
		    printf("  Falsche Parameter\n");
		    apropos("plot");
		endif;
	    else
		printf("  Fuehren Sie zuerst einen Fit durch!\n");
		apropos("fit");
	    endif;

      % Baustelle    TODO
      elseif ( strcmp(substring(eingaben,2),"su"))
    	    fig(FIG_SPECTRA);
    	    plot(freqvec, u(:, str2num(substring(eingaben,3) )) );
	    xlabel(wavenumber_axis);
	    ylabel(intensity_axis);
	    flipx();
	    %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;

      elseif ( strcmp(substring(eingaben,2),"ru"))
    	    fig(FIG_SPECTRA);
    	    plot(freqvec, u_rot(:, str2num(substring(eingaben,3) )) );
	    xlabel(wavenumber_axis);
	    ylabel(intensity_axis);
	    %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
	    flipx();

      elseif ( strcmp(substring(eingaben,2),"sk"))
    	    fig(FIG_KINETICS);
    	    plot(freqvec, v(:, str2num(substring(eingaben,3) )) );
	    xlabel(wavenumber_axis);
	    ylabel(intensity_axis);
	    %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
	    flipx();

      elseif ( strcmp(substring(eingaben,2),"rk"))
    	    fig(FIG_KINETICS);
    	    plot(freqvec, v_rot(:, str2num(substring(eingaben,3) )) );
	    xlabel(wavenumber_axis);
	    ylabel(intensity_axis);
	    %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
	    flipx();
      elseif ( strcmp(substring(eingaben,2),"av"))
		    printf("  No command found. \n  Please use the function av instead!\n  Syntax: var=av(starttime,endtime)\n");
      elseif ( strcmp(substring(eingaben,2),"dglfit"))
    	  % über dglfit angepasstes Modell ausgeben
        fig(FIG_LSQFIT);
        hold off;
        clear plotmatrix;
        plotmatrix = dglfit_DAT;
        plotmatrix(columns(:,(dglfit_DAT+1):2*columns(dglfit_DAT))) = fitmatrix;
        % zuerst die gefitteten Daten, dann die Originaldaten
        plot(timevec, plotmatrix);
        clear dgl_legend;
        for i=1:columns(fitmatrix)
          lsq_legend{i}=sprintf("%s (model)",basename(basespectrum(i).name{1}));
        end;
        for i=1:columns(fitmatrix)
          lsq_legend{columns(fitmatrix)+i}=sprintf("%s (data)",basename(basespectrum(i).name{1}));
        end;
        legend(dgl_legend);
        xlabel(time_axis);
        ylabel("share");
        drawnow();
        add_to_history("dglfit show");
      elseif ( strcmp(substring(eingaben,2),"lsqfit"))
        % der Fit an Basisspektren ...
        % TODO: hier noch die Basisspektren in separaten plot mit rein!
        % TODO: noch Unterscheiden: Grace mit for-schleife einzeln plotten, gnuplot: alles als 1 Matrix
        fig(FIG_LSQFIT);
        subplot(2,1,1);
        hold off;			% for grace-compatibility: Plot all Curves sequentially
        for i=1:columns(fitmatrix)
          plot(timevec, fitmatrix(:,i));
          hold on;
        end;
        clear lsq_legend;
        for i=1:columns(fitmatrix)
            lsq_legend{i}=sprintf("%s",basename(basespectrum(i).name));
        end;
    	  legend(lsq_legend);
        xlabel(time_axis);
        ylabel("share");
        printf("  fitmatrix(:,nr) dargestellt\n");
        subplot(2,1,2);
        for i=1:columns(base_matrix)
          plot(freqvec, base_matrix(:,i));
          hold on;
        end;
        legend(lsq_legend);
        xlabel(wavenumber_axis);
        ylabel(intensity_axis);
      elseif ( strcmp(substring(eingaben,2),"scale") )
        if (eing_num==2)
	        axis();
	elseif ( substring(eingaben,3) == "x" )
	  axis_scale=axis();
	  axis_scale(1) = str2num(substring(eingaben,4));
	  axis_scale(2) = str2num(substring(eingaben,5));
	  axis(axis_scale);
	elseif ( substring(eingaben,3) == "y" )
	  axis_scale=axis();
	  axis_scale(3) = str2num(substring(eingaben,4));
	  axis_scale(4) = str2num(substring(eingaben,5));
	  axis(axis_scale);
	endif;

      elseif ( strcmp(substring(eingaben,2),"avg") )		% plot_avg
    	if (eing_num==2)
    		printf("  Syntax: plot avg starttime stoptime\n");
    	else
		if (AUTO_FIGURE==1), fig(FIG_SPECTRA); end;
		% hold off;
		% num_to_plot = eing_num - 2;
		% offset=0.0;
		first_index = time_get_index(str2num(substring(eingaben,3)), timevec);
		last_index = time_get_index(str2num(substring(eingaben,4)), timevec);
		% printf("  Plotte Mittelwert Index %d - %d\n", first_index, last_index);
		plot_label = sprintf("-;ave time %f-%f;%s",timevec(first_index),timevec(last_index),DEFAULT_COLOR);
		plot(freqvec, (sum(mdata(:,first_index:last_index),2)./(last_index-first_index+1)), plot_label);
		xlabel(wavenumber_axis);
		ylabel(intensity_axis);
		%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
		flipx();
    	endif;
      elseif ( strcmp(substring(eingaben,2),"diff") )		% plot_diff
    	if (eing_num==2)
    		printf("  Syntax: plot diff #t1 #t2\n");
    	else
		if (AUTO_FIGURE==1), fig(FIG_SPECTRA); end;
		first_index = time_get_index(str2num(substring(eingaben,3)), timevec);
		last_index = time_get_index(str2num(substring(eingaben,4)), timevec);
		printf("  Plotte Differenz Index %d - %d\n", first_index, last_index);
		plot(freqvec, mdata(:, first_index)-mdata(:,last_index));
		xlabel(wavenumber_axis);
		ylabel(intensity_axis);
		%if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
		flipx();
    	end;
      elseif ( strcmp(substring(eingaben,2),"exp") || strcmp(substring(eingaben,2),"x") )		% einen Ausdruck plotten, entweder plot exp x y, oder plot exp y,
		if (eing_num>2)
			if (eing_num>4)
				x_temp_vector = eval(substring(eingaben,3));
				y_temp_vector = eval(substring(eingaben,4));
				ldummy = substring(eingaben,5);
			elseif (eing_num>3)
				x_temp_vector = eval(substring(eingaben,3));
				y_temp_vector = eval(substring(eingaben,4));
				ldummy = substring(eingaben,4);
			else
				x_temp_vector = freqvec;										% Dann wird automatisch x als freqvec angenommen.
				y_temp_vector = eval(substring(eingaben,3));
				ldummy = substring(eingaben,3);
			end;
			[x_temp_notion, x_temp_order] = get_axis_notion(x_temp_vector);
			if (strcmp(x_temp_notion, "time (s)"))
					x_temp_FIG = FIG_KINETICS;
			else
					x_temp_FIG = FIG_SPECTRA;
			end;
			if (AUTO_FIGURE==1), fig(x_temp_FIG); end;
			plot_label = sprintf("-;%s;%s",ldummy,DEFAULT_COLOR);
			plot(x_temp_vector, y_temp_vector, plot_label);
			xlabel(x_temp_notion);
			ylabel("absorbance change");
			if (x_temp_order == 1)
					set(gca(),"XDir","reverse");
			end;
		else
			printf("  Syntax: plot exp [x] y [label]\n");
			printf("	[x] has to be specified if [label] is used\n");
		endif;
      elseif (strcmp(substring(eingaben,2),"c"))
          contour(timevec, freqvec, mdata);
          ylabel(wavenumber_axis);
          xlabel(time_axis);
      elseif (strcmp(substring(eingaben,2),"cc"))
          try
            p_dt = infofield.datatype;
          catch
            p_dt = "unknown";
          end_try_catch
          corplot(timevec, freqvec, mdata);
          ylabel(wavenumber_axis);
          xlabel(time_axis);
          if (inverse_wavenumber_axis==1)
            set(gca(),"XDir","reverse");
            set(gca(),"YDir","reverse");
          end;
          if (strcmp(p_dt,"2D Spectrum sync"))
            title("Synchronous");
          elseif (strcmp(p_dt,"2D Spectrum async"))
            title("Asynchronous");
          elseif (strcmp(p_dt,"2D Spectrum SIGN"))
            title("2DCos Sign");
          end;
          set(gca(),'XMinorTick','on');
          set(gca(),'YMinorTick','on');
      elseif (strcmp(substring(eingaben,2),"2dcos"))
          % Special Mode for 2D Correlation plots
          if (AUTO_FIGURE), fig(FIG_CORRELATION); end;
          if ((eing_num) == 3)
              PLOT_TARGET=str2num(substring(eingaben,3));
          else
              PLOT_TARGET=number_a+1;
          end;
          subplot(1,2,1);                 % For Synchronous
          if (CORR_MODE==1)
            corplot(timevec_a{PLOT_TARGET},freqvec_a{PLOT_TARGET},mdata_a{PLOT_TARGET});
          else
            surfplot(timevec_a{PLOT_TARGET},freqvec_a{PLOT_TARGET},mdata_a{PLOT_TARGET},0,90,"flat","","","",0,0,150,150);
            xscale(min(freqvec_a{PLOT_TARGET}),max(freqvec_a{PLOT_TARGET}));
            yscale(min(timevec_a{PLOT_TARGET}),max(timevec_a{PLOT_TARGET}));
          end;
            ylabel(wavenumber_axis_a{PLOT_TARGET});
            xlabel(time_axis_a{PLOT_TARGET});
            title("synchronous");
            set(gca(),'XMinorTick','on');
            set(gca(),'YMinorTick','on');
            if (inverse_wavenumber_axis==1)
              set(gca(),"XDir","reverse");
              set(gca(),"YDir","reverse");
            end;
            subplot(1,2,2);                 % For Synchronous
          if (CORR_MODE==1)
            corplot(timevec_a{PLOT_TARGET+1},freqvec_a{PLOT_TARGET+1},mdata_a{PLOT_TARGET+1});
          else
            surfplot(timevec_a{PLOT_TARGET+1},freqvec_a{PLOT_TARGET+1},mdata_a{PLOT_TARGET+1},0,90,"flat","","","",0,0,150,150);
            xscale(min(freqvec_a{PLOT_TARGET+1}),max(freqvec_a{PLOT_TARGET+1}));
            yscale(min(timevec_a{PLOT_TARGET+1}),max(timevec_a{PLOT_TARGET+1}));
          end;
            ylabel(wavenumber_axis_a{PLOT_TARGET+1});
            xlabel(time_axis_a{PLOT_TARGET+1});
            title("asyncronous");
            set(gca(),'XMinorTick','on');
            set(gca(),'YMinorTick','on');
            if (inverse_wavenumber_axis==1)
              set(gca(),"XDir","reverse");
              set(gca(),"YDir","reverse");
            end;
          printf("  set PRINTOUT_SIZE=\"-S1120,420\" for optimal printout (EMF)\n");
          printf("  set PRINTOUT_SIZE=\"-S1120,420\" for optimal printout (JPG/PNG)\n");
          printf("  set PRINTOUT_FONT=\"-F:12\" for optimal printout (JPG/PNG)\n");
          printf("  Plot-Styles: CORR_MODE=1 | 2 | 3\n");
      else
		printf("  Falsches Argument. Syntax: plot v [Anzahl Spektren]\n");
      endif;
    	else printf("  Argument fehlt. ? plot fuer Hilfe\n");
		plot_active=0;
    endif;

	%%%%% This holds the pipe to the plot window open so it can be manipulated. Close window to resume code execution from here
	%if (plot_active)
	%	printf("	close current plot window before proceeding...\n");
	%	pause(1)
	%	while (waitforbuttonpress()==0) pause(0.5) endwhile;
	%endif;




#
#	Ende Plot
#
#####################################################################################
#
#       Speicherfunktionen
  case {"save" }
    if (eing_num>1)
      # set save path
      if (number_a)
        [folder,name,extension]=fileparts(infofield_a{number_a}.info);
      else
        folder = "none";
      endif

      if (exist(folder)==7) # check if variable folder is a real folder
        cd(folder);
        printf("  File will be saved in folder: %s\n", folder);
      else
        printf("  File will be saved in folder: %s\n", pwd);
      endif
	    if ( strcmp(substring(eingaben,2),"data" ) || strcmp(substring(eingaben,2),"3ddata") )
	      if ( eing_num > 2 )
		      if ( strcmp(substring(eingaben,3),"auto") )
			      filename=basename(listenname);
		      else
			      filename = substring(eingaben,3);
		      end;
		      save_csv_matrix(filename, freqvec, timevec, mdata);
		      printf("  %s saved.\n", filename);
	      else										% Dateiname aus den File extrahieren
		      printf("  Syntax: save data <<filename>>\n");
	      	printf("               sava data auto    (Speichert unter aktuellem Namen)\n");
	      end;
	    elseif ( strcmp(substring(eingaben,2),"igor") )
	      if ( eing_num > 2 )
		      filename = substring(eingaben,3);
		      filename_time = sprintf("%s_time.dat",filename);
		      filename_freq = sprintf("%s_freq.dat",filename);
		      filename_data = sprintf("%s_data.dat",filename);
		      [aaa,bbb,ccc] = make_triple(freqvec,timevec,mdata);
		      save_vector(filename_time,timevec);
		      save_vector(filename_freq,freqvec);
		      save_vector(filename_data,ccc);
		      clear ccc;
		      clear aaa;
		      clear bbb;
	      else										% Dateiname aus den File extrahieren
		      printf("  Syntax: save igor <<base_filename>>\n");
	      end;
	    elseif ( strcmp(substring(eingaben,2),"state") )
	      new_filename = sprintf("%s.spoc-state", substring(eingaben,3));
	      save("-binary", new_filename, "*");
	      printf("  System state saved as %s.\n", new_filename);
	      printf("  Use octave prompt to load back.\n");
	    elseif ( strcmp(substring(eingaben,2),"ml") )
	      new_filename = sprintf("%s.spoc-data", substring(eingaben,3));
	      save("-binary", new_filename, "timevec", "freqvec", "mdata", "infofield", "listenname", "REACTION_START_INDEX", "wavenumber_axis", "time_axis", "DATA_TYPE");
	      printf("  Current dataset saved: %s.\n", new_filename);
      elseif ( strcmp(substring(eingaben,2),"ds") )
	      new_filename = sprintf("%s.spoc-dataset", substring(eingaben,3));
	      save("-binary", new_filename, "timevec", "freqvec", "mdata", "infofield", "listenname", "freqvec_a", "timevec_a", "mdata_a", "infofield_a", "listenname_a", "startindex_a", "REACTION_START_INDEX", "wavenumber_axis", "time_axis", "wavenumber_axis_a", "time_axis_a", "DATA_TYPE", "loaded_files","number_o","number_a");
	      printf("  All datasets saved under %s.\n", new_filename);
	    elseif ( strcmp(substring(eingaben,2),"config") )
	      if (eing_num>2)
		        f_filename = substring(eingaben, 3);
		        save f_filename BL_SPLINE
	      else
		        printf("  Benutzung: save config <name>\n");
	      end;
	    elseif ( strcmp(substring(eingaben,2),"fileset") )
	      if (eing_num > 2)
		      f_filename = substring(eingaben, 3);
		      printf("  %d Dateien werden gespeichert.\n"); fflush(stdout);
		      for i=1:length(timevec)
		        if ( i<10 )
			        f_position="0000";
		        elseif (i<100)
			        f_position="000";
		        elseif (i<1000)
			        f_position="00";
		        elseif (i<10000)
			        f_position="0";
		        end;
		        f_savename = sprintf("%s_%s%d_%f.dat", f_filename, f_position, i, timevec(i));
		        save_ir_file(f_savename, freqvec, mdata(:,i));
		      end;
		      printf("  %d Dateien gespeichert\n", i);
	      else
		      printf("  Benutzung: save fileset name\n");
	      end;
	    elseif ( strcmp(substring(eingaben,2),"mat7") )
	      if (eing_num > 2)
		      save("-mat7-binary",substring(eingaben,3),"timevec","freqvec","mdata");
	      else
		      printf("Dateiname fehlt!\n");
	      end;
	    elseif ( strcmp(substring(eingaben,2),"movie") )
	      if ( eing_num > 2 )
		      if ( strcmp(substring(eingaben,3),"kin") )
		        frames = str2num(substring(eingaben,4));
		        if ( frames > length(timevec) ), frames=length(timevec); end;
		          filename = substring(eingaben,5);
		          dirname = strcat(filename,"_movietmp");
		          mkdir(dirname);
		          tmpfilename = strcat(dirname,"/",filename);
              %%%%%%%%%%%%%%%
		          %print_options1 = "-deps";				% Calculate VIA eps
		          print_options1 = "-dpng";
              %%%%%%%%%%%%%%%
		          print_options2 = "-landscape";
		          print_options3 = "-S640,480";
		          print_options4 = "-color";
		          frame_delay = 20;
		          movie_cmd = sprintf("gifsicle --delay=%d --colors 256 --loop %s/*.gif > %s.gif", frame_delay, dirname, filename);

      		    step = length(timevec) / frames;
	  	        position = 1;
		          fig(FIG_SPECTRA);
		          zmax = max(max(mdata));
		          zmin = min(min(mdata));
		          plot(freqvec, mdata(:,1));
		          as=axis();
		          as(3)=zmin;
		          as(4)=zmax;
		          for i=1:(frames-1)
			          filenumber = num2str(i);
			          if ( i<10 ), filenumber = sprintf("0%s", filenumber); end;
			          if ( i<100 ), filenumber = sprintf("0%s", filenumber); end;
			          if ( i<1000 ), filenumber = sprintf("0%s", filenumber); end;
			          if ( i<10000 ), filenumber = sprintf("0%s", filenumber); end;
                %%%%%%%%%%%%%%%%
			          %savename = strcat(tmpfilename,filenumber,".eps");	%Calculate VIA eps
			          savename = strcat(tmpfilename,filenumber,".png");
                %%%%%%%%%%%%%%%%
			          finalname= strcat(tmpfilename,filenumber,".gif");
			          % intensities = mean( mdata(:, i:i+step) );
			          clf();
			          plot_label = sprintf("-;%f;", timevec(round(i*step)));
			          trace_to_plot=mean( mdata(:,round(i*step):round((i+1)*step)),2 );
			          plot(freqvec, trace_to_plot, plot_label);
			          xlabel(wavenumber_axis);
			          ylabel(intensity_axis);
			          %if (strcmp(DEFAULT_PLOTTER,"gnuplot")); set(gca,"XDir","reverse"); end;
			          flipx();
			          axis(as);
			          print(savename,print_options1, print_options2, print_options4);
			          gifcmd = sprintf("/usr/bin/convert %s -resize 640x480 %s", savename, finalname);
			          system(gifcmd);
			          printf("  %s gespeichert (%d von %d Frames)\n", savename, i, frames); fflush(stdout);
		          end;
		          printf("Startet: %s\n", movie_cmd);
		          system(movie_cmd);
		          rmdir(dirname,"s");
		      else							% 3D-Surface drehen
		          frames = str2num(substring(eingaben,3));
		          filename = substring(eingaben,4);
		          dirname = strcat(filename,"_movietmp");
		          mkdir(dirname);
		          tmpfilename = strcat(dirname,"/",filename);
              %%%%%%%%%%%%%%%%
		          %print_options1 = "-deps";				% Calculate VIA eps
		          print_options1 = "-dpng";
              %%%%%%%%%%%%%%%%
	  	        print_options2 = "-landscape";
		          print_options3 = "-S640,480";
		          print_options4 = "-color";
		          frame_delay = 20;
		          movie_cmd = sprintf("gifsicle --delay=%d --colors 256 --loop %s/*.gif > %s.gif", frame_delay, dirname, filename);
		          step = 360 / frames;
		          az=315; el=30;
		          for i=0:frames
			          filenumber = num2str(i);
			          if ( i<10 ), filenumber = sprintf("0%s", filenumber); end;
			          if ( i<100 ), filenumber = sprintf("0%s", filenumber); end;
			          if ( i<1000 ), filenumber = sprintf("0%s", filenumber); end;
			          if ( i<10000 ), filenumber = sprintf("0%s", filenumber); end;
                %%%%%%%%%%%%%%%%%
			          %savename = strcat(tmpfilename,filenumber,".eps");	%Calculate VIA eps
			          savename = strcat(tmpfilename,filenumber,".png");
                %%%%%%%%%%%%%%%%%
			          finalname= strcat(tmpfilename,filenumber,".gif");
			          view(az,el);
			          print(savename,print_options1, print_options2, print_options4);
			          gifcmd = sprintf("/usr/bin/convert %s -resize 640x480 %s", savename, finalname);
			          system(gifcmd);
			          printf("  %s gespeichert (%d von %d Frames)\n", savename, i, frames); fflush(stdout);
			          az = az + step;
			          if (az>360), az=0; end
		          end
		          printf("Startet: %s\n", movie_cmd);
		          system(movie_cmd);
		          rmdir(dirname,"s");
		      end;
	    else
		    printf("  Syntax: save movie <nr of frames> <filename> [<delay>]         ... Die aktuelle 3D-Surface Darstellung als gif animieren\n");
		    printf("          save movie kin <nr of frames> <filename> [<delay>]     ... Die Spektren zeitabhängig animieren\n");
		    printf("	  save mat7 <filename>					 ... Die Daten im Mathematica-Format\n");
		    printf("		Standartwert <delay>: 10 ms \n");
	    end;
	    elseif ( strcmp(substring(eingaben,2),"lsq") )
	    if ( eing_num == 3 )
		for i=1:is_basis
		    filename = sprintf("%s.base-%d.dat", substring(eingaben,3), i);
		    filedesc = fopen(filename,"w");
		    for j=1:rows(timevec)
			fprintf(filedesc,"%f %f\n", timevec(j), fitmatrix(j,i));
		    endfor;
		    fclose(filedesc);
		endfor;
	    else
	      printf("  Noch nicht implementiert\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"u") )
	    if ( eing_num == 4 )
		save_ir_file( substring(eingaben,4), freqvec, u(:, str2num( substring(eingaben,3)  )) );
	    else
	        printf("  Syntax: save u <nr> <name>\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"o") )          % save_o
	    if ( eing_num == 4 )
		[ to_plot, real_to_plot ] = time_get_index(str2num(substring(eingaben,3)), timevec);
		save_ir_file(substring(eingaben,4),freqvec,mdata(:, to_plot));
		printf("Index %d (WZ: %f cm-1) gepeichert.\n", to_plot, real_to_plot)
	    elseif ( strcmp(substring(eingaben,3),"mesh") )
		% TODO: Save as Mesh
	    elseif ( eing_num == 3)
		save_ir_matrix(substring(eingaben,3), freqvec, timevec, mdata);
	    else
		printf("  Syntax: save o <nr> <name>\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"avg") )		% save_avg
		if ( eing_num < 4 )
			printf("  Syntax: save avg starttime endtime [name]\n");
		else
			if (eing_num < 5)
				first_index = time_get_index(str2num(substring(eingaben,3)), timevec);
				last_index = time_get_index(str2num(substring(eingaben,4)), timevec);
				fname_dummy = sprintf("%s_AVG_%d-%d.dat", basename(listenname), first_index, last_index);
			else
				first_index = time_get_index(str2num(substring(eingaben,3)), timevec);
				last_index = time_get_index(str2num(substring(eingaben,4)), timevec);
				fname_dummy = substring(eingaben,5);
			end;
			printf("  Speichere gemittelt Index %d - %d\n", first_index, last_index);
			savevec = (sum(mdata(:,first_index:last_index),2)./(last_index-first_index+1));
			save_ir_file(fname_dummy, freqvec, savevec);
		endif;
	elseif ( strcmp(substring(eingaben,2),"kin") )
	    if (eing_num < 3)
		printf("  Syntax: save kin <nr> [<name>]\n");
	    else
	        [von_index, von_wz] = ir_get_index(str2num(substring(eingaben,3)), freqvec);
		if ( eing_num < 4)
			dummy = sprintf("%s_KIN_%f.kin", basename(listenname), von_wz);
		else
			dummy = substring(eingaben,4);
		end;
		filedesc = fopen(dummy,"w");
		for i=1:length(timevec)
		    fprintf(filedesc,"%f %f\n", timevec(i), mdata(von_index,i));
		endfor;
		fclose(filedesc);
	    endif;
	elseif ( strcmp(substring(eingaben,2),"v") )
	    if ( eing_num == 4 )
		save_ir_file( substring(eingaben,4), timevec, v(:, str2num( substring(eingaben,3)  )) );
	    else
	        printf("  Syntax: save v <nr> <name>\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"rotkin"))
		if (eing_num == 4 )
			save_ir_file(substring(eingaben,4), timevec, v_rot(:, str2num(substring(eingaben,3))));
		else
			printf("  Syntax: save rotspec <nr> <name>\n");
		endif;
	elseif ( strcmp(substring(eingaben,2),"rotspec"))
		if (eing_num == 4 )
			save_ir_file(substring(eingaben,4), freqvec, u_rot(:, str2num(substring(eingaben,3))));
		else
			printf("  Syntax: save rotspec <nr> <name>\n");
		endif;
	elseif ( strcmp(substring(eingaben,2),"fitmatrix") )
	    if ( eing_num == 3 )
	    else
		printf("  Syntax: save fitmatrix <dateiname>\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"fitparameter") )
	    if ( strcmp(substring(eingaben,3),"svd") )
		fit_file = fopen(substring(eingaben,4));
		for i=1:SVD_FIT
		    fprintf(fit_file,"%s\n",svdfit(i).report);
		endfor;
		fclose(fit_file);
	    else
		fit_file = fopen(substring(eingaben,3));
		for i=1:is_fit
		    fprintf(fit_file,"%s\n",fit(i).report);
		endfor;
		fclose(fit_file);
	    endif;
	elseif ( strcmp(substring(eingaben,2),"history") )
	    if ( eing_num == 3 )
		histfile = fopen(substring(eingaben,3), "w");
		% TODO
		fprintf(histfile,"%% Spoc History File created on %s\n", date());
		fprintf(histfile,"%%\n");
		fprintf(histfile,"%% Datafile: %s\n%%\n", basename(listenname));
		fprintf(histfile,"%% The next line indicates the data file\n");
		fprintf(histfile,"%%#! %s\n", listenname);
		for i=1:(command_ctr-2)
		    fprintf(histfile,"%s\n", dhistory(i).name);
		endfor;
		fclose(histfile);
	    else
		printf("  Syntax: save history <dateiname>\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"globalfit") )
	    if ( eing_num == 3 )
		save("-binary", substring(eingaben,3), "uu", "vv", "laststep", "AMatrix", "KMatrix","OMatrix", "components", "u", "v", "s", "u_r", "v_r", "s_r");
		printf("  Ergebnisse des GlobalFit gesichert.\n  load %s zum laden verwenden!\n", substring(eingaben,3));
	    else
		printf("  Syntax: save globalfit <dateiname>\n");
	    endif;
	elseif ( strcmp(substring(eingaben,2),"exp") || strcmp(substring(eingaben,2),"x") )		% einen Ausdruck speichern, entweder save exp x y, oder save exp y,
		if (eing_num>3)
			x_temp_filename = substring(eingaben,3);
			if (eing_num>4)						% Dann wird automatisch x als freqvec angenommen.
				x_temp_vector = eval(substring(eingaben,4));
				y_temp_vector = eval(substring(eingaben,5));
			else
				x_temp_vector = freqvec;
				y_temp_vector = eval(substring(eingaben,4));
			end;
			[x_temp_notion, x_temp_order] = get_axis_notion(x_temp_vector);

			x_temp_fd = fopen(x_temp_filename,"w");
			for i=1:length(x_temp_vector)
				fprintf(x_temp_fd,"%f	%f\n", x_temp_vector(i), y_temp_vector(i));
			end;
			fclose(x_temp_filename);
		else
			printf("  Syntax: save exp name [x] y\n");
		end;
	elseif ( strcmp(substring(eingaben,2),"gffiles") )
		if ( eing_num < 3 )
			fname_dummy = basename(listenname);
			printf("  Syntax: save gffiles <dateiname>\n");
			printf("  Kein Dateiname angegeben. Setze: %s\n",fname_dummy);
		else
			fname_dummy = substring(eingaben,3);
		end
		% components sollte die Anzahl der benutzten Komponenten enthalten
		dummy = sprintf("%s-GLOBALFIT-info.txt",fname_dummy);
		fnamed = fopen(dummy,"a");
		fprintf(fnamed, "Globalfit Parameter:\n\n");
		fprintf(fnamed,"RAW data:\n");
		fprintf(fnamed,"AMatrix:\n");
		for j=1:rows(AMatrix)
			for i=1:columns(AMatrix)
				fprintf(fnamed," %f",AMatrix(j,i));
			end;
			fprintf(fnamed,"\n");
		end;
		fprintf(fnamed,"KMatrix:\n");
		for j=1:rows(KMatrix)
			for i=1:columns(KMatrix)
				fprintf(fnamed," %f",KMatrix(j,i));
			end;
			fprintf(fnamed,"\n");
		end;
		fprintf(fnamed,"OMatrix:\n");
		for j=1:rows(OMatrix)
			for i=1:columns(OMatrix)
				fprintf(fnamed," %f",OMatrix(j,i));
			end;
			fprintf(fnamed,"\n");
		end;

		fprintf(fnamed,"\n");

		% Vorsortieren in Bezug auf KMatrix:   (siehe plot gf)
		[kn, k_order] = sort(KMatrix,"descend");
		for i=1:components
			dummy = sprintf("%s-GLOBALFIT-BSPEC-%d.dat", fname_dummy,i);
      dukin = sprintf("%s-GLOBALFIT-KIN-%d.dat"  , fname_dummy,i);       %Kinetiken werden mitgespeichert; Paul Fischer
      dumod = sprintf("%s-GLOBALFIT-MOD-%d.dat", fname_dummy,i);          % Modellkinetiken speichern...
			save_ir_file(dummy, freqvec, uu(:,k_order(i)));
      save_ir_file(dukin, timevec, v_r(:,k_order(i)));                   %Kinetiken werden mitgespeichert; Paul Fischer
      save_ir_file(dumod, timevec_to_fit, fv(:,k_order(i)));
			% TODO: Save also kinetics
			fprintf(fnamed, "k_%d = %f\n", i, KMatrix(k_order(i)));
		end;
		fprintf(fnamed,"Method: %s\n", gf_METHOD);
		fprintf(fnamed,"Konvergence: %s\n", gf_KONVERGENCE);
		fprintf(fnamed,"Initial parameters: %s\n", gf_INITIAL_PARAMETERS);
		fprintf(fnamed,"Stdresid: %s\n", gf_STDRESID);
		fprintf(fnamed,"Rsquare: %s\n", gf_R2);
		fclose(fnamed);
      elseif ( strcmp(substring(eingaben,2),"svd") )
        if (eing_num<3)
            printf("  Syntax: save svd <#components> <fname>\n");
        else
            to_do = str2num(substring(eingaben,3));
            if (eing_num==4)
              svd_filename=substring(eingaben,4);
            else
              svd_filename=listenname;
            end;
            for i=1:to_do
              fnameu=sprintf("%s-%04d.U", svd_filename, i);
              fnamev=sprintf("%s-%04d.V", svd_filename, i);
              save_ir_file(fnameu, freqvec, u(:,i));
              save_ir_file(fnamev, timevec, v(:,i));
            endfor;
            fnames=sprintf("%s.S", svd_filename);
            dummy=1:length(diag(s));
            save_ir_file(fnames,dummy,diag(s));
            printf("  Files saved (%s, %s)\n", fnameu, fnamev);
        endif;
	    else
	      printf("  No further arguments given. Will save the active dataset as binary.\n");
	      % Datensatz kompatibel mit neuer Funktion generieren
        clear dataset;
        dataset.freqvec=freqvec;
        dataset.timevec=timevec;
        dataset.mdata=mdata;
        dataset.time_axis=time_axis;
        dataset.wavenumber_axis=wavenumber_axis;
        dataset.infofield=infofield;
        dataset.listenname=listenname;
        dataset.reaction_start_index=REACTION_START_INDEX;
        dataset.pre_time=PRE_TIME;
        % *.spd is the new format; struct containing all necessary information to work with the file
        fnames=sprintf("%s.spd",substring(eingaben,2));
        save("-binary",fnames,"dataset");
	    endif;
    else
	      printf("save - Speicherfunktion\n  ? save fuer weitere Informationen\n");
    end;
#
#	Ende Speichern
#####################################################################################
  case{"run"}				% equivalent load history
		if (eing_num > 1)
			if ( (histfile = fopen(substring(eingaben,2), "r")) == -1 )
				printf("  Die angegebene Datei wurde nicht gefunden!\n");
			else
				j=1;
				do
					todo(j++).command = fgetl(histfile);
					printf("  [%s]\n", todo(j-1).command);
					add_to_history(todo(j-1).command);
				until feof(histfile);						    # history einlesen und in ein Array to_do speichern
				to_do = j-1;
				fclose(histfile);
				printf("  %d Kommandos gelesen, Starte...\n");
			end;
		else
			printf("  Syntax: run <Dateiname>\n");
		end;
#####################################################################################
#
#       Ladefunktionen
  case {"load" }	% TODO: Bei unbekannter Unterfunktion direkt über Octave gehen
    if ( eing_num > 1 )
      if ( strcmp(substring(eingaben,2),"history") )
	      if ( eing_num == 3 )
		      histfile = fopen(substring(eingaben,3), "r");
		      j=1;
		      do
		        todo(j++).command = fgetl(histfile);
		        printf("  [%s]\n", todo(j-1).command);
		        add_to_history(todo(j-1).command);
		      until feof(histfile);						    # history einlesen und in ein Array to_do speichern
		      to_do = j-1;
		      fclose(histfile);
		      printf("  %d Kommandos gelesen, Starte...\n");
	      else
		        printf("  Syntax: load history <dateiname>\n");
	      endif;
      elseif ( strcmp(substring(eingaben,2),"ml") )
        if ( eing_num==3 )
          dummyf=substring(eingaben,3);
        else
          [fn, fp] = uigetfile("*","Select Files",".","MultiSelect","On");
          dummyf=sprintf("%s%s", fp, fn);
	        load dummyf;
          try
            s=infofield.info;
          catch
            clear infofield;
            infofield.info=s;
            printf("  Converting old-style data\n");
          end_try_catch;
          printf("  Dataset loaded to curent position\n");
        endif;

      elseif ( strcmp(substring(eingaben,2),"csv") )   # Paul Fischer: load uvvis data in *.csv-format
          loaded_files++;
		      if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
		        listenname_a{1} = listenname;
		        timevec_a{1} = timevec;
		        freqvec_a{1} = freqvec;
		        mdata_a{1} = mdata;
            wavenumber_axis_a{1}=wavenumber_axis;
            time_axis_a{1}=time_axis;
		        infofield_a{1} = infofield;
		        startindex_a{1} = 0;								% geht nur, wenn der schon ex.   TODO
		        printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
		        number_a = 1;
		        loaded_files++;
		      end;

          [fn, fp] = uigetfile("*","Select data file",".","MultiSelect","Off");
          dummyf=sprintf("%s%s", fp, fn); %construct path string
          datamatrix=dlmread(dummyf,",");

          freqvec = datamatrix(2:end,1);
          timevec = datamatrix(1,2:end);
          mdata = datamatrix(2:end, 2:end);

          filetype_name="#uvvisdata";

			    listenname_a{loaded_files} = dummyf;
			    infofield_a{loaded_files}.info = dummyf;

          printf("  load *.csv UVVis data.\n");
          freqvec_a{loaded_files} = freqvec;
          timevec_a{loaded_files} = timevec;
          mdata_a{loaded_files} = mdata;
			    startindex_a{loaded_files}=0;
          wavenumber_axis_a{loaded_files}="Wellenlänge [nm]";
          time_axis_a{loaded_files}="Time [min]";

			    printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);

		      number_o = number_a;
		      number_a = loaded_files;
		      freqvec_a{number_o} = freqvec;		% alte Daten sichern
		      timevec_a{number_o} = timevec;
		      mdata_a{number_o} = mdata;
          wavenumber_axis_a{number_o}=wavenumber_axis;
          time_axis_a{number_o}=time_axis;
		      listenname_a{number_o} = listenname;
		      infofield_a{number_o} = infofield;
		      startindex_a{number_o} = REACTION_START_INDEX;
		      freqvec = freqvec_a{number_a};		% Neuer Satz zur Bearbeitung
		      timevec = timevec_a{number_a};
		      mdata = mdata_a{number_a};
          wavenumber_axis=wavenumber_axis_a{number_a};     % Fehlerquelle?
          time_axis=time_axis_a{number_a};
		      infofield = infofield_a{number_a};
		      listenname = listenname_a{number_a};


          #set reaction start index
          REACTION_START_INDEX = 1;

		      is_svd = 0;
		      is_basis = 0;
		      speichermodus = 0;
		      is_fit = 0;
		      PRE_TIME = 0;
		      base_matrix = 0;


      elseif ( strcmp(substring(eingaben,2),"lab2data") )   # Paul Fischer: Funktion zum Laden der Datens�tze aus Labor  2 der Gruppe Hamm
          loaded_files++;
		      if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
		        listenname_a{1} = listenname;
		        timevec_a{1} = timevec;
		        freqvec_a{1} = freqvec;
		        mdata_a{1} = mdata;
            wavenumber_axis_a{1}=wavenumber_axis;
            time_axis_a{1}=time_axis;
		        infofield_a{1} = infofield;
		        startindex_a{1} = 0;								% geht nur, wenn der schon ex.   TODO
		        printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
		        number_a = 1;
		        loaded_files++;
		      end;

          %wavenumber vector
          [fn, fp] = uigetfile("*","Select wavenumber vector",".","MultiSelect","Off");
          dummyf=sprintf("%s%s", fp, fn); %construct path string
          wzvector = load(dummyf,'-ascii');

          %time delay vector
          [fn, fp] = uigetfile("*","Select time delay vector",".","MultiSelect","Off");
          dummyf=sprintf("%s%s", fp, fn); %construct path string
          delayvec = load(dummyf,'-ascii');

          %data matrix
          [fn, fp] = uigetfile("*","Select data file",".","MultiSelect","Off");
          dummyf=sprintf("%s%s", fp, fn); %construct path string
          datamatrix=dlmread(dummyf);

          %delete empty entries
          i = 1;
          while (delayvec(i)<=0)
            delayvec(i) = [];
            datamatrix(i,:) = [];
            i++;
          endwhile
          delayvec=delayvec';
          time_unit_factor = 10^9;
          delayvec=delayvec/time_unit_factor;
          datamatrix=datamatrix';

          filetype_name="#lab2data";

			    listenname_a{loaded_files} = dummyf;
			    infofield_a{loaded_files}.info = dummyf;

          printf("  load data lab 2.\n");
          freqvec_a{loaded_files} = wzvector;
          timevec_a{loaded_files} = delayvec;
          mdata_a{loaded_files} = datamatrix;
			    startindex_a{loaded_files}=0;
          wavenumber_axis_a{loaded_files}="Wavenumber [1/cm]";
          time_axis_a{loaded_files}="Time [s]";

			    printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);

		      number_o = number_a;
		      number_a = loaded_files;
		      freqvec_a{number_o} = freqvec;		% alte Daten sichern
		      timevec_a{number_o} = timevec;
		      mdata_a{number_o} = mdata;
          wavenumber_axis_a{number_o}=wavenumber_axis;
          time_axis_a{number_o}=time_axis;
		      listenname_a{number_o} = listenname;
		      infofield_a{number_o} = infofield;
		      startindex_a{number_o} = REACTION_START_INDEX;
		      freqvec = freqvec_a{number_a};		% Neuer Satz zur Bearbeitung
		      timevec = timevec_a{number_a};
		      mdata = mdata_a{number_a};
          wavenumber_axis=wavenumber_axis_a{number_a};     % Fehlerquelle?
          time_axis=time_axis_a{number_a};
		      infofield = infofield_a{number_a};
		      listenname = listenname_a{number_a};


          #set reaction start index
          REACTION_START_INDEX = 1;

		      is_svd = 0;
		      is_basis = 0;
		      speichermodus = 0;
		      is_fit = 0;
		      PRE_TIME = 0;
		      base_matrix = 0;



      elseif ( strcmp(substring(eingaben,2),"lab3data") )   # Paul Fischer: Funktion zum Laden der Datensätze aus Labor 3 in der Gruppe Peter Hamm
        loaded_files++;
          if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
            listenname_a{1} = listenname;
            timevec_a{1} = timevec;
            freqvec_a{1} = freqvec;
            mdata_a{1} = mdata;
            wavenumber_axis_a{1}=wavenumber_axis;
            time_axis_a{1}=time_axis;
            infofield_a{1} = infofield;
            startindex_a{1} = 0;								% geht nur, wenn der schon ex.   TODO
            printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
            number_a = 1;
            loaded_files++;
          end;

          [fn, fp] = uigetfile("*","Select 3d dataset",".","MultiSelect","Off");


          dummyf=sprintf("%s%s", fp, fn);
          listenname_a{loaded_files} = dummyf;
          infofield_a{loaded_files}.info = dummyf;

          printf("  load data lab 3.\n");
          [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_lab3data(listenname_a{loaded_files});
          startindex_a{loaded_files}=0;
          wavenumber_axis_a{loaded_files}="Wavenumber [1/cm]";
          time_axis_a{loaded_files}="Time [s]";

			   printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);

          number_o = number_a;
          number_a = loaded_files;
          freqvec_a{number_o} = freqvec;		% alte Daten sichern
          timevec_a{number_o} = timevec;
          mdata_a{number_o} = mdata;
          wavenumber_axis_a{number_o}=wavenumber_axis;
          time_axis_a{number_o}=time_axis;
          listenname_a{number_o} = listenname;
          infofield_a{number_o} = infofield;
          startindex_a{number_o} = REACTION_START_INDEX;
          freqvec = freqvec_a{number_a};		% Neuer Satz zur Bearbeitung
          timevec = timevec_a{number_a};
          mdata = mdata_a{number_a};
          wavenumber_axis=wavenumber_axis_a{number_a};     % Fehlerquelle?
          time_axis=time_axis_a{number_a};
          infofield = infofield_a{number_a};
          listenname = listenname_a{number_a};


          #set reaction start index
          dt=timevec(2)-timevec(1);
          REACTION_START_INDEX = floor(-timevec(1)/dt)+1;

          %reduce data by apply a logarithmic binning
          #[mdata, timevec] = makeLogBinning (mdata, timevec, REACTION_START_INDEX);

		      is_svd = 0;
		      is_basis = 0;
		      speichermodus = 0;
		      is_fit = 0;
		      PRE_TIME = 0;
		      base_matrix = 0;




      elseif ( strcmp(substring(eingaben,2),"2ddata") )                                                                   % mehrere Files zu einer Matrix zusammenf�gen
		      loaded_files++;
		      if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
		        listenname_a{1} = listenname;
		        timevec_a{1} = timevec;
		        freqvec_a{1} = freqvec;
		        mdata_a{1} = mdata;
            wavenumber_axis_a{1}=wavenumber_axis;
            time_axis_a{1}=time_axis;
		        startindex_a{1} = REACTION_START_INDEX;
		        printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
		        number_a = 1;
		        loaded_files++;
		      end;
		      printf("  Lade neuen Datensatz in # %d\n", loaded_files);
		      %dummyf = file_selection("Laden","multiple",sprintf("%s/",pwd()));
    	    [fn, fp] = uigetfile("*","Select 2D dataset",".","MultiSelect","On");
		      if ( iscell(dummyf) )					% mehrere Files selektiert
    			  for k=1:length(dummyf)					% TODO: sauber programmieren!
				      %listenname_a{loaded_files} = dummyf{k};
				      %[freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_data(listenname_a{loaded_files});
				      %printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);
				      %loaded_files++;
			      end;
			      loaded_files--;						% wurde ja schon am Anfang erhöht
		      else
			      printf("  Es muessen mehrere Dateien selektiert werden!\n");
			      %listenname_a{loaded_files} = dummyf;
			      %[freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_data(listenname_a{loaded_files});
			      %printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);
		      end;
	    elseif ( strcmp(substring(eingaben,2),"3ddata") || strcmp(substring(eingaben,2),"data") )	% TODO: hier die Mehrfachverwaltung rein
		      loaded_files++;
		      if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
		        listenname_a{1} = listenname;
		        timevec_a{1} = timevec;
		        freqvec_a{1} = freqvec;
		        mdata_a{1} = mdata;
            wavenumber_axis_a{1}=wavenumber_axis;
            time_axis_a{1}=time_axis;
		        infofield_a{1} = infofield;
		        startindex_a{1} = 0;								% geht nur, wenn der schon ex.   TODO
		        printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
		        number_a = 1;
		        loaded_files++;
		      end;
		      printf("  Lade neuen Datensatz in # %d\n", loaded_files);
		      if ( eing_num == 3 )
		        listenname_a{loaded_files} = substring(eingaben,3);
		        infofield_a{loaded_files}.info = substring(eingaben,3);
		        if ( strcmp(fileextension(listenname_a{loaded_files}), "dpt") )		% Workaround fuer OPUS
				      [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_opus_ascii(listenname_a{loaded_files});
              wavenumber_axis_a{loaded_files}=wavenumber_axis;
              time_axis_a{loaded_files}=time_axis;
				      %%filetype_name="OPUS_ASCII";
            elseif (strcmp(fileextension(listenname_a{loaded_files}), "spd") )
              load(listenname_a{loaded_files},"dataset");
              mdata_a{loaded_files}=dataset.mdata;
              freqvec_a{loaded_files}=dataset.freqvec;
              timevec_a{loaded_files}=dataset.timevec;
              time_axis_a{loaded_files}=dataset.time_axis;
              wavenumber_axis_a{loaded_files}=dataset.wavenumber_axis;
              infofield_a{loaded_files}=dataset.infofield;
		        else
				      [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_data(listenname_a{loaded_files});
		        endif;
		        startindex_a{loaded_files}=0;
		        % [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files},idummy] = process_data(freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files});
		        printf("  Datensatz an Position %d geladen.\n", loaded_files);
		        idummy = get_timesteps(timevec_a{loaded_files});
		        if (length(idummy)>1)
			        printf("  Dataset is composed of subsets.\n  Use <<process>> to split\n");
		        end;
		      else
	          [fn, fp] = uigetfile("*","Select 3d dataset",".","MultiSelect","On");
		        if ( iscell(fn) )					% mehrere Files selektiert
              printf(" *** WARNING! Multiple file loading does not yet work with *.spd files! ***\n");
			        for k=1:length(fn)					% TODO: sauber programmieren!
                dummyf=sprintf("%s%s",fp, fn{k});
				        listenname_a{loaded_files} = dummyf{k};
				        infofield_a{loaded_files}.info = dummyf{k};
				        if ( strcmp(fileextension(listenname_a{loaded_files}), "dpt") )		    % Workaround fuer OPUS
					        [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_opus_ascii(listenname_a{loaded_files});
					        %%filetype_name="OPUS_ASCII";
                elseif ( strcmp(fileextension(listenname_a{loaded_files}), "spd") )   % Binaerformat
                  load(listenname_a{loaded_files},"dataset");
                  mdata_a{loaded_files}=dataset.mdata;
                  freqvec_a{loaded_files}=dataset.freqvec;
                  timevec_a{loaded_files}=dataset.timevec;
                  time_axis_a{loaded_files}=dataset.time_axis;
                  wavenumber_axis_a{loaded_files}=dataset.wavenumber_axis;
                  infofield_a{loaded_files}=dataset.infofield;
				        else                                                                  % blunt guess...
					        [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_data(listenname_a{loaded_files});
				        endif;
				        startindex_a{loaded_files}=0;
				        printf("  Datensatz %s an Position %d geladen.\n", dummyf{k}, loaded_files);
				        loaded_files++;
		  	      end;
			        loaded_files--;						% wurde ja schon am Anfang erhöht
		        else                        % hier normale Selektion (1 Feld, ...)
              dummyf=sprintf("%s%s", fp, fn);
			        listenname_a{loaded_files} = dummyf;
			        infofield_a{loaded_files}.info = dummyf;
			        if ( strcmp(fileextension(listenname_a{loaded_files}), "dpt") )		% Workaround fuer OPUS
				          [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_opus_ascii(listenname_a{loaded_files});
			            startindex_a{loaded_files}=0;
                  wavenumber_axis_a{loaded_files}="Wavenumber [1/cm]";
                  time_axis_a{loaded_files}="Time [s]";
				          %%filetype_name="OPUS_ASCII";
			        elseif ( strcmp(fileextension(listenname_a{loaded_files}), "x3d") )
				          [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_data(listenname_a{loaded_files});
			            startindex_a{loaded_files}=0;
                  wavenumber_axis_a{loaded_files}="Wavenumber [1/cm]";
                  time_axis_a{loaded_files}="Time [s]";
              elseif ( strcmp(fileextension(listenname_a{loaded_files}), "spd") )
                  load(listenname_a{loaded_files},"dataset");
                  mdata_a{loaded_files}=dataset.mdata;
                  freqvec_a{loaded_files}=dataset.freqvec;
                  timevec_a{loaded_files}=dataset.timevec;
                  time_axis_a{loaded_files}=dataset.time_axis;
                  wavenumber_axis_a{loaded_files}=dataset.wavenumber_axis;
                  infofield_a{loaded_files}=dataset.infofield;
			        elseif ( strcmp(fileextension(listenname_a{loaded_files}), "spoc-data") )
                  printf("  Cannot load binary files. Load manually!\n");
              else
                  printf("  Unknown Filetype. Assuming x3d.\n");
				          [freqvec_a{loaded_files}, timevec_a{loaded_files}, mdata_a{loaded_files}] = read_data(listenname_a{loaded_files});
			            startindex_a{loaded_files}=0;
                  wavenumber_axis_a{loaded_files}="Wavenumber [1/cm]";
                  time_axis_a{loaded_files}="Time [s]";
			        endif;
			        printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);
		        end;
		      end;
		      % dummy = sprintf("# %d",loaded_files);		% Umschalten auf den neuesten Slot - anpassen!! TODO
      		%								Umschalten auf den gerade geladenen Datensatz - direkt, damit kein Konflikt mit Macro.
		      %								Kommandofolge exakt wie in load 3ddata.
          % TODO: Manuell umsortieren, um binaerfiles laden zu koennen...
		      number_o = number_a;
		      number_a = loaded_files;
		      freqvec_a{number_o} = freqvec;		% alte Daten sichern
		      timevec_a{number_o} = timevec;
		      mdata_a{number_o} = mdata;
          wavenumber_axis_a{number_o}=wavenumber_axis;
          time_axis_a{number_o}=time_axis;
		      listenname_a{number_o} = listenname;
		      infofield_a{number_o} = infofield;
		      startindex_a{number_o} = REACTION_START_INDEX;
		      freqvec = freqvec_a{number_a};		% Neuer Satz zur Bearbeitung
		      timevec = timevec_a{number_a};
		      mdata = mdata_a{number_a};
          wavenumber_axis=wavenumber_axis_a{number_a};     % Fehlerquelle?
          time_axis=time_axis_a{number_a};
		      infofield = infofield_a{number_a};
		      listenname = listenname_a{number_a};
          try
		          REACTION_START_INDEX = startindex_a{number_a};			%% Das ist die Fehlerquelle!!
          catch
              REACTION_START_INDEX = 1;
              printf("  REACTION_START_INDEX not defined, setting to 1!\n");
          end_try_catch;
		      is_svd = 0;
		      is_basis = 0;
		      speichermodus = 0;
		      is_fit = 0;
		      PRE_TIME = 0;
		      base_matrix = 0;
      elseif (strcmp(substring(eingaben,2),"set"))
          printf("  Loading new Fileset - all data will be discarded\n");
 	        if ( eing_num == 3 )
		        dummy = substring(eingaben,3);
            load(dummy);
            printf("  New Dataset loaded.\n");
		      else
            [dummylist,dummypath] = uigetfile("*","Select Files",".","MultiSelect","Off")
		        sprintf("%s%s",dummypath,dummylist);
			      if ( strcmp(fileextension(dummyf), "spoc-dataset") )
              load(dummyf);
              printf("  New dataset loaded\n");
              printf("  Old data discarded\n");
            else
              printf("  Wrong filetype. Select a spoc-dataset\n");
            end;
          end;

      elseif (strcmp(substring(eingaben,2),"single"))
          % to load single 2D files. Since program is not suited to handle those, it will be copied 10 times and an artificial timevector will be constructed ranging from 1 to 10; PF
          loaded_files++;
		      if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
		        listenname_a{1} = listenname;
		        timevec_a{1} = timevec;
		        freqvec_a{1} = freqvec;
		        mdata_a{1} = mdata;
            wavenumber_axis_a{1}=wavenumber_axis;
            time_axis_a{1}=time_axis;
		        startindex_a{1} = REACTION_START_INDEX;
		        printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
		        number_a = 1;
		        loaded_files++;
		      end;
		      printf("  Lade neuen Datensatz in # %d\n", loaded_files);
    	    [fn, fp] = uigetfile("*","Select 2D dataset",".","MultiSelect","Off");
		      dummyf=sprintf("%s%s",fp, fn);
          listenname_a{loaded_files} = dummyf;
          infofield_a{loaded_files}.info = dummyf;

          [freqvec_a{loaded_files}, mdata] = load_ir_file(dummyf);
          mdata_a{loaded_files}=repmat(mdata,1,10);
          timevec_a{loaded_files}=[1:10];

          startindex_a{loaded_files}=0;
          wavenumber_axis_a{loaded_files}="Wavenumber [1/cm]";
          time_axis_a{loaded_files}="Time [s]";

			    printf("  Datensatz %s an Position %d geladen.\n", dummyf, loaded_files);

		      number_o = number_a;
		      number_a = loaded_files;
		      freqvec_a{number_o} = freqvec;		% alte Daten sichern
		      timevec_a{number_o} = timevec;
		      mdata_a{number_o} = mdata;
          wavenumber_axis_a{number_o}=wavenumber_axis;
          time_axis_a{number_o}=time_axis;
		      listenname_a{number_o} = listenname;
		      infofield_a{number_o} = infofield;
		      startindex_a{number_o} = REACTION_START_INDEX;
		      freqvec = freqvec_a{number_a};		% Neuer Satz zur Bearbeitung
		      timevec = timevec_a{number_a};
		      mdata = mdata_a{number_a};
          wavenumber_axis=wavenumber_axis_a{number_a};     % Fehlerquelle?
          time_axis=time_axis_a{number_a};
		      infofield = infofield_a{number_a};
		      listenname = listenname_a{number_a};

      elseif (strcmp(substring(eingaben,2),"status"))
	        listenname = substring(eingaben,3);
	        load listenname;
	        printf("  Warning: Octave binary variables loaded. System Variables might be overwritten\n");
	    else
	        printf("  Warning: Information on dataset are guessed from the file extension.\n");
          if (strcmp(substring(eingaben,2), "spd"))
              load(substring(eingaben,2),"dataset");
              mdata=dataset.mdata;
              freqvec=dataset.freqvec;
              timevec=dataset.timevec;
              time_axis=dataset.time_axis;
              wavenumber_axis=dataset.wavenumber_axis;
              infofield=dataset.infofield;            % listenname is overwritten %BUG%
				      printf("  ...done\n");
          else
              printf("  File not recognized!\n");
          endif;
	    endif;
    else
	      printf("  Some Error occurred during file loading. Use <<? load>> for more information...\n");
    end;
#
#	Ende Laden
#####################################################################################

  case {"v" }
    # V spaltenweise (auch interressant)
    do
      do
        printf("    Nummer fuer Spaltenvektor (V; 1-%d; <0> beendet): ", columns(v));
        nrs=input("","s");
        if (strcmp(nrs,"save"))
          printf("    Dateiname fuer Vektor V[%d]:>", nr);
          fname=input("","s");
          save_trace(fname,timevec,v(:,nr));
        endif;
      until (!strcmp(nrs,"save"));
      nr = str2num (nrs);
      if ( nr > 0 )
       if ( nr < columns(v)+1 )
        elements=rows(v);
        for i=1:elements
          colvec_v(i)=v(i,nr);
        endfor
        plot (timevec, colvec_v);
      if (speichermodus == 1)
        fname=input ("Speichern (Spaltenvektor V)- Dateiname:","s");
        sfile = fopen(fname,"a");
        for i=1:elements
          fprintf(sfile,"%f %f\n", timevec(i), colvec_v(i));
        endfor
        fclose(sfile);
      endif;
       elseif
        printf("Spalte ausserhalb des Bereichs (max. %d)!\n", columns(v));
       endif;
      endif
    until ( nr == 0 );

  case {"print" }			# Als PS-Datei speichern
    if (eing_num > 1)
      filename = substring(eingaben,2);
      options = sprintf("-d%s", OUTPUT_FORMAT);
      if ( gcf() == FIG_SVD )
        options = sprintf("%s -portrait", options);
      endif;
      printf("  Schreibe Datei: %s\n", filename);
      print(filename, options);

    else
      printf("  Syntax: print <<Dateiname>>\n");
    endif;

  case {"resample" }		# Kompatibel Machen
    if ( eing_num > 1 )
        if ( strcmp(substring(eingaben,2),"base") )
      for i=1:is_basis
                # Die Basisspektren in base_matrix(:,i) anpassen
                # bl_wave ist der Vektor der WZ
          work.wavenumbers=bl_wave;
          work.intensities=base_matrix(:,i);
  #		    work = spec
      endfor;
        else
      printf("  Anpassen der Matrix ist derzeit noch nicht möglich\n");
        endif;
    else
        printf ("  Welche Daten anpassen: Basisspekten (base) oder Daten (matrix)?\n");
    endif;
  case {"quit" "exit"}
    ende=1;

  case {"cls" }
    cls();

  case {"block" }
    printf("\n\n\n");

  case {"line" }
    printf("__________________________________________________________________________________\n");

  case {"_test" }
    add_to_history("block");
    add_to_history("version");
    add_to_history("block");
    add_to_history("block");
    add_to_history("block");
    add_to_history("line");
    add_to_history("version");
    add_to_history("line");

  case {"gnuplot" }
    DEFAULT_PLOTTER = "gnuplot";
    if (exist("use_grace_state","var"))
	    if (strcmp(use_grace_state,"on")) toggle_grace_use ; end;
    end;

  case {"grace" }
    if (exist("use_grace_state","var"))
      if (strcmp(use_grace_state,"off")); toggle_grace_use ; end;
      if (strcmp(use_grace_state,"on"))
          DEFAULT_PLOTTER = "grace";
      else
          DEFAULT_PLOTTER = "gnuplot";
          printf("  Fehler beim Initialisieren von Graceplot\n");
      end;
    else
      printf("  Initialisiere Grace\n");
      toggle_grace_use;
      if (strcmp(use_grace_state,"on"))
          DEFAULT_PLOTTER = "grace";
      else
          DEFAULT_PLOTTER = "gnuplot";
          printf("  Fehler beim Initialisieren von Graceplot\n");
      end;
    end;

  case {"logx" }
    user_plot=@semilogx;

  case {"normx" }
    user_plot=@plot;

  case {"version" }
    printf("%s\n",VERSION);

  case {"grid" }
    plot3d=@mesh;

  case {"surface" }
    plot3d=@surface;

  case {"show" }			% Verschiedene Einstellungen anzeigen
    if ( strcmp(substring(eingaben,2), "time") )
      printf("  Zeitachse timevec(%d): %f - %f\n", size(timevec), timevec(1), timevec(end));
      printf("  Einteilung: (DETECTION_LEVEL = %f)\n", DETECTION_LEVEL);
      steptime = timevec(2)-timevec(1);
      printf("  dt(1-2) = %f\n", steptime);
      for i=3:length(timevec);
        steptimen = timevec(i)-timevec(i-1);
        if ( ((abs(steptimen-steptime)) * 100 / abs(steptime)) > DETECTION_LEVEL  )
          printf("  dt(%d - ...) = %f\n", i-1, steptimen);
          steptime = steptimen;
        end;
      end;
    end;

  case {"history" }
     for i=1:command_ctr-1
       printf ("  [%d]->  %s\n",i, dhistory(i).name );
     end;

  case {"macro" }				% Definiert ein einfaches Makro.
    if (eing_num>=2)
      if (strcmp(substring(eingaben,2),"define") )
        if (strcmp(substring(eingaben,5),"-" ) )		% macro define name 7 -10
        %	mak_nr++;
        %	macro{mak_nr}.name = substring(eingaben,3);
          mak_start = str2num(substring(eingaben, 4));
          mak_stop = str2num(substring(eingaben, 6));
          mak_nr++;
          macro{mak_nr}.name = substring(eingaben,3);
          macro{mak_nr}.nr_commands = mak_stop - mak_start+1;
          j=1;
          for i=mak_start:mak_stop
            macro{mak_nr}.command{j++} = dhistory(i).name;
          end;
        else									% macro define name 2 3 4 8 10
          mak_nr++;
          macro{mak_nr}.name = substring(eingaben,3);
          macro{mak_nr}.nr_commands = eing_num - 3;
          for i=1:eing_num-3
            macro{mak_nr}.command{i} = dhistory(str2num(substring(eingaben,i+3))).name;
          end;
        end;
      elseif (strcmp(substring(eingaben,2),"list") )
        if (eing_num==2)
          for i=1:mak_nr
            printf("Macro Nr. %d: %s\n", i, macro{i}.name)
          end;
        elseif (eing_num==3)
          i=get_macro_name(substring(eingaben,3));
          if (i==0)
            printf("  Syntax: macro list <macro-number>\n");
            printf("  Please use <macro list> (without argument) to obtain macro-number\n");
          else
            printf("  %s:\n",macro{i}.name);
            for j=1:length(macro{i}.command)
              printf("    %d.: %s\n",j, macro{i}.command{j});
            end;
          end;
        else
          printf("  Syntax: macro list [<#nr>]\n");
        end;
      elseif (strcmp(substring(eingaben,2),"save"))
        if (eing_num==3)
          dummy=sprintf("%s.mak",substring(eingaben,3));
          save("-binary", dummy, "macro");
        else
          printf("  Syntax: macro save <name>\n");
        end;
      elseif (strcmp(substring(eingaben,2),"load"))
        if (eing_num==3)
          dummy=sprintf("%s.mak",substring(eingaben,3));
          macrotmp=load(dummy);
          for i=1:length(macrotmp.macro)
            mak_nr++;
            macro{mak_nr}=macrotmp.macro{i};
          end;
        else
          printf("  Syntax: macro load <name>\n");
        end;
      elseif (strcmp(substring(eingaben,2),"record"))
        if (macro_record_start == 0)
          macro_record_start = command_ctr;
        else
          macro_record_stop = command_ctr;
          printf("  Name des Macro: ");
          macro_record_name = input(" ","s");
          mak_nr++;
          macro{mak_nr}.name = macro_record_name;
          j=1;
          for macro_record_i=macro_record_start:macro_record_stop-2
            macro{mak_nr}.command{j++} = dhistory(macro_record_i).name;
          end;
          macro_record_start = 0;
        end;
      elseif (strcmp(substring(eingaben,2),"change"))
        if ( eing_num < 5)
          printf("  Syntax: macro change <macro_name> <command_num> <command (Text)>\n");
        else
          if (get_macro_name(substring(eingaben,3))==0)
            printf("  Macro ist nicht bekannt\n");
          else
            dummy=sprintf("%s", substring(eingaben,5));
            for (j=6:eing_num)
              dummy=sprintf("%s %s",dummy,substring(eingaben,j));
            end;
            macro{get_macro_num(substring(eingaben,3))}.command{str2num(substring(eingaben,4))}=dummy;
          end;
        end;
      elseif (strcmp(substring(eingaben,2),"delete"))
        if ( eing_num < 4)
          printf("  Syntax: macro delete <macro_num> <command_num>\n");
        else
          i=get_macro_num(substring(eingaben,4));
          if (i==0)
            printf("  Makro unbekannt\n");
          else
            if (length(macro{str2num(substring(eingaben,3))}.command)>i)
              do
                macro{str2num(substring(eingaben,3))}.command{i}=macro{str2num(substring(eingaben,3))}.command{i+1};
                i++;
              until (i>=length(macro{str2num(substring(eingaben,3))}.command));
            end;
            macro{str2num(substring(eingaben,3))}.command{i}="nop";
            end;
        end;
      elseif (strcmp(substring(eingaben,2),"insert"))
        if ( eing_num < 4)
          printf("  Syntax: macro insert <macro_num> <command_num> <command (Text)>\n");
        else
          dummy=sprintf("%s", substring(eingaben,5));
          for (j=6:eing_num)
            dummy=sprintf("%s %s",dummy,substring(eingaben,j));
          end;
          i=str2num(substring(eingaben,4));
          j=length(macro{str2num(substring(eingaben,3))}.command);
          if (j>i)
            for k=j+1:-1:i
              macro{str2num(substring(eingaben,3))}.command{k}=macro{str2num(substring(eingaben,3))}.command{k-1};
            end;
            macro{str2num(substring(eingaben,3))}.command{i}=dummy;
          else
            macro{str2num(substring(eingaben,3))}.command{j+1}=dummy;
          end;
        end;
      else
        printf(" Macro command unknown\n");
      end;
    else
      printf("  Syntax: macro command <<arguments>>\n");
      printf("  command may be one of define, list, save, load\n");
      printf("  Syntax: macro define name #command1 #command2 ...\n");
      printf("  mrun <<name>> shall be used for executing a macro\n");
      printf("  mapply uses a macro for several files\n\n");
      printf("  All macro functions are saved in macro{i}.xxx. The list is reversely executed.\n");
    end;

  case{"mrun"}					% Makro ausfuehren. (run name)
    if ( eing_num == 2 )
      mak_i = mak_nr+1;
      do
        mak_i=mak_i-1;
      until ( (mak_i==0) || strcmp(macro{mak_i}.name, substring(eingaben,2)) );
      if (mak_i==0 )
        printf("  Fehler: Das angegebene Makro ist nicht definiert\n");
      else
              add_to_history("rem START MACRO");
        for k=1:length(macro{mak_i}.command)
          add_to_history(macro{mak_i}.command{k});
          % printf("Will execute: %s\n",macro{i}.command{k});
        end;
        add_to_history("rem END MACRO");
      end;
    elseif
      printf("  Name des Makros erforderlich.\n  Syntax: run name\n");
    end;

  case {"mapply" }
    if ( eing_num==2 )
      i_mak = mak_nr+1;
      do
        i_mak=i_mak-1;
      until ( (i_mak==0) || strcmp(macro{i_mak}.name, substring(eingaben,2)) );
      if ( i_mak==0 )
        printf("  Fehler: Das angegebene Makro ist nicht definiert\n");
      else														% Makro ist da. Dateien laden und ausfuehren
        %macro_file_list = file_selection("Files to work on","multiple",sprintf("%s/",pwd()));
        [dummyname, dummypath] = uigetfile("*","Select Files to work on",".","MultiSelect","On")
        if iscell(dummyname)
          for im=1:length(dummyname)
            macro_file_list{im} = sprintf("%s%s",dummypath, dummyname{im});
          endfor
        endif

        for i_file=1:length(macro_file_list)
          dummy = sprintf("load 3ddata %s\n", macro_file_list{i_file});	% Funktioniert so nicht....
          if ( ispc()==0 ), dummy(length(dummy))=[]; end;
          add_to_history(dummy);
          for k=1:length(macro{i_mak}.command)
            add_to_history(macro{i_mak}.command{k});
            % printf("Will execute: %s\n",macro{i}.command{k});
          end;
        end;
      end;
    else
      printf("  Syntax: mapply <macroname>\n");
    end;

  case {"*" }			% Angegebenes Spektrum waehlen
    if ( eing_num == 2 )
        i = str2num(substring(eingaben,2));
        if ( (i>0) && (i <= length(timevec)) )
      select = i;
      figure (FIG);
      clf();
      plot(freqvec, mdata(:,select));
        else
      printf("  Angabe ausserhalb des gültigen Bereiches\n");
        end;
    else
        printf("  Aktuell ausgewaehlt: #%d (%f)\n", select, timevec(select));
        printf("  Bitte eine Nummer angeben\n");
    end;

  case {"*d"}
    for i=select:(length(timevec)-1)
        timevec(i)=timevec(i+1);
        mdata(:,i)=mdata(:,i+1);
    end;
    timevec = timevec(1:(length(timevec)-1));
    mdata = mdata(:,1:(length(timevec)-1));
    case {"*s" }
    if ( USE_GUI == 1 )
      s_filename = inputdlg("Dateiname"){1};
    else
      s_filename = input("  Dateiname: ");
    end
    ofile = fopen(s_filename,"a");
    for i=1:length(freqvec)
      fprintf(ofile,"%f	%f\n", freqvec(i), mdata(freqvec, select));
    end
    fclose(ofile);

%___________________________Funktionen für mehrere Datensätze

  case {"#average" "#av" "#avg" }
	if ( eing_num == 1 )
		printf("  Syntax: #av <Nr. 1> <Nr. n>         ( mittelt die Datensätze 1 - n )\n");
	else
		startwert = str2num(substring(eingaben, 2));
		stopwert = str2num(substring(eingaben, 3));
		loaded_files++;
		listenname_a{loaded_files} = sprintf("Mittelwert %d - %d", startwert, stopwert);
		freqvec_a{loaded_files} = freqvec_a{startwert};
		timevec_a{loaded_files} = timevec_a{startwert};
		mdata_a{loaded_files} = mdata_a{startwert};
    wavenumber_axis_a{loaded_files}=wavenumber_axis_a{startwert};
    time_axis_a{loaded_files}=time_axis_a{startwert};

		for i=startwert+1:stopwert
		    freqvec_a{loaded_files} = freqvec_a{loaded_files} + freqvec_a{i};
		    timevec_a{loaded_files} = timevec_a{loaded_files} + timevec_a{i};
		    mdata_a{loaded_files} = mdata_a{loaded_files} + mdata_a{i};
		end;
		freqvec_a{loaded_files} = freqvec_a{loaded_files} ./ (stopwert-startwert+1);
		timevec_a{loaded_files} = timevec_a{loaded_files} ./ (stopwert-startwert+1);
		mdata_a{loaded_files} = mdata_a{loaded_files} ./ (stopwert-startwert+1);
		printf("  Mittelwert berechnet und abgelegt in %d.\n", loaded_files);
	end;

  case {"#+" }			% den aktiven Datensatz auf seine ursprünglich Version speichern
	  if ( loaded_files == 0 )
		  printf("  Cannot perform operation in single data mode\n");
	  else
	    freqvec_a{number_a} = freqvec;		% alte Daten sichern
	    timevec_a{number_a} = timevec;
	    mdata_a{number_a} = mdata;
	    listenname_a{number_a} = listenname;
      time_axis_a{number_a}=time_axis;
      wavenumber_axis_a{number_a}=wavenumber_axis;
      infofield_a{number_a}=infofield;
      reaction_start_index_a{number_a}=REACTION_START_INDEX;
      % TODO pretime_a{number_a}=PRE_TIME;
	    printf("  Dateset stored in slot %d.\n", number_a);
	  end;
  case {"#-" }			% den aktiven Datensatz zurücksetzen
	  if ( loaded_files == 0 )
		  printf("  Cannot perform operation in single data mode\n");
	  else
      freqvec=freqvec_a{number_a};		% alte Daten sichern
	    timevec=timevec_a{number_a};
	    mdata=mdata_a{number_a};
	    listenname=listenname_a{number_a}  ;
      time_axis=time_axis_a{number_a};
      wavenumber_axis=wavenumber_axis_a{number_a};
      infofield=infofield_a{number_a};
      REACTION_START_INDEX=reaction_start_index_a{number_a};
      % TODO pretime_a{number_a}=PRE_TIME;
	    printf("  Dateset restored from slot %d.\n", number_a);
	  end;

  case {"#" }			% Speicher xxx als Datei bearbeiten
    printf("number of entries: %d\n", loaded_files);
    if ( eing_num == 1)
	    if ( loaded_files == 0 )
	        printf("  Keine weiteren Dateien geladen\n");
    	  else
	        printf("  %d Datensätze geladen:\n");
	        for i=1:loaded_files
		        if ( i==number_a )
			        printf(" *** %d	%s\n", i, infofield_a{i}.info);
		        else
			        printf("     %d	%s\n", i, infofield_a{i}.info);
		        endif;
	        endfor;
	    endif;
    else
	    number_o = number_a;				% alten Datensatz sichern
	    if ( eing_num==3 )					% Berechnen, welcher Slot geladen wird (# + xxx)
		    slot_shift = str2num(substring(eingaben,3));
		    if ( strcmp(substring(eingaben,2),"-") )
			    slot_destination = number_a - slot_shift;
		    elseif (strcmp(substring(eingaben,2),"+") )
			    slot_destination = number_a + slot_shift;
		    else
			    printf("  Unbekannte Sprungmarke\n");
			    slot_destination = number_a;
		    end;
		    number_a = slot_destination;
	    else
		    number_a = str2num(substring(eingaben,2));
	    end;
	    if ( number_a > loaded_files )
 	      printf("  Bitte Speicherplatz zwischen 1 und %d angeben!\n", loaded_files);
	      number_a = number_o;
	    elseif (number_a < 1 )
	      printf("  Bitte Speicherplatz zwischen 1 und %d angeben!\n", loaded_files);
	      number_a = number_o;
    	  else
	        %	put();					% Hier nicht sichern, da das ja sowieso passiert...
	        %                  TODO: REACTION_START_INDEX immer mitf�hren!!!
        if ( substring(eingaben,2)=="dup" )
          printf("   please use #dup !\n");
        else
	        freqvec_a{number_o} = freqvec;		% alte Daten sichern
	        timevec_a{number_o} = timevec;
	        mdata_a{number_o} = mdata;
          wavenumber_axis_a{number_o}=wavenumber_axis;
          time_axis_a{number_o}=time_axis;
	        listenname_a{number_o} = listenname;
	        infofield_a{number_o} = infofield;
	        startindex_a{number_o} = REACTION_START_INDEX;
          freqvec = freqvec_a{number_a};		% Neuer Satz zur Bearbeitung
	        timevec = timevec_a{number_a};
	        mdata = mdata_a{number_a};
          time_axis=time_axis_a{number_a};
          wavenumber_axis=wavenumber_axis_a{number_a};
	        infofield = infofield_a{number_a};
	        listenname = listenname_a{number_a};
	        REACTION_START_INDEX = startindex_a{number_a};			%% Das ist die Fehlerquelle!!
	        is_svd = 0;
	        is_basis = 0;
	        speichermodus = 0;
	        is_fit = 0;
	        PRE_TIME = 0;
	        base_matrix = 0;
        endif;
	    endif;
    endif;

 case {"##" }
							% # Zeigt belegte Plätze an
	if ( loaded_files == 0 )
	    printf("  Keine weiteren Dateien geladen\n");
	else
	    printf("  %d Datensätze geladen:\n");
	    for i=1:loaded_files
		    if ( i==number_a )
			    printf(" *** %d	%s\n", i, basename(listenname_a{i}));
		    else
			    printf("     %d	%s\n", i, basename(listenname_a{i}));
		    endif;
	    end;
	endif

 case {"###" }
							% Ausfuehrliche Anzeige
	if ( loaded_files == 0 )
	    printf("  Keine weiteren Dateien geladen\n");
	else
	    printf("  %d Datensätze geladen:\n");
	    for i=1:loaded_files
        if ( i==number_a )
          printf(" *** %d	%s\n", i, basename(listenname_a{i}));
        else
          printf("     %d	%s\n", i, basename(listenname_a{i}));
        end;
        printf("     %s\n",infofield_a{i}.info);
	    end;
	end

  case {"#label" }
	  infofield.info=sprintf("%s",substring(eingaben,2));
  case {"#dup" } 			% den aktuellen Datensatzes duplizieren   Baustelle
    if ( loaded_files == 0 )			% In Mehrfachmodus umschalten, und den Datensatz sichern
      printf("  Umschalten in den Mehrfachmodus und Sichern der Daten auf Platz # 1\n");
    end;
    loaded_files++;
    listenname_a{loaded_files} = listenname;
    timevec_a{loaded_files} = timevec;
    freqvec_a{loaded_files} = freqvec;
    time_axis_a{loaded_files}=time_axis;
    wavenumber_axis_a{loaded_files}=wavenumber_axis;
    mdata_a{loaded_files} = mdata;
    startindex_a{loaded_files} = REACTION_START_INDEX;
    infofield_a{loaded_files}.info = sprintf("Copy_of_%s_made_at_step_%d\n", listenname, command_position);
    printf("  Der Originaldatensatz wurde in # %d gespeichert\n", loaded_files);
    if ( loaded_files == 1 )
      number_a = 1;
    end;

  case {"#div" }
    if (eing_num==1)
      printf("  Usage: #div <n>\n  devides the actual by the given dataset\n");
    else
      devnum = str2num(substring(eingaben,2));
      if ( (length(freqvec)==sum(freqvec==freqvec_a{devnum})) && (length(timevec)==sum(timevec==timevec_a{devnum})) )
        mdata = mdata./mdata_a{devnum};
      else
        printf("  Error: datasets are incompatible. Try time_resample or wave_resample\n");
      endif
    endif

  case {"#adapt_to" }		% 2D Interpoplation zum Kompatibel machen
    if (eing_num==1)
      printf("  Usage: #adapt_to <nr>			Interpolates the current dataset to fit <nr>\n");
      printf("					If the original dataset is larger, last values are retained\n");
    else
      put();
      ref_set = str2num(substring(eingaben,2));
      printf("  Reference Set:\n");
      printf("	Frequencies: Min: %f; Max: %f; Vals: %d\n", min(freqvec_a{ref_set}),max(freqvec_a{ref_set}),length(freqvec_a{ref_set}));
      printf("	Time:	Min: Min: %f; Max: %f; Vals: %d\n", min(timevec_a{ref_set}),max(timevec_a{ref_set}),length(timevec_a{ref_set}));
      printf("  Current Set:\n");
      printf("	Frequencies: Min: %f; Max: %f; Vals: %d\n", min(freqvec),max(freqvec),length(freqvec));
      printf("	Time:	Min: Min: %f; Max: %f; Vals: %d\n", min(timevec),max(timevec),length(timevec));
      if ( (min(freqvec) > min(freqvec_a{ref_set})) || (max(freqvec) < max(freqvec_a{ref_set})) )
        printf("  Warning: frequency axis will be extrapolated\n");
        printf("  Extrapolated Values are set to 0. Correct manually!\n");
      endif;
      if ( (min(timevec) > min(timevec_a{ref_set})) || (max(timevec) < max(timevec_a{ref_set})) )
        printf("  Warning: time axis will be extrapolated\n");
        printf("  Extrapolated Values are set to 0. Correct manually!\n")
      endif;
      [fvt, tvt, mdt] = wave_resample(freqvec, timevec, mdata, freqvec_a{ref_set});
      [freqvec, timevec, mdata] = time_resample(fvt, tvt, mdt, timevec_a{ref_set});
      clear fvt;
      clear tvt;
      clear mdt;
    endif

  case {"split" }
    if (eing_num==1)
      printf("  Benutzung: split <time>\n  Den Datensatz zum geg. Zeitpunkt auftrennen\n");
    elseif ( ( str2num(substring(eingaben,2))<timevec(1) ) || ( str2num(substring(eingaben,2))>timevec(length(timevec) ) ) )
      printf("  Bitte einen Wert zwischen %f und %f angeben!\n", timevec(1), timevec(length(timevec)));
    else
      % Baustelle
      % erzeugt 2 neue Files; an der angegebenen Position wird die aktuelle Datei aufgespaltet
      time_split = str2num(substring(eingaben,2));
      time_split_index = time_get_index(time_split, timevec);
      % Die beiden Teile Speichern
      loaded_files++;
      if (loaded_files == 1)							% Nummer 1 ist immer der Originaldatensatz
          listenname_a{1} = listenname;
          timevec_a{1} = timevec;
          freqvec_a{1} = freqvec;
          mdata_a{1} = mdata;
          infofield_a{1} = infofield;
          printf("  Der Originaldatensatz wurde in #1 gespeichert\n");
          number_a = 1;
          loaded_files++;
      end;

      listenname_a{loaded_files} = sprintf("%s_part1", listenname);
      freqvec_a{loaded_files} = freqvec;
      timevec_a{loaded_files} = timevec(1:time_split_index);
      mdata_a{loaded_files} = mdata(:, 1:time_split_index);
      infofield_a{loaded_files} = infofield;							% TODO: make a better name!
      loaded_files++;
      listenname_a{loaded_files} = sprintf("%s_part2", listenname);
      freqvec_a{loaded_files} = freqvec;
      timevec_a{loaded_files} = timevec(time_split_index+1:end);
      mdata_a{loaded_files} = mdata(:, time_split_index+1:end);
      infofield_a{loaded_files} = infofield;
      printf("  Datensatz aufgeteilt. <#> zum Anzeigen.\n");

    end;

  case {"join" }					% Baustelle
    if (eing_num<3 )							% TODO: "interaktiver" Modus
      printf("  Benutzung: join <#1> <#2> [Set2_offset | i | a]\n   Verbindet die Datensaetze #1 und #2\n   i - Interaktive Abfrage der Verschiebung des 2. Sets, a - automtisch\n");
    else
      js1 = str2num(substring(eingaben,2));
      js2 = str2num(substring(eingaben,3));
      if (eing_num > 3)
        if (strcmp(substring(eingaben,4),"i"))			% Interaktiver Modus, Verschiebung abfragen
          printf("  Ende Zeitvektor 1. Datensatz: [ ...%f, %f, %f]\n",  timevec_a{js1}(length(timevec_a{js1})-2), timevec_a{js1}(length(timevec_a{js1})-1), timevec_a{js1}(length(timevec_a{js1})-0));
          printf("  Anfang Zeitvektor 2. Datensatz: [ ...%f, %f, %f]\n",  timevec_a{js2}(1), timevec_a{js2}(2), timevec_a{js2}(3));
          printf("  Vorschlag Offset: %f\n", timevec_a{js1}(length(timevec_a{js1})-2)-timevec_a{js2}(1));
          offset=input("  >");
        elseif (strcmp(substring(eingaben,4),"a"))		% Automatikmodus
          base_offset =  timevec_a{js1}(length(timevec_a{js1})-2)-timevec_a{js2}(1);
          offset=base_offset + (timevec_a{js2}(2)-timevec_a{js2}(1));
        else
          offset=str2num(substring(eingaben,4));
        end;
      else
        offset=0;
      end;

      %printf("     Zeitvektor Set 1 Bereich: (%f, %f, %f, ..., %f, %f, %f\n", timevec_a{js1}(1), timevec_a{js1}(2), timevec_a{js1}(3), timevec_a{js1}(length(timevec_a{js1})-2), timevec_a{js1}(length(timevec_a{js1})-1), timevec_a{js1}(length(timevec_a{js1})));
      %printf("     Zeitvektor Set 2 Bereich: (%f, %f, %f, ..., %f, %f, %f\n", timevec_a{js2}(1), timevec_a{js2}(2), timevec_a{js2}(3), timevec_a{js2}(length(timevec_a{js2})-2), timevec_a{js2}(length(timevec_a{js2})-1), timevec_a{js2}(length(timevec_a{js2})));

      if ( (min(freqvec_a{js1}) >= min(freqvec_a{js2})) && (max(freqvec_a{js1})<=max(freqvec_a{js2})) )
        loaded_files++;
        listenname_a{loaded_files} = sprintf("joined_sets_%d_%d", js1, js2);
        [timevec_a{loaded_files}, freqvec_a{loaded_files}, mdata_a{loaded_files}] = ir_join(timevec_a{js1}, freqvec_a{js1}, mdata_a{js1},
                                      timevec_a{js2}+offset, freqvec_a{js2}, mdata_a{js2});

        startindex_a{loaded_files} = 0;								% re-define!
        infofield_a{loaded_files}.info = sprintf("Joined sets %d and %d\n", js1, js2);
        printf("  Gespeichert in # %d\n", loaded_files);
        if ( loaded_files == 1 )
          number_a = 1;
        end;
      else
        printf("   Operation kann nicht durchgefuehrt werden: Frequenzbereich von Set %d zu gross.\n", js1);
      end;
    end;

  case {"joincomplete"}
    if (eing_num<3 )							% PF
      printf("  Usage: joincomplete <#1> <#2> [w1 | w2]\n");
      printf("  Joins data sets #1 und #2\n   w1 - statistical weight of set 1\n w2 - statistical weight of set 2. If omitted, w1 will be relative to w2\n");
    else

      js1 = str2num(substring(eingaben,2));
      js2 = str2num(substring(eingaben,3));

      blend_identifier = "none";

      if (eing_num==4)
        weight1 = str2num(substring(eingaben,4));
        weight2 = 1;
      elseif (eing_num>=5)
        weight1 = str2num(substring(eingaben,4));
        weight2 = str2num(substring(eingaben,5));
        if (eing_num>=6)
          blend_identifier = substring(eingaben,6);
        endif
      else
        weight1 = 1;
        weight2 = 1;
      endif

      printf("  Weights are set to w1 = %f and w2 = %f\n", weight1, weight2);

      time1 = timevec_a{js1};
      time2 = timevec_a{js2};
      freq1 = freqvec_a{js1};
      freq2 = freqvec_a{js2};
      mdata1 = mdata_a{js1};
      mdata2 = mdata_a{js2};

      t1_lo = min(time1);
      t1_up = max(time1);
      t2_lo = min(time2);
      t2_up = max(time2);

      f1_lo = min(freq1);
      f1_up = max(freq1);
      f2_lo = min(freq2);
      f2_up = max(freq2);

      if (t1_up>=t2_up&&t1_lo<=t2_lo)
        if (f1_up>=f2_up&&f1_lo<=f2_lo)
          # create new dataset
          loaded_files++;

          listenname_a{loaded_files} = sprintf("joined_sets_%d_%d", js1, js2);
          [timevec_a{loaded_files}, freqvec_a{loaded_files}, mdata_a{loaded_files}] = join_complete(time1, freq1, mdata1, weight1,
                                        time2, freq2, mdata2, weight2, blend_identifier);

          startindex_a{loaded_files} = startindex_a{js1};
          time_axis_a{loaded_files}=time_axis;
          wavenumber_axis_a{loaded_files} = wavenumber_axis;
          infofield_a{loaded_files}.info = sprintf("Joined sets %d and %d\n", js1, js2);
          printf("  Gespeichert in # %d\n", loaded_files);
          if ( loaded_files == 1 )
            number_a = 1;
          end;

        else
          printf("  Joining can not be performed. Set 2 mus be a complete frequency subset of 1!\n");
        endif
      else
        printf("  Joining can not be performed. Set 2 mus be a complete temporal subset of 1!\n");
      endif

    endif;

  case {"joinwz"}
    if (eing_num<3 )							% PF
      printf("  Usage: joinwz <#1> <#2> [w1 | w2]\n");
      printf("  Joins data sets #1 und #2\n   w1 - statistical weight of set 1\n w2 - statistical weight of set 2. If omitted, w1 will be relative to w2\n");
    else
      js1 = str2num(substring(eingaben,2));
      js2 = str2num(substring(eingaben,3));

      blend_identifier = "none";

      if (eing_num==4)
        weight1 = str2num(substring(eingaben,4));
        weight2 = 1;
      elseif (eing_num>=5)
        weight1 = str2num(substring(eingaben,4));
        weight2 = str2num(substring(eingaben,5));
        if (eing_num>=6)
          blend_identifier = substring(eingaben,6);
        endif
      else
        weight1 = 1;
        weight2 = 1;
      endif

      printf("  Weights are set to w1 = %f and w2 = %f\n", weight1, weight2);

      time1 = timevec_a{js1};
      time2 = timevec_a{js2};

      t1_lo = min(time1);
      t1_up = max(time1);
      t2_lo = min(time2);
      t2_up = max(time2);

      if !( t1_lo > t2_up || t1_up < t2_lo )  # time1 and time2 must have overlap
        printf("  Sets have a temporal overlap, Joining will be performed\n");

        mdata1 = mdata_a{js1};
        mdata2 = mdata_a{js2};

        t1_up_idx = time_get_index(max(time2), time1);
        t1_lo_idx = time_get_index(min(time2), time1);
        t2_up_idx = time_get_index(max(time1), time2);
        t2_lo_idx = time_get_index(min(time1), time2);
        mdata1 = mdata1(:,t1_lo_idx:t1_up_idx);
        mdata2 = mdata2(:,t2_lo_idx:t2_up_idx);
        time1 = time1(t1_lo_idx:t1_up_idx);
        time2 = time2(t2_lo_idx:t2_up_idx);

        mdata2 = interp1(time2, mdata2', time1, "extrap");
        # make joined time vec
        #if (t2_lo<=t1_lo<=t2_up && t1_up>=t2_up)
          # Set1
          # -----
          # | --|--
          # --|-- |
          #   |   |
          #   -----
          #   Set2

        #elseif (t1_up>=t2_up && t1_lo<=t2_lo)
          # Set1
          # -----
          # | --|-- Set2
          # | | | |
          # | --|--
          # -----

        #elseif (t2_up>=t1_up && t2_lo<=t1_lo)
          #     Set2
          # Set1-----
          #   --|-- |
          #   | | | |
          #   --|-- |
          #     -----

        #elseif (t1_lo<=t2_lo<=t1_up && t2_up>=t1_up)
          #   Set2
          #   -----
          #   |   |
          # --|-- |
          # | --|--
          # |   |
          # -----
          # Set1
        #endif;

        # make joined freqvec
        mdata1 = mdata_a{js1};
        mdata2 = mdata_a{js2};

        freq1 = freqvec_a{js1};
        freq2 = freqvec_a{js2};

        if ((max(freqvec_a{js1}) < max(freqvec_a{js2})) && (min(freqvec_a{js1}) > min(freqvec_a{js2})))
          printf("  Data set 2 is complete frequency subset of set 1; Frequency vector of 1 will be taken.\n");
          joined_freq = freq1;

        elseif (max(freqvec_a{js1}) <= max(freqvec_a{js2}))
          freq2_sidx = get_index(max(freqvec_a{js1}), freqvec_a{js2});
          freq2_overlap = freqvec_a{js2}(freq2_sidx+1:end);
          joined_freq = [freq1; freq2_overlap];
        elseif (min(freqvec_a{js1}) >= min(freqvec_a{js2}))
          freq2_eidx = get_index(min(freqvec_a{js1}), freqvec_a{js2});
          freq2_overlap = freqvec_a{js2}(1:freq2_eidx-1);
          joined_freq = [freq2_overlap; freq1];
        endif


        # create new dataset
        loaded_files++;

        listenname_a{loaded_files} = sprintf("joined_sets_%d_%d", js1, js2);
        [timevec_a{loaded_files}, freqvec_a{loaded_files}, mdata_a{loaded_files}] = ir_join_wz(time1, freq1, mdata1, weight1,
                                      time2, freq2, mdata2, weight2, joined_freq, blend_identifier);

        startindex_a{loaded_files} = startindex_a{js1};
        time_axis_a{loaded_files}=time_axis;
        wavenumber_axis_a{loaded_files} = wavenumber_axis;
        infofield_a{loaded_files}.info = sprintf("Joined sets %d and %d\n", js1, js2);
        printf("  Gespeichert in # %d\n", loaded_files);
        if ( loaded_files == 1 )
          number_a = 1;
        end;
      else
        printf("  sets cannot be joined. Time vector of set 2 must be a temporal subset of set 1. Cut time of set 2 and try again.\n")
        printf("  Or use <jointime> instead to join sets in time domain.\n");
      endif;
    endif;

  case {"jointime"}
    if (eing_num<3 )							% PF
      printf("  Usage: join_time <#1> <#2> [w1 | w2]\n");
      printf("  Joins data sets #1 und #2\n   w1 - statistical weight of set 1\n w2 - statistical weight of set 2. If omitted, w1 will be relative to w2\n");
    else
      joinable = 1;
      js1 = str2num(substring(eingaben,2));
      js2 = str2num(substring(eingaben,3));

      if (eing_num==4)
        weight1 = str2num(substring(eingaben,4));
        weight2 = 1;
      elseif (eing_num>=5)
        weight1 = str2num(substring(eingaben,4));
        weight2 = str2num(substring(eingaben,5));
      else
        weight1 = 1;
        weight2 = 1;
      endif

      # make freqvecs compatible
      freq1 = freqvec_a{js1};
      freq2 = freqvec_a{js2};
      mdata1 = mdata_a{js1};
      mdata2 = mdata_a{js2};

      f1_lo = min(freq1);
      f1_up = max(freq1);
      f2_lo = min(freq2);
      f2_up = max(freq2);


      if !(f1_lo > f2_up || f2_lo > f1_up)    # Sets have frequency overlap
        printf("  Frequency vectors have an overlap, joining will be performed\n");
        printf("  Set 2 will be interpolated to match 1 in overlap region\n");

        f1_lo_idx = ir_get_index(f2_lo, freq1);
        f1_up_idx = ir_get_index(f2_up, freq1);
        f2_lo_idx = ir_get_index(f1_lo, freq2);
        f2_up_idx = ir_get_index(f1_up, freq2);

        mdata1 = mdata1(f1_lo_idx:f1_up_idx,:);
        mdata2 = mdata2(f2_lo_idx:f2_up_idx,:);
        freq1 = freq1(f1_lo_idx:f1_up_idx);
        freq2 = freq2(f2_lo_idx:f2_up_idx);

        mdata2 = interp1(freq1, mdata1, freq2);

      else
        printf("  Sets cannot be joined. Frequency vectors must have an overlap.\n")
        joinable = 0;
      endif;

      if joinable
         # make joined timevec
        time1 = timevec_a{js1};
        time2 = timevec_a{js2};


        loaded_files++;
        listenname_a{loaded_files} = sprintf("joined_sets_%d_%d", js1, js2);
        [timevec_a{loaded_files}, freqvec_a{loaded_files}, mdata_a{loaded_files}] = join_time(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2);

        startindex_a{loaded_files} = startindex_a{js1};
        time_axis_a{loaded_files}=time_axis;
        wavenumber_axis_a{loaded_files} = wavenumber_axis;
        infofield_a{loaded_files}.info = sprintf("Joined sets %d and %d\n", js1, js2);
        printf("  Gespeichert in # %d\n", loaded_files);
        if ( loaded_files == 1 )
          number_a = 1;
        end;
      endif


    endif


  case {"inc_ratio" }
    put();
    mdata=inc_ratio_time(mdata);
  case {"inc_diff" }
    put();
    for i=2:columns(mdata)
      mdata_t(:,i)=mdata(:,i)-mdata(:,i-1);
    endfor
    mdata = mdata_t;
    clear mdata_t;
  case {"inc_add" }
    put();
    for i=2:columns(mdata)
      mdata_t(:,i)=mdata(:,i)+mdata(:,i-1);
    endfor
    mdata = mdata_t;
    clear mdata_t;
  case {"inc_mult" }
    put();
    for i=2:columns(mdata)
      mdata_t(:,i)=mdata(:,i).*mdata(:,i-1);
    endfor
    mdata = mdata_t;
    clear mdata_t;

  case {"top" }
    XRES_3D=200;
    YRES_3D=200;
    shading_3D="flat";
    AZ_3D=0;
    EL_3D=90;

  case {"perspective" }
    XRES_3D=100;
    YRES_3D=100;
    shading_3D="faceted";
    AZ_3D=220;
    EL_3D=30;

  case {"shift_odd" } 		% shifts every 2nd row in the data matrix. used for AIM
    mdata=intensity_shifter(mdata,str2num(substring(eingaben,2)),1);
    timevec=timevec(1:end-str2num(substring(eingaben,2)));

  case {"shift_even" }
    mdata=intensity_shifter(mdata,str2num(substring(eingaben,2)),0);
    timevec=timevec(1:end-str2num(substring(eingaben,2)));

  case {"join_odd_even"}
    printf("  Warning - experimental. Parameters are not checked!\n");
    if (eing_num < 3)
      printf("  Usage: join_odd_even <set1> <set2>\n");
    endif;
    nodd=str2num(substring(eingaben,2));
    neven=str2num(substring(eingaben,3));
    timevec = timevec_a{str2num(substring(eingaben,2))};
    bailout=0;
    i=1; j=1;
    do
      clear freqvec;
      freqvec(j) = freqvec_a{nodd}(i);
      mdata(j,:) = mdata_a{nodd}(i,:);
      j++;
      if (i<length(freqvec_a{neven}))
          freqvec(j) = freqvec_a{neven}(i);
          mdata(j,:) = mdata_a{neven}(i,:);
          j++;
      else
          bailout=1;
      endif;
      i++;
      if (i>length(freqvec_a{nodd})) bailout=1; end;
    until (bailout);

  case {"split_odd_even"}       % generates 2 new datasets with the odd and
                                % even wavenumber parts separated
    if ( loaded_files == 0 )			% In Mehrfachmodus umschalten, und den Datensatz sichern
		  printf("  Umschalten in den Mehrfachmodus und Sichern der Daten auf Platz # 1\n");
	  end;
	  loaded_files++;
	  listenname_a{loaded_files} = listenname;
	  timevec_a{loaded_files} = timevec;
	  freqvec_a{loaded_files} = freqvec(1:2:end);
    time_axis_a{loaded_files}=time_axis;
    wavenumber_axis_a{loaded_files}=wavenumber_axis;
	  mdata_a{loaded_files} = mdata(1:2:end,:);
	  startindex_a{loaded_files} = REACTION_START_INDEX;
	  infofield_a{loaded_files}.info = sprintf("Copy_ODD_of_%s_made_at_step_%d\n", listenname, command_position);
	  printf("  Odd part saved in # %d\n", loaded_files);

    loaded_files++;
	  listenname_a{loaded_files} = listenname;
	  timevec_a{loaded_files} = timevec;
	  freqvec_a{loaded_files} = freqvec;
    freqvec_a{loaded_files}(1:2:end)=[];
    time_axis_a{loaded_files}=time_axis;
    wavenumber_axis_a{loaded_files}=wavenumber_axis;
	  mdata_a{loaded_files} = mdata;
    mdata_a{loaded_files}(1:2:end,:)=[];
	  startindex_a{loaded_files} = REACTION_START_INDEX;
	  infofield_a{loaded_files}.info = sprintf("Copy_Even_of_%s_made_at_step_%d\n", listenname, command_position);
	  printf("  Even Part saved in # %d\n", loaded_files);

  case {"align_odd"}        % shifts odd part of the wl by defined value
    value = str2num(substring(eingaben,2));
    mdata(1:2:end,:)=mdata(1:2:end,:)+value;

  case {"oe_correct"}       % corrects odd-even offset for AIM detector by average <A(I),A(I+1)>
    %mo = mdata(1:2:end,:);      % Matrix_odd
    %me = mdata;
    %me(1:2:end,:) = [];         % Matrix even
      mdata_new = mdata;
      mdata_new(end,:)=[];
      for i=1:rows(mdata)-1
        mdata_new(i,:) = (mdata(i,:)+mdata(i+1,:))./2;
      end;
      mdata=mdata_new;
      fv_new=freqvec;
      fv_new(end)=[];
      for i=1:rows(freqvec)-1
        fv_new(i) = (freqvec(i+1)+freqvec(i)) ./ 2;
      endfor;
      freqvec = fv_new;
    %else
    %  printf("Cannot work with odd freq numbers");
    %endif;

  case {"fig" }
	  if (eing_num<2)
		  printf(" Figures (examples):\n");
		  printf(" 1	arbitrary\n	2	3D surface plot\n	3	spectra\n	4	kinetics\n");
		  printf(" 5	fitted kinetics\n	6	U\n	7	V\n	8	least square fit\n");
		  printf(" 9	base spectra\n");
      printf(" Current status for automatic figure: %d\n", AUTO_FIGURE);
      printf(" Select by fig auto|a or fig man|m\n");
    elseif ( strcmp(substring(eingaben,2),"auto") || strcmp(substring(eingaben,2),"a") )
      AUTO_FIGURE=1;
    elseif ( strcmp(substring(eingaben,2),"man") || strcmp(substring(eingaben,2),"m"))
      AUTO_FIGURE=0;
	  else
		  figure(str2num(substring(eingaben,2)));
	  endif

  case {"interpolate"}
    if (eing_num<=2)
      printf("  Usage:    interpolate freq/time <factor>\n");
      printf("  Example:  interpolate freq 2\n");
      printf("            will interpolate the spectral data in the frequency domain with a spline\n");
      printf("            function and increase the spectral reolution artificially by factor of 2\n");
    else
      put();
      if (strcmp(substring(eingaben,2),"time"))
        printf("  not yet implemented");
      elseif strcmp(substring(eingaben,2),"freq")
        factor = str2num(substring(eingaben,3));
        number_of_data_points = length(freqvec);
        indices_orig = 1:1:number_of_data_points;
        stepsize = 1/factor;
        indices_interp = 1:stepsize:number_of_data_points;
        freqvec_interp = interp1(indices_orig, freqvec, indices_interp); # linear interpolation of frequency axis

        mdata_interp = zeros(length(freqvec_interp), length(timevec));

        for i=1:length(timevec)
          spec_interp = interp1(freqvec, mdata(:,i), freqvec_interp, "spline");
          if (LIVE_MODE)
              fig(FIG_LIVE);
              plot(freqvec, mdata(:,i), '+', freqvec_interp, spec_interp);
              plot_label=sprintf("%d/%d: %f", i, length(timevec), timevec(i));
              legend(plot_label);
              drawnow();
          end;
          mdata_interp(:,i) = spec_interp;
        endfor
        mdata = mdata_interp;
        freqvec = freqvec_interp';
      else
        printf("  Usage:    interpolate freq/time <factor>\n");
      endif

    endif

  case {"interpolate_time"}
    if (eing_num==1)
      printf("Usage: interpolate_time <ref_vec>\n");
    else
      dummy = eval(substring(eingaben,2));
      [freqvec, timevec, mdata] = time_resample(freqvec, timevec, mdata, dummy);
    endif;

  case {"interpolate_wave"}
    if (eing_num==1)
      printf("Usage: interpolate_wave <ref_vec>\n");
    else
      dummy = eval(substring(eingaben,2));
      [freqvec, timevec, mdata] = wave_resample(freqvec, timevec, mdata, dummy);
    endif;

  case {"axes"}
	  if (eing_num<2)
      printf("Current axis parameters\n");
      wavenumber_axis
      inverse_wavenumber_axis
      time_axis
      intensity_axis
      arbitrary_axis
      parameter_axis
      s_x_axis
      s_y_axis
    else
      switch substring(eingaben,2)
        case {"fontsize" "fs"}
          h = get(gcf,"currentaxes");
          set(h,"fontsize",str2num(substring(eingaben,3)));
        case {"linewidth" "lw"}
          h = get(gcf,"currentaxes");
          set(h,"linewidth",str2num(substring(eingaben,3)));
      endswitch;
    endif;

  case {"pp" }
    if (eing_num<2)
      printf("  Benutzung: pp <Dateiname>\n");
      filename = basename(listenname);
      filename = sprintf("%s-%d-f%d", filename, command_ctr, gcf());
      printf("  Kein Dateiname angegeben. Setze: %s.emf\n", filename);
    else
      filename = substring(eingaben,2);
    end;
    filename = sprintf("%s.emf", filename);
    if ( strcmp(PRINTOUT_SIZE,"") )
        print(filename, "-demf");
    else
        print(filename, "-demf", PRINTOUT_SIZE);
    endif;

  case {"pj" }
    if (eing_num<2)
      printf("  Benutzung: pj <Dateiname>\n");
      filename = basename(listenname);
      printf("  Kein Dateiname angegeben. Setze: %s-%d-f%d.jpg\n", filename, command_ctr,gcf());
    else
      filename = substring(eingaben,2);
    end;
    filename = sprintf("%s-%d-f%d.jpg", filename, command_ctr, gcf());
    if ( strcmp(PRINTOUT_SIZE,"") )
      print(filename, "-color", "-djpg", "-F:12");
    else
      print(filename, "-color", "-djpg", "-F:6", PRINTOUT_SIZE);
    end;


  case {"pg" }
	  if (eing_num<2)
		  printf("  Benutzung: pg <Dateiname>\n");
		  filename = basename(listenname);
		  printf("  Kein Dateiname angegeben. Setze: %s-%d-f%d.png\n", filename, command_ctr,gcf());
	  else
		  filename = substring(eingaben,2);
	  end;
	  filename = sprintf("%s-%d-f%d.png", filename, command_ctr, gcf());
	  print(filename, "-color", "-dpng");

  % Signal to noise calculation (via mean(t)/std(t))

  case {"movie"}
    figure(FIG_MISC);
    clf();
    starti = get_index(str2num(substring(eingaben,2)),timevec);
    stopi = get_index(str2num(substring(eingaben,3)),timevec);
    for i=starti:stopi
      dummy=sprintf(";%f;",timevec(i));
      clf();
      plot(freqvec,mdata(:,i),dummy);
      pause(0.01);
    endfor

  case {"SNR"}
    clear snr_mdata;
    clear mdata_SMOOTH;
    clear mdata_NOISE;

    if ( (eing_num == 2) || (eing_num > 4) )
      apropos("SNR");
    else
      if (eing_num == 4)                            % Smmothing abfragen
        SMOOTHING = str2num(substring(eingaben,4));
      else
        SMOOTHING = 0;
      end;
      if (eing_num > 2)                             % Bereich abfragen
        calc_from = get_index(str2num(substring(eingaben,2)),timevec);
        calc_to = get_index(str2num(substring(eingaben,3)),timevec);
      else
        calc_from = 1;
        calc_to = columns(mdata);
      end;
      SNR_points_used = calc_to - calc_from;

      if (SMOOTHING==0)
        for i=1:rows(mdata)
          snr_mdata(i)=mean(mdata(i,calc_from:calc_to))/std(mdata(i,calc_from:calc_to));
        endfor;
      else
        for i=1:length(freqvec)
	        mdata_SMOOTH(i,:) = medfilt1(mdata(i,:),SMOOTHING);
          mdata_NOISE(i,:) = mdata(i,:)-mdata_SMOOTH(i,:);
          snr_mdata(i)= mean(mdata_SMOOTH(i,calc_from:calc_to))/std(mdata_NOISE(i,calc_from:calc_to));
	      end;
      end;

      printf("  calculated SNR data in snr_mdata as a function of freqvec\n");
      printf("  Average S/N: %f\n",mean(snr_mdata));
      printf("  Points used: %d\n", SNR_points_used);
      figure(FIG_MISC);
      % clf();
      plot(freqvec,snr_mdata);
      xlabel(wavenumber_axis);
      ylabel("Signal-to-Noise");
    end;

  case {"2dcos"}
    if ( eing_num<5 )
        printf("  Usage: 2dcos freq1 freq2 time1 time2\n");
        printf("  2 new datasets for synchronous or asynchronous maps are generated\n");
        printf("  For plotting, use:\n");
        printf("    p o                   3D Version}\n");
        printf("    p c                   Contour\n");
        printf("    p cc                  Contour in color\n");
        printf("    countour(freqvec,timevec, mdata);\n");
        printf("    countourf(freqvec,timevec, mdata);\n");
        printf("    corplot=@contourf, corplot=@contour  to select plot style\n");
        printf("    Use COS_TRESHOLD_SYN, COS_TRESHOLD_ASYN for noise elimination\n");
        printf("    Current values: %d, %d\n",COS_TRESHOLD_SYN*100, COS_TRESHOLD_ASYN*100);

    else
		fvon=str2num(substring(eingaben,2));
		fbis=str2num(substring(eingaben,3));
		tvon=str2num(substring(eingaben,4));
		tbis=str2num(substring(eingaben,5));
		[startwert, realsta_wz] = ir_get_index(fvon,freqvec);
		[stopwert, realsto_wz] = ir_get_index(fbis,freqvec);
		if (stopwert<startwert)
			h=stopwert; stopwert=startwert; startwert=h;
		endif;
		new_freqvec = freqvec(startwert:stopwert);
		new_mdata=mdata(startwert:stopwert,:);
		start_index = time_get_index(tvon, timevec);
		stop_index = time_get_index(tbis, timevec);
		new_timevec = timevec(start_index:stop_index);
		new_mdata = new_mdata(:,start_index:stop_index);
		% auf neue Plaetze speichern für 2Dcos
		if ( loaded_files == 0 )
			loaded_files++;
			listenname_a{loaded_files} = listenname;
			timevec_a{loaded_files} = timevec;
			freqvec_a{loaded_files} = freqvec;
			mdata_a{loaded_files} = mdata;
			startindex_a{loaded_files} = REACTION_START_INDEX;
			infofield_a{loaded_files} = infofield;
			number_a = 1;
		end;
		% Synchronous Part
		new_mdata=new_mdata-new_mdata(:,1);      % reference to 1st sectrum in set
		loaded_files++;
		listenname_a{loaded_files} = listenname;
		timevec_a{loaded_files} = new_timevec;
		freqvec_a{loaded_files} = new_freqvec;
		mdata_a{loaded_files} = new_mdata;
		time_axis_a{loaded_files} = wavenumber_axis;
		wavenumber_axis_a{loaded_files} = wavenumber_axis;
		startindex_a{loaded_files} = REACTION_START_INDEX;
		infofield_a{loaded_files}.info = "2DCos Sync";
		infofield_a{loaded_files}.datatype = "2D Spectrum sync";
		l=length(timevec_a{loaded_files});
		mdata_a{loaded_files}=mdata_a{loaded_files}(:,2:l)*mdata_a{loaded_files}(:,2:l)'/(l-2);
		MAXVAL=max(max(mdata_a{loaded_files}));
		% Set to zero if below the noise level!
		mdata_a{loaded_files}(abs(mdata_a{loaded_files})<COS_TRESHOLD_SYN*MAXVAL)=0;
		timevec_a{loaded_files}=freqvec_a{loaded_files};

		% ASynchronous Part
		loaded_files++;
		listenname_a{loaded_files} = listenname;
		timevec_a{loaded_files} = new_timevec;
		freqvec_a{loaded_files} = new_freqvec;
		time_axis_a{loaded_files} = wavenumber_axis;
		wavenumber_axis_a{loaded_files} = wavenumber_axis;
		mdata_a{loaded_files} = new_mdata;
		startindex_a{loaded_files} = REACTION_START_INDEX;
		infofield_a{loaded_files}.info = "2DCos ASync";
		infofield_a{loaded_files}.datatype = "2D Spectrum async";
		l=length(timevec_a{loaded_files});
		hm=hilbert_noda_matrix(l);
		% ATTENTION TODO POSSIBLE ERROR: check why this has to be transposed!
		mdata_a{loaded_files}=(mdata_a{loaded_files}(:,2:l)*hm*mdata_a{loaded_files}(:,2:l)'/(l-2))';
		MAXVAL=max(max(mdata_a{loaded_files}));
		mdata_a{loaded_files}(abs(mdata_a{loaded_files})<COS_TRESHOLD_ASYN*MAXVAL)=0;
		timevec_a{loaded_files}=freqvec_a{loaded_files};  %'

		% Multiply for sign
		loaded_files++;
		listenname_a{loaded_files} = listenname;
		timevec_a{loaded_files} = new_timevec;
		freqvec_a{loaded_files} = new_freqvec;
		time_axis_a{loaded_files} = wavenumber_axis;
		wavenumber_axis_a{loaded_files} = wavenumber_axis;
		startindex_a{loaded_files} = REACTION_START_INDEX;
		infofield_a{loaded_files}.info = "2DCos SIGN";
		infofield_a{loaded_files}.datatype = "2D Spectrum SIGN";
		l=length(timevec_a{loaded_files});
		% ATTENTION TODO POSSIBLE ERROR: check why this has to be transposed!
		mdata_a{loaded_files}=mdata_a{loaded_files-2}.*mdata_a{loaded_files-1};
		timevec_a{loaded_files}=freqvec_a{loaded_files};
		printf("  2D correlation set calculated. Values in %d - %d.\n",loaded_files-2,loaded_files);
      end;

  case {"2dcossimplify"}
      if (eing_num==2)
        cos_eps=str2num(substring(eingaben,2));
      else
        printf("  Usage: 2dcossimplify <treshold>\n");
        printf("  if not specified, %d % treshold is assumed\n", cos_eps);
      end;
      %%iii=
      MAXVAL=max(max(mdata))-min(min(mdata));

      mdata(mdata>MAXVAL*cos_eps) = 1;
      mdata(mdata<-MAXVAL*cos_eps) = -1;
      mdata(abs(mdata)<=MAXVAL*cos_eps)=0;

  case {"2dcosstrong"}
      if (eing_num==2)
        cos_eps=str2num(substring(eingaben,2));
      else
        printf("  Usage: 2dcosstrong <treshold>\n");
        printf("  if not specified, %d % treshold is assumed\n", cos_eps);
        printf("  Under construction -- as yet it will destroy the sign\n");
      end;
      %%iii=
      MAXVAL=max(max(mdata))-min(min(mdata));

      mdata(mdata>MAXVAL*cos_eps) = 1e6;
      mdata(mdata<-MAXVAL*cos_eps) = 1e6;
      mdata(abs(mdata)<=MAXVAL*cos_eps)=1;
      mdata(mdata>1e5) = 0;


  case {"2dcossort"}
    if ( eing_num == 3)                                   % einfache Funktion; sortiert 2 Banden
        printf("  Using cos_eps=%f\n",cos_eps);
        band1=str2num(substring(eingaben,2));
        band2=str2num(substring(eingaben,3));
        if (band1>band2)
            h=band1; band1=band2; band2=h;
        endif;
        i1=get_index(band1,freqvec);
        i2=get_index(band2,freqvec);
        d=mdata(i1,i2);
        if ( abs(d) <= cos_eps )
            printf("   No information. Consider decreasing cos_eps.\n");
        elseif ( d < 0)
            printf("%f -> %f\n",band1,band2);
        else
            printf("%f -> %f\n",band2,band1);
        endif;
    else
      if ( eing_num==2 )
        cos_eps=str2num(substring(eingaben,2));
      else
        printf("  Using cos_eps=%f, cos_dx=%f, cos_dy=%f\n",cos_eps, cos_dx, cos_dy);
      endif;
      if ( exist("cbh") )
          if ( length(cbh)>0 )
            printf(" Predefined bands found:\n");
            cbh
            yn=input(" Use (y/n)? >","c");
            if (yn == "n"), cbh=[]; end;
          end;
      else
        cbh=[];
      end;
      if ( length(cbh)==0 )
        printf("  Enter Bands of interest, -1 cancels\n");
        i=1;
        cbh=[];
        do
          s = input(" -> ","c");
          if ( length(s)==0 )
              cbh(i)=-1;
          else
              cbh(i)=str2num(s);
          end;
        until (cbh(i++) == -1);
        cbh(i-1)=[];
      end;
      cbh=sort(cbh,"descend");
      cbv=cbh';
      cbv=sort(cbv,"ascend");
      %cbh
      %cbv
      cm = zeros(length(cbh)+1,length(cbh)+1);
      cm(2:end,1)=cbv;
      cm(1,2:end)=cbh;
      for s=1:length(cbh)
          for z=1:length(cbv)
            %if (z>s)
              m_yv= get_index(cbv(z)+cos_dy, freqvec);
              m_yb= get_index(cbv(z)-cos_dy, freqvec);
              m_xv= get_index(cbh(s)+cos_dx, freqvec);
              m_xb= get_index(cbh(s)-cos_dx, freqvec);
              if (m_yv>m_yb)
                  d=m_yv;
                  m_yv=m_yb;
                  m_yb=d;
              endif
              if (m_xv>m_xb)
                  d=m_xv;
                  m_xv=m_xb;
                  m_xb=d;
              endif
              d = mean(mean(mdata( m_yv:m_yb, m_xv:m_xb )));
              if (abs(d)<=cos_eps)
                d=0;
              elseif (d<(0-cos_eps))
                d=-1;
              else
                d=1;
              end;
              if (length(cbh)-z>=s), cm(z+1,s+1)=d; end;
            %end;
          end;
      end;
      cm
    endif;

  % Some more functions for averaging and data improvement
  case {"plot_time_resolution"}
    figure(FIG_MISC);
    clf();
    for i=2:length(freqvec)
      time_resolution(i-1)=timevec(i)-timevec(i-1);
    end;
    plot(timevec(1:length(freqvec)-1), time_resolution);

  case {"tag"}
      if ( eing_num == 2 )
        infofield.info=substring(eingaben,2);
      else
        printf("%s\n", infofield.info);
      end;

  case {"" }
  case {"%" }
    # Do nothing
    #
  case {"%#!" }			# Fragen, ob diese oder eine andere Datei Bearbeitet werden soll
	% Baustelle
	prelim_file = substring(eingaben,2);
	dummy_message = sprintf("Die Datei %s bearbeiten?", prelim_file);
	if ( message(dummy_message,"question")==0 )
		% Ok., die Datei laden
		printf("  Lade die Datei...\n");
		dummy_message = sprintf("load 3ddata %s", prelim_file);
		add_to_history(dummy_message);
	else
		if (message("Eine andere datei laden?","question")==0)
			% Ok., andere Datei laden
			prelim_file = file_selection("Laden:",sprintf("%s/",pwd()));
			dummy_message = sprintf("load 3ddata %s\n", prelim_file);
			add_to_history(dummy_message);
			% prelim_file = file_selection(".", "multiple");
		else
			printf("  Keine Datei geladen. Bearbeite interne Daten...\n");
		end;
	end;

  case {"to_abs"}
      put();
      mdata(mdata<1e-5)=1e-5;
      mdata=-log10(mdata);
      intensity_axis = "absorbance";
  case {"to_trans"}
      put();
      mdata=10.^(-mdata);
      intensity_axis = "transmittance";
  case {"taxis" "tax"}
      time_axis = substring(eingaben,2);
      infofield.timeaxis = time_axis;
  case {"waxis" "wax"}
      wavenumber_axis = substring(eingaben,2);
      infofield.freqaxis = wavenumber_axis;
  case {"iaxis" "iax"}
      intensity_axis = substring(eingaben,2);
      infofield.intensity = intensity_axis;
  case {"xinv"}
      set(gca(),"XDir","reverse");
  case {"yinv"}
      set(gca(),"YDir","reverse");
  case {"xnor"}
      set(gca(),"XDir","normal");
  case {"ynor"}
      set(gca(),"YDir","normal");
  case {"h0"}
      hold off;
  case {"h1"}
      hold on;
  case {"undo" }
	    undo();
  case {"reset" }
	  clear -all;
    break;
  case {"about" }
	  message(SYSINFO);
  case {"nop"}
  case {"rem" "REM" }				% Remark
    if (eing_num == 1)      % print all remarks
    else
    endif;
  case {"" }			% nichts tun
  case {"let"}		% BASIC in memoriam....
    put();
    dummy = eingaben(5:end);
    eval(dummy);
    otherwise
    midx=length(macro);
    macro_to_run=0;
    do							% Existiert ein Makro mit diesem Namen?
      if (strcmp(macro{midx}.name,eingaben) ), macro_to_run=midx; end;
      midx--;
    until ( (midx<1) || (macro_to_run>0) );
    if ( macro_to_run > 0 )					% wenn ja, Makro starten
              add_to_history("rem START MACRO");
        for k=1:length(macro{macro_to_run}.command)
          add_to_history(macro{macro_to_run}.command{k});
          % printf("Will execute: %s\n",macro{i}.command{k});
        end;
        add_to_history("rem END MACRO");
    else							% sonst Octave Kommando ausfuehren
      put();
      eval(eingaben);
    end;
  endswitch

catch                                               % trycatch
   printf("  Error: %s\n",lasterr());
   printf("  last input: %s\n", u_choice);
   command_ctr=command_position;
end_try_catch;

until (ende);

printf("Program closed. Data:\n");
printf("time data: timevec,\nfrequency data: freqvec\nintensity_data: mdata\n\n");
printf("Returning to octave.\n");
