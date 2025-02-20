## -*- texinfo -*-
## @deftypefn {Function File} {} csv2x3d
## Imports csv into spoc as x3d. Function implemented for Windows. 
## Function will create a new entry in spocs 'loaded_files' registry. 
##
## @example
## @group
## 
##      @result{} 
## @end group
## @end example
##
## @seealso{}
## @end deftypefn

## Author: Paul Fischer

function [timevec_csv, freqvec_csv, mdata_csv] = csv2x3d (csv_path)
  
  csvloaded=0;
  
  datatype=[];
  intervalltest=0
    


  %get csv directory
  %csv_path=zenity_file_selection("Select *.csv data", sprintf("%s/",pwd()));
  %convert path for windows
  %csv_path=strtrim(strrep(strcat(sprintf("%s", csv_path{1}),":", sprintf("%s", csv_path{2})), "\\", "/"));
  
    

  %Abfrage ob Datei eingelesen
  if length(csv_path)==0
    printf("\n");
    printf("Keine Datei ausgewählt!\n");
    clear jn;
    printf("\n");
    printf("Andere Datei laden?\n");
    jn = input("  [j/n]","c");
    if jn=="j"
      csv2x3d();
    else
      printf("Keine Datei geladen\n");
    endif
  endif
  %Abfrage ob Dateiendung *.csv
  i=length(csv_path);
  while !strcmp(csv_path(i),".")
    datatype=[csv_path(i),datatype];
    i--;
    if i==1 
      sprintf("Keine Dateiendung gefunden. Bsp: *csv/n");
      break    
    endif
  endwhile
  
  if !strcmp(datatype,"csv")
    sprintf("Datei keine *.csv Datei. Benutze spoc-Befehl 'load'./n")
  else 
    csvloaded=1;
  endif
  
  if csvloaded==1  

    dataid=fopen(csv_path);
    data=[];
    linedata=[];
    while ((line=fgetl(dataid))&& !(line==-1))
      line=strrep(line,","," ");
      newdata=sscanf(line,"%f");
      if length(newdata)!=0
        data=[data;newdata'];
      endif
    endwhile
    fclose(dataid)  
%Erzeugen der reinen Datenmatrix 'mdata_csv' ohne Wellenzahlinformationen
    mdata_csv=[];
    for i=1:columns(data)
      if i/2==floor(i/2)  %nur gerade Spalten
        mdata_csv(:,i/2)=data(:,i);
      endif
    endfor  
    freqvec_csv=data(:,1);
   
    
 %Erzeugung des Zeitvektors
 %Abfrage der Zeitdifferenz zwischen zwei Messungen
 
    
    while intervalltest==0
      printf("\n")
      printf("Bitte Zeitintervall zwischen zwei Messungen wählen. Angabe in Sekunden.\n")
      printf("\n");
      clear tint;
      tint = str2num(input("  Zeitintervall > ","c"));
      if length(tint)==0 || tint==0
        printf("Zeitintervall muss eine reelle Zahl ungleich Null sein.\n");
      else
        intervalltest=1;
      endif 
    endwhile
    
    timevec_csv=[];
    for i=0:columns(mdata_csv)-1
      timevec_csv=[timevec_csv,i*tint];
    endfor
    csvloaded=2;
  endif
%endfunction
