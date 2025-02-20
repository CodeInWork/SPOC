
dateiliste = zenity_file_selection(".","multiple");
[frequencies, timepoints, data, filetype] = average_files(dateiliste);
filename = zenity_entry("Dateiname für Mittelwert");

save_csv_matrix(filename, frequencies, timepoints, data);


