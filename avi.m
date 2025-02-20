function mw = avi(index_start, index_stop)
%
% Die Spektren einer 3D Datei werden im angegebenen Bereich gemittelt und in eine Variable geschrieben
%
    global mdata;
    global timevec;
    global freqvec;
    mw = mean(mdata(:,index_start:index_stop),2);
endfunction