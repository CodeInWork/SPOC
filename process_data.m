function [wzvector, kineticsx, irdata, timesteps] = process_data(wzvector, kineticsx, irdata, pd_mode)
% function [wzvector, kineticsx, irdata, timesteps] = process_data(wzvector, kineticsx, irdata, pd_mode)
%  Fuehrt einzelne Korrekturfunktionen an einem Datensatz durch
%  Korrektur auf reset timebase
%  Achtung: nur der 1. Zeitsprung wird korrigiert!!!

	if ( nargin < 4), pd_mode = 0; end

	nr_timesteps = 0;		% sollte in read_data integriert werden
	timesteps(1)=1;		% Diese Variable be
	for i=2:length(kineticsx)-1					% i.e. über process_data
		if ( kineticsx(i) <= kineticsx(i-1) )			% TODO: keep original space - necessary? possible?
			nr_timesteps++;
			timesteps(nr_timesteps+1) = i;		% Wo tritt der Sprung auf?
			if ( nr_timesteps == 1)												% nur beim 1ten Sprung Vorperiode �ndern
				reaction_dt_pre = (kineticsx(i-1) - kineticsx(i-2))/2;						% Letzte halbe Intervall�nge
				time_offset = kineticsx(i-1)+reaction_dt_pre;							% Zeiz zwischen letztem alten und 1. neuen
				kineticsx(1:i-1)=kineticsx(1:i-1)-time_offset;							% Vorperiode ok., Nachperiode muss nicht geaendert werden
				printf("  process_data: Erster Zeitsprung: Reaktionsstart: index=%d\n", i);
			else
				% printf("  Modul process_data.m: Warnung: reset timebase mehrfach vorhanden\n  Nur erster Sprung wird auf 0 gesetzt\n");
				if ( pd_mode == 1 )												% alles sequentiell anordnen, dann keine automatische Aufspaltung
					reaction_dt_pre = (kineticsx(i-1) - kineticsx(i-2))/2;					% Letzte halbe Intervall�nge
					reaction_dt_aft = (kineticsx(i+1) - kineticsx(i))/2;					% Neue halbe Intervall�nge
					printf(" Position %i: dt_pre=%f, dt_aft=%f\n", i, reaction_dt_pre, reaction_dt_aft);
					time_offset = kineticsx(i-1)+reaction_dt_pre+reaction_dt_aft;			% Zeiz zwischen letztem alten und 1. neuen
					printf("Korrigiere Offset: %f\n", time_offset);														% realen Versatz bestimmen (Welche Zeit nach reset_timebase? -  scheint mit 0 zu starten
					%%printf("Vorher:\n");
					%%kineticsx(i-5:i+5)
					kineticsx(i:end) = kineticsx(i:end)-kineticsx(i)+time_offset;					% alles nach hinten schieben
					%%printf("Hinterher:\n");
					%%kineticsx(i-5:i+5)
					printf("  Weiterer Zeitsprung an Position %d wurde korrigiert\n",i);
				end;
			end;
		end;
	end;
endfunction
