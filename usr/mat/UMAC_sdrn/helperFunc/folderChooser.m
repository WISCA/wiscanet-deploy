
function [fdir] = folderChooser( labelString, uniqueID, showParentOnReopen )
% Encapsulated folder selection function
% 
% INPUTS:
%   * labelString
%       - Default:  ''
%       - Label/title for the chooser window
%   * uniqueID
%       - Default:  ???
%       - Unique identifier to use when storing the chosen value
%   * showParentOnReopen
%       - Default:  false
%       - True/false flag if the directory that is shown on reopen is
%           # false - the previously chosen directory
%           # true  - the parent of the previously chosen directory
% 
% OUTPUTS:
%   * fdir
%       - Full path of the chosen directory
% 

if ~exist('labelString','var') || isempty(labelString)
    % No title
    labelString = '';
end
if ~exist('uniqueID','var') || isempty(uniqueID)
    % Use the dbstack to generate a unique identifier
    a = dbstack;
    uniqueID = sprintf('prevSelectFldr_%s_%u',a(min(2,end)).name,a(min(2,end)).line);
end
if ~exist('showParentOnReopen','var') || isempty(showParentOnReopen)
    showParentOnReopen = false;
end

% Check if this function has been called before
tmp = getappdata(0,uniqueID);
if isempty(tmp) || ~iscell(tmp) || ~isdir(tmp{1})
    tmp = pwd;
elseif ~isdir(fullfile(tmp{1},tmp{2})) || showParentOnReopen
    tmp = tmp{1};
else
    tmp = fullfile(tmp{1},tmp{2});
end

% Open the matlab file selector
fdir = uigetdir( tmp, labelString );

% Throw an error to exit if requested
if ~ischar(fdir)
    error('User exit during folder selection')
end

% Pull apart the seleted path
[a,b,~] = fileparts(fdir);

% Update the state
setappdata(0,uniqueID,{a b})

% Print the selected folder information
fprintf(' <strong>Selected folder:</strong>\n')
fdirtmp = strrep(fdir,pwd,'.');
if ~isempty(fdirtmp) && ~strcmp(fdirtmp,sprintf('.%s',filesep))
    fprintf('\t%s\n',fdirtmp)
end
fprintf('\n')


end




