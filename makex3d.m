% Reads spectra from ASCII(CSV), interpolates them according to a reference,
% calculates a matrix in the x3d-format in the form:
%	#OPUS	WZ1	WZ2	WZ3
%	t1		...
%	t2		...
%	t3		...
% 
% The reference is not included in the data.

zenity_message("Select Reference:");
ref = zenity_file_selection("Reference",".");

zenity_message("Select Data:");
dl = zenity_file_selection("Data",".","multiple");

[referenz, dummy] = convert_file_path(ref);
[dateiliste, ordner] = convert_file_path(dl);

cd (ordner);					% Ergebnis gleich hier speichern


% Referenz in referenz, Files in dateiliste


[wlref, dnref] = load_ir_file(referenz);
data = zeros(length(dateiliste), length(wlref));

for i=1:length(dateiliste)
	[wzr, dnr] = load_ir_file(dateiliste{i});
	dn = interp1(wzr, dnr, wlref);
	data(i,:) = dn;
	indx(i)=i;
end;

if (0==zenity_message("Change independent variable?","question"))
	for i=1:length(dateiliste)
		dummy = sprintf("%d: %s", i, dateiliste{i});
		indx(i) = str2num(zenity_entry(dummy));
	end
end

if (0==zenity_message("Sort data according to independent variable?","question"))
	% sort according to index...
	indx_min = indx(1);
	do
		swapp=0;
		for i=1:length(dateiliste)-1
			if ( indx(i)>indx(i+1) )
				indx_bak=indx(i);
				indx(i)=indx(i+1);
				indx(i+1)=indx_bak;
				dateiliste_bak=dateiliste{i};
				dateiliste{i}=dateiliste{i+1};
				dateiliste{i+1}=dateiliste_bak;
				data_bak=data(i,:);
				data(i,:)=data(i+1,:);
				data(i+1,:)=data_bak;
				swapp=1;
			end
		end
	until (swapp==0)
end;

if (0==zenity_message("Normalize Spectra?","question"))
	norm1wl = str2num(zenity_entry("Frequency Range Start:"));
	norm2wl = str2num(zenity_entry("Frequency Range Stop:"));

	data=data';

	inorm1=ir_get_index(norm1wl, wlref);
	inorm2=ir_get_index(norm2wl, wlref);

	normdiff = dnref(inorm2)-dnref(inorm1);

	for i=1:length(dateiliste)
		[data(:,i), scale_temp, offset_temp] = normalize(wlref,data(:,i),wlref,dnref,norm1wl,norm2wl);
	end;
	
	data=data';

end

jn = zenity_message("Write Data to File?","question");

if (jn==0)
	outname = zenity_entry("Select Filename");
	% Datei schreiben...
  if (ispc())
    outname=outname(1:length(outname)-1);
  end;
	fd = fopen(outname,"w");
	fprintf(fd,"#OPUS");
	for wz=1:length(wlref)
		fprintf(fd," %f", wlref(wz));
	end;
	fprintf(fd,"\n");
	for spektrum=1:length(dateiliste)
		fprintf(fd,"%f",indx(spektrum));
		for wz=1:length(wlref)
			fprintf(fd, " %f", data(spektrum, wz));
		end;
		fprintf(fd,"\n");
	end;
end;

printf("Data in <<data>>, Frequency/ Wavenumbers in <<wlref>>, Indexdata in <<indx>>\n");
printf("Returning to Octave\n");



