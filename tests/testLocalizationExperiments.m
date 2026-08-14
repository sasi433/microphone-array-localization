function tests = testLocalizationExperiments
%TESTLOCALIZATIONEXPERIMENTS Compact deterministic experiment coverage.
tests = functiontests(localfunctions);
end

function testRepeatedTrialsAreDeterministicAndSeeded(testCase)
config = createCompactExperimentConfig();

firstExperiment = micloc.runMonteCarloTrials(config, 2, 7300);
secondExperiment = micloc.runMonteCarloTrials(config, 2, 7300);

verifyEqual(testCase, firstExperiment.seeds, [7300; 7301]);
verifyEqual(testCase, firstExperiment.trialTable, ...
    secondExperiment.trialTable);
verifyEqual(testCase, height(firstExperiment.trialTable), 2);
verifyEqual(testCase, firstExperiment.trialTable.RandomSeed, [7300; 7301]);
verifyTrue(testCase, ...
    all(isfinite(firstExperiment.trialTable.LocalizationErrorMeters)));
verifyEqual(testCase, numel(firstExperiment.trialResults), 2);
end

function testConfigurableSNRScriptUsesDistinctSeedBlocks(testCase)
repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
snrLevelsDb = [Inf, 25]; %#ok<NASGU>
trialsPerSnr = 1; %#ok<NASGU>
startingSeed = 7400; %#ok<NASGU>

run(fullfile(repositoryRoot, 'examples', 'runSNRExperiment.m'));

verifyEqual(testCase, snrExperiment.snrLevelsDb, [Inf, 25]);
verifyEqual(testCase, snrExperiment.trialsPerSnr, 1);
verifyEqual(testCase, height(snrExperiment.trialTable), 2);
verifyEqual(testCase, snrExperiment.trialTable.SnrLevelIndex, [1; 2]);
verifyEqual(testCase, snrExperiment.trialTable.RandomSeed, [7400; 7401]);
verifyEqual(testCase, snrExperiment.trialTable.RequestedSnrDb, [Inf; 25]);
verifyEqual(testCase, numel(snrExperiment.levelExperiments), 2);
end

function testSummaryStatisticsAndFailureCounts(testCase)
trialTable = table([20; 20; 20; 20; 10; 10; 0], ...
    [true; true; true; true; true; false; true], ...
    [1; 2; 3; 4; 5; 100; NaN], 'VariableNames', { ...
    'RequestedSnrDb', 'SolverSucceeded', 'LocalizationErrorMeters'});

summary = micloc.summarizeLocalizationTrials(trialTable);
level20 = summary.RequestedSnrDb == 20;
level10 = summary.RequestedSnrDb == 10;
level0 = summary.RequestedSnrDb == 0;

verifyEqual(testCase, summary.TotalTrialCount(level20), 4);
verifyEqual(testCase, summary.ValidTrialCount(level20), 4);
verifyEqual(testCase, summary.MeanErrorMeters(level20), 2.5, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, summary.MedianErrorMeters(level20), 2.5, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, summary.StandardDeviationMeters(level20), ...
    std([1; 2; 3; 4]), 'AbsTol', 1e-12);
verifyEqual(testCase, summary.MinimumErrorMeters(level20), 1);
verifyEqual(testCase, summary.MaximumErrorMeters(level20), 4);
verifyEqual(testCase, summary.Percentile90ErrorMeters(level20), 3.7, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, summary.SolverFailureCount(level10), 1);
verifyEqual(testCase, summary.ValidTrialCount(level10), 1);
verifyEqual(testCase, summary.InvalidMetricCount(level0), 1);
verifyTrue(testCase, isnan(summary.MeanErrorMeters(level0)));
end

function testExperimentExportProducesInspectableArtifacts(testCase)
trialTable = table((1:4).', (8100:8103).', [Inf; Inf; 20; 20], ...
    [true; true; true; false], [1; 1; 1; -2], ...
    [0.01; 0.02; 0.04; 0.5], 'VariableNames', { ...
    'TrialIndex', 'RandomSeed', 'RequestedSnrDb', 'SolverSucceeded', ...
    'SolverExitFlag', 'LocalizationErrorMeters'});
experiment = struct('trialTable', trialTable);
outputDirectory = tempname;
cleanup = onCleanup(@() removeTestDirectory(outputDirectory));

exported = micloc.exportLocalizationExperiment( ...
    experiment, outputDirectory, 'compact-sweep');

verifyTrue(testCase, isfile(exported.trialTablePath));
verifyTrue(testCase, isfile(exported.summaryTablePath));
verifyTrue(testCase, isfile(exported.plotPath));
verifyEqual(testCase, height(readtable(exported.trialTablePath)), 4);
verifyEqual(testCase, height(readtable(exported.summaryTablePath)), 2);
plotDetails = dir(exported.plotPath);
verifyGreaterThan(testCase, plotDetails.bytes, 0);
verifyEqual(testCase, exported.summaryTable, ...
    micloc.summarizeLocalizationTrials(trialTable));
end

function testExperimentInputsAreValidated(testCase)
config = createCompactExperimentConfig();
verifyError(testCase, @() micloc.runMonteCarloTrials(config, 0), ...
    'MATLAB:runMonteCarloTrials:expectedPositive');
verifyError(testCase, @() micloc.runMonteCarloTrials( ...
    config, 2, double(intmax('uint32')) - 1), ...
    'micloc:runMonteCarloTrials:SeedRangeExceeded');

incompleteTable = table(20, true, 'VariableNames', { ...
    'RequestedSnrDb', 'SolverSucceeded'});
verifyError(testCase, @() micloc.summarizeLocalizationTrials( ...
    incompleteTable), ...
    'micloc:summarizeLocalizationTrials:MissingVariable');
verifyError(testCase, @() micloc.plotLocalizationErrorBySNR( ...
    incompleteTable), ...
    'micloc:plotLocalizationErrorBySNR:MissingVariable');
end

function config = createCompactExperimentConfig
config = micloc.defaultConfig();
config.durationSeconds = 0.2;
config.microphonePositionsMeters = [ ...
    -0.06, -0.04; ...
     0.06, -0.04; ...
    -0.06,  0.04; ...
     0.06,  0.04];
config.sourcePositionMeters = [0.15, 0.22];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'fractional';
config.noise.enabled = true;
config.noise.snrDb = 30;
config.lms.filterLength = 64;
config.lms.stepSize = 0.003;
config.lms.bulkDelaySamples = 24;
config.localization.initialGuessMeters = [0.1, 0.15];
config.localization.lowerBoundsMeters = [-0.5, -0.5];
config.localization.upperBoundsMeters = [1, 1];
config.plot.enabled = false;
config = micloc.validateConfig(config);
end

function removeTestDirectory(directoryPath)
if isfolder(directoryPath)
    rmdir(directoryPath, 's');
end
end
