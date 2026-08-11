function tests = testLMSDelayEstimation
%TESTLMSDELAYESTIMATION Validate LMS estimates across signed clean lags.
tests = functiontests(localfunctions);
end

function testEstimatesZeroLag(testCase)
result = runDelayCase(0, 401);

verifyEqual(testCase, result.peakDelaySamples, 0);
verifyEqual(testCase, result.phaseDelaySamples, 0, 'AbsTol', 1e-8);
verifyEqual(testCase, result.alignment.zeroTDOACausalLagSamples, 8);
verifyGreaterThan(testCase, result.lms.mseReductionDb, 0);
end

function testEstimatesPositiveIntegerLag(testCase)
result = runDelayCase(2, 402);

verifyEqual(testCase, result.peakDelaySamples, 2);
verifyEqual(testCase, result.phaseDelaySamples, 2, 'AbsTol', 1e-8);
verifyEqual(testCase, result.peak.causalDelaySamples, 10);
end

function testEstimatesNegativeIntegerLag(testCase)
result = runDelayCase(-3, 403);

verifyEqual(testCase, result.peakDelaySamples, -3);
verifyEqual(testCase, result.phaseDelaySamples, -3, 'AbsTol', 1e-8);
verifyEqual(testCase, result.peak.causalDelaySamples, 5);
end

function testEstimatesPositiveFractionalLag(testCase)
trueDelaySamples = 2.4;
result = runDelayCase(trueDelaySamples, 404);

verifyLessThanOrEqual(testCase, ...
    abs(result.peakDelaySamples - trueDelaySamples), 0.51);
verifyLessThan(testCase, ...
    abs(result.phaseDelaySamples - trueDelaySamples), 0.02);
verifyEqual(testCase, result.peak.resolutionSamples, 1);
verifyEqual(testCase, result.phase.fitQuality, 'good');
end

function testEstimatesNegativeFractionalLag(testCase)
trueDelaySamples = -1.5;
result = runDelayCase(trueDelaySamples, 405);

verifyLessThanOrEqual(testCase, ...
    abs(result.peakDelaySamples - trueDelaySamples), 0.51);
verifyLessThan(testCase, ...
    abs(result.phaseDelaySamples - trueDelaySamples), 0.02);
verifyGreaterThan(testCase, result.phase.phaseFitRSquared, 0.99);
end

function result = runDelayCase(trueDelaySamples, randomSeed)
sampleRateHz = 48000;
sampleCount = 20000;
bulkDelaySamples = 8;
adaptiveFilterLength = 25;
stepSize = 0.003;

randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
sourceSignal = randn(randomStream, sampleCount, 1);
referenceDelaySamples = max(0, -trueDelaySamples);
comparisonDelaySamples = max(0, trueDelaySamples);
referenceSignal = micloc.applyFractionalDelay( ...
    sourceSignal, referenceDelaySamples);
comparisonSignal = micloc.applyFractionalDelay( ...
    sourceSignal, comparisonDelaySamples);
[referenceSignal, comparisonSignal] = equalizeLengths( ...
    referenceSignal, comparisonSignal);

[adaptiveInput, desiredSignal, alignmentDiagnostics] = ...
    micloc.alignMicrophonePairForLMS( ...
    referenceSignal, comparisonSignal, bulkDelaySamples);
[filterCoefficients, ~, ~, lmsDiagnostics] = micloc.adaptiveLMS( ...
    adaptiveInput, desiredSignal, adaptiveFilterLength, stepSize);
[peakDelaySamples, peakDiagnostics] = ...
    micloc.estimateDelayFromImpulseResponse( ...
    filterCoefficients, bulkDelaySamples);
[phaseDelaySamples, phaseDiagnostics] = micloc.estimateDelayFromPhase( ...
    filterCoefficients, sampleRateHz, bulkDelaySamples, ...
    [1000, 18000], 0.1, 0);

result.peakDelaySamples = peakDelaySamples;
result.phaseDelaySamples = phaseDelaySamples;
result.alignment = alignmentDiagnostics;
result.lms = lmsDiagnostics;
result.peak = peakDiagnostics;
result.phase = phaseDiagnostics;
end

function [firstSignal, secondSignal] = equalizeLengths( ...
        firstSignal, secondSignal)
commonSampleCount = max(numel(firstSignal), numel(secondSignal));
firstSignal((end + 1):commonSampleCount, 1) = 0;
secondSignal((end + 1):commonSampleCount, 1) = 0;
end
