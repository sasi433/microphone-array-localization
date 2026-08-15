function tests = testGCCPHATDelayEstimation
%TESTGCCPHATDELAYESTIMATION Validate signed clean and noisy GCC-PHAT lags.
tests = functiontests(localfunctions);
end

function testEstimatesZeroLagAndReportsDiagnostics(testCase)
referenceSignal = createBroadbandSignal(2048, 1301);

[estimatedDelaySamples, diagnostics] = ...
    micloc.estimateDelayGCCPHAT(referenceSignal, referenceSignal, 20);

verifyEqual(testCase, estimatedDelaySamples, 0, 'AbsTol', 1e-12);
verifyEqual(testCase, diagnostics.integerDelaySamples, 0);
verifyEqual(testCase, diagnostics.maximumLagSamples, 20);
verifyEqual(testCase, diagnostics.searchedLagsSamples, (-20:20).');
verifyEqual(testCase, diagnostics.method, 'gcc-phat');
verifyEqual(testCase, diagnostics.tdoaSignConvention, ...
    'comparison arrival minus reference arrival');
verifyGreaterThan(testCase, diagnostics.peakToSecondPeakRatio, 1);
end

function testEstimatesSignedIntegerLags(testCase)
requestedDelaysSamples = [6, -7];
for delayIndex = 1:numel(requestedDelaysSamples)
    requestedDelaySamples = requestedDelaysSamples(delayIndex);
    [comparisonSignal, referenceSignal] = createDelayPair( ...
        requestedDelaySamples, 1310 + delayIndex, 2048);

    [estimatedDelaySamples, diagnostics] = ...
        micloc.estimateDelayGCCPHAT( ...
        comparisonSignal, referenceSignal, 20);

    verifyEqual(testCase, estimatedDelaySamples, requestedDelaySamples, ...
        'AbsTol', 1e-10);
    verifyEqual(testCase, diagnostics.integerDelaySamples, ...
        requestedDelaySamples);
    verifyTrue(testCase, diagnostics.subsampleInterpolationApplied);
end
end

function testEstimatesSignedFractionalLags(testCase)
requestedDelaysSamples = [4.5, -2.5];
for delayIndex = 1:numel(requestedDelaysSamples)
    requestedDelaySamples = requestedDelaysSamples(delayIndex);
    [comparisonSignal, referenceSignal] = createDelayPair( ...
        requestedDelaySamples, 1320 + delayIndex, 8192);

    [estimatedDelaySamples, diagnostics] = ...
        micloc.estimateDelayGCCPHAT( ...
        comparisonSignal, referenceSignal, 20);

    verifyLessThan(testCase, ...
        abs(estimatedDelaySamples - requestedDelaySamples), 0.06);
    verifyTrue(testCase, diagnostics.subsampleInterpolationApplied);
    verifyEqual(testCase, diagnostics.subsampleInterpolationReason, ...
        'applied');
    verifyLessThanOrEqual(testCase, ...
        abs(diagnostics.fractionalOffsetSamples), 1);
end
end

function testEstimatesNoisyFractionalLagDeterministically(testCase)
requestedDelaySamples = 4.5;
[comparisonSignal, referenceSignal] = createDelayPair( ...
    requestedDelaySamples, 1330, 8192);
noisySignals = micloc.addNoiseAtSNR( ...
    [referenceSignal, comparisonSignal], 0, 1331);

firstEstimate = micloc.estimateDelayGCCPHAT( ...
    noisySignals(:, 2), noisySignals(:, 1), 20);
secondEstimate = micloc.estimateDelayGCCPHAT( ...
    noisySignals(:, 2), noisySignals(:, 1), 20);

verifyEqual(testCase, firstEstimate, secondEstimate);
verifyLessThan(testCase, ...
    abs(firstEstimate - requestedDelaySamples), 0.1);
end

function testGeometryBoundsConstrainThePeakSearch(testCase)
microphonePositionsMeters = [0, 0; 0.03, 0; 0, 0.04];
maximumTDOASamples = micloc.calculateMaximumTDOASamples( ...
    microphonePositionsMeters, 1, 48000, 343);
verifyEqual(testCase, maximumTDOASamples, [0; 5; 6]);

referenceSignal = createBroadbandSignal(2048, 1340);
comparisonSignal = micloc.applyIntegerDelay(referenceSignal, 12);
referenceSignal(end + 1:numel(comparisonSignal), 1) = 0;
[estimatedDelaySamples, diagnostics] = ...
    micloc.estimateDelayGCCPHAT( ...
    comparisonSignal, referenceSignal, maximumTDOASamples(2));

verifyLessThanOrEqual(testCase, abs(estimatedDelaySamples), 5);
verifyNotEqual(testCase, diagnostics.integerDelaySamples, 12);
verifyEqual(testCase, diagnostics.searchedLagsSamples, (-5:5).');
verifyTrue(testCase, diagnostics.lagConstraintApplied);
end

function testRejectsUnidentifiableAndInvalidSignals(testCase)
verifyError(testCase, @() micloc.estimateDelayGCCPHAT( ...
    ones(8, 1), ones(7, 1)), ...
    'micloc:estimateDelayGCCPHAT:MismatchedSignalLengths');
verifyError(testCase, @() micloc.estimateDelayGCCPHAT(1, 1), ...
    'micloc:estimateDelayGCCPHAT:SignalTooShort');
verifyError(testCase, @() micloc.estimateDelayGCCPHAT( ...
    zeros(8, 1), ones(8, 1)), ...
    'micloc:estimateDelayGCCPHAT:ZeroCrossSpectrum');
end

function signal = createBroadbandSignal(sampleCount, randomSeed)
randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
signal = randn(randomStream, sampleCount, 1);
end

function [comparisonSignal, referenceSignal] = createDelayPair( ...
        relativeDelaySamples, randomSeed, sampleCount)
sourceSignal = createBroadbandSignal(sampleCount, randomSeed);
referenceDelaySamples = max(0, -relativeDelaySamples);
comparisonDelaySamples = max(0, relativeDelaySamples);
referenceSignal = micloc.applyFractionalDelay( ...
    sourceSignal, referenceDelaySamples);
comparisonSignal = micloc.applyFractionalDelay( ...
    sourceSignal, comparisonDelaySamples);
commonSampleCount = max(numel(referenceSignal), numel(comparisonSignal));
referenceSignal(end + 1:commonSampleCount, 1) = 0;
comparisonSignal(end + 1:commonSampleCount, 1) = 0;
end
