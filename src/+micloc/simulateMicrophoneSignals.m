function [microphoneSignals, diagnostics] = simulateMicrophoneSignals( ...
        sourceSignal, delaySamples, delayMethod, fractionalFilterLength)
%SIMULATEMICROPHONESIGNALS Simulate delayed microphone channels.
%   SIGNALS = MICLOC.SIMULATEMICROPHONESIGNALS(SOURCE, DELAYS, METHOD)
%   applies one nonnegative delay per microphone and returns a
%   samples-by-microphones matrix. METHOD is 'integer' or 'fractional'. In
%   integer mode, DELAYS must contain integer sample counts. In fractional
%   mode, each delay uses the windowed-sinc implementation and the common
%   output length is NUMEL(SOURCE) + MAX(CEIL(DELAYS)). Each shorter channel
%   receives trailing zeros. SOURCE orientation does not affect the output
%   layout.
%
%   SIGNALS = MICLOC.SIMULATEMICROPHONESIGNALS(..., FILTERLENGTH) selects
%   an odd fractional-delay filter length. The default is 65 taps. This
%   argument is validated and used only in fractional mode.
%
%   [SIGNALS, DIAGNOSTICS] also returns the applied delays, dimensions,
%   group-delay alignment, filter settings, and per-channel diagnostics.

if nargin < 4
    fractionalFilterLength = 65;
end

validateattributes(sourceSignal, {'numeric'}, ...
    {'vector', 'nonempty', 'finite'}, mfilename, 'sourceSignal');
validateattributes(delaySamples, {'numeric'}, ...
    {'real', 'vector', 'nonempty', 'finite', 'nonnegative'}, ...
    mfilename, 'delaySamples');

isCharacterRow = ischar(delayMethod) && isrow(delayMethod) ...
    && ~isempty(delayMethod);
isStringScalar = isstring(delayMethod) && isscalar(delayMethod) ...
    && strlength(delayMethod) > 0;
if ~(isCharacterRow || isStringScalar)
    error('micloc:simulateMicrophoneSignals:UnsupportedDelayMethod', ...
        'Delay method must be a nonempty text scalar.');
end
delayMethod = lower(char(delayMethod));
if ~any(strcmp(delayMethod, {'integer', 'fractional'}))
    error('micloc:simulateMicrophoneSignals:UnsupportedDelayMethod', ...
        'Delay method must be ''integer'' or ''fractional''.');
end
if strcmp(delayMethod, 'integer') && any(delaySamples ~= floor(delaySamples))
    error('micloc:simulateMicrophoneSignals:NonintegerDelay', ...
        'Integer mode requires whole-sample delays.');
end
if strcmp(delayMethod, 'fractional')
    validateattributes(fractionalFilterLength, {'numeric'}, ...
        {'real', 'scalar', 'finite', 'integer', '>=', 3}, mfilename, ...
        'fractionalFilterLength');
    if mod(fractionalFilterLength, 2) == 0
        error('micloc:simulateMicrophoneSignals:EvenFilterLength', ...
            'Fractional-delay filter length must be odd.');
    end
end

sourceSignal = sourceSignal(:);
delaySamples = delaySamples(:);
microphoneCount = numel(delaySamples);
maximumDelaySamples = max(delaySamples);
inputSampleCount = numel(sourceSignal);
outputSampleCount = inputSampleCount + max(ceil(delaySamples));
if strcmp(delayMethod, 'integer')
    microphoneSignals = zeros( ...
        outputSampleCount, microphoneCount, 'like', sourceSignal);
else
    microphoneSignals = zeros(outputSampleCount, microphoneCount);
end
channelDiagnostics = cell(microphoneCount, 1);

for microphoneIndex = 1:microphoneCount
    if strcmp(delayMethod, 'integer')
        delayedChannel = micloc.applyIntegerDelay( ...
            sourceSignal, delaySamples(microphoneIndex));
        channelDiagnostics{microphoneIndex} = struct( ...
            'delayMethod', 'integer', ...
            'requestedDelaySamples', delaySamples(microphoneIndex), ...
            'appliedDelaySamples', delaySamples(microphoneIndex), ...
            'netFixedGroupDelaySamples', 0);
    else
        [delayedChannel, channelDiagnostics{microphoneIndex}] = ...
            micloc.applyFractionalDelay(sourceSignal, ...
            delaySamples(microphoneIndex), fractionalFilterLength);
    end
    microphoneSignals(1:numel(delayedChannel), microphoneIndex) ...
        = delayedChannel;
end

diagnostics.delayMethod = delayMethod;
diagnostics.requestedDelaySamples = delaySamples;
diagnostics.appliedDelaySamples = delaySamples;
diagnostics.groupDelaySamples = 0;
diagnostics.inputSampleCount = inputSampleCount;
diagnostics.outputSampleCount = outputSampleCount;
diagnostics.microphoneCount = microphoneCount;
diagnostics.maximumDelaySamples = maximumDelaySamples;
diagnostics.maximumOutputDelaySamples = max(ceil(delaySamples));
if strcmp(delayMethod, 'fractional')
    diagnostics.fractionalFilterLength = fractionalFilterLength;
    diagnostics.filterGroupDelaySamples = ...
        (fractionalFilterLength - 1) / 2;
    diagnostics.compensatedGroupDelaySamples = ...
        diagnostics.filterGroupDelaySamples;
else
    diagnostics.fractionalFilterLength = 0;
    diagnostics.filterGroupDelaySamples = 0;
    diagnostics.compensatedGroupDelaySamples = 0;
end
diagnostics.channelDiagnostics = channelDiagnostics;
end
