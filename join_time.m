function [time_, freq_, mdata_] = join_time(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2, blending)

  # make frequencies compatible
  if !isequal(freq1, freq2)
    printf("  Warning: dataset %d will be interpolated in frequency domain to match %d\n", 2, 1);
    printf("  Warning: dataset %d will be cropped in frequency domain to match %d\n", 1, 1);

    f1_up_idx = ir_get_index(max(freq2), freq1);
    f1_lo_idx = ir_get_index(min(freq2), freq1);
    f2_up_idx = ir_get_index(max(freq1), freq2);
    f2_lo_idx = ir_get_index(min(freq1), freq2);
    mdata1 = mdata1(f1_lo_idx:f1_up_idx,:);
    mdata2 = mdata2(f2_lo_idx:f2_up_idx,:);
    freq1 = freq1(f1_lo_idx:f1_up_idx);
    freq2 = freq2(f2_lo_idx:f2_up_idx);

    mdata2 = interp1(freq2, mdata2, freq1, "extrap");
    freq_ = freq1(f1_lo_idx:f1_up_idx);
  else
    freq_ = freq1;
  endif;

  
  t1_lo = min(time1);
  t1_up = max(time1);
  t2_lo = min(time2);
  t2_up = max(time2);
  
  t1_lo_idx = get_index(t2_lo, time1);
  t1_up_idx = get_index(t2_up, time1);
  t2_lo_idx = get_index(t1_lo, time2); 
  t2_up_idx = get_index(t1_up, time2);   
  
  # time vector
  time1_lo = time1(1:t1_lo_idx-1);
  time1_up = time1(t1_up_idx+1:end);
  time2_lo = time2(1:t2_lo_idx-1);
  time2_up = time2(t2_up_idx+1:end);
  time1_overlap = time1(t1_lo_idx:t1_up_idx);
  
  time_ = [time1_lo, time2_lo, time1_overlap, time1_up, time2_up];
  
  # data
  mdata1_lo = mdata1(:,1:t1_lo_idx-1);    # part of mdata1 lower than mdata2
  mdata1_up = mdata1(:,t1_up_idx+1:end);  # part of mdata1 higher than mdata2
  mdata2_lo = mdata2(:,1:t2_lo_idx-1);    # part of mdata2 lower than mdata1
  mdata2_up = mdata2(:,t2_up_idx+1:end);  # part of mdata2 higher than mdata1    
  
  mdata1_overlap = mdata1(:,t1_lo_idx:t1_up_idx);
  mdata2_overlap = mdata2(:,t2_lo_idx:t2_up_idx);
  mdata2_overlap = interp1(time2(t2_lo_idx:t2_up_idx), mdata2_overlap', time1(t1_lo_idx:t1_up_idx),"extrap")';
  
  if strcmp(blending, "linear")
    length_overlap = columns(mdata2_overlap);
    blend_func_rise = linspace(0,1,length_overlap);
    blend_func_fall = flip(blend_func_rise);

    blend_weight1 = weight2*blend_func_fall;
    blend_weight2 = weight1*blend_func_rise;
    overlap_data = (mdata1_overlap.*blend_weight2+mdata2_overlap.*blend_weight1)./(blend_weight1+blend_weight2);
    printf("  Linear blending of overlaping area will be computed.\n");
  else
    overlap_data = (mdata1_overlap*weight1+mdata2_overlap*weight2)/(weight1+weight2);
  endif

  # combine in time domain
  mdata_ = [mdata1_lo,mdata2_lo,overlap_data,mdata1_up,mdata2_up];


endfunction
