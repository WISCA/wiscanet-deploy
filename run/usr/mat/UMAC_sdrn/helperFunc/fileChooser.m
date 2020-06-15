
function [fname,fdir] = fileChooser( validFiles, labelString, uniqueID, enableMultiSelect, doPrintSelection )
% Encapsulated file selection function
% 
% INPUTS:
%   * validFiles  (optional)
%       - Default:  {'*' 'All Files'}
%       - Allows only certain types of files to be displayed/selectable
%   * labelString
%       - Default:  ''
%       - Label/title for the chooser window
%   * uniqueID
%       - Default:  ???
%       - Unique identifier to use when storing the chosen value
%   * enableMultiSelect
%       - Default:  false
%       - True/false flag if MultiSelect should be enabled
%   * doPrintSelection
%       - Default:  true
%       - True/false flag if the selected file(s) and fold should print
% 
% OUTPUTS:
%   * fname
%       - Name of the selected file
%   * fdir
%       - Full path of the directory containing the selected file
% 

if ~exist('validFiles','var') || isempty(validFiles)
    % All files are valid
    validFiles = {'*' 'All Files'};
end
if ~exist('labelString','var') || isempty(labelString)
    % No title
    labelString = '';
end
if ~exist('uniqueID','var') || isempty(uniqueID)
    % Use the dbstack to generate a unique identifier
    a = dbstack;
    uniqueID = sprintf('prevSelectFile_%s_%u',a(min(2,end)).name,a(min(2,end)).line);
end
if ~exist('enableMultiSelect','var') || isempty(enableMultiSelect)
    enableMultiSelect = false;
else
    enableMultiSelect = all(enableMultiSelect~=0);
end
if ~exist('doPrintSelection','var') || isempty(doPrintSelection)
    doPrintSelection = true;
end

% Check if this function has been called before
prevVal = getappdata(0,uniqueID);
if isempty(prevVal) || ~iscell(prevVal) || ~isdir(prevVal{1})
    % Function not called before or stored value invalid
    %   * Point to current working directory
    dpath = pwd;
    dfile = '';
% elseif iscell(prevVal{2}) && all(cellfun(@(x) exist(fullfile(prevVal{1},x),'file'),prevVal{2}))
%     % Preveious selection was MultiSelect and all still exist
%     %   * Set all as default
%     dpath = prevVal{1};
%     dfile = sprintf('"%s" ',prevVal{2}{:});
elseif iscell(prevVal{2}) || ~exist(fullfile(prevVal{1},prevVal{2}),'file')
    % Previous folder exists but previous file does not
    %   * Point to previous folder
    dpath = prevVal{1};
    dfile = '';
else
    % Previous selection was a single file that still exists
    %   * Set as default
    dpath = prevVal{1};
    dfile = prevVal{2};
end

% Open the Matlab file selector
ufd = matlab.ui.internal.dialog.FileOpenChooser();

% Set the dialog parameters
ufd.MultiSelection = enableMultiSelect;
ufd.FileFilter = validFiles;
ufd.Title = labelString;
ufd.InitialFileName = dfile;
ufd.InitialPathName = dpath;

% Show the dialog box
ufd.show();

% Get the selected file name(s) and path
fname = ufd.FileName;
if iscell(fname) && (numel(fname)==1)
    fname = fname{1};
end
fdir = ufd.PathName;

% Throw an error to exit, if requested
if ~ischar(fname) && ~iscell(fname)
    throwAsCaller(MException('','User exit during file selection'))
end

% Update the state
setappdata(0,uniqueID,{fdir fname})

if doPrintSelection
    % Print the selected file/folder information
    fprintf(' <strong>Selected file:</strong>\n')
    if iscell(fname)
        fprintf('\tfile:\n')
        fprintf('\t\t%s\n',fname{:})
    else
        fprintf('\tfile:   %s\n',fname)
    end
    fdirtmp = strrep(fdir,pwd,'.');
    if ~isempty(fdirtmp) && ~strcmp(fdirtmp,sprintf('.%s',filesep))
        fprintf('\tfolder: %s\n',fdirtmp)
    end
    fprintf('\n')
end

% If less than two outputs are requested, combine the file name and path
if nargout<2
    if iscell(fname)
        fname = cellfun(@(x) fullfile(fdir,x), fname, 'UniformOutput', false );
    else
        fname = fullfile(fdir,fname);
    end
    if enableMultiSelect && ~iscell(fname)
        fname = {fname};
    end
end


end




