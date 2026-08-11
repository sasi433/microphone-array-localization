function tests = testLMSDelayMethodComparison
%TESTLMSDELAYMETHODCOMPARISON Compare peak and phase on identical filters.
tests = functiontests(localfunctions);
end

function testBothMethodsRecoverCleanIntegerDelays(testCase)
trueDelaysSamples = [-3, 0, 2];
peakEstimatesSamples = zeros(size(trueDelaysSamples));
phaseEstimatesSamples = zeros(size(trueDelaysSamples));

for caseIndex = 1:numel(trueDelaysSamples)
    comparison = estimateBothMethods( ...
        trueDelaysSamples(caseIndex), 510 + caseIndex);
    peakEstimatesSamples(caseIndex) = comparison.peakDelaySamples;
    phaseEstimatesSamples(caseIndex) = comparison.phaseDelaySamples;
    verifyEqual(testCase, comparison.peakDiagnostics.method, ...
        'impulse-response-peak');
    verifyEqual(testCase, comparison.phaseDiagnostics.method, ...
        'unwrapped-phase-slope');
end

verifyEqual(testCase, peakEstimatesSamples, trueDelaysSamples);
verifyEqual(testCase, phaseEstimatesSamples, trueDelaysSamples, ...
    'AbsTol', 1e-8);
end

function testPhaseSlopeImprovesCleanFractionalDelayAccuracy(testCase)
trueDelaysSamples = [-2.6, 1.75, 3.4];
peakErrorsSamples = zeros(size(trueDelaysSamples));
phaseErrorsSamples = zeros(size(trueDelaysSamples));

for caseIndex = 1:numel(trueDelaysSamples)
    comparison = estimateBothMethods( ...
        trueDelaysSamples(caseIndex), 500 + caseIndex);
    peakErrorsSamples(caseIndex) = abs( ...
        comparison.peakDelaySamples - trueDelaysSamples(caseIndex));
    phaseErrorsSamples(caseIndex) = abs( ...
        comparison.phaseDelaySamples - trueDelaysSamples(caseIndex));
end

verifyLessThanOrEqual(testCase, max(peakErrorsSamples), 0.5);
verifyLessThan(testCase, max(phaseErrorsSamples), 0.02);
verifyLessThan(testCase, mean(phaseErrorsSamples), ...
    mean(peakErrorsSamples));
end

function comparison = estimateBothMethods(trueDelaySamples, randomSeed)
sampleRateHz = 48000;
bulkDelaySamples = 8;
randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
sourceSignal = randn(randomStream, 20000, 1);
referenceSignal = micloc.applyFractionalDelay( ...
    sourceSignal, max(0, -trueDelaySamples));
comparisonSignal = micloc.applyFractionalDelay( ...
    sourceSignal, max(0, trueDelaySamples));
[referenceSignal, comparisonSignal] = equalizeLengths( ...
    referenceSignal, comparisonSignal);
[adaptiveInput, desiredSignal] = micloc.alignMicrophonePairForLMS( ...
    referenceSignal, comparisonSignal, bulkDelaySamples);
learnedCoefficients = micloc.adaptiveLMS( ...
    adaptiveInput, desiredSignal, 25, 0.003);

[comparison.peakDelaySamples, comparison.peakDiagnostics] = ...
    micloc.estimateDelayFromImpulseResponse( ...
    learnedCoefficients, bulkDelaySamples);
[comparison.phaseDelaySamples, comparison.phaseDiagnostics] = ...
    micloc.estimateDelayFromPhase(learnedCoefficients, sampleRateHz, ...
    bulkDelaySamples, [1000, 18000], 0.1, 0);
comparison.learnedCoefficients = learnedCoefficients;
end

function [firstSignal, secondSignal] = equalizeLengths( ...
        firstSignal, secondSignal)
commonSampleCount = max(numel(firstSignal), numel(secondSignal));
firstSignal((end + 1):commonSampleCount, 1) = 0;
secondSignal((end + 1):commonSampleCount, 1) = 0;
end
