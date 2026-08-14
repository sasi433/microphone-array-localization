function summaryTable = summarizeLocalizationTrials(trialData)
%SUMMARIZELOCALIZATIONTRIALS Summarize localization errors by SNR.
%   SUMMARY = MICLOC.SUMMARIZELOCALIZATIONTRIALS(TRIALTABLE) groups the
%   compact table returned by RUNMONTECARLOTRIALS or RUNSNREXPERIMENT by
%   RequestedSnrDb. Statistics use only successful trials with finite,
%   nonnegative localization errors. Counts preserve solver failures and
%   invalid metrics instead of silently dropping them.
%
%   SUMMARY = MICLOC.SUMMARIZELOCALIZATIONTRIALS(EXPERIMENT) accepts a
%   scalar structure containing the field trialTable. The returned table
%   reports total, valid, failed-solver, and invalid-metric counts plus mean,
%   median, sample standard deviation, minimum, maximum, and an independently
%   calculated linearly interpolated 90th percentile in metres.

if isstruct(trialData) && isscalar(trialData) ...
        && isfield(trialData, 'trialTable')
    trialTable = trialData.trialTable;
else
    trialTable = trialData;
end
if ~istable(trialTable)
    error('micloc:summarizeLocalizationTrials:InvalidInput', ...
        'Input must be a trial table or scalar experiment structure.');
end
requiredVariables = {'RequestedSnrDb', 'SolverSucceeded', ...
    'LocalizationErrorMeters'};
missingVariables = requiredVariables(~ismember( ...
    requiredVariables, trialTable.Properties.VariableNames));
if ~isempty(missingVariables)
    error('micloc:summarizeLocalizationTrials:MissingVariable', ...
        'Required trial-table variable %s is missing.', ...
        missingVariables{1});
end
if isempty(trialTable)
    error('micloc:summarizeLocalizationTrials:EmptyTable', ...
        'Trial table must contain at least one row.');
end

validateattributes(trialTable.RequestedSnrDb, {'numeric'}, ...
    {'real', 'vector'}, mfilename, 'RequestedSnrDb');
if any(isnan(trialTable.RequestedSnrDb)) ...
        || any(isinf(trialTable.RequestedSnrDb) ...
        & trialTable.RequestedSnrDb < 0)
    error('micloc:summarizeLocalizationTrials:InvalidSNR', ...
        'Requested SNR values must be finite or positive infinity.');
end
if ~(islogical(trialTable.SolverSucceeded) ...
        && isvector(trialTable.SolverSucceeded))
    error('micloc:summarizeLocalizationTrials:InvalidSolverStatus', ...
        'SolverSucceeded must be a logical vector.');
end
validateattributes(trialTable.LocalizationErrorMeters, {'numeric'}, ...
    {'real', 'vector'}, mfilename, 'LocalizationErrorMeters');
if height(trialTable) ~= numel(trialTable.RequestedSnrDb) ...
        || height(trialTable) ~= numel(trialTable.SolverSucceeded) ...
        || height(trialTable) ~= numel(trialTable.LocalizationErrorMeters)
    error('micloc:summarizeLocalizationTrials:InvalidColumnLength', ...
        'Required trial-table variables must have one value per row.');
end

snrLevelsDb = unique(trialTable.RequestedSnrDb, 'stable');
levelCount = numel(snrLevelsDb);
totalTrialCount = zeros(levelCount, 1);
validTrialCount = zeros(levelCount, 1);
solverFailureCount = zeros(levelCount, 1);
invalidMetricCount = zeros(levelCount, 1);
meanErrorMeters = NaN(levelCount, 1);
medianErrorMeters = NaN(levelCount, 1);
standardDeviationMeters = NaN(levelCount, 1);
minimumErrorMeters = NaN(levelCount, 1);
maximumErrorMeters = NaN(levelCount, 1);
percentile90ErrorMeters = NaN(levelCount, 1);

for levelIndex = 1:levelCount
    levelMask = trialTable.RequestedSnrDb == snrLevelsDb(levelIndex);
    levelSucceeded = trialTable.SolverSucceeded(levelMask);
    levelErrors = trialTable.LocalizationErrorMeters(levelMask);
    finiteNonnegative = isfinite(levelErrors) & levelErrors >= 0;
    validMask = levelSucceeded & finiteNonnegative;
    validErrors = levelErrors(validMask);

    totalTrialCount(levelIndex) = nnz(levelMask);
    validTrialCount(levelIndex) = numel(validErrors);
    solverFailureCount(levelIndex) = nnz(~levelSucceeded);
    invalidMetricCount(levelIndex) = nnz(levelSucceeded & ~finiteNonnegative);
    if ~isempty(validErrors)
        meanErrorMeters(levelIndex) = mean(validErrors);
        medianErrorMeters(levelIndex) = median(validErrors);
        standardDeviationMeters(levelIndex) = std(validErrors);
        minimumErrorMeters(levelIndex) = min(validErrors);
        maximumErrorMeters(levelIndex) = max(validErrors);
        percentile90ErrorMeters(levelIndex) = ...
            interpolatedPercentile(validErrors, 0.9);
    end
end

summaryTable = table(snrLevelsDb, totalTrialCount, validTrialCount, ...
    solverFailureCount, invalidMetricCount, meanErrorMeters, ...
    medianErrorMeters, standardDeviationMeters, minimumErrorMeters, ...
    maximumErrorMeters, percentile90ErrorMeters, 'VariableNames', { ...
    'RequestedSnrDb', 'TotalTrialCount', 'ValidTrialCount', ...
    'SolverFailureCount', 'InvalidMetricCount', 'MeanErrorMeters', ...
    'MedianErrorMeters', 'StandardDeviationMeters', ...
    'MinimumErrorMeters', 'MaximumErrorMeters', ...
    'Percentile90ErrorMeters'});
end

function percentileValue = interpolatedPercentile(values, probability)
sortedValues = sort(values(:));
if isscalar(sortedValues)
    percentileValue = sortedValues(1);
    return
end
position = 1 + (numel(sortedValues) - 1) * probability;
lowerIndex = floor(position);
upperIndex = ceil(position);
fraction = position - lowerIndex;
percentileValue = sortedValues(lowerIndex) ...
    + fraction * (sortedValues(upperIndex) - sortedValues(lowerIndex));
end
