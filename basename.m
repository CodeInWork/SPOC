function neu = basename(alt)
%
% Liefert den reinen Dateinamensanteil eines Unix-Pfades
%
		position = 1;
		if (ispc()==1)
			trenner = "\\";
		else
			trenner = "/";		% Change this for Windows
		end;
		for i=1:length(alt)
			if ( alt(i) == trenner ); position=i+1; end;
	neu = alt(position:end);
end;
