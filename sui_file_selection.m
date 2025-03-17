function res = sui_file_selection(varargin)

  % find out if multiple_files can be selected
  multiples=0;
  spath="*";
  action1="Select File";
  action2="Select Files";
  for i=2:nargin
     known_argument=0;
     if strcmp(varargin{i},"multiple")
       multiples=1;
       known_argument=1;
       % printf("Set to multiples");
     elseif strcmp(varargin{i},"save")
       known_argument=1;
     elseif strcmp(varargin{i},"directory")
       known_argument=1;
     elseif strcmp(varargin{i},"error")
       known_argument=1;
     else                 % unknown Argument; set as path
       spath=varargin{i};
     endif
  endfor
  % printf("Arguments: %d\n",nargin);
  if (multiples==1)
    [a,b]=uigetfile("*",action2,"MultiSelect","on");
  else
    [a,b]=uigetfile("*",action1,"MultiSelect","off");
  endif
  %% Umwandeln in Zenity-Format:  a{1} - drive
  %%                              a{2} - Complete Path i  drive
  drive = b(1);
  folder= b(3:end);
  if (multiples==1)
    for i=1:columns(a)
      res{2*i-1} = drive;
      res{2*i} = sprintf("%s%s ",folder,a{i});
    endfor
  else
    res{1} = drive;
    res{2} = sprintf("%s%s ",folder,a);
  endif
endfunction
