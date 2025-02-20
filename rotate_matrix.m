function [R,l]=rotate_matrix(V, rotation_order)
    if (nargin<2) ; rotation_order = 1; end;
    for i=1:min(size(V))
	for j=1:min(size(V))
	    X(i,j) = 0;
    	    for k=1:(max(size(V))-rotation_order)
        	X(i,j) = X(i,j) + V(k,i)*V(k+rotation_order,j);
    	    end
	end
    end
    Xs=(X+X')./2;

    [R1,l1]=eig(Xs);

    R = fliplr(R1);
    l = flipud(fliplr(l1));
end
