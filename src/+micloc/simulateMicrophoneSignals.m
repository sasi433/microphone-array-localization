function [microphoneSignals, diagnostics] = simulateMicrophoneSignals( ...
        sourceSignal, delaySamples, delayMethod)
%SIMULATEMICROPHONESIGNALS Simulate delayed microphone channels.
%   SIGNALS = MICLOC.SIMULATEMICROPHONESIGNALS(SOURCE, DELAYS, METHOD)
%   applies one nonnegative delay per microphone and returns a
%   samples-by-microphones matrix. In 'integer' mode, DELAYS must contain
%   integer sample counts. Each channel receives leading delay padding and
%   enough trailing zeros to share the common output length
%   NUMEL(SOURCE) + MAX(DELAYS). SOURCE orientation does not affect the
%   output layout.
%
%   [SIGNALS, DIAGNOSTICS] also returns the applied delays, dimensions, and
%   alignment information. Fractional mode is added by the planned
%   fractional-delay implementation.

validateattributes(sourceSignal, {'numeric'}, ...
    {'vector', 'nonempty', 'finite'}, mfilename, 'sourceSignal');
validateattributes(delaySamples, {'numeric'}, ...
    {'real', 'vector', 'nonempty', 'finite', 'integer', 'nonnegative'}, ...
    mfilename, 'delaySamples');

isCharacterRow = ischar(delayMethod) && isrow(delayMethod) ...
    && ~isempty(delayMethod);
isStringScalar = isstring(delayMethod) && isscalar(delayMethod) ...
    && strlength(delayMethod) > 0;
if ~(isCharacterRow || isStringScalar) ...
        || ~strcmpi(char(delayMethod), 'integer')
    error('micloc:simulateMicrophoneSignals:UnsupportedDelayMethod', ...
        'Delay method must be ''integer'' at this implementation stage.');
end

sourceSignal = sourceSignal(:);
delaySamples = delaySamples(:);
microphoneCount = numel(delaySamples);
maximumDelaySamples = max(delaySamples);
inputSampleCount = numel(sourceSignal);
outputSampleCount = inputSampleCount + maximumDelaySamples;
microphoneSignals = zeros( ...
    outputSampleCount, microphoneCount, 'like', sourceSignal);

for microphoneIndex = 1:microphoneCount
    delayedChannel = micloc.applyIntegerDelay( ...
        sourceSignal, delaySamples(microphoneIndex));
    microphoneSignals(1:numel(delayedChannel), microphoneIndex) ...
        = delayedChannel;
end

diagnostics.delayMethod = 'integer';
diagnostics.requestedDelaySamples = delaySamples;
diagnostics.appliedDelaySamples = delaySamples;
diagnostics.groupDelaySamples = 0;
diagnostics.inputSampleCount = inputSampleCount;
diagnostics.outputSampleCount = outputSampleCount;
diagnostics.microphoneCount = microphoneCount;
diagnostics.maximumDelaySamples = maximumDelaySamples;
end
