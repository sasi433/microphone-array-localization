function config = defaultConfig()
%DEFAULTCONFIG Return the default microphone-localization configuration.
%   CONFIG = MICLOC.DEFAULTCONFIG() returns a deterministic configuration
%   for a single-source, two-dimensional, direct-path simulation. Distances
%   are in metres, time is in seconds, sampling frequency is in hertz, and
%   sound speed is in metres per second.

microphoneCount = 6;
microphoneSpacingMeters = 0.08;
microphoneXCoordinatesMeters = ...
    ((0:(microphoneCount - 1)).' - (microphoneCount - 1) / 2) ...
    * microphoneSpacingMeters;

config.sampleRateHz = 48000;
config.durationSeconds = 1.0;
config.randomSeed = 5489;
config.speedOfSoundMetersPerSecond = 343;
config.microphonePositionsMeters = [ ...
    microphoneXCoordinatesMeters, zeros(microphoneCount, 1)];
config.sourcePositionMeters = [1.5, 2.0];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'integer';

config.noise.enabled = false;
config.noise.snrDb = 30;

config.lms.filterLength = 64;
config.lms.stepSize = 0.01;
config.lms.bulkDelaySamples = 32;
config.lms.storeCoefficientHistory = false;

config.localization.initialGuessMeters = [0, 1];
config.localization.lowerBoundsMeters = [-5, 0];
config.localization.upperBoundsMeters = [5, 5];
config.localization.maxIterations = 200;
config.localization.maxFunctionEvaluations = 2000;
config.localization.functionTolerance = 1e-10;
config.localization.stepTolerance = 1e-10;
config.localization.optimalityTolerance = 1e-10;
config.localization.solverDisplay = 'off';

config.plot.enabled = true;
config = micloc.validateConfig(config);
end
