function [ filename, filepath ] = convert_file_path(listenname) 
% [ filename, filepath ] = function convert_win_path(filen) 

	if  (ispc())				% Windows schreibt LW in anderes Feld
		ctr=1;
		ctr2=1;
		do
			lsn=sprintf("%s:%s", listenname{ctr}, listenname{ctr+1});
			%lsn=lsn(1:length(lsn)-1);
																% mit cd in ensprechendes Verzeichnis springen
			foldername = lsn;
			l = length(foldername);
			done = 0;
			do
				ll = foldername(l);
				if ( ll=='\\' )
					foldername(l)=[];
					done=1;
				else
					foldername(l)=[];
				end;
				l=l-1;
			until (done==1);
			if ( length(listenname) == 2)
				fnam=lsn(1:length(lsn)-1);
			else
				if ( (ctr+2) > length(listenname) ), lsn=lsn(1:length(lsn)-1); end;		% Workaround fuer Zenity Fehler
				fnam{ctr2}=lsn;
			end;
			ctr=ctr+2;
			ctr2=ctr2+1;
		until ( ctr > length(listenname) );
		
			%cd (foldername);
	else
			fnam=listenname;											% hier ok
			if ( iscell(listenname) )
				foldername = listenname{1};									% Unter Linux mit CD ins Verzeichnis...
			else
				foldername = listenname;
			end;
			l = length(foldername);
			done = 0;
			do
				ll = foldername(l);
				if ( ll=='/' )
					foldername(l)=[];
					done=1;
				else
					foldername(l)=[];
				end;
				l=l-1;
			until (done==1);
			%cd (foldername);
	end;
	filename=fnam;
	filepath = foldername;											% fuer Foldername immer nur der letzte!
end;

