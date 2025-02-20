function helpontopic(topic)
  if (strcmp(topic,"set"))
    printf("\n");
    printf("Syntax: set [u | s | v | o | hold | forget]\n");
    printf("		Einstellen verschiedener Parameter:\n");
    printf("		u,s,v,o 	... Rechenoperationen beziehen sich auf diese Matrix\n");
    printf("		hold, forget	... Beim Plotten werden vorhergehende Daten behalten\n");
    printf("				    oder geloescht\n");
    printf("\n");
  elseif (strcmp(topic, "plot"))
    printf("\n");
    printf("Syntax: plot u | v | o | ok [x1] [x2] [x3] ...\n");
    printf("		Grafische Darstellung der Parameter\n");
    printf("\n");
    printf("	Unterfunktionen:\n");
    printf("		plot ok		Kinetiken der Originaldaten plotten\n");
    printf("		Syntax:\n");
    printf("            	plot ok\n");
    printf("    		plot ok wl\n");
    printf("    		plot ok wl1 wl2 wl3 ....\n");
    printf("    		plot ok wl1 - wl2\n\n");  
    printf("		plot fit\n");
    printf("		plot fit parameter x		... Einen bestimmten Parameter des Fits plotten\n");
    printf("		plot fit stddev			... Die Standardabweichung\n");
    printf("\n");
  elseif (strcmp(topic, "zero"))
    printf("\n");
    printf("Syntax: zero xxx\n");
    printf("		Die aktuelle Matrix wird auf der Zeitachse verschoben.\n");
    printf("		Der Wert xxx wird auf Null gesetzt.\n");
    printf("            Zeitwerte unter 0 werden abgeschnitten\n");
    printf("		Zero ohne Parameter verschiebt die Funktion in der Zeitachse\n");
    printf("            auf Startpunkt 0\n");
    printf("            Funktion ist derzeit nur für o implementiert\n");
    printf("\n");
  elseif (strcmp(topic, "fit"))
    printf("\n");
    printf("Syntax: fit type [file filename ] | [ wavelength1 wavelength2 ... ]\n");
    printf("		Die aktuelle Datenmatrix wird an eine Funktion <<type>> angepasst\n");
    printf("		<<type>> umfasst:\n");
    printf("			exp	-	Monoexponentieller Fit y=a0+a1*(1-exp(-a2*x))\n");
    printf("                    2exp    -       2Phasig exponentieller Fit\n");
    printf("\n\n");
  elseif (strcmp(topic, "cut"))
    printf("\n");
    printf("Syntax: cut starttime endtimetype\n");
    printf("		Aus der aktuellen Datenmatrix wird nur der Bereich zwischen\n");
    printf("		<<starttime>> und <<endtime>> behalten\n");
    printf("		<<->> als Parameter bewirkt Beibehalten des alten Wertes\n");
    printf("		Durch nachfolgenden Aufruf von <<zero>> können die Daten dann\n");
    printf("		auf der Zeitachse nullpunktverschoben werden\n");
    printf("\n");
  endif
endfunction
