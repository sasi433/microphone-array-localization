function experiment = runEstimatorSNRComparison( ...
        baseConfig, snrLevelsDb, trialsPerSnr, startingSeed)
%RUNESTIMATORSNRCOMPARISON Compare localization estimators across SNR.
%   EXPERIMENT = MICLOC.RUNESTIMATORSNRCOMPARISON(CONFIG, SNRLEVELS,
%   TRIALSPERSNR) runs lms-peak, lms-phase, and gcc-phat for every seeded
%   trial at each requested SNR. Within a trial, all estimators receive
%   exactly identical generated microphone signals through
%   MICLOC.COMPARETDOAESTIMATORS.
%
%   EXPERIMENT = MICLOC.RUNESTIMATORSNRCOMPARISON(..., STARTINGSEED)
%   selects the first consecutive seed; CONFIG.randomSeed is the default.
%   SNRLEVELS may contain finite real dB values and positive infinity. The
%   returned trial table preserves solver states, localization errors, and
%   TDOA errors. The summary table groups localization statistics by
%   estimator and SNR without silently dropping solver failures.

baseConfig = micloc.validateConfig(baseConfig);
validateattributes(snrLevelsDb, {'numeric'}, ...
    {'real', 'vector', 'nonempty'}, mfilename, 'snrLevelsDb');
if any(isnan(snrLevelsDb)) || any(isinf(snrLevelsDb) & snrLevelsDb < 0)
    error('micloc:runEstimatorSNRComparison:InvalidSNRLevels', ...
        'SNR levels must be finite real values or positive infinity.');
end
validateattributes(trialsPerSnr, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, ...
    'trialsPerSnr');
if nargin < 4
    startingSeed = baseConfig.randomSeed;
end
validateattributes(startingSeed, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, ...
    'startingSeed');

snrLevelsDb = snrLevelsDb(:).';
levelCount = numel(snrLevelsDb);
estimatorNames = ["lms-peak", "lms-phase", "gcc-phat"];
estimatorCount = numel(estimatorNames);
comparisonCount = levelCount * double(trialsPerSnr);
finalSeed = double(startingSeed) + comparisonCount - 1;
if finalSeed > double(intmax('uint32')) - 1
    error('micloc:runEstimatorSNRComparison:SeedRangeExceeded', ...
        ['Trial seeds must leave one additional uint32 seed value for ' ...
        'deterministic noise generation.']);
end

rowCount = comparisonCount * estimatorCount;
snrLevelIndices = zeros(rowCount, 1);
trialIndices = zeros(rowCount, 1);
randomSeeds = zeros(rowCount, 1);
requestedSnrDb = zeros(rowCount, 1);
tdoaEstimators = strings(rowCount, 1);
solverSucceeded = false(rowCount, 1);
solverExitFlags = zeros(rowCount, 1);
localizationErrorMeters = zeros(rowCount, 1);
meanAbsoluteTDOAErrorSamples = zeros(rowCount, 1);
rootMeanSquareTDOAErrorSamples = zeros(rowCount, 1);
maximumAbsoluteTDOAErrorSamples = zeros(rowCount, 1);
comparisons = cell(levelCount, trialsPerSnr);

comparisonIndex = 0;
rowIndex = 0;
for levelIndex = 1:levelCount
    for trialIndex = 1:trialsPerSnr
        comparisonIndex = comparisonIndex + 1;
        trialConfig = baseConfig;
        trialConfig.randomSeed = double(startingSeed) + comparisonIndex - 1;
        trialConfig.noise.enabled = isfinite(snrLevelsDb(levelIndex));
        trialConfig.noise.snrDb = snrLevelsDb(levelIndex);
        comparison = micloc.compareTDOAEstimators(trialConfig);
        comparisons{levelIndex, trialIndex} = comparison;

        for estimatorIndex = 1:estimatorCount
            rowIndex = rowIndex + 1;
            methodResult = comparison.results{estimatorIndex};
            delayMetrics = comparison.delayMetricsTable(estimatorIndex, :);
            snrLevelIndices(rowIndex) = levelIndex;
            trialIndices(rowIndex) = trialIndex;
            randomSeeds(rowIndex) = trialConfig.randomSeed;
            requestedSnrDb(rowIndex) = snrLevelsDb(levelIndex);
            tdoaEstimators(rowIndex) = estimatorNames(estimatorIndex);
            solverSucceeded(rowIndex) = methodResult.solverSucceeded;
            solverExitFlags(rowIndex) = ...
                methodResult.solverDiagnostics.exitFlag;
            localizationErrorMeters(rowIndex) = ...
                methodResult.localizationErrorMeters;
            meanAbsoluteTDOAErrorSamples(rowIndex) = ...
                delayMetrics.MeanAbsoluteTDOAErrorSamples;
            rootMeanSquareTDOAErrorSamples(rowIndex) = ...
                delayMetrics.RootMeanSquareTDOAErrorSamples;
            maximumAbsoluteTDOAErrorSamples(rowIndex) = ...
                delayMetrics.MaximumAbsoluteTDOAErrorSamples;
        end
    end
end

trialTable = table(snrLevelIndices, trialIndices, randomSeeds, ...
    requestedSnrDb, tdoaEstimators, solverSucceeded, solverExitFlags, ...
    localizationErrorMeters, meanAbsoluteTDOAErrorSamples, ...
    rootMeanSquareTDOAErrorSamples, maximumAbsoluteTDOAErrorSamples, ...
    'VariableNames', {'SnrLevelIndex', 'TrialIndex', 'RandomSeed', ...
    'RequestedSnrDb', 'TDOAEstimator', 'SolverSucceeded', ...
    'SolverExitFlag', 'LocalizationErrorMeters', ...
    'MeanAbsoluteTDOAErrorSamples', ...
    'RootMeanSquareTDOAErrorSamples', ...
    'MaximumAbsoluteTDOAErrorSamples'});

methodSummaries = cell(estimatorCount, 1);
for estimatorIndex = 1:estimatorCount
    methodMask = trialTable.TDOAEstimator == estimatorNames(estimatorIndex);
    methodSummary = micloc.summarizeLocalizationTrials( ...
        trialTable(methodMask, :));
    methodSummary.TDOAEstimator = repmat( ...
        estimatorNames(estimatorIndex), height(methodSummary), 1);
    methodSummaries{estimatorIndex} = movevars( ...
        methodSummary, 'TDOAEstimator', 'Before', 1);
end
summaryTable = vertcat(methodSummaries{:});

experiment.baseConfig = baseConfig;
experiment.snrLevelsDb = snrLevelsDb;
experiment.trialsPerSnr = trialsPerSnr;
experiment.startingSeed = double(startingSeed);
experiment.estimatorNames = estimatorNames;
experiment.comparisons = comparisons;
experiment.trialTable = trialTable;
experiment.summaryTable = summaryTable;
experiment.inputsVerifiedIdentical = all(cellfun( ...
    @(entry) entry.inputsVerifiedIdentical, comparisons), 'all');
end
