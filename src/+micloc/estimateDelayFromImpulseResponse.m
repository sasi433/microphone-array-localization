function [relativeDelaySamples, diagnostics] = ...
        estimateDelayFromImpulseResponse(filterCoefficients, ...
        bulkDelaySamples)
%ESTIMATEDELAYFROMIMPULSERESPONSE Estimate signed delay from an FIR peak.
%   DELAYSAMPLES = MICLOC.ESTIMATEDELAYFROMIMPULSERESPONSE(COEFFICIENTS,
%   BULKDELAY) finds the unique largest absolute FIR coefficient. With
%   zero-delay-first coefficient ordering, its zero-based index is the
%   causal lag. The returned microphone TDOA is
%   causalLagSamples - BULKDELAY, where positive means the comparison
%   microphone received the signal later than the reference microphone.
%
%   This estimator has one-sample resolution and does not interpolate the
%   peak. A zero response or exactly tied largest magnitudes is rejected as
%   unidentifiable rather than resolved by coefficient order.
%
%   [DELAYSAMPLES, DIAGNOSTICS] reports the selected coefficient, causal
%   lag, bulk delay, peak magnitudes, and peak-to-second-peak ratio.

validateattributes(filterCoefficients, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, ...
    'filterCoefficients');
validateattributes(bulkDelaySamples, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, ...
    'bulkDelaySamples');

coefficientColumn = filterCoefficients(:);
filterLength = numel(coefficientColumn);
if bulkDelaySamples >= filterLength
    error('micloc:estimateDelayFromImpulseResponse:BulkDelayOutsideFilter', ...
        'Bulk delay must be smaller than the adaptive-filter length.');
end

coefficientMagnitudes = abs(coefficientColumn);
peakMagnitude = max(coefficientMagnitudes);
if peakMagnitude == 0
    error('micloc:estimateDelayFromImpulseResponse:ZeroResponse', ...
        'A zero impulse response does not identify a delay.');
end

peakIndices = find(coefficientMagnitudes == peakMagnitude);
if numel(peakIndices) ~= 1
    error('micloc:estimateDelayFromImpulseResponse:AmbiguousPeak', ...
        'The impulse response has multiple equal-magnitude largest peaks.');
end

peakCoefficientIndex = peakIndices(1);
causalDelaySamples = peakCoefficientIndex - 1;
relativeDelaySamples = causalDelaySamples - bulkDelaySamples;

remainingMagnitudes = coefficientMagnitudes;
remainingMagnitudes(peakCoefficientIndex) = [];
if isempty(remainingMagnitudes)
    secondPeakMagnitude = 0;
else
    secondPeakMagnitude = max(remainingMagnitudes);
end
if secondPeakMagnitude == 0
    peakToSecondPeakRatio = Inf;
else
    peakToSecondPeakRatio = peakMagnitude / secondPeakMagnitude;
end

diagnostics.method = 'impulse-response-peak';
diagnostics.filterLength = filterLength;
diagnostics.bulkDelaySamples = bulkDelaySamples;
diagnostics.peakCoefficientIndex = peakCoefficientIndex;
diagnostics.causalDelaySamples = causalDelaySamples;
diagnostics.relativeDelaySamples = relativeDelaySamples;
diagnostics.peakCoefficient = coefficientColumn(peakCoefficientIndex);
diagnostics.peakMagnitude = peakMagnitude;
diagnostics.secondPeakMagnitude = secondPeakMagnitude;
diagnostics.peakToSecondPeakRatio = peakToSecondPeakRatio;
diagnostics.resolutionSamples = 1;
diagnostics.tdoaSignConvention = ...
    'comparison arrival minus reference arrival';
end
