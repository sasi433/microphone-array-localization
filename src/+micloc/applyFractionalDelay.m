function [delayedSignal, diagnostics] = applyFractionalDelay( ...
        signal, delaySamples, filterLength)
%APPLYFRACTIONALDELAY Apply a nonnegative windowed-sinc delay.
%   DELAYED = MICLOC.APPLYFRACTIONALDELAY(SIGNAL, DELAYSAMPLES) applies a
%   nonnegative delay using a 65-tap Hann-windowed sinc FIR. The fixed
%   32-sample FIR group delay is explicitly compensated. Exact integer
%   delays bypass interpolation. The output length is
%   NUMEL(SIGNAL) + CEIL(DELAYSAMPLES), vector orientation is preserved,
%   and output samples are double precision.
%
%   DELAYED = MICLOC.APPLYFRACTIONALDELAY(SIGNAL, DELAYSAMPLES, LENGTH)
%   uses an odd FIR LENGTH of at least three taps.
%
%   [DELAYED, DIAGNOSTICS] reports delay decomposition, filter and window
%   information, group-delay compensation, coefficients, and dimensions.

if nargin < 3
    filterLength = 65;
end

validateattributes(signal, {'numeric'}, ...
    {'vector', 'nonempty', 'finite'}, mfilename, 'signal');
validateattributes(delaySamples, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'delaySamples');
validateattributes(filterLength, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', '>=', 3}, mfilename, ...
    'filterLength');
if mod(filterLength, 2) == 0
    error('micloc:applyFractionalDelay:EvenFilterLength', ...
        'Fractional-delay filter length must be odd.');
end

inputWasRow = isrow(signal);
signalColumn = double(signal(:));
inputSampleCount = numel(signalColumn);
integerDelaySamples = floor(delaySamples);
fractionalDelaySamples = delaySamples - integerDelaySamples;

if fractionalDelaySamples == 0
    delayedColumn = micloc.applyIntegerDelay( ...
        signalColumn, integerDelaySamples);
    filterCoefficients = 1;
    filterGroupDelaySamples = 0;
    windowName = 'none';
    interpolationApplied = false;
else
    filterGroupDelaySamples = (filterLength - 1) / 2;
    tapCoordinates = (-filterGroupDelaySamples:filterGroupDelaySamples).';
    sincArguments = tapCoordinates - fractionalDelaySamples;
    idealResponse = ones(filterLength, 1);
    nonzeroArguments = sincArguments ~= 0;
    idealResponse(nonzeroArguments) = sin( ...
        pi * sincArguments(nonzeroArguments)) ...
        ./ (pi * sincArguments(nonzeroArguments));
    windowIndices = (0:(filterLength - 1)).';
    hannWindow = 0.5 - 0.5 * cos( ...
        2 * pi * windowIndices / (filterLength - 1));
    filterCoefficients = idealResponse .* hannWindow;
    filterCoefficients = filterCoefficients / sum(filterCoefficients);

    filteredSignal = conv(signalColumn, filterCoefficients, 'full');
    alignedStartIndex = filterGroupDelaySamples + 1;
    alignedEndIndex = alignedStartIndex + inputSampleCount;
    fractionallyDelayed = filteredSignal( ...
        alignedStartIndex:alignedEndIndex);
    delayedColumn = [zeros(integerDelaySamples, 1); fractionallyDelayed];
    windowName = 'hann';
    interpolationApplied = true;
end

if inputWasRow
    delayedSignal = delayedColumn.';
else
    delayedSignal = delayedColumn;
end

diagnostics.delayMethod = 'windowed-sinc';
diagnostics.requestedDelaySamples = delaySamples;
diagnostics.appliedDelaySamples = ...
    integerDelaySamples + fractionalDelaySamples;
diagnostics.integerDelaySamples = integerDelaySamples;
diagnostics.fractionalDelaySamples = fractionalDelaySamples;
diagnostics.filterLength = filterLength;
diagnostics.window = windowName;
diagnostics.filterGroupDelaySamples = filterGroupDelaySamples;
diagnostics.compensatedGroupDelaySamples = filterGroupDelaySamples;
diagnostics.netFixedGroupDelaySamples = 0;
diagnostics.interpolationApplied = interpolationApplied;
diagnostics.filterCoefficients = filterCoefficients;
diagnostics.inputSampleCount = inputSampleCount;
diagnostics.outputSampleCount = numel(delayedColumn);
end
