function [time_, freq_, mdata_] = ir_join(time1,freq1,mdata1, time2, freq2, mdata2)

	time_ = [time1, time2];
	freq_ = freq1;
	
	mdata_ = [mdata1,interp1(freq2, mdata2, freq1)];
end;

	
	
	