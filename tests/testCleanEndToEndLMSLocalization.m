function tests = testCleanEndToEndLMSLocalization
%TESTCLEANENDTOENDLMSLOCALIZATION Clean deterministic pipeline integration.
tests = functiontests(localfunctions);
end

function testLocalizesCleanFractionalDelayScene(testCase)
config = createCleanConfig();

result = micloc.runLocalizationSimulation(config);

verifyTrue(testCase, result.solverSucceeded, ...
    result.solverDiagnostics.solverMessage);
verifyEqual(testCase, result.actualPositionMeters, ...
    config.sourcePositionMeters);
verifyEqual(testCase, result.microphonePositionsMeters, ...
    config.microphonePositionsMeters);
verifyLessThan(testCase, result.localizationErrorMeters, 0.02);
verifyLessThan(testCase, ...
    max(abs(result.tdoaErrorsSeconds)) * config.sampleRateHz, 0.01);
verifyEqual(testCase, ...
    result.estimatedTDOAsSeconds(config.referenceMicrophoneIndex), 0);
verifyTrue(testCase, all(isfinite(result.estimatedPositionMeters)));
verifyTrue(testCase, all(cellfun(@(entry) ...
    entry.isReferenceMicrophone || strcmp(entry.phase.fitQuality, 'good'), ...
    result.lmsDiagnostics)));
end

function config = createCleanConfig
config = micloc.defaultConfig();
config.durationSeconds = 0.5;
config.microphonePositionsMeters = [ ...
    -0.06, -0.04; ...
     0.06, -0.04; ...
    -0.06,  0.04; ...
     0.06,  0.04];
config.sourcePositionMeters = [0.15, 0.22];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'fractional';
config.noise.enabled = false;
config.lms.filterLength = 64;
config.lms.stepSize = 0.003;
config.lms.bulkDelaySamples = 24;
config.localization.initialGuessMeters = [0.1, 0.15];
config.localization.lowerBoundsMeters = [-0.5, -0.5];
config.localization.upperBoundsMeters = [1, 1];
config = micloc.validateConfig(config);
end
