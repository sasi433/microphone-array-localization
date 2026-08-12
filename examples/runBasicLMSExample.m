%RUNBASICLMSEXAMPLE Run a reproducible clean LMS localization simulation.
%   This script configures one synthetic stationary source and four
%   synchronized microphones in a direct-path, free-field simulation. It
%   reports estimated TDOAs and coordinates; it is not a real-time or
%   production acoustic-localization example.

exampleFilePath = mfilename('fullpath');
repositoryRoot = fileparts(fileparts(exampleFilePath));
addpath(repositoryRoot);
repositoryRoot = setupProject();
config = micloc.defaultConfig();
config.durationSeconds = 0.5;
config.microphonePositionsMeters = [ ...
    -0.06, -0.04; ...
     0.06, -0.04; ...
    -0.06,  0.04; ...
     0.06,  0.04];
config.sourcePositionMeters = [0.15, 0.22];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'fractional';
config.noise.enabled = false;
config.lms.filterLength = 64;
config.lms.stepSize = 0.003;
config.lms.bulkDelaySamples = 24;
config.localization.initialGuessMeters = [0.1, 0.15];
config.localization.lowerBoundsMeters = [-0.5, -0.5];
config.localization.upperBoundsMeters = [1, 1];
config.plot.enabled = false;
config = micloc.validateConfig(config);

basicLMSResult = micloc.runLocalizationSimulation(config);

fprintf('Microphone-array LMS localization example\n');
fprintf('Repository: %s\n', repositoryRoot);
fprintf('Random seed: %u\n', basicLMSResult.randomSeed);
fprintf('Actual position:    [%.6f, %.6f] m\n', ...
    basicLMSResult.actualPositionMeters);
fprintf('Estimated position: [%.6f, %.6f] m\n', ...
    basicLMSResult.estimatedPositionMeters);
fprintf('Localization error: %.6f m\n', ...
    basicLMSResult.localizationErrorMeters);
fprintf('Solver succeeded:   %d (exit flag %d)\n', ...
    basicLMSResult.solverSucceeded, ...
    basicLMSResult.solverDiagnostics.exitFlag);
fprintf('\nMicrophone  True TDOA (samples)  Estimated TDOA (samples)\n');
for microphoneIndex = 1:size(config.microphonePositionsMeters, 1)
    fprintf('%10d  %19.6f  %24.6f\n', microphoneIndex, ...
        basicLMSResult.trueTDOAsSeconds(microphoneIndex) ...
        * config.sampleRateHz, ...
        basicLMSResult.estimatedTDOAsSamples(microphoneIndex));
end

assert(basicLMSResult.solverSucceeded, ...
    'The basic example localization solver did not converge.');
