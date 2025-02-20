function num = numinput(text, predefined)
  fflush(stdout);
  printf("%s [%f] > ", text, predefined);
  zz = input("");
  if ( length(zz)>0 )
    num = zz;
  else
    num = predefined;
  end;
endfunction;
