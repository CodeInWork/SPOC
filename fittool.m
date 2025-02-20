% Fittool 
% Eingeben der Basisspektren,
% Dann können entweder einzelne spektren oder eine Matric eingegeben werden.
% Ausgabe erfolgt als Matrix (die Parameter)
% ggf residuen speichern
% benutzt:
% normalize
% specfit
% TODO: Parametergrenzen prüfen und ggf alle Spekten zurechtschneiden
%		Die Spektren werden auf das 1. Basisspektrum skaliert, daher muss dieses Spektrum am kürzesten sein.
% 		ggf vorher durchscannen

NOP=0;
SINGLE_FILE=1;
MULTIPLE_FILES=2;
MATRIX_SET=3;				% TODOTODOTODO
OPERATION_MODE=0;
RESTRICT_FIT=0;

zenity_message("Base Spectra");

basespectra_names = zenity_file_selection(".","multiple");

zenity_message("Spectra to fit");

work_names = zenity_file_selection(".","multiple");

% Bestimmung eines WZ-Vektors als Referenz
% Minimaler Vektor wird verwendet, alles Andere darauf interpolieren

[dummy1, dummy2] = load_ir_file(basespectra_names{1});
cur_max_bound= max(dummy1);
cur_min_bound = min(dummy1);
cur_step = dummy1(2) - dummy1(1);

for i=2:length(basespectra_names)
		[dummy1, dummy2] = load_ir_file(basespectra_names{i});
		if ( cur_max_bound > max(dummy1) ), cur_max_bound = max(dummy1); end;
		if ( cur_min_bound < min(dummy1) ), cur_min_bound = min(dummy1); end;
		if ( abs(cur_step) > abs(dummy1(2)-dummy1(1)) ), cur_step = dummy1(2)-dummy1(1); end;
end;


if ( iscell(work_names) == 1 )
	OPERATION_MODE=MULTIPLE_FILES;
	for i=1:length(work_names)
		[dummy1, dummy2] = load_ir_file(work_names{i});
		if ( cur_max_bound > max(dummy1) ), cur_max_bound = max(dummy1); end;
		if ( cur_min_bound < min(dummy1) ), cur_min_bound = min(dummy1); end;
		if ( abs(cur_step) > abs(dummy1(2)-dummy1(1)) ), cur_step = dummy1(2)-dummy1(1); end;	
	end;
else
	if ( strcmp(fileextension(work_names),"x3d")==1 )			% X3D Datei
		OPERATION_MODE=MATRIX_SET;
		%TODOTODOTODO
		[datawz_temp, xv, prelim_data] = load_csv_matrix(work_names);
		datamatrix = interp1(datawz_temp, prelim_data, basewz1);
		baseindex = xv;
		
	else
		OPERATION_MODE=SINGLE_FILE;
		[dummy1, dummy2] = load_ir_file(work_names);
		if ( cur_max_bound > max(dummy1) ), cur_max_bound = max(dummy1); end;
		if ( cur_min_bound < min(dummy1) ), cur_min_bound = min(dummy1); end;
		if ( abs(cur_step) > abs(dummy1(2)-dummy1(1)) ), cur_step = dummy1(2)-dummy1(1); end;	
	end;
end;

% cur_step = abs(cur_step)/4;				% Sampling theorem !!!
cur_step = abs(cur_step)/2;

printf("new scaling will be applied: [%f:%f:%f]\n", cur_min_bound, cur_step, cur_max_bound);
basewz1 = cur_min_bound:cur_step:cur_max_bound;


if (zenity_message("Limit fitting range?","question")==0)
	lower_fit_border = str2double(zenity_entry("lower border"));
	upper_fit_border = str2double(zenity_entry("upper border"));
	lower_index = get_index(lower_fit_border, basewz1);
	upper_index = get_index(upper_fit_border, basewz1);
	if ( lower_index > upper_index )
		dummy=lower_index;
		lower_index=upper_index;
		upper_index=dummy;
	end;
	RESTRICT_FIT=1;									% Gewichtungsevektor konstruieren
													% TODO: an Specfit übergeben
end;


% basematrix und datamatrix bauen
% datamatrix ist basewz1 x baseindex1

for i=1:length(basespectra_names)
		[basewz_x, basedat_x] = load_ir_file(basespectra_names{i});
		basematrix(:,i) = interp1(basewz_x, basedat_x, basewz1);
