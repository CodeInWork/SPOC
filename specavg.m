function average_spec = specavg(datamatrix, timevec, tstart, tstop)
%
% 	function average_spec = specavg(datamatrix, timevec, tstart, tstop)
%

    vstart = time_get_index(tstart, timevec);
    vstop = time_get_index(tstop, timevec);
    average_spec = mean(datamatrix(:,tstart:tstop),2);

endfunction