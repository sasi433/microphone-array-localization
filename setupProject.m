function repositoryRoot = setupProject()
%SETUPPROJECT Configure the MATLAB path for this repository.
%   REPOSITORYROOT = SETUPPROJECT() determines the repository root from
%   this file's location and adds its src directory to the current MATLAB
%   session. Calling SETUPPROJECT repeatedly does not duplicate the path
%   entry. The MATLAB path is not saved or changed permanently.

repositoryRoot = fileparts(mfilename('fullpath'));
sourceDirectory = fullfile(repositoryRoot, 'src');

if ~isfolder(sourceDirectory)
    error('micloc:setupProject:MissingSourceDirectory', ...
        'Expected source directory does not exist: %s', sourceDirectory);
end

pathEntries = strsplit(path, pathsep);
if ispc
    sourceIsOnPath = any(strcmpi(sourceDirectory, pathEntries));
else
    sourceIsOnPath = any(strcmp(sourceDirectory, pathEntries));
end

if ~sourceIsOnPath
    addpath(sourceDirectory);
end
end
