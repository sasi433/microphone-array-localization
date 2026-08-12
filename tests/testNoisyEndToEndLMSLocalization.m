function tests = testNoisyEndToEndLMSLocalization
%TESTNOISYENDTOENDLMSLOCALIZATION Deterministic finite-SNR integration.
tests = functiontests(localfunctions);
end

function testNoisySimulationIsDeterministicAndBounded(testCase)
config = createNoisyConfig();

firstResult = micloc.runLocalizationSimulation(config);
secondResult = micloc.runLocalizationSimulation(config);

verifyEqual(testCase, firstResult.sourceSignal, secondResult.sourceSignal);
verifyEqual(testCase, firstResult.noiseSamples, secondResult.noiseSamples);
verifyEqual(testCase, firstResult.estimatedTDOAsSeconds, ...
    secondResult.estimatedTDOAsSeconds);
verifyEqual(testCase, firstResult.estimatedPositionMeters, ...
    secondResult.estimatedPositionMeters);
verifyTrue(testCase, firstResult.solverSucceeded, ...
    firstResult.solverDiagnostics.solverMessage);
verifyTrue(testCase, all(isfinite(firstResult.estimatedPositionMeters)));
verifyTrue(testCase, all(isfinite(firstResult.estimatedTDOAsSeconds)));
verifyGreaterThan(testCase, norm(firstResult.noiseSamples, 'fro'), 0);
verifyEqual(testCase, firstResult.diagnostics.noise.measuredSnrDb, ...
    config.noise.snrDb * ones(1, 4), 'AbsTol', 1e-10);
verifyLessThan(testCase, firstResult.localizationErrorMeters, 0.03);
verifyLessThan(testCase, ...
    max(abs(firstResult.tdoaErrorsSeconds)) * config.sampleRateHz, 0.02);
end

function config = createNoisyConfig
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
config.noise.enabled = true;
config.noise.snrDb = 30;
config.lms.filterLength = 64;
config.lms.stepSize = 0.003;
config.lms.bulkDelaySamples = 24;
config.localization.initialGuessMeters = [0.1, 0.15];
config.localization.lowerBoundsMeters = [-0.5, -0.5];
config.localization.upperBoundsMeters = [1, 1];
config = micloc.validateConfig(config);
end
