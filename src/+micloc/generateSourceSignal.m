function [sourceSignal, timeSeconds] = generateSourceSignal(config)
%GENERATESOURCESIGNAL Generate a deterministic synthetic source signal.
%   [SIGNAL, TIME] = MICLOC.GENERATESOURCESIGNAL(CONFIG) generates a
%   column-vector signal from the validated simulation configuration and a
%   matching time vector in seconds. Supported types are seeded Gaussian
%   broadband noise and a deterministic linear chirp. Gaussian-noise
%   generation uses a local random stream and does not modify MATLAB's
%   global random state.

config = micloc.validateConfig(config);
sampleCount = round(config.sampleRateHz * config.durationSeconds);
timeSeconds = (0:(sampleCount - 1)).' / config.sampleRateHz;

switch lower(char(config.sourceSignal.type))
    case 'gaussian-noise'
        randomStream = RandStream('mt19937ar', ...
            'Seed', config.randomSeed);
        sourceSignal = config.sourceSignal.amplitude ...
            * randn(randomStream, sampleCount, 1);
    case 'chirp'
        sweepRateHzPerSecond = (config.sourceSignal.endFrequencyHz ...
            - config.sourceSignal.startFrequencyHz) ...
            / config.durationSeconds;
        phaseRadians = config.sourceSignal.initialPhaseRadians ...
            + 2 * pi * (config.sourceSignal.startFrequencyHz * timeSeconds ...
            + 0.5 * sweepRateHzPerSecond * timeSeconds .^ 2);
        sourceSignal = config.sourceSignal.amplitude * sin(phaseRadians);
    otherwise
        error('micloc:generateSourceSignal:UnsupportedType', ...
            'Unsupported source-signal type: %s', config.sourceSignal.type);
end
end
