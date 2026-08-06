function powerValue = signalPower(signal)
%SIGNALPOWER Calculate mean-square discrete-time signal power.
%   POWER = MICLOC.SIGNALPOWER(SIGNAL) returns MEAN(ABS(SIGNAL).^2) as a
%   finite nonnegative double-precision scalar. SIGNAL must be a nonempty
%   finite numeric vector and may be real or complex.

validateattributes(signal, {'numeric'}, ...
    {'vector', 'nonempty', 'finite'}, mfilename, 'signal');

signal = double(signal);
powerValue = mean(abs(signal) .^ 2);
end
