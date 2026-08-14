%RUNSNREXPERIMENT Run a configurable deterministic localization SNR sweep.
%   Optional caller variables before running this script:
%     snrLevelsDb  - row vector of finite dB values and/or positive Inf
%     trialsPerSnr - positive integer trial count for each level
%     startingSeed - first nonnegative deterministic seed
%
%   Defaults are [Inf, 40, 30, 20, 10, 5, 0], 10 trials per level, and
%   seed 12000. The output structure snrExperiment contains the exact base
%   configuration, per-level experiments, and a combined trial table.

experimentFilePath = mfilename('fullpath');
repositoryRoot = fileparts(fileparts(experimentFilePath));
addpath(repositoryRoot);
setupProject();

if ~exist('snrLevelsDb', 'var')
    snrLevelsDb = [Inf, 40, 30, 20, 10, 5, 0];
end
if ~exist('trialsPerSnr', 'var')
    trialsPerSnr = 10;
end
if ~exist('startingSeed', 'var')
    startingSeed = 12000;
end

validateattributes(snrLevelsDb, {'numeric'}, ...
    {'real', 'vector', 'nonempty'}, mfilename, 'snrLevelsDb');
if any(isnan(snrLevelsDb)) || any(isinf(snrLevelsDb) & snrLevelsDb < 0)
    error('micloc:runSNRExperiment:InvalidSNRLevels', ...
        'SNR levels must be finite real values or positive infinity.');
end
validateattributes(trialsPerSnr, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, ...
    'trialsPerSnr');
validateattributes(startingSeed, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, ...
    'startingSeed');

baseConfig = micloc.defaultConfig();
baseConfig.durationSeconds = 0.5;
baseConfig.microphonePositionsMeters = [ ...
    -0.06, -0.04; ...
     0.06, -0.04; ...
    -0.06,  0.04; ...
     0.06,  0.04];
baseConfig.sourcePositionMeters = [0.15, 0.22];
baseConfig.referenceMicrophoneIndex = 1;
baseConfig.delayMethod = 'fractional';
baseConfig.lms.filterLength = 64;
baseConfig.lms.stepSize = 0.003;
baseConfig.lms.bulkDelaySamples = 24;
baseConfig.localization.initialGuessMeters = [0.1, 0.15];
baseConfig.localization.lowerBoundsMeters = [-0.5, -0.5];
baseConfig.localization.upperBoundsMeters = [1, 1];
baseConfig.plot.enabled = false;

snrLevelsDb = snrLevelsDb(:).';
levelCount = numel(snrLevelsDb);
levelExperiments = cell(levelCount, 1);
combinedTrialTable = table();

for levelIndex = 1:levelCount
    levelConfig = baseConfig;
    levelConfig.noise.enabled = isfinite(snrLevelsDb(levelIndex));
    levelConfig.noise.snrDb = snrLevelsDb(levelIndex);
    levelConfig = micloc.validateConfig(levelConfig);
    levelStartingSeed = double(startingSeed) ...
        + (levelIndex - 1) * double(trialsPerSnr);
    levelExperiment = micloc.runMonteCarloTrials( ...
        levelConfig, trialsPerSnr, levelStartingSeed);
    levelTable = levelExperiment.trialTable;
    levelTable.SnrLevelIndex = repmat(levelIndex, height(levelTable), 1);
    levelTable = movevars(levelTable, 'SnrLevelIndex', 'Before', 1);
    levelExperiments{levelIndex} = levelExperiment;
    combinedTrialTable = [combinedTrialTable; levelTable]; %#ok<AGROW>
    fprintf('SNR %g dB: %d trials, %d solver successes\n', ...
        snrLevelsDb(levelIndex), trialsPerSnr, ...
        nnz(levelTable.SolverSucceeded));
end

snrExperiment.baseConfig = baseConfig;
snrExperiment.snrLevelsDb = snrLevelsDb;
snrExperiment.trialsPerSnr = trialsPerSnr;
snrExperiment.startingSeed = double(startingSeed);
snrExperiment.levelExperiments = levelExperiments;
snrExperiment.trialTable = combinedTrialTable;
