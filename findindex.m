function index = findindex(zahl, vector)
    difference = inf;
    position = 1;
    nearest_element = 1;
    do
	diffneu = abs( vector(position) - zahl );
	if (diffneu < difference)
	    difference = diffneu;
	    nearest_element = position;
	end;
	position++;
    until (position>length(vector))
    index = nearest_element;
end;
