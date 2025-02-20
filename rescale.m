function new_scale = rescale(old_scale, start, stop)
  v_size = length(old_scale);
  vd_size = stop-start;
  vd_incr = vd_size / (v_size-1);
  new_scale = start:vd_incr:stop;
endfunction