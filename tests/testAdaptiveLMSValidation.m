function tests = testAdaptiveLMSValidation
%TESTADAPTIVELMSVALIDATION Validate public LMS inputs and failure cases.
tests = functiontests(localfunctions);
end

function testRejectsNonpositiveAndNonfiniteStepSizes(testCase)
[inputSignal, desiredSignal] = validSignals();
invalidStepSizes = {0, -0.01, Inf, NaN};

for valueIndex = 1:numel(invalidStepSizes)
    verifyCallFails(testCase, @() micloc.adaptiveLMS( ...
        inputSignal, desiredSignal, 2, invalidStepSizes{valueIndex}));
end
end

function testRejectsInvalidFilterLengths(testCase)
[inputSignal, desiredSignal] = validSignals();
invalidFilterLengths = {0, -1, 1.5, Inf, NaN};

for valueIndex = 1:numel(invalidFilterLengths)
    verifyCallFails(testCase, @() micloc.adaptiveLMS( ...
        inputSignal, desiredSignal, invalidFilterLengths{valueIndex}, 0.01));
end
end

function testRejectsSignalsShorterThanFilter(testCase)
verifyError(testCase, @() micloc.adaptiveLMS( ...
    ones(3, 1), ones(3, 1), 4, 0.01), ...
    'micloc:adaptiveLMS:SignalTooShort');
end

function testRejectsMismatchedSignalLengths(testCase)
verifyError(testCase, @() micloc.adaptiveLMS( ...
    ones(8, 1), ones(7, 1), 2, 0.01), ...
    'micloc:adaptiveLMS:MismatchedSignalLengths');
end

function testRejectsNonfiniteAndNonnumericSignals(testCase)
[inputSignal, desiredSignal] = validSignals();
invalidCalls = { ...
    @() micloc.adaptiveLMS([inputSignal(1:end-1); NaN], ...
        desiredSignal, 2, 0.01), ...
    @() micloc.adaptiveLMS(inputSignal, ...
        [desiredSignal(1:end-1); Inf], 2, 0.01), ...
    @() micloc.adaptiveLMS('input', desiredSignal, 2, 0.01)};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function testRejectsInvalidInitialCoefficients(testCase)
[inputSignal, desiredSignal] = validSignals();
invalidInitialCoefficients = { ...
    1, [1; NaN], [1; 1i], ones(2, 2), 'coefficients'};

for valueIndex = 1:numel(invalidInitialCoefficients)
    verifyCallFails(testCase, @() micloc.adaptiveLMS( ...
        inputSignal, desiredSignal, 2, 0.01, ...
        invalidInitialCoefficients{valueIndex}));
end
end

function testRejectsInvalidCoefficientHistorySettings(testCase)
[inputSignal, desiredSignal] = validSignals();
invalidHistorySettings = {0, 1, [true, false], 'true'};

for valueIndex = 1:numel(invalidHistorySettings)
    verifyError(testCase, @() micloc.adaptiveLMS( ...
        inputSignal, desiredSignal, 2, 0.01, [], ...
        invalidHistorySettings{valueIndex}), ...
        'micloc:adaptiveLMS:InvalidHistorySetting');
end
end

function [inputSignal, desiredSignal] = validSignals
inputSignal = (1:8).';
desiredSignal = 0.5 * inputSignal;
end

function verifyCallFails(testCase, functionHandle)
caughtIdentifier = '';
try
    functionHandle();
catch errorInfo
    caughtIdentifier = errorInfo.identifier;
end

verifyNotEmpty(testCase, caughtIdentifier, ...
    'Expected the invalid LMS input to raise an identified error.');
end
