function [time_, freq_, mdata_] = ir_join_wz(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2, freq, blending = "none")

	time_ = time1;
  freq_ = freq;
  mdata1_overlap=mdata1;

  # make time compatible
  if !isequal(time1, time2)
    printf("  Warning: dataset %d will be interpolated in time to match %d\n", js2, js1);
    printf("  Warning: dataset %d will be cropped in time to match %d\n", js1, js2);

    t1_lo_idx = time_get_index(min(time2), time1);
    t1_up_idx = time_get_index(max(time2), time1);

    time1_overlap =  time1(t1_lo_idx:t1_up_idx);
    mdata2 = interp1(time2, mdata2', time1_overlap, "extrap");
    mdata1 = mdata1(:,t1_lo_idx:t1_up_idx); # reduce dataset 1 to match 2
  endif;

  if(min(freq1)<=min(freq2) && max(freq1)<=max(freq2))
    overlap_idx1 = get_index(min(freq2), freq1);
    overlap_idx2 = get_index(max(freq1), freq2);
    data1 = mdata1(1:overlap_idx1-1,:);
    mdata1_overlap = mdata1(overlap_idx1:end,:);
    mdata2_overlap = mdata2(1:overlap_idx2,:);
    mdata2_overlap_comp = interp1(freq2(1:overlap_idx2), mdata2_overlap, freq1(overlap_idx1:end),"extrap");

    if strcmp(blending, "linear")
      length_overlap = rows(mdata2_overlap_comp);
      blend_func_rise = linspace(0,1,length_overlap);
      blend_func_fall = flip(blend_func_rise);

      blend_weight1 = weight1*blend_func_fall;
      blend_weight2 = weight2*blend_func_rise;
      overlap_data = (mdata1_overlap.*blend_weight1'+mdata2_overlap_comp.*blend_weight2')./(blend_weight1'+blend_weight2');
      printf("  Linear blending of overlaping area will be computed.\n");
    else
      overlap_data = (mdata1_overlap*weight1+mdata2_overlap_comp*weight2)/(weight1+weight2);
    endif

    data2 = mdata2(overlap_idx2+1:end,:);

  elseif(min(freq1)>=min(freq2) && max(freq1)>=max(freq2))
    overlap_idx1 = get_index(max(freq2), freq1);
    overlap_idx2 = get_index(min(freq1), freq2);
    data1 = mdata2(1:overlap_idx2-1,:);

    mdata1_overlap = mdata1(1:overlap_idx1,:);
    mdata2_overlap = mdata2(overlap_idx2:end,:);
    mdata2_overlap_comp = interp1(freq2(overlap_idx2:end), mdata2_overlap, freq1(1:overlap_idx1),"extrap");

    if strcmp(blending, "linear")
      length_overlap = rows(mdata2_overlap_comp);
      blend_func_rise = linspace(0,1,length_overlap);
      blend_func_fall = flip(blend_func_rise);

      blend_weight1 = weight2*blend_func_fall;
      blend_weight2 = weight1*blend_func_rise;
      overlap_data = (mdata1_overlap.*blend_weight2'+mdata2_overlap_comp.*blend_weight1')./(blend_weight1'+blend_weight2');
      printf("  Linear blending of overlaping area will be computed.\n");
    else
      overlap_data = (mdata1_overlap*weight1+mdata2_overlap_comp*weight2)/(weight1+weight2);
    endif

    data2 = mdata1(overlap_idx1+1:end,:);
  endif;

  # combine in frequency domain
	mdata_ = [data1; overlap_data; data2];
  # combine in time domain
  # mdata_ = [mdata1(:,1:t1_lo_idx-1), mdata_freq, mdata1(:,t1_up_idx+1:end)];
end;
