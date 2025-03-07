# Substring liefert den nten teilstring (abgegrenzt durch leerzeichen

function retval = substring(string, nummer)
  [n,v] = splitstr(string);
  if (nummer>n)
    retval="";
  else
    retval = v{nummer};
  endif;
endfunction

