function handles = plotLocalizationErrorBySNR(summaryTable, targetAxes)
%PLOTLOCALIZATIONERRORBYSNR Plot localization-error statistics by SNR.
%   HANDLES = MICLOC.PLOTLOCALIZATIONERRORBYSNR(SUMMARYTABLE) plots the
%   mean, median, and 90th-percentile localization errors from
%   MICLOC.SUMMARIZELOCALIZATIONTRIALS. Positive infinity is labelled as a
%   clean simulation rather than as a finite SNR value.
%
%   HANDLES = MICLOC.PLOTLOCALIZATIONERRORBYSNR(SUMMARYTABLE, AXES) draws
%   into the supplied scalar axes. The returned structure exposes the
%   figure, axes, and line handles for inspection and customization.

validateSummaryTable(summaryTable);
if nargin < 2 || isempty(targetAxes)
    figureHandle = figure('Name', 'Localization error by SNR', ...
        'NumberTitle', 'off');
    targetAxes = axes(figureHandle);
else
    validateattributes(targetAxes, {'matlab.graphics.axis.Axes'}, ...
        {'scalar'}, mfilename, 'targetAxes');
    figureHandle = ancestor(targetAxes, 'figure');
end

xValues = (1:height(summaryTable)).';
hold(targetAxes, 'on');
meanLine = plot(targetAxes, xValues, summaryTable.MeanErrorMeters, ...
    '-o', 'LineWidth', 1.5, 'DisplayName', 'Mean');
medianLine = plot(targetAxes, xValues, summaryTable.MedianErrorMeters, ...
    '-s', 'LineWidth', 1.5, 'DisplayName', 'Median');
percentile90Line = plot(targetAxes, xValues, ...
    summaryTable.Percentile90ErrorMeters, '-^', 'LineWidth', 1.5, ...
    'DisplayName', '90th percentile');

targetAxes.XTick = xValues;
targetAxes.XTickLabel = formatSNRLabels(summaryTable.RequestedSnrDb);
xlabel(targetAxes, 'Requested SNR (dB)');
ylabel(targetAxes, 'Localization error (m)');
title(targetAxes, sprintf( ...
    'Localization error by SNR (%d solver failures)', ...
    sum(summaryTable.SolverFailureCount)));
grid(targetAxes, 'on');
legend(targetAxes, 'Location', 'best');
hold(targetAxes, 'off');

handles.figure = figureHandle;
handles.axes = targetAxes;
handles.meanLine = meanLine;
handles.medianLine = medianLine;
handles.percentile90Line = percentile90Line;
end

function validateSummaryTable(summaryTable)
if ~istable(summaryTable) || isempty(summaryTable)
    error('micloc:plotLocalizationErrorBySNR:InvalidSummary', ...
        'Summary input must be a nonempty table.');
end
requiredVariables = {'RequestedSnrDb', 'SolverFailureCount', ...
    'MeanErrorMeters', 'MedianErrorMeters', ...
    'Percentile90ErrorMeters'};
missingVariables = requiredVariables(~ismember( ...
    requiredVariables, summaryTable.Properties.VariableNames));
if ~isempty(missingVariables)
    error('micloc:plotLocalizationErrorBySNR:MissingVariable', ...
        'Required summary-table variable %s is missing.', ...
        missingVariables{1});
end
validateattributes(summaryTable.RequestedSnrDb, {'numeric'}, ...
    {'real', 'vector'}, mfilename, 'RequestedSnrDb');
if any(isnan(summaryTable.RequestedSnrDb)) ...
        || any(isinf(summaryTable.RequestedSnrDb) ...
        & summaryTable.RequestedSnrDb < 0)
    error('micloc:plotLocalizationErrorBySNR:InvalidSNR', ...
        'Requested SNR values must be finite or positive infinity.');
end
validateattributes(summaryTable.SolverFailureCount, {'numeric'}, ...
    {'real', 'finite', 'vector', 'integer', 'nonnegative'}, mfilename, ...
    'SolverFailureCount');
metricVariables = requiredVariables(3:end);
for variableIndex = 1:numel(metricVariables)
    values = summaryTable.(metricVariables{variableIndex});
    validateattributes(values, {'numeric'}, {'real', 'vector'}, ...
        mfilename, metricVariables{variableIndex});
    if any(isinf(values)) || any(values < 0)
        error('micloc:plotLocalizationErrorBySNR:InvalidMetric', ...
            '%s values must be nonnegative or NaN.', ...
            metricVariables{variableIndex});
    end
end
for variableIndex = 1:numel(requiredVariables)
    if numel(summaryTable.(requiredVariables{variableIndex})) ...
            ~= height(summaryTable)
        error('micloc:plotLocalizationErrorBySNR:InvalidColumnLength', ...
            'Required summary variables must have one value per row.');
    end
end
end

function labels = formatSNRLabels(snrLevelsDb)
labels = strings(numel(snrLevelsDb), 1);
for levelIndex = 1:numel(snrLevelsDb)
    if isinf(snrLevelsDb(levelIndex))
        labels(levelIndex) = "Clean";
    else
        labels(levelIndex) = compose('%g', snrLevelsDb(levelIndex));
    end
end
end
