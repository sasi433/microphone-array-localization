function delayedSignal = applyIntegerDelay(signal, delaySamples)
%APPLYINTEGERDELAY Apply a causal integer delay with zero padding.
%   DELAYED = MICLOC.APPLYINTEGERDELAY(SIGNAL, DELAYSAMPLES) prepends
%   DELAYSAMPLES zeros to a nonempty finite numeric vector. DELAYSAMPLES
%   must be a nonnegative integer. No input samples are discarded, so the
%   output length is NUMEL(SIGNAL) + DELAYSAMPLES. Row or column orientation
%   and numeric type are preserved. A zero delay returns SIGNAL unchanged.

validateattributes(signal, {'numeric'}, ...
    {'vector', 'nonempty', 'finite'}, mfilename, 'signal');
validateattributes(delaySamples, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, ...
    'delaySamples');

if isrow(signal)
    padding = zeros(1, delaySamples, 'like', signal);
    delayedSignal = [padding, signal];
else
    padding = zeros(delaySamples, 1, 'like', signal);
    delayedSignal = [padding; signal];
end
end
