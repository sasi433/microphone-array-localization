function experiment = runMonteCarloTrials( ...
        baseConfig, trialCount, startingSeed)
%RUNMONTECARLOTRIALS Run repeated deterministic localization simulations.
%   EXPERIMENT = MICLOC.RUNMONTECARLOTRIALS(CONFIG, TRIALCOUNT) runs the
%   complete localization pipeline TRIALCOUNT times using consecutive seeds
%   beginning at CONFIG.randomSeed.
%
%   EXPERIMENT = MICLOC.RUNMONTECARLOTRIALS(CONFIG, TRIALCOUNT,
%   STARTINGSEED) selects the first seed explicitly. Each trial preserves
%   its complete simulation result. EXPERIMENT.trialTable contains compact
%   coordinates, localization and maximum TDOA errors, requested SNR,
%   solver success, and exit flags. Failed solver states remain in the
%   output and are not silently removed.

baseConfig = micloc.validateConfig(baseConfig);
validateattributes(trialCount, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, ...
    'trialCount');
if nargin < 3
    startingSeed = baseConfig.randomSeed;
end
validateattributes(startingSeed, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, ...
    'startingSeed');

largestAllowedTrialSeed = double(intmax('uint32')) - 1;
finalSeed = double(startingSeed) + double(trialCount) - 1;
if finalSeed > largestAllowedTrialSeed
    error('micloc:runMonteCarloTrials:SeedRangeExceeded', ...
        ['Trial seeds must leave one additional uint32 seed value for ' ...
        'deterministic noise generation.']);
end

trialIndices = (1:trialCount).';
seeds = double(startingSeed) + trialIndices - 1;
requestedSnrDb = repmat(baseConfig.noise.snrDb, trialCount, 1);
solverSucceeded = false(trialCount, 1);
exitFlags = zeros(trialCount, 1);
actualXMeters = zeros(trialCount, 1);
actualYMeters = zeros(trialCount, 1);
estimatedXMeters = zeros(trialCount, 1);
estimatedYMeters = zeros(trialCount, 1);
localizationErrorMeters = zeros(trialCount, 1);
maximumAbsoluteTDOAErrorSamples = zeros(trialCount, 1);
trialResults = cell(trialCount, 1);

for trialIndex = 1:trialCount
    trialConfig = baseConfig;
    trialConfig.randomSeed = seeds(trialIndex);
    trialResult = micloc.runLocalizationSimulation(trialConfig);
    trialResults{trialIndex} = trialResult;

    solverSucceeded(trialIndex) = trialResult.solverSucceeded;
    exitFlags(trialIndex) = trialResult.solverDiagnostics.exitFlag;
    actualXMeters(trialIndex) = trialResult.actualPositionMeters(1);
    actualYMeters(trialIndex) = trialResult.actualPositionMeters(2);
    estimatedXMeters(trialIndex) = trialResult.estimatedPositionMeters(1);
    estimatedYMeters(trialIndex) = trialResult.estimatedPositionMeters(2);
    localizationErrorMeters(trialIndex) = ...
        trialResult.localizationErrorMeters;
    maximumAbsoluteTDOAErrorSamples(trialIndex) = max( ...
        abs(trialResult.tdoaErrorsSeconds)) * baseConfig.sampleRateHz;
end

trialTable = table(trialIndices, seeds, requestedSnrDb, ...
    solverSucceeded, exitFlags, actualXMeters, actualYMeters, ...
    estimatedXMeters, estimatedYMeters, localizationErrorMeters, ...
    maximumAbsoluteTDOAErrorSamples, 'VariableNames', { ...
    'TrialIndex', 'RandomSeed', 'RequestedSnrDb', 'SolverSucceeded', ...
    'SolverExitFlag', 'ActualXMeters', 'ActualYMeters', ...
    'EstimatedXMeters', 'EstimatedYMeters', ...
    'LocalizationErrorMeters', 'MaximumAbsoluteTDOAErrorSamples'});

experiment.baseConfig = baseConfig;
experiment.trialCount = trialCount;
experiment.startingSeed = double(startingSeed);
experiment.seeds = seeds;
experiment.trialResults = trialResults;
experiment.trialTable = trialTable;
end
