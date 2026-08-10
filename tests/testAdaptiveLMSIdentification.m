function tests = testAdaptiveLMSIdentification
%TESTADAPTIVELMSIDENTIFICATION Identify deterministic known FIR systems.
tests = functiontests(localfunctions);
end

function testIdentifiesOneTapGain(testCase)
knownCoefficients = 1.75;
inputSignal = createInputSignal(3000, 101);
desiredSignal = filter(knownCoefficients, 1, inputSignal);

[estimatedCoefficients, outputSignal, errorSignal] = ...
    micloc.adaptiveLMS(inputSignal, desiredSignal, 1, 0.01);

verifyEqual(testCase, estimatedCoefficients, knownCoefficients, ...
    'AbsTol', 1e-8);
verifySize(testCase, outputSignal, size(inputSignal));
verifySize(testCase, errorSignal, size(inputSignal));
verifyLessThan(testCase, mean(errorSignal(end-499:end) .^ 2), 1e-12);
end

function testIdentifiesShortFIRFilter(testCase)
knownCoefficients = [0.4; -0.2; 0.15];
inputSignal = createInputSignal(8000, 102);
desiredSignal = filter(knownCoefficients, 1, inputSignal);

[estimatedCoefficients, ~, errorSignal] = micloc.adaptiveLMS( ...
    inputSignal, desiredSignal, numel(knownCoefficients), 0.005);

verifyEqual(testCase, estimatedCoefficients, knownCoefficients, ...
    'AbsTol', 1e-8);
verifyLessThan(testCase, mean(errorSignal(end-499:end) .^ 2), 1e-12);
end

function testIdentifiesDelayedImpulseFilter(testCase)
knownCoefficients = [0; 0; 1; 0];
inputSignal = createInputSignal(8000, 103);
desiredSignal = filter(knownCoefficients, 1, inputSignal);

[estimatedCoefficients, ~, errorSignal] = micloc.adaptiveLMS( ...
    inputSignal, desiredSignal, numel(knownCoefficients), 0.005);
[~, peakCoefficientIndex] = max(abs(estimatedCoefficients));

verifyEqual(testCase, estimatedCoefficients, knownCoefficients, ...
    'AbsTol', 1e-8);
verifyEqual(testCase, peakCoefficientIndex, 3);
verifyLessThan(testCase, mean(errorSignal(end-499:end) .^ 2), 1e-12);
end

function inputSignal = createInputSignal(sampleCount, randomSeed)
randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
inputSignal = randn(randomStream, sampleCount, 1);
end
