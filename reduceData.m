## Function to reduce the size of a data set along the time axis. For UV-Vis data sets with uncertain reaction start
## Example: step = 10;
##          timevec=[1,..,1000]
##          compressed by factor 1: 1..10   (uncompressed)
##          compressed by factor 2: 11..100
##          compressed by factor 4: 101..1000


## Author: Paul Fischer
## Created: 2018-11-09

function [redData,redTime, new_sidx] = reduceData (data, timevec, sidx, step)
  %Error margins for reaction start index (sidx)
  upper_margin=20;
  lower_margin=11;
  
  if(sidx>1)
    if ( nargin < 4 ), step = 10; end;

    j=1; i=1;
    tpts = length(timevec);
    while (i+step<sidx-lower_margin)   %4 is lower error margin of reaction start idx
      redTime(j)=mean(timevec(i:i+step));
      redData(:,j)=mean(data(:,i+step),2);
      j++;
      i=i+step+1;
    endwhile
    
    redTime(j)=mean(timevec(i:sidx-lower_margin-1));
    redData(:,j)=mean(data(:,i:sidx-lower_margin-1),2);
    j++;
    i=sidx-lower_margin;
    
    %inbetween sidx-lower_margin to sidx+upper_margin-1 original data is copied without compression
    while (i<sidx+upper_margin)       
      redTime(j)=timevec(i);
      redData(:,j)=data(:,i);
      if (i==sidx), new_sidx=j; end;
      j++;
      i++;
    endwhile;
    
    while (i+step<tpts)
      step=floor(log2(i-sidx+11));
      redTime(j)=mean(timevec(i:i+step));
      redData(:,j)=mean(data(:,i+step),2);
      j++;
      i=i+step+1;
    endwhile;
  else
    printf("Warning: REACTION_START_INDEX is not set or 1\n")
    printf("set REACTION_START_INDEX vie <ad> or manually and try again\n")
  endif;
endfunction;