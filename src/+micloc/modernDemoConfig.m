function config = modernDemoConfig()
%MODERNDEMOCONFIG Return a modern deterministic demonstration preset.
%   CONFIG = MICLOC.MODERNDEMOCONFIG() uses a compact non-collinear array,
%   fractional-delay mode, and finite-SNR noise settings. Coordinates and
%   distances are expressed in metres.

config = micloc.defaultConfig();

xCoordinatesMeters = [-0.12; -0.04; 0.04; 0.12];
lowerRowMeters = [xCoordinatesMeters, -0.04 * ones(4, 1)];
upperRowMeters = [xCoordinatesMeters, 0.04 * ones(4, 1)];

config.sampleRateHz = 48000;
config.durationSeconds = 0.75;
config.randomSeed = 2026;
config.microphonePositionsMeters = [lowerRowMeters; upperRowMeters];
config.sourcePositionMeters = [1.2, 1.8];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'fractional';

config.noise.enabled = true;
config.noise.snrDb = 30;

config.lms.filterLength = 96;
config.lms.stepSize = 0.005;
config.lms.bulkDelaySamples = 48;

config.localization.initialGuessMeters = [0, 1];
config.localization.lowerBoundsMeters = [-5, -1];
config.localization.upperBoundsMeters = [5, 5];
config = micloc.validateConfig(config);
end
