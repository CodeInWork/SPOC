function fe = fileextension(testname)
% Liefert den Teil des Strings nach letztem . zurueck
	i = length(testname);
	do
		i=i-1;
	until ( (testname(i)=='.') || i==1 );
	if (i>1)
		fe = testname(i+1:end);
	else
		fe = testname;
	end;
endfunction
