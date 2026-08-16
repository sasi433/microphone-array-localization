function tests = testGCCPHATEndToEndLocalization
%TESTGCCPHATENDTOENDLOCALIZATION GCC-PHAT pipeline and comparison cases.
tests = functiontests(localfunctions);
end

function testLocalizesCleanFractionalScene(testCase)
config = createComparisonConfig();
config.tdoaEstimator = 'gcc-phat';
config.noise.enabled = false;

result = micloc.runLocalizationSimulation(config);

verifyTrue(testCase, result.solverSucceeded, ...
    result.solverDiagnostics.solverMessage);
verifyEqual(testCase, result.tdoaEstimator, 'gcc-phat');
verifyLessThan(testCase, result.localizationErrorMeters, 0.04);
verifyLessThan(testCase, ...
    max(abs(result.tdoaErrorsSeconds)) * config.sampleRateHz, 0.3);
verifyEmpty(testCase, result.lmsDiagnostics);
verifyEqual(testCase, numel(result.pairDiagnostics), 4);

maximumTDOASamples = micloc.calculateMaximumTDOASamples( ...
    config.microphonePositionsMeters, config.referenceMicrophoneIndex, ...
    config.sampleRateHz, config.speedOfSoundMetersPerSecond);
for microphoneIndex = 1:numel(result.pairDiagnostics)
    pair = result.pairDiagnostics{microphoneIndex};
    if ~pair.isReferenceMicrophone
        verifyEqual(testCase, pair.gccPhat.maximumLagSamples, ...
            maximumTDOASamples(microphoneIndex));
        verifyLessThanOrEqual(testCase, ...
            abs(pair.estimatedTDOASamples), ...
            maximumTDOASamples(microphoneIndex));
    end
end
end

function testNoisyLocalizationIsDeterministicAndBounded(testCase)
config = createComparisonConfig();
config.tdoaEstimator = 'gcc-phat';
config.noise.enabled = true;
config.noise.snrDb = 10;

firstResult = micloc.runLocalizationSimulation(config);
secondResult = micloc.runLocalizationSimulation(config);

verifyEqual(testCase, firstResult.microphoneSignals, ...
    secondResult.microphoneSignals);
verifyEqual(testCase, firstResult.estimatedTDOAsSamples, ...
    secondResult.estimatedTDOAsSamples);
verifyEqual(testCase, firstResult.estimatedPositionMeters, ...
    secondResult.estimatedPositionMeters);
verifyTrue(testCase, firstResult.solverSucceeded, ...
    firstResult.solverDiagnostics.solverMessage);
verifyGreaterThan(testCase, norm(firstResult.noiseSamples, 'fro'), 0);
verifyEqual(testCase, firstResult.diagnostics.noise.measuredSnrDb, ...
    10 * ones(1, 4), 'AbsTol', 1e-10);
verifyLessThan(testCase, firstResult.localizationErrorMeters, 0.04);
verifyLessThan(testCase, ...
    max(abs(firstResult.tdoaErrorsSeconds)) * config.sampleRateHz, 0.3);
end

function testEstimatorComparisonUsesIdenticalSignals(testCase)
config = createComparisonConfig();
config.noise.enabled = true;
config.noise.snrDb = 20;

comparison = micloc.compareTDOAEstimators(config);

verifyTrue(testCase, comparison.inputsVerifiedIdentical);
verifyEqual(testCase, comparison.estimatorNames, ...
    ["lms-peak", "lms-phase", "gcc-phat"]);
verifyEqual(testCase, height(comparison.delayMetricsTable), 3);
for estimatorIndex = 1:numel(comparison.results)
    verifyEqual(testCase, ...
        comparison.results{estimatorIndex}.microphoneSignals, ...
        comparison.microphoneSignals);
    verifyEqual(testCase, comparison.results{estimatorIndex}.noiseSamples, ...
        comparison.noiseSamples);
end

gccRow = comparison.delayMetricsTable.TDOAEstimator == "gcc-phat";
gccErrors = comparison.tdoaErrorSamples(2:end, gccRow);
verifyEqual(testCase, ...
    comparison.delayMetricsTable.MaximumAbsoluteTDOAErrorSamples(gccRow), ...
    max(abs(gccErrors)), 'AbsTol', 1e-12);
end

function testCompactSNRComparisonPreservesSeedsAndMethods(testCase)
config = createComparisonConfig();

experiment = micloc.runEstimatorSNRComparison( ...
    config, [Inf, 15], 1, 17000);

verifyTrue(testCase, experiment.inputsVerifiedIdentical);
verifyEqual(testCase, height(experiment.trialTable), 6);
verifyEqual(testCase, height(experiment.summaryTable), 6);
verifyEqual(testCase, experiment.trialTable.RandomSeed, ...
    [repmat(17000, 3, 1); repmat(17001, 3, 1)]);
verifyEqual(testCase, experiment.trialTable.RequestedSnrDb, ...
    [Inf(3, 1); repmat(15, 3, 1)]);
verifyEqual(testCase, experiment.summaryTable.TotalTrialCount, ...
    ones(6, 1));
verifyEqual(testCase, unique(experiment.trialTable.TDOAEstimator, ...
    'stable').', experiment.estimatorNames);
end

function testRejectsUnsupportedConfiguredEstimator(testCase)
config = createComparisonConfig();
config.tdoaEstimator = 'unsupported';

verifyError(testCase, @() micloc.validateConfig(config), ...
    'micloc:validateConfig:InvalidField');
end

function config = createComparisonConfig
config = micloc.defaultConfig();
config.durationSeconds = 0.3;
config.microphonePositionsMeters = [ ...
    -0.06, -0.04; ...
     0.06, -0.04; ...
    -0.06,  0.04; ...
     0.06,  0.04];
config.sourcePositionMeters = [0.15, 0.22];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'fractional';
config.lms.filterLength = 64;
config.lms.stepSize = 0.003;
config.lms.bulkDelaySamples = 24;
config.localization.initialGuessMeters = [0.1, 0.15];
config.localization.lowerBoundsMeters = [-0.5, -0.5];
config.localization.upperBoundsMeters = [1, 1];
config.plot.enabled = false;
config = micloc.validateConfig(config);
end
