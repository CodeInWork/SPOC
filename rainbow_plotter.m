function rainbow_plotter(x,y,legends,line_thickness)
% function rainbow_plotter(x,y)
% plots a matrix columnwise with automatic colors
	col = [0,0,1];            % color to start with (violet)
	lines = columns(y);
  step = 5 / lines;         % v->b->c->y->r
  coli = [0,step,0];
  thickness=1;
	if ( nargin > 3)
			thickness = line_thickness;
	end;
	hold on;

  for i=1:lines
    if ( nargin > 2 )                             % Plots the current line
			dummy = sprintf("-;%s;",legends{i});
			plot(x,y(:,i),dummy,"LineWidth",thickness,"Color",col);
		else
			plot(x,y(:,i),"LineWidth",thickness,"Color",col);
		endif;
                                                  % apply color change
      col=col+coli;

     if ( col(2)>1 )
          dc = col(2)-1;
          col(2)=1;
          col(3)=col(3)-dc;
          coli=[0,0,-step];
      endif
      if ( col(3)<0 )
          dc = -col(3);
          col(3)=0;
          col(1)=col(1)+dc;
          coli=[step,0,0];
      endif
      if ( col(1)>1 )
          dc = col(1)-1;
          col(1)=1;
          col(2)=col(2)-dc;
          coli=[0,-step,0];
      endif
      if ( col(2)<0 )
          dc = -col(2);
          col(2)=0;
          col(3)=col(3)+dc;
          coli=[0,0,step];
      endif;

  endfor
endfunction
