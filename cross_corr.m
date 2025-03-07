function [ X ] = cross_corr(k, v)
%
%    calculates the cross correlation function X = Sum_k[V_ki V_k+1,j] of the matrix V
  n=length(k);
  X=zeros(n,n)
  for j=1:n-1
    for i=1:n-1
      X(i,j)=X(i,j)+V(k(i),i)*V(k(i)+1,j)
    endfor
  endfor
endfunction
