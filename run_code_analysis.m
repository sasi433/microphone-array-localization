function issueCount = run_code_analysis()
%RUN_CODE_ANALYSIS Run MATLAB Code Analyzer on repository MATLAB files.
%   ISSUECOUNT = RUN_CODE_ANALYSIS() checks MATLAB files in src, tests,
%   examples, and the repository root. The function reports every finding
%   and raises an error when Code Analyzer finds an issue.

repositoryRoot = setupProject();
scanDirectories = ["src", "tests", "examples"];
fileGroups = cell(numel(scanDirectories) + 1, 1);
fileGroups{1} = dir(fullfile(repositoryRoot, '*.m'));

for directoryIndex = 1:numel(scanDirectories)
    fileGroups{directoryIndex + 1} = dir(fullfile(repositoryRoot, ...
        scanDirectories(directoryIndex), '**', '*.m'));
end

files = vertcat(fileGroups{:});
[~, sortOrder] = sort(string(fullfile({files.folder}, {files.name})));
files = files(sortOrder);
issueCount = 0;

for fileIndex = 1:numel(files)
    fileName = fullfile(files(fileIndex).folder, files(fileIndex).name);
    issues = checkcode(fileName, '-id');
    issueCount = issueCount + numel(issues);

    if ~isempty(issues)
        relativeFileName = erase(fileName, [repositoryRoot filesep]);
        fprintf('Code Analyzer findings for %s:\n', relativeFileName);
        disp(struct2table(issues));
    end
end

assert(issueCount == 0, 'micloc:codeAnalysis:FindingsReported', ...
    'MATLAB Code Analyzer reported %d finding(s).', issueCount);
fprintf('MATLAB Code Analyzer passed for %d file(s).\n', numel(files));
end
