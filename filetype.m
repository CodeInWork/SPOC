function ft = filetype(name)
%
% ft = filetype(name)
%
%  returns the first string of the file 
%
    global global_error;
    
    liste = fopen(name,"r");
    
    if (liste!=-1)
	ft = fscanf(liste,"%s","C");
	fclose(name);
    else
	global_error = 1;
	ft = "no_file";
    endif;
endfunction;
    