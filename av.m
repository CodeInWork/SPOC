function mw = av(time_start, time_stop)
%function mw = av(time_start, time_stop)
% function for spoc; averages the spectra in the time range between time_start and time_stop and returns
% the data in a varibale. Could be used together with p exp
%
    global mdata;
    global timevec;
    global freqvec;
    index_start = time_get_index(time_start, timevec);
    index_stop = time_get_index(time_stop, timevec);
    mw = mean(mdata(:,index_start:index_stop),2);
endfunction