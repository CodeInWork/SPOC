function rv = compress_ws(data)
% function rv = compress_ws(data)
% removes unnecessary whitespaces from a string

    i = 1;
    trenner = " ";		% Change this for Windows

    do
	if ( (data(i) == trenner) && ( data(i+1) == trenner ) )
		%printf("Leerzeichen wird entfernt: %d: [%s]\n", length(data), data);
		data(i+1)=[]; 
		%printf("Laenge neu: %d: [%s]\n", length(data),data);
	elseif ( (data(i)==trenner) && i==1 )
		data(i)=[];
	else
		i++;
	end;
	% i
	% data
	% printf("Position: %d of %d\n", i, length(data));
	% printf("\n");
    until ( i>(length(data)-1) );
    if (data(length(data))==trenner); data(length(data))=[]; end; 
    rv = data;
end;
