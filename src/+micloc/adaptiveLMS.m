function [finalCoefficients, outputSignal, errorSignal, diagnostics] = ...
        adaptiveLMS( ...
        inputSignal, desiredSignal, filterLength, stepSize, ...
        initialCoefficients, storeCoefficientHistory)
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
%   LENGTH-element coefficient vector. Pass [] to use zeros when supplying
%   the sixth argument.
%
%   [COEFFICIENTS, OUTPUT, ERROR] also returns N-by-1 sequences calculated
%   before each coefficient update. ERROR = DESIRED - OUTPUT, followed by
%   the update w = w + STEP * ERROR(n) * x_n.
%
%   [COEFFICIENTS, OUTPUT, ERROR, DIAGNOSTICS] returns the update count,
%   squared-error history, overall and endpoint-window MSE summaries, MSE
%   reduction in decibels, and settings. Set STORECOEFFICIENTHISTORY to a
%   logical true to include an (N+1)-by-LENGTH coefficient history. Its
%   first row is the initial state and row n+1 is the state after update n.

narginchk(4, 6);
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

if nargin < 5 || isempty(initialCoefficients)
    initialCoefficients = zeros(filterLength, 1);
else
    validateattributes(initialCoefficients, {'numeric'}, ...
        {'real', 'vector', 'finite', 'numel', filterLength}, mfilename, ...
        'initialCoefficients');
    initialCoefficients = initialCoefficients(:);
end
if nargin < 6
    storeCoefficientHistory = false;
elseif ~(islogical(storeCoefficientHistory) ...
        && isscalar(storeCoefficientHistory))
    error('micloc:adaptiveLMS:InvalidHistorySetting', ...
        'storeCoefficientHistory must be a logical scalar.');
end

inputSignal = inputSignal(:);
desiredSignal = desiredSignal(:);
outputSignal = zeros(sampleCount, 1);
errorSignal = zeros(sampleCount, 1);
rollingInput = zeros(filterLength, 1);
finalCoefficients = initialCoefficients;
if storeCoefficientHistory
    coefficientHistory = zeros(sampleCount + 1, filterLength);
    coefficientHistory(1, :) = initialCoefficients.';
else
    coefficientHistory = [];
end

for sampleIndex = 1:sampleCount
    rollingInput(2:end) = rollingInput(1:(end - 1));
    rollingInput(1) = inputSignal(sampleIndex);
    outputSignal(sampleIndex) = finalCoefficients.' * rollingInput;
    errorSignal(sampleIndex) = desiredSignal(sampleIndex) ...
        - outputSignal(sampleIndex);
    finalCoefficients = finalCoefficients ...
        + stepSize * errorSignal(sampleIndex) * rollingInput;
    if storeCoefficientHistory
        coefficientHistory(sampleIndex + 1, :) = finalCoefficients.';
    end
end

squaredErrorHistory = errorSignal .^ 2;
mseWindowLength = min(sampleCount, max(filterLength, ceil(sampleCount / 10)));
initialWindowMeanSquaredError = mean( ...
    squaredErrorHistory(1:mseWindowLength));
finalWindowMeanSquaredError = mean( ...
    squaredErrorHistory((end - mseWindowLength + 1):end));

diagnostics.numberOfUpdates = sampleCount;
diagnostics.sampleCount = sampleCount;
diagnostics.filterLength = filterLength;
diagnostics.stepSize = stepSize;
diagnostics.initialCoefficients = initialCoefficients;
diagnostics.meanSquaredError = mean(squaredErrorHistory);
diagnostics.initialWindowMeanSquaredError = initialWindowMeanSquaredError;
diagnostics.finalWindowMeanSquaredError = finalWindowMeanSquaredError;
diagnostics.mseWindowLength = mseWindowLength;
diagnostics.mseReductionDb = calculateMSEReduction( ...
    initialWindowMeanSquaredError, finalWindowMeanSquaredError);
diagnostics.squaredErrorHistory = squaredErrorHistory;
diagnostics.coefficientHistoryStored = storeCoefficientHistory;
diagnostics.coefficientHistory = coefficientHistory;
end

function validateSignal(signal, argumentName)
validateattributes(signal, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, argumentName);
end

function reductionDb = calculateMSEReduction(initialMSE, finalMSE)
if initialMSE == 0 && finalMSE == 0
    reductionDb = 0;
elseif finalMSE == 0
    reductionDb = Inf;
else
    reductionDb = 10 * log10(initialMSE / finalMSE);
end
end
