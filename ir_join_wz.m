function [time_, freq_, mdata_] = ir_join_wz(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2, freq)

	time_ = time1;
  freq_ = freq;
  mdata1_overlapp=mdata1;

  if(min(freq1)<=min(freq2) && max(freq1)<=max(freq2))
    overlap_idx1 = get_index(min(freq2), freq1);
    overlap_idx2 = get_index(max(freq1), freq2);
    data1 = mdata1(1:overlap_idx1-1,:);
    mdata1_overlapp = mdata1(overlap_idx1:end,:);
    mdata2_overlapp = mdata2(1:overlap_idx2,:);
    mdata2_overlapp_comp = interp1(freq2(1:overlap_idx2), mdata2_overlapp, freq1(overlap_idx1:end),"extrap");

    overlap_data = (mdata1_overlapp*weight1+mdata2_overlapp_comp*weight2)/(weight1+weight2);
    data2 = mdata2(overlap_idx2+1:end,:);

  elseif(min(freq1)>=min(freq2) && max(freq1)>=max(freq2))
    overlap_idx1 = get_index(max(freq2), freq1);
    overlap_idx2 = get_index(min(freq1), freq2);
    data1 = mdata2(1:overlap_idx2-1,:);

    mdata1_overlapp = mdata1(1:overlap_idx1,:);
    mdata2_overlapp = mdata2(overlap_idx2:end,:);
    mdata2_overlapp_comp = interp1(freq2(overlap_idx2:end), mdata2_overlapp, freq1(1:overlap_idx1),"extrap");

    overlap_data = (mdata1_overlapp*weight1+mdata2_overlapp_comp*weight2)/(weight1+weight2);
    data2 = mdata1(overlap_idx1+1:end,:);
  endif;

	mdata_ = [data1; overlap_data; data2];
end;
