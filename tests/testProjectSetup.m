function tests = testProjectSetup
%TESTPROJECTSETUP Smoke tests for the repository bootstrap.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.RepositoryRoot = repositoryRoot;
testCase.applyFixture( ...
    matlab.unittest.fixtures.PathFixture(repositoryRoot));
end

function testReturnsRepositoryRoot(testCase)
expectedRoot = testCase.TestData.RepositoryRoot;
actualRoot = setupProject();

verifyEqual(testCase, actualRoot, expectedRoot);
end

function testAddsSourceDirectoryOnlyOnce(testCase)
repositoryRoot = setupProject();
sourceDirectory = fullfile(repositoryRoot, 'src');

setupProject();
pathEntries = strsplit(path, pathsep);
if ispc
    matchingEntries = strcmpi(sourceDirectory, pathEntries);
else
    matchingEntries = strcmp(sourceDirectory, pathEntries);
end

verifyEqual(testCase, nnz(matchingEntries), 1);
end

function testMiclocPackageIsDiscoverable(testCase)
repositoryRoot = setupProject();
packageInfo = what('micloc');

verifyNotEmpty(testCase, packageInfo);
verifyEqual(testCase, packageInfo.path, ...
    fullfile(repositoryRoot, 'src', '+micloc'));
end
