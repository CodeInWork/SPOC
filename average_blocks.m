
% average blocks of spectra after zero time point

function [ new_mdata, new_timevec ] = average_blocks(mdata, timevec, numOfSpec2av)
    [zero_idx, real_val] = time_get_index(0, timevec);

    if zero_idx>0
      new_mdata(:,1:zero_idx-1)=mdata(:,1:zero_idx-1);
      new_timevec(1:zero_idx-1)=timevec(1:zero_idx-1);
    endif

    length=length(timevec);
    i=zero_idx;
    j=zero_idx;
    while(i+numOfSpec2av-1<=length)
       new_mdata(:,j)=mean(mdata(:,i:i+numOfSpec2av-1),2);
       new_timevec(j)=mean(timevec(i:i+numOfSpec2av-1));
       i+=numOfSpec2av;
       j+=1;
    endwhile


endfunction
