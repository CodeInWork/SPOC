function [time_, freq_, mdata_] = ir_join_wz(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2, blending = "none")



  # make time compatible
  if !isequal(time1, time2)
    printf("  Warning: dataset %d will be interpolated in time to match %d\n", 2, 1);
    printf("  Warning: dataset %d will be cropped in time to match %d\n", 1, 1);

    t1_up_idx = time_get_index(max(time2), time1);
    t1_lo_idx = time_get_index(min(time2), time1);
    t2_up_idx = time_get_index(max(time1), time2);
    t2_lo_idx = time_get_index(min(time1), time2);
    mdata1 = mdata1(:,t1_lo_idx:t1_up_idx);
    mdata2 = mdata2(:,t2_lo_idx:t2_up_idx);
    time1 = time1(t1_lo_idx:t1_up_idx);
    time2 = time2(t2_lo_idx:t2_up_idx);

    mdata2 = interp1(time2, mdata2', time1, "extrap")';
    time_ = time1(t1_lo_idx:t1_up_idx);
  else
    time_ = time1;
  endif;

  
  f1_lo = min(freq1);
  f1_up = max(freq1);
  f2_lo = min(freq2);
  f2_up = max(freq2);
  
  f1_lo_idx = get_index(f2_lo, freq1);
  f1_up_idx = get_index(f2_up, freq1);
  f2_lo_idx = get_index(f1_lo, freq2); 
  f2_up_idx = get_index(f1_up, freq2);   
  
  # frequency vector
  freq1_lo = freq1(1:f1_lo_idx-1);
  freq1_up = freq1(f1_up_idx+1:end);
  freq2_lo = freq2(1:f2_lo_idx-1);
  freq2_up = freq2(f2_up_idx+1:end);
  freq1_overlap = freq1(f1_lo_idx:f1_up_idx);
  
  freq_ = [freq1_lo; freq2_lo; freq1_overlap; freq1_up; freq2_up];
  
  # data
  mdata1_lo = mdata1(1:f1_lo_idx-1,:);    # part of mdata1 lower than mdata2
  mdata1_up = mdata1(f1_up_idx+1:end,:);  # part of mdata1 higher than mdata2
  mdata2_lo = mdata2(1:f2_lo_idx-1,:);    # part of mdata2 lower than mdata1
  mdata2_up = mdata2(f2_up_idx+1:end,:);  # part of mdata2 higher than mdata1    
  
  mdata1_overlap = mdata1(f1_lo_idx:f1_up_idx,:);
  mdata2_overlap = mdata2(f2_lo_idx:f2_up_idx,:);
  mdata2_overlap = interp1(freq2(f2_lo_idx:f2_up_idx), mdata2_overlap, freq1(f1_lo_idx:f1_up_idx),"extrap");
  
  if strcmp(blending, "linear")
    length_overlap = rows(mdata2_overlap);
    blend_func_rise = linspace(0,1,length_overlap);
    blend_func_fall = flip(blend_func_rise);

    blend_weight1 = weight2*blend_func_fall;
    blend_weight2 = weight1*blend_func_rise;
    overlap_data = (mdata1_overlap.*blend_weight2'+mdata2_overlap.*blend_weight1')./(blend_weight1'+blend_weight2');
    printf("  Linear blending of overlaping area will be computed.\n");
  else
    overlap_data = (mdata1_overlap*weight1+mdata2_overlap*weight2)/(weight1+weight2);
  endif

  # combine in frequency domain
	# mdata_ = [data1; overlap_data; data2];
  mdata_ = [mdata1_lo;mdata2_lo;overlap_data;mdata1_up;mdata2_up];

end;
