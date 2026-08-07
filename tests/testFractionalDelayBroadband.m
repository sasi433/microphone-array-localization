function tests = testFractionalDelayBroadband
%TESTFRACTIONALDELAYBROADBAND Broadband tests for fractional delays.
tests = functiontests(localfunctions);
end

function testPhaseSlopeEstimatesRequestedDelays(testCase)
sourceSignal = createBroadbandSignal();
requestedDelays = [0.1, 0.25, 0.5, 0.75, 0.9, 2.25, 3.75];

for delayIndex = 1:numel(requestedDelays)
    delayedSignal = micloc.applyFractionalDelay( ...
        sourceSignal, requestedDelays(delayIndex));
    [estimatedDelay, phaseFitRmse, validBinCount] = ...
        estimateDelayFromBroadbandPhase(sourceSignal, delayedSignal);

    verifyEqual(testCase, estimatedDelay, requestedDelays(delayIndex), ...
        'AbsTol', 0.01);
    verifyLessThan(testCase, phaseFitRmse, 0.01);
    verifyGreaterThan(testCase, validBinCount, 1000);
end
end

function testCustomFilterLengthMeetsBroadbandTolerance(testCase)
sourceSignal = createBroadbandSignal();
requestedDelays = [0.25, 0.5, 0.75];

for delayIndex = 1:numel(requestedDelays)
    delayedSignal = micloc.applyFractionalDelay( ...
        sourceSignal, requestedDelays(delayIndex), 33);
    estimatedDelay = estimateDelayFromBroadbandPhase( ...
        sourceSignal, delayedSignal);

    verifyEqual(testCase, estimatedDelay, requestedDelays(delayIndex), ...
        'AbsTol', 0.01);
end
end

function testBroadbandPowerIsApproximatelyPreserved(testCase)
sourceSignal = createBroadbandSignal();
requestedDelays = [0.25, 0.5, 0.75];

for delayIndex = 1:numel(requestedDelays)
    delayedSignal = micloc.applyFractionalDelay( ...
        sourceSignal, requestedDelays(delayIndex));
    powerRatio = micloc.signalPower(delayedSignal) ...
        / micloc.signalPower(sourceSignal);

    verifyGreaterThan(testCase, powerRatio, 0.96);
    verifyLessThan(testCase, powerRatio, 1.04);
end
end

function testBroadbandDelayIsDeterministicAndFinite(testCase)
sourceSignal = createBroadbandSignal();

firstOutput = micloc.applyFractionalDelay(sourceSignal, 1.375);
secondOutput = micloc.applyFractionalDelay(sourceSignal, 1.375);

verifyEqual(testCase, firstOutput, secondOutput);
verifyTrue(testCase, all(isfinite(firstOutput)));
verifySize(testCase, firstOutput, [numel(sourceSignal) + 2, 1]);
end

function testFractionalDelayIsLinear(testCase)
sourceSignal = createBroadbandSignal();
secondSignal = flipud(sourceSignal);
delaySamples = 0.625;

combinedOutput = micloc.applyFractionalDelay( ...
    2 * sourceSignal - 0.5 * secondSignal, delaySamples);
separateOutput = 2 * micloc.applyFractionalDelay( ...
    sourceSignal, delaySamples) - 0.5 * micloc.applyFractionalDelay( ...
    secondSignal, delaySamples);

verifyEqual(testCase, combinedOutput, separateOutput, 'AbsTol', 2e-14);
end

function testFractionalDelayDoesNotChangeGlobalRandomState(testCase)
sourceSignal = createBroadbandSignal();
stateBefore = rng;

micloc.applyFractionalDelay(sourceSignal, 0.5);

stateAfter = rng;
verifyEqual(testCase, stateAfter, stateBefore);
end

function sourceSignal = createBroadbandSignal()
config = micloc.defaultConfig();
config.sampleRateHz = 8000;
config.durationSeconds = 1.024;
config.randomSeed = 2026;
sourceSignal = micloc.generateSourceSignal(config);
end

function [estimatedDelay, phaseFitRmse, validBinCount] = ...
        estimateDelayFromBroadbandPhase(sourceSignal, delayedSignal)
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
fittedPhase = polyval(fitCoefficients, angularFrequency(validBand));
phaseFitRmse = sqrt(mean( ...
    (unwrappedPhase(validBand) - fittedPhase) .^ 2));
validBinCount = nnz(validBand);
end
