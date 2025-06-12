function [time_, freq_, mdata_] = join_complete(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2)
  t1_lo = min(time1);
  t1_up = max(time1);
  t2_lo = min(time2);
  t2_up = max(time2);

  f1_lo = min(freq1);
  f1_up = max(freq1);
  f2_lo = min(freq2);
  f2_up = max(freq2);


  t1_lo_idx = time_get_index(t2_lo, time1);
  t1_up_idx = time_get_index(t2_up, time1);

  f1_lo_idx = ir_get_index(f2_lo, freq1);
  f1_up_idx = ir_get_index(f2_up, freq1);

  # interpolate mdata2 in time
  mdata1_overlap = mdata1(f1_lo_idx:f1_up_idx,t1_lo_idx:t1_up_idx);

  time1_overlap(t1_lo_idx:t1_up_idx);
  freq1_overlap(f1_lo_idx:f1_up_idx);

  mdata2 = interp1(time2, mdata2', time1_overlap, "extrap");
  mdata2 = interp1(freq2, mdata2, freq1_overlap, "extrap");

  # average with weights and blended weights



endfunction
