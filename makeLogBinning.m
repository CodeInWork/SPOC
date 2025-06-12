## Copyright (C) 2023 Paul
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {} {@var{retval} =} makeLogBinning (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Paul <Paul@PAUL-PC>
## Created: 2023-11-20

function [redData, redTime] = makeLogBinning (data, timevec, startIdx)
          
          step=10;
          tpts = length(timevec);
          
          
          %from data begin to reaction start +10 time points original data is copied without compression
          
          %while (i<sidx+step)       
          %  redTime(j)=timevec(i);
          %  redData(:,j)=data(:,i);
          %  if (i==sidx), new_sidx=j; end;
          %  j++;
          %  i++;
          %endwhile;
          redTime = timevec(1:startIdx);
          redData = data(:,1:startIdx);
          
          j=startIdx+1; i=startIdx+1;
          
          bin=0; k=0;
          while(i+2^bin-1<tpts)
            redTime(j) = mean(timevec(i:i+2^bin-1));
            redData(:,j)=mean(data(:,i:i+2^bin-1),2);
            j++;k++;
            i=i+2^bin;
            if(k==step)
               bin++; k=0;
            endif;
          endwhile;
          
endfunction
