function config = historicalStyleConfig()
%HISTORICALSTYLECONFIG Return a representative academic-style preset.
%   CONFIG = MICLOC.HISTORICALSTYLECONFIG() returns a deterministic,
%   six-microphone linear-array configuration inspired only by the broad
%   intent of the historical academic experiment. The numerical values are
%   newly selected for this clean-room reconstruction and are not claimed
%   to reproduce undocumented historical parameters.

config = micloc.defaultConfig();

microphoneCount = 6;
microphoneSpacingMeters = 0.20;
microphoneXCoordinatesMeters = ...
    (0:(microphoneCount - 1)).' * microphoneSpacingMeters;

config.sampleRateHz = 8000;
config.durationSeconds = 1.0;
config.randomSeed = 1996;
config.microphonePositionsMeters = [ ...
    microphoneXCoordinatesMeters, zeros(microphoneCount, 1)];
config.sourcePositionMeters = [2.0, 3.0];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'integer';
config.noise.enabled = false;

config.lms.filterLength = 96;
config.lms.stepSize = 0.005;
config.lms.bulkDelaySamples = 48;

config.localization.initialGuessMeters = [0.5, 1.0];
config.localization.lowerBoundsMeters = [-10, 0];
config.localization.upperBoundsMeters = [10, 10];
config = micloc.validateConfig(config);
end
