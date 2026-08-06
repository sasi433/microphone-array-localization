function [normalizedSignal, scaleFactor] = normalizeSignal( ...
        signal, targetPeak)
%NORMALIZESIGNAL Scale a signal to a requested absolute peak.
%   NORMALIZED = MICLOC.NORMALIZESIGNAL(SIGNAL) returns a double-precision
%   vector whose maximum absolute sample is one. Vector orientation is
%   preserved. An all-zero signal is returned unchanged.
%
%   [NORMALIZED, SCALE] = MICLOC.NORMALIZESIGNAL(SIGNAL, TARGETPEAK)
%   scales a nonzero signal to the positive finite TARGETPEAK and returns
%   the multiplicative SCALE. For an all-zero signal, SCALE is one because
%   no scaling is applied.

if nargin < 2
    targetPeak = 1;
end

validateattributes(signal, {'numeric'}, ...
    {'vector', 'nonempty', 'finite'}, mfilename, 'signal');
validateattributes(targetPeak, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'positive'}, mfilename, 'targetPeak');

signal = double(signal);
currentPeak = max(abs(signal));
if currentPeak == 0
    scaleFactor = 1;
else
    scaleFactor = targetPeak / currentPeak;
end

normalizedSignal = signal * scaleFactor;
end
