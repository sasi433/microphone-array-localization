function results = run_tests()
%RUN_TESTS Run the complete microphone-localization MATLAB test suite.
%   RESULTS = RUN_TESTS() configures the repository, discovers tests below
%   the tests directory, runs them, prints a concise summary, and raises an
%   error if no tests are discovered or any test does not pass.

repositoryRoot = setupProject();
testsDirectory = fullfile(repositoryRoot, 'tests');

results = runtests(testsDirectory, ...
    IncludeSubfolders=true, InvalidFileFoundAction='error');

if isempty(results)
    error('micloc:runTests:NoTestsDiscovered', ...
        'No MATLAB tests were discovered below %s.', testsDirectory);
end

passedCount = nnz([results.Passed]);
failedCount = nnz([results.Failed]);
incompleteCount = nnz([results.Incomplete]);
totalCount = numel(results);

fprintf('\nMATLAB test summary: %d passed, %d failed, %d incomplete, %d total.\n', ...
    passedCount, failedCount, incompleteCount, totalCount);

assert(all([results.Passed]), 'micloc:runTests:TestFailure', ...
    '%d of %d MATLAB tests did not pass.', totalCount - passedCount, totalCount);
end
