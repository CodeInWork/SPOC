function yn = monoexponential(x,p)
	yn=p(1)+p(2)*(1-exp(-p(3)*x));
end;
