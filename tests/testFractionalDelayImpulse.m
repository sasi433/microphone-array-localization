function tests = testFractionalDelayImpulse
%TESTFRACTIONALDELAYIMPULSE Impulse tests for windowed-sinc delays.
tests = functiontests(localfunctions);
end

function testZeroDelayIsExact(testCase)
impulse = [zeros(4, 1); 1; zeros(4, 1)];

[delayed, diagnostics] = micloc.applyFractionalDelay(impulse, 0);

verifyEqual(testCase, delayed, impulse);
verifyFalse(testCase, diagnostics.interpolationApplied);
verifyEqual(testCase, diagnostics.outputSampleCount, numel(impulse));
end

function testIntegerDelayMatchesIntegerImplementation(testCase)
impulse = [1; zeros(31, 1)];

for delaySamples = 0:5
    fractionalFunctionOutput = micloc.applyFractionalDelay( ...
        impulse, delaySamples);
    integerFunctionOutput = micloc.applyIntegerDelay( ...
        double(impulse), delaySamples);
    verifyEqual(testCase, fractionalFunctionOutput, integerFunctionOutput);
end
end

function testFractionalImpulseResponseMatchesReportedCoefficients(testCase)
inputSampleCount = 192;
impulseIndex = 80;
requestedDelaySamples = 3.25;
impulse = zeros(inputSampleCount, 1);
impulse(impulseIndex) = 1;

[delayed, diagnostics] = micloc.applyFractionalDelay( ...
    impulse, requestedDelaySamples);
integerDelaySamples = diagnostics.integerDelaySamples;
halfLength = diagnostics.filterGroupDelaySamples;
responseStart = impulseIndex + integerDelaySamples - halfLength;
responseEnd = impulseIndex + integerDelaySamples + halfLength;

verifyEqual(testCase, delayed(responseStart:responseEnd), ...
    diagnostics.filterCoefficients, 'AbsTol', 2e-15);
verifyEqual(testCase, delayed(1:(responseStart - 1)), ...
    zeros(responseStart - 1, 1), 'AbsTol', 2e-15);
verifyEqual(testCase, delayed((responseEnd + 1):end), ...
    zeros(numel(delayed) - responseEnd, 1), 'AbsTol', 2e-15);
end

function testFractionalOutputLengthUsesCeilingPolicy(testCase)
impulse = [1; zeros(15, 1)];
requestedDelays = [0.1, 0.5, 0.9, 1.25, 4.75];

for delayIndex = 1:numel(requestedDelays)
    delayed = micloc.applyFractionalDelay( ...
        impulse, requestedDelays(delayIndex));
    expectedLength = numel(impulse) + ceil(requestedDelays(delayIndex));
    verifyEqual(testCase, numel(delayed), expectedLength);
end
end

function testGroupDelayIsExplicitlyCompensated(testCase)
impulse = [zeros(95, 1); 1; zeros(95, 1)];

[~, diagnostics] = micloc.applyFractionalDelay(impulse, 0.5, 65);

verifyEqual(testCase, diagnostics.filterGroupDelaySamples, 32);
verifyEqual(testCase, diagnostics.compensatedGroupDelaySamples, 32);
verifyEqual(testCase, diagnostics.netFixedGroupDelaySamples, 0);
verifyEqual(testCase, diagnostics.integerDelaySamples, 0);
verifyEqual(testCase, diagnostics.fractionalDelaySamples, 0.5);
end

function testFilterHasUnitDCGain(testCase)
impulse = [zeros(63, 1); 1; zeros(63, 1)];
fractionalDelays = [0.1, 0.25, 0.5, 0.75, 0.9];

for delayIndex = 1:numel(fractionalDelays)
    [~, diagnostics] = micloc.applyFractionalDelay( ...
        impulse, fractionalDelays(delayIndex));
    verifyEqual(testCase, sum(diagnostics.filterCoefficients), 1, ...
        'AbsTol', 2e-15);
end
end

function testCustomOddFilterLengthAndOrientation(testCase)
rowImpulse = [1, zeros(1, 31)];

[delayed, diagnostics] = micloc.applyFractionalDelay( ...
    rowImpulse, 0.25, 33);

verifyTrue(testCase, isrow(delayed));
verifyEqual(testCase, diagnostics.filterLength, 33);
verifyEqual(testCase, diagnostics.filterGroupDelaySamples, 16);
verifyEqual(testCase, numel(diagnostics.filterCoefficients), 33);
verifyClass(testCase, delayed, 'double');
end

function testComplexImpulseIsSupported(testCase)
impulse = complex(zeros(64, 1));
impulse(32) = 1 + 2i;

delayed = micloc.applyFractionalDelay(impulse, 0.5);
reference = (1 + 2i) * micloc.applyFractionalDelay( ...
    double(impulse ~= 0), 0.5);

verifyEqual(testCase, delayed, reference, 'AbsTol', 2e-15);
end

function testRejectsInvalidFractionalDelayInputs(testCase)
invalidCalls = { ...
    @() micloc.applyFractionalDelay([], 0.5), ...
    @() micloc.applyFractionalDelay([1, NaN], 0.5), ...
    @() micloc.applyFractionalDelay([1, 2], -0.1), ...
    @() micloc.applyFractionalDelay([1, 2], Inf), ...
    @() micloc.applyFractionalDelay([1, 2], 0.5, 2), ...
    @() micloc.applyFractionalDelay([1, 2], 0.5, 32)};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function verifyCallFails(testCase, functionHandle)
caughtIdentifier = '';
try
    functionHandle();
catch errorInfo
    caughtIdentifier = errorInfo.identifier;
end

verifyNotEmpty(testCase, caughtIdentifier, ...
    'Expected invalid fractional-delay input to raise an identified error.');
end
