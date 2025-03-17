## Copyright (C) 2018 Administrator
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {} {@var{retval} =} makeDiffSpec (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Paul Fischer <Administrator@EXPBP119>
## Created: 2018-11-02

function [newMdata] = makeDiffSpec (mdata, timevec)
  zeroIdx = time_get_index(0, timevec);
  if (zeroIdx > 1)
    dunkel = mean(mdata(:,1:zeroIdx-2),2);
    for i=1:length(timevec)
      newMdata(:,i)=log10(dunkel./mdata(:,i));
    endfor
  endif;
endfunction
