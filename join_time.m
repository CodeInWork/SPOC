function [time_, freq_, mdata_] = join_time(time1, freq1, mdata1, weight1, time2, freq2, mdata2, weight2)

  mat1 = max(time1);
  mat2 = max(time2);
  mit1 = min(time1);
  mit2 = min(time2);


  if (mat1 <= mat2 && mit1 <= mit2)       # set 2 later than 1
    t2_idx = time_get_index(mat1, time2);
    t1_idx = time_get_index(mit2, time1);
    time2_nonoverlapp = time2(t2_idx+1:end);
    time_join = [time1, time2_nonoverlapp];

    mdata1_overlapp = mdata1(:, t1_idx:end);
    mdata2_overlapp = mdata2(:, 1:t2_idx);
    mdata2_overlapp_comp = interp1(time2(1:t2_idx), mdata2_overlapp', time1(t1_idx:end),"extrap");

    data1 = mdata1(:, 1:t1_idx-1);
    overlap_data = (mdata1(:,t1_idx:end)*weight1+ mdata2_overlapp_comp'*weight2)/(weight1+weight2);
    data2 = mdata2(:,t2_idx+1:end);

  elseif (mat1 >= mat2 && mit1 >= mit2)   # set 1 later than 2
    t2_idx = time_get_index(mit1, time2);
    t1_idx = time_get_index(mat2, time1);
    time2_nonoverlapp = time2(1:t2_idx-1);
    time_join = [time2_nonoverlapp, time1];

    mdata1_overlapp = mdata1(:, 1:t1_idx);
    mdata2_overlapp = mdata2(:, t2_idx:end);
    mdata2_overlapp_comp = interp1(time2(t2_idx:end), mdata2_overlapp', time1(1:t1_idx),"extrap");

    data1 = mdata2(:,1:t2_idx-1);
    overlap_data = (mdata1(:,1:t1_idx)*weight1+mdata2_overlapp_comp'*weight2)/(weight1+weight2);
    data2 = mdata1(:,t1_idx+1:end);

  elseif (mat1 >= mat2 && mit1 <= mit2)   # set 2 complete time subset of 1
    time_join = time1;
    t1_idx1 = time_get_index(mit2, time1);
    t1_idx2 = time_get_index(mat1, time1);

    mdata1_overlapp = mdata1(:, t1_idx1:t1_idx2);
    mdata2_overlapp_comp = interp1(time2, mdata2', time1(t1_idx1:t1_idx2),"extrap");

    data1 = mdata1(:,1:t1_idx1-1);
    overlap_data = (mdata1(:,t1_idx1:t2_idx2)*weight1+mdata2_overlapp_comp'*weight2)/(weight1+weight2);
    data2 = mdata1(:, t1_idx2+1:end);

  else                                    # set 1 complete time subset of 2
    t2_idx1 = time_get_index(mit1, time2);
    t2_idx2 = time_get_index(mat1, time2);
    time2_low = time2(1:t2_idx1-1);
    time2_high = time2(t2_idx2+1:end);
    time_join = [time2_low, time1, time2_high];

    mdata2_overlapp = mdata2(:, t2_idx1:t2_idx2);
    mdata2_overlapp_comp = interp1(time2(t2_idx1:t2_idx2), mdata2_overlapp', time1,"extrap");

    data1 = mdata2(:,1:t2_idx1-1);
    overlap_data = (mdata1*weight1+mdata2_overlapp_comp'*weight2)/(weight1+weight2);
    data2 = mdata2(:, t2_idx2+1:end);

  endif

  time_ = time_join;
  freq_ = freq1;
  mdata_ = [data1, overlap_data, data2];


endfunction
