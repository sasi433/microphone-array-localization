function tests = testFractionalDelayMultichannel
%TESTFRACTIONALDELAYMULTICHANNEL Multichannel fractional-delay tests.
tests = functiontests(localfunctions);
end

function testMixedDelaysMatchIndependentChannels(testCase)
sourceSignal = [1; 2; 3; 4];
delaySamples = [0, 0.25, 1.5, 2];

[microphoneSignals, diagnostics] = micloc.simulateMicrophoneSignals( ...
    sourceSignal, delaySamples, 'fractional');

verifySize(testCase, microphoneSignals, [6, 4]);
for microphoneIndex = 1:numel(delaySamples)
    independentChannel = micloc.applyFractionalDelay( ...
        sourceSignal, delaySamples(microphoneIndex));
    expectedChannel = [independentChannel; zeros( ...
        size(microphoneSignals, 1) - numel(independentChannel), 1)];
    verifyEqual(testCase, microphoneSignals(:, microphoneIndex), ...
        expectedChannel, 'AbsTol', 2e-15);
end
verifyEqual(testCase, diagnostics.maximumOutputDelaySamples, 2);
verifyEqual(testCase, diagnostics.outputSampleCount, 6);
end

function testZeroDelayChannelIsAlignedExactly(testCase)
sourceSignal = [1; -2; 3];

microphoneSignals = micloc.simulateMicrophoneSignals( ...
    sourceSignal, [0, 0.5, 1.25], 'fractional');

verifyEqual(testCase, microphoneSignals(:, 1), ...
    [sourceSignal; zeros(2, 1)]);
end

function testIntegerDelaysAreConsistentAcrossModes(testCase)
sourceSignal = [1; 2; 3; 4];
delaySamples = [0, 1, 3, 2];

integerSignals = micloc.simulateMicrophoneSignals( ...
    sourceSignal, delaySamples, 'integer');
fractionalModeSignals = micloc.simulateMicrophoneSignals( ...
    sourceSignal, delaySamples, 'fractional');

verifyEqual(testCase, fractionalModeSignals, double(integerSignals));
end

function testArbitraryMicrophoneCountAndCustomFilter(testCase)
sourceSignal = [1; zeros(31, 1)];
delaySamples = linspace(0, 2.75, 8);

[microphoneSignals, diagnostics] = micloc.simulateMicrophoneSignals( ...
    sourceSignal, delaySamples, 'fractional', 33);

verifySize(testCase, microphoneSignals, [35, 8]);
verifyEqual(testCase, diagnostics.microphoneCount, 8);
verifyEqual(testCase, diagnostics.fractionalFilterLength, 33);
verifyEqual(testCase, diagnostics.filterGroupDelaySamples, 16);
verifyEqual(testCase, diagnostics.compensatedGroupDelaySamples, 16);
verifyEqual(testCase, numel(diagnostics.channelDiagnostics), 8);
end

function testBroadbandChannelsRecoverRequestedDelays(testCase)
sourceSignal = createBroadbandSignal();
requestedDelays = [0, 0.25, 0.75, 1.5, 2.25, 3.75];

microphoneSignals = micloc.simulateMicrophoneSignals( ...
    sourceSignal, requestedDelays, 'fractional');

for microphoneIndex = 1:numel(requestedDelays)
    estimatedDelay = estimateDelayFromBroadbandPhase( ...
        sourceSignal, microphoneSignals(:, microphoneIndex));
    verifyEqual(testCase, estimatedDelay, ...
        requestedDelays(microphoneIndex), 'AbsTol', 0.01);
end
end

function testGeometryDerivedDelaysAreApplied(testCase)
sampleRateHz = 8000;
speedOfSoundMetersPerSecond = 343;
microphonesMeters = [0, 0; 0.08, 0; 0, 0.08; 0.08, 0.08];
sourcePositionMeters = [1, 1.2];
arrivalTimesSeconds = micloc.calculateArrivalTimes( ...
    sourcePositionMeters, microphonesMeters, ...
    speedOfSoundMetersPerSecond);
delaySamples = arrivalTimesSeconds * sampleRateHz;
sourceSignal = createBroadbandSignal();

[microphoneSignals, diagnostics] = micloc.simulateMicrophoneSignals( ...
    sourceSignal, delaySamples, 'fractional');

verifySize(testCase, microphoneSignals, ...
    [numel(sourceSignal) + max(ceil(delaySamples)), 4]);
verifyEqual(testCase, diagnostics.requestedDelaySamples, delaySamples);
for microphoneIndex = 1:numel(delaySamples)
    estimatedDelay = estimateDelayFromBroadbandPhase( ...
        sourceSignal, microphoneSignals(:, microphoneIndex));
    verifyEqual(testCase, estimatedDelay, delaySamples(microphoneIndex), ...
        'AbsTol', 0.01);
end
end

function testRejectsInvalidFractionalMultichannelInputs(testCase)
sourceSignal = [1; 2; 3];
invalidCalls = { ...
    @() micloc.simulateMicrophoneSignals( ...
        sourceSignal, [0, -0.5], 'fractional'), ...
    @() micloc.simulateMicrophoneSignals( ...
        sourceSignal, [0, NaN], 'fractional'), ...
    @() micloc.simulateMicrophoneSignals( ...
        sourceSignal, [0, 0.5], 'fractional', 32), ...
    @() micloc.simulateMicrophoneSignals( ...
        sourceSignal, [0, 0.5], 'unknown')};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function sourceSignal = createBroadbandSignal()
config = micloc.defaultConfig();
config.sampleRateHz = 8000;
config.durationSeconds = 1.024;
config.randomSeed = 404;
sourceSignal = micloc.generateSourceSignal(config);
end

function estimatedDelay = estimateDelayFromBroadbandPhase( ...
        sourceSignal, delayedSignal)
commonLength = numel(delayedSignal);
sourcePadded = [sourceSignal; zeros(commonLength - numel(sourceSignal), 1)];
fftLength = 2 ^ nextpow2(commonLength);
sourceSpectrum = fft(sourcePadded, fftLength);
delayedSpectrum = fft(delayedSignal, fftLength);
positiveBins = (1:(fftLength / 2 + 1)).';
angularFrequency = 2 * pi * (positiveBins - 1) / fftLength;
sourceMagnitude = abs(sourceSpectrum(positiveBins));
crossSpectrum = delayedSpectrum(positiveBins) ...
    .* conj(sourceSpectrum(positiveBins));
unwrappedPhase = unwrap(angle(crossSpectrum));
validBand = angularFrequency >= 0.05 * pi ...
    & angularFrequency <= 0.65 * pi ...
    & sourceMagnitude >= 0.02 * max(sourceMagnitude);
fitCoefficients = polyfit( ...
    angularFrequency(validBand), unwrappedPhase(validBand), 1);
estimatedDelay = -fitCoefficients(1);
end

function verifyCallFails(testCase, functionHandle)
caughtIdentifier = '';
try
    functionHandle();
catch errorInfo
    caughtIdentifier = errorInfo.identifier;
end

verifyNotEmpty(testCase, caughtIdentifier, ...
    'Expected invalid multichannel input to raise an identified error.');
end
