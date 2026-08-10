function [finalCoefficients, outputSignal, errorSignal] = adaptiveLMS( ...
        inputSignal, desiredSignal, filterLength, stepSize, ...
        initialCoefficients)
%ADAPTIVELMS Identify a causal FIR system using standard LMS adaptation.
%   COEFFICIENTS = MICLOC.ADAPTIVELMS(INPUT, DESIRED, LENGTH, STEP) runs a
%   real-valued LENGTH-tap LMS adaptive filter. INPUT and DESIRED must be
%   equal-length finite vectors containing at least LENGTH samples. STEP
%   is the positive LMS step size. The initial coefficients are zero.
%
%   COEFFICIENTS are returned as an LENGTH-by-1 vector ordered from zero
%   delay to LENGTH-1 samples of delay. At sample n, coefficient k+1
%   multiplies INPUT(n-k), with samples before the input treated as zero.
%
%   MICLOC.ADAPTIVELMS(..., INITIALCOEFFICIENTS) starts from the supplied
%   LENGTH-element coefficient vector.
%
%   [COEFFICIENTS, OUTPUT, ERROR] also returns N-by-1 sequences calculated
%   before each coefficient update. ERROR = DESIRED - OUTPUT, followed by
%   the update w = w + STEP * ERROR(n) * x_n.

narginchk(4, 5);
validateSignal(inputSignal, 'inputSignal');
validateSignal(desiredSignal, 'desiredSignal');
validateattributes(filterLength, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, ...
    'filterLength');
validateattributes(stepSize, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'positive'}, mfilename, 'stepSize');

sampleCount = numel(inputSignal);
if numel(desiredSignal) ~= sampleCount
    error('micloc:adaptiveLMS:MismatchedSignalLengths', ...
        'Input and desired signals must contain the same number of samples.');
end
if sampleCount < filterLength
    error('micloc:adaptiveLMS:SignalTooShort', ...
        'Signals must contain at least as many samples as the filter length.');
end

if nargin < 5
    initialCoefficients = zeros(filterLength, 1);
else
    validateattributes(initialCoefficients, {'numeric'}, ...
        {'real', 'vector', 'finite', 'numel', filterLength}, mfilename, ...
        'initialCoefficients');
    initialCoefficients = initialCoefficients(:);
end

inputSignal = inputSignal(:);
desiredSignal = desiredSignal(:);
outputSignal = zeros(sampleCount, 1);
errorSignal = zeros(sampleCount, 1);
rollingInput = zeros(filterLength, 1);
finalCoefficients = initialCoefficients;

for sampleIndex = 1:sampleCount
    rollingInput(2:end) = rollingInput(1:(end - 1));
    rollingInput(1) = inputSignal(sampleIndex);
    outputSignal(sampleIndex) = finalCoefficients.' * rollingInput;
    errorSignal(sampleIndex) = desiredSignal(sampleIndex) ...
        - outputSignal(sampleIndex);
    finalCoefficients = finalCoefficients ...
        + stepSize * errorSignal(sampleIndex) * rollingInput;
end
end

function validateSignal(signal, argumentName)
validateattributes(signal, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, argumentName);
end
