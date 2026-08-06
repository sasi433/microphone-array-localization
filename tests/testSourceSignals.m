function tests = testSourceSignals
%TESTSOURCESIGNALS Tests for deterministic source signals and utilities.
tests = functiontests(localfunctions);
end

function testGaussianNoiseIsRepeatable(testCase)
config = shortGaussianConfig();

[firstSignal, firstTime] = micloc.generateSourceSignal(config);
[secondSignal, secondTime] = micloc.generateSourceSignal(config);

verifyEqual(testCase, firstSignal, secondSignal);
verifyEqual(testCase, firstTime, secondTime);
verifyTrue(testCase, all(isfinite(firstSignal)));
end

function testDifferentSeedsProduceDifferentNoise(testCase)
firstConfig = shortGaussianConfig();
secondConfig = firstConfig;
secondConfig.randomSeed = firstConfig.randomSeed + 1;

firstSignal = micloc.generateSourceSignal(firstConfig);
secondSignal = micloc.generateSourceSignal(secondConfig);

verifyNotEqual(testCase, firstSignal, secondSignal);
end

function testSampleCountAndTimeVector(testCase)
config = shortGaussianConfig();
config.sampleRateHz = 1000;
config.durationSeconds = 0.0105;

[signal, timeSeconds] = micloc.generateSourceSignal(config);

verifySize(testCase, signal, [11, 1]);
verifySize(testCase, timeSeconds, [11, 1]);
verifyEqual(testCase, timeSeconds, (0:10).' / 1000, 'AbsTol', 1e-15);
end

function testGenerationDoesNotChangeGlobalRandomState(testCase)
config = shortGaussianConfig();
stateBefore = rng;

micloc.generateSourceSignal(config);

stateAfter = rng;
verifyEqual(testCase, stateAfter, stateBefore);
end

function testChirpIsRepeatableAndMatchesDefinition(testCase)
config = shortChirpConfig();

[firstSignal, timeSeconds] = micloc.generateSourceSignal(config);
secondSignal = micloc.generateSourceSignal(config);
sweepRateHzPerSecond = (config.sourceSignal.endFrequencyHz ...
    - config.sourceSignal.startFrequencyHz) / config.durationSeconds;
expectedPhaseRadians = config.sourceSignal.initialPhaseRadians ...
    + 2 * pi * (config.sourceSignal.startFrequencyHz * timeSeconds ...
    + 0.5 * sweepRateHzPerSecond * timeSeconds .^ 2);
expectedSignal = config.sourceSignal.amplitude * sin(expectedPhaseRadians);

verifyEqual(testCase, firstSignal, secondSignal);
verifyEqual(testCase, firstSignal, expectedSignal, 'AbsTol', 1e-14);
verifyLessThanOrEqual(testCase, max(abs(firstSignal)), ...
    config.sourceSignal.amplitude + 1e-14);
verifyTrue(testCase, all(isfinite(firstSignal)));
end

function testPeakNormalizationPreservesOrientation(testCase)
[normalizedRow, rowScale] = micloc.normalizeSignal([-2, 1]);
[normalizedColumn, columnScale] = micloc.normalizeSignal([1; -4; 2], 2);

verifyEqual(testCase, normalizedRow, [-1, 0.5]);
verifyEqual(testCase, rowScale, 0.5);
verifyEqual(testCase, normalizedColumn, [0.5; -2; 1]);
verifyEqual(testCase, columnScale, 0.5);
verifyTrue(testCase, isrow(normalizedRow));
verifyTrue(testCase, iscolumn(normalizedColumn));
end

function testZeroSignalNormalizationIsExplicit(testCase)
inputSignal = zeros(4, 1);

[normalizedSignal, scaleFactor] = micloc.normalizeSignal(inputSignal, 2);

verifyEqual(testCase, normalizedSignal, inputSignal);
verifyEqual(testCase, scaleFactor, 1);
end

function testSignalPowerUsesMeanSquareDefinition(testCase)
verifyEqual(testCase, micloc.signalPower([1, -1, 1, -1]), 1);
verifyEqual(testCase, micloc.signalPower([1i, -1i]), 1);
verifyEqual(testCase, micloc.signalPower(zeros(5, 1)), 0);
verifyEqual(testCase, micloc.signalPower([1, 2, 3]), 14 / 3, ...
    'AbsTol', eps(14 / 3));
end

function testRejectsInvalidSourceSignalSettings(testCase)
baseConfig = shortGaussianConfig();
invalidConfigs = cell(6, 1);

invalidConfigs{1} = baseConfig;
invalidConfigs{1}.sourceSignal.type = 'unsupported';
invalidConfigs{2} = baseConfig;
invalidConfigs{2}.sourceSignal.amplitude = 0;
invalidConfigs{3} = baseConfig;
invalidConfigs{3}.durationSeconds = 0.1 / baseConfig.sampleRateHz;
invalidConfigs{4} = shortChirpConfig();
invalidConfigs{4}.sourceSignal = rmfield( ...
    invalidConfigs{4}.sourceSignal, 'endFrequencyHz');
invalidConfigs{5} = shortChirpConfig();
invalidConfigs{5}.sourceSignal.endFrequencyHz = ...
    invalidConfigs{5}.sourceSignal.startFrequencyHz;
invalidConfigs{6} = shortChirpConfig();
invalidConfigs{6}.sourceSignal.endFrequencyHz = ...
    invalidConfigs{6}.sampleRateHz / 2;

for configIndex = 1:numel(invalidConfigs)
    verifyCallFails(testCase, ...
        @() micloc.generateSourceSignal(invalidConfigs{configIndex}));
end
end

function testRejectsInvalidSignalUtilityInputs(testCase)
invalidCalls = { ...
    @() micloc.normalizeSignal([]), ...
    @() micloc.normalizeSignal([1, NaN]), ...
    @() micloc.normalizeSignal(ones(2)), ...
    @() micloc.normalizeSignal([1, 2], 0), ...
    @() micloc.signalPower([]), ...
    @() micloc.signalPower([1, Inf]), ...
    @() micloc.signalPower(ones(2))};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function config = shortGaussianConfig()
config = micloc.defaultConfig();
config.durationSeconds = 0.01;
end

function config = shortChirpConfig()
config = micloc.modernDemoConfig();
config.sampleRateHz = 2000;
config.durationSeconds = 0.02;
config.sourceSignal.startFrequencyHz = 100;
config.sourceSignal.endFrequencyHz = 600;
config.sourceSignal.initialPhaseRadians = pi / 6;
end

function verifyCallFails(testCase, functionHandle)
caughtIdentifier = '';
try
    functionHandle();
catch errorInfo
    caughtIdentifier = errorInfo.identifier;
end

verifyNotEmpty(testCase, caughtIdentifier, ...
    'Expected the invalid input to raise an identified error.');
end
