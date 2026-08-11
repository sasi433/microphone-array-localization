function [adaptiveInputSignal, desiredSignal, diagnostics] = ...
        alignMicrophonePairForLMS(referenceSignal, comparisonSignal, ...
        bulkDelaySamples)
%ALIGNMICROPHONEPAIRFORLMS Make signed pair delays causal for LMS.
%   [INPUT, DESIRED, DIAGNOSTICS] =
%   MICLOC.ALIGNMICROPHONEPAIRFORLMS(REFERENCE, COMPARISON, BULKDELAY)
%   prepares an equal-length microphone pair for causal adaptive filtering.
%   REFERENCE becomes INPUT with BULKDELAY trailing zeros. COMPARISON is
%   delayed by BULKDELAY samples to form DESIRED.
%
%   The microphone TDOA convention is comparison arrival minus reference
%   arrival, so a positive value means COMPARISON arrived later. If the LMS
%   impulse response identifies a zero-based causal lag K, the signed TDOA
%   is K - BULKDELAY samples. BULKDELAY must therefore be at least the
%   magnitude of the most negative TDOA that must be represented.
%
%   Inputs must be equal-length, nonempty, finite, real numeric vectors.
%   Outputs are double-precision columns with NUMEL(REFERENCE)+BULKDELAY
%   samples. No original samples are discarded.

validateSignal(referenceSignal, 'referenceSignal');
validateSignal(comparisonSignal, 'comparisonSignal');
validateattributes(bulkDelaySamples, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, ...
    'bulkDelaySamples');

inputSampleCount = numel(referenceSignal);
if numel(comparisonSignal) ~= inputSampleCount
    error('micloc:alignMicrophonePairForLMS:MismatchedSignalLengths', ...
        'Reference and comparison signals must have equal lengths.');
end

referenceColumn = double(referenceSignal(:));
comparisonColumn = double(comparisonSignal(:));
bulkPadding = zeros(bulkDelaySamples, 1);
adaptiveInputSignal = [referenceColumn; bulkPadding];
desiredSignal = [bulkPadding; comparisonColumn];

diagnostics.bulkDelaySamples = bulkDelaySamples;
diagnostics.zeroTDOACausalLagSamples = bulkDelaySamples;
diagnostics.zeroTDOACoefficientIndex = bulkDelaySamples + 1;
diagnostics.inputSampleCount = inputSampleCount;
diagnostics.outputSampleCount = numel(adaptiveInputSignal);
diagnostics.originalSamplesDiscarded = 0;
diagnostics.relativeDelayFormula = ...
    'signedTDOASamples = causalLagSamples - bulkDelaySamples';
diagnostics.tdoaSignConvention = ...
    'comparison arrival minus reference arrival';
end

function validateSignal(signal, argumentName)
validateattributes(signal, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, argumentName);
end
