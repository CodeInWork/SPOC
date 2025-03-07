function retval = svd_autocorr(matrix, vektoren, order)
%
%  function retval = svd_autocorr(matrix [, vektoren[, order]])
%	berechnet die AKF der Ordnung <order> der ersten <vektoren> Spalten
%	einer Matrix
%
    if (nargin<3), order = 1; end
    if (nargin<2), vektoren = columns(matrix); end
    for i=1:vektoren
	retval(i) = 0;
	for j=1:(rows(matrix)-order)
	    retval(i) = retval(i) + (matrix(j,i)*matrix(j+order,i));
	end
    end
end