end;



if ( iscell(work_names)==1 )			% mehrere einzelne Dateien
	for i=1:length(work_names)
		[datawz_temp, data_temp]  = load_ir_file(work_names{i});
		datamatrix(:,i) = interp1(datawz_temp, data_temp, basewz1);
		baseindex(i) = i;
	end;
else								% 1 Dat-Datei oder 1 x3d Datei
	if ( strcmp(fileextension(work_names),"x3d")==1 )			% X3D Datei
		[datawz_temp, xv, prelim_data] = read_data(work_names);
		datamatrix = interp1(datawz_temp, prelim_data, basewz1);
		baseindex = xv;
	else												% 1 Dat-datei
		[datawz_temp, prelim_data] = load_ir_file(work_names);
		datamatrix(:,1) = interp1(datawz_temp, prelim_data, basewz1);
		baseindex(1)=1;
	end;
end;

% ggf noch normieren

if (RESTRICT_FIT==1)									% TODO: weights an specfit übergeben!
	WEIGHTS = zeros(size(basewz1));
	WEIGHTS(lower_index:upper_index)=1;
	[parametermatrix, fitted_data_matrix] = specfit(basematrix, datamatrix, WEIGHTS);
else
	[parametermatrix, fitted_data_matrix] = specfit(basematrix, datamatrix);
end;

difference_matrix = datamatrix .- fitted_data_matrix;

if (zenity_message("Save calculated data?","question")==0)
	base_filename = zenity_entry("Filename:");
	% Parametermatrix speichern: ( Die Spalten sind die Parameter für die einzelnen gefitteten Dateien
	dummy = sprintf("%s.parameter.dat",base_filename);
	fout = fopen(dummy,"w");
	dz = "# Basespectra:";
	for i=1:length(basespectra_names)
		dz=sprintf("%s %d %s", dz, i, basespectra_names{i});
	end;
	dz=sprintf("%s\n",dz);
	fprintf(fout,dz);
	if (OPERATION_MODE==MULTIPLE_FILES)
		dz = "#";
		for i=1:length(work_names)
			dz=sprintf("%s %s",dz,work_names{i});
		end;
		dz=sprintf("%s\n",dz);
		fprintf(fout,dz);
		for j=1:length(basespectra_names)
			dz = sprintf("%d",j);
			for i=1:length(work_names)
				dz=sprintf("%s %f",dz, parametermatrix(j,i));
			end;
			dz=sprintf("%s\n",dz);
			fprintf(fout,dz);
		end;
		% Gefittete Spektren und Doppeldifferenzen speichern
		for i=1:length(work_names)
			dummy = sprintf("%s_%s.FITTED.dat", base_filename, basename(work_names{i}));
			save_ir_file(dummy,basewz1, fitted_data_matrix(:,i));
			dummy = sprintf("%s_%s.RESIDUAL.dat", base_filename, basename(work_names{i}));
			save_ir_file(dummy,basewz1, difference_matrix(:,i));
		end;
	elseif (OPERATION_MODE==SINGLE_FILE)
		for j=1:length(basespectra_names)
			dz=sprintf("%d %f\n",j, parametermatrix(j));
			fprintf(fout,dz);
		end;
		dummy = sprintf("%s_%s.FITTED.dat", base_filename, basename(work_names));
		save_ir_file(dummy,basewz1, fitted_data_matrix(:,1));
		dummy = sprintf("%s_%s.RESIDUAL.dat", base_filename, basename(work_names));
		save_ir_file(dummy,basewz1, difference_matrix(:,1));
	elseif (OPERATION_MODE==MATRIX_SET)
		dz = "#PARAMETER";
		% Indexvektor schreiben, derselbe wie von der x3d Datei
		for i=1:length(xv)
			dz=sprintf("%s %f", dz, xv(i));
		end;
		dz=sprintf("%s\n",dz);
		fprintf(fout, dz);
		for i=1:length(basewz1)
			dz = sprintf("%f", basewz1(i));
			for j=1:length(xv)
				dz=sprintf("%s %f", dz, parametermatrix(i,j) );
			end;
			dz=sprintf("%s\n");
			fprintf(fout, dz);
		end;
		printf("function not available\n");
	end;
	fclose(fout);
end;

