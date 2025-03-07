function timesteps = get_timesteps(timevec)
%  Erzeugt einen Vektor, der die Positionen enthält, an denen ein Zeitsprung stattfindet
	timesteps(1)=1;				% IMMER
	nrsteps=1;
	for i=2:length(timevec)
		if timevec(i)<timevec(i-1)
			nrsteps++;
			timesteps(nrsteps)=i;
		end;
	end;
end;
