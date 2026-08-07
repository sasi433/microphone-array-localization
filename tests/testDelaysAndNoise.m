function tests = testDelaysAndNoise
%TESTDELAYSANDNOISE Tests for integer delays and additive target-SNR noise.
tests = functiontests(localfunctions);
end

function testZeroIntegerDelayReturnsInput(testCase)
rowSignal = [1, -2, 3];
columnSignal = rowSignal.';

verifyEqual(testCase, micloc.applyIntegerDelay(rowSignal, 0), rowSignal);
verifyEqual(testCase, micloc.applyIntegerDelay(columnSignal, 0), columnSignal);
end

function testIntegerDelayPadsWithoutTruncation(testCase)
inputSignal = [1; 2; 3];

delayedSignal = micloc.applyIntegerDelay(inputSignal, 2);

verifyEqual(testCase, delayedSignal, [0; 0; 1; 2; 3]);
verifySize(testCase, delayedSignal, [5, 1]);
end

function testIntegerDelayPreservesRowOrientationAndType(testCase)
inputSignal = single([1, 2]);

delayedSignal = micloc.applyIntegerDelay(inputSignal, 3);

verifyEqual(testCase, delayedSignal, single([0, 0, 0, 1, 2]));
verifyTrue(testCase, isrow(delayedSignal));
verifyClass(testCase, delayedSignal, 'single');
end

function testIntegerMultichannelAlignment(testCase)
sourceSignal = [1; 2; 3];

[microphoneSignals, diagnostics] = micloc.simulateMicrophoneSignals( ...
    sourceSignal, [0, 2, 1], 'integer');
expectedSignals = [ ...
    1, 0, 0; ...
    2, 0, 1; ...
    3, 1, 2; ...
    0, 2, 3; ...
    0, 3, 0];

verifyEqual(testCase, microphoneSignals, expectedSignals);
verifyEqual(testCase, diagnostics.appliedDelaySamples, [0; 2; 1]);
verifyEqual(testCase, diagnostics.outputSampleCount, 5);
verifyEqual(testCase, diagnostics.groupDelaySamples, 0);
end

function testIntegerMultichannelSupportsArbitraryCount(testCase)
sourceSignal = [1, -1];
delaySamples = 0:7;

microphoneSignals = micloc.simulateMicrophoneSignals( ...
    sourceSignal, delaySamples, 'integer');

verifySize(testCase, microphoneSignals, [9, 8]);
for microphoneIndex = 1:numel(delaySamples)
    expectedStart = delaySamples(microphoneIndex) + 1;
    verifyEqual(testCase, microphoneSignals( ...
        expectedStart:(expectedStart + 1), microphoneIndex), [1; -1]);
end
end

function testNoiseIsDeterministicAndSeeded(testCase)
cleanSignal = createCleanSignal();

[firstNoisy, firstNoise] = micloc.addNoiseAtSNR(cleanSignal, 20, 42);
[secondNoisy, secondNoise] = micloc.addNoiseAtSNR(cleanSignal, 20, 42);
[differentNoisy, differentNoise] = micloc.addNoiseAtSNR( ...
    cleanSignal, 20, 43);

verifyEqual(testCase, firstNoisy, secondNoisy);
verifyEqual(testCase, firstNoise, secondNoise);
verifyNotEqual(testCase, firstNoisy, differentNoisy);
verifyNotEqual(testCase, firstNoise, differentNoise);
end

function testMeasuredVectorSNRMatchesTarget(testCase)
cleanSignal = createCleanSignal();
targetSnrDb = 17;

[~, noise, diagnostics] = micloc.addNoiseAtSNR( ...
    cleanSignal, targetSnrDb, 7);
measuredSnrDb = 10 * log10( ...
    micloc.signalPower(cleanSignal) / micloc.signalPower(noise));

verifyEqual(testCase, measuredSnrDb, targetSnrDb, 'AbsTol', 1e-10);
verifyEqual(testCase, diagnostics.measuredSnrDb, targetSnrDb, ...
    'AbsTol', 1e-10);
verifyLessThanOrEqual(testCase, abs(measuredSnrDb - targetSnrDb), 0.25);
end

function testMeasuredMatrixSNRMatchesPerChannel(testCase)
cleanSignal = createCleanSignal();
cleanSignals = [cleanSignal, 0.5 * cleanSignal, 2 * cleanSignal];

[~, noise, diagnostics] = micloc.addNoiseAtSNR(cleanSignals, 5, 99);
measuredSnrDb = 10 * log10( ...
    mean(cleanSignals .^ 2, 1) ./ mean(noise .^ 2, 1));

verifyEqual(testCase, measuredSnrDb, 5 * ones(1, 3), 'AbsTol', 1e-10);
verifyEqual(testCase, diagnostics.measuredSnrDb, measuredSnrDb, ...
    'AbsTol', 1e-12);
end

function testInfiniteSNRAddsNoNoise(testCase)
cleanSignal = [1, -1, 2, -2];

[noisySignal, noise, diagnostics] = micloc.addNoiseAtSNR( ...
    cleanSignal, Inf, 1);

verifyEqual(testCase, noisySignal, cleanSignal);
verifyEqual(testCase, noise, zeros(size(cleanSignal)));
verifyEqual(testCase, diagnostics.measuredSnrDb, Inf);
end

function testNoiseGenerationPreservesGlobalRandomState(testCase)
cleanSignal = createCleanSignal();
stateBefore = rng;

micloc.addNoiseAtSNR(cleanSignal, 10, 123);

stateAfter = rng;
verifyEqual(testCase, stateAfter, stateBefore);
end

function testRejectsInvalidIntegerDelayInputs(testCase)
invalidCalls = { ...
    @() micloc.applyIntegerDelay([], 1), ...
    @() micloc.applyIntegerDelay([1, NaN], 1), ...
    @() micloc.applyIntegerDelay([1, 2], -1), ...
    @() micloc.applyIntegerDelay([1, 2], 1.5), ...
    @() micloc.simulateMicrophoneSignals([1, 2], [0, -1], 'integer'), ...
    @() micloc.simulateMicrophoneSignals([1, 2], [0, 0.5], 'integer')};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function testRejectsInvalidNoiseInputs(testCase)
invalidCalls = { ...
    @() micloc.addNoiseAtSNR([], 20, 1), ...
    @() micloc.addNoiseAtSNR([1, NaN], 20, 1), ...
    @() micloc.addNoiseAtSNR([1, 2], NaN, 1), ...
    @() micloc.addNoiseAtSNR([1, 2], -Inf, 1), ...
    @() micloc.addNoiseAtSNR([1, 2], 20, -1), ...
    @() micloc.addNoiseAtSNR(zeros(10, 1), 20, 1)};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function signal = createCleanSignal()
sampleIndices = (0:999).';
signal = sin(0.07 * sampleIndices) + 0.3 * cos(0.19 * sampleIndices);
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
