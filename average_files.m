function [wzvector, kineticsx, irdata, filetype_name] = average_files(dateiliste);
	%dateiliste = zenity_file_selection(".","multiple");
	av_error=0;
	[wzvector, kineticsx, irdata, filetype_name] = read_data(dateiliste{1});
	for i=2:length(dateiliste)
		[wzvn, kn, idn, ftn] = read_data(dateiliste{i});
		if (length(wzvn)==length(wzvector))
			if (length(kn)==length(kineticsx))
				if (strcmp(ftn,filetype_name))
					wzvector+=wzvn;
					kineticsx+=kn;
					irdata+=idn;
				else
					printf("  average_files: Dateitypen stimmen nicht überein!\n");
					av_error=1;
				end;
			else
				printf("  average_files: Keine Übereinstimmung der Zeitachse\n");
				av_error=1;
			end;
		else
			printf("  average_files: Keine Übereinstimmung der Frequenzachse\n");
			av_error=1;
		end;
		if (av_error==1); break; end;
	end;
	if (av_error==0)
		wzvector = wzvector./length(dateiliste);
		kineticsx = kineticsx./length(dateiliste);
		irdata = irdata ./ length(dateiliste);
	else
		printf("Funktion abgebrochen\n");
	end;
end;
