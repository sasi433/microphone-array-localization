%GENERATEV10FIGURES Reproduce the selected V1.0 documentation figures.
%   Run from any working directory with:
%   matlab -batch "run('examples/generateV10Figures.m')"
%
%   The script runs a five-level identical-input estimator comparison with
%   five deterministic trials per SNR. Selected PNGs are written to
%   docs/assets; the exact summary table is written below ignored results/
%   for review. Use generateV01Figures.m for the geometry, TDOA, and LMS
%   diagnostic figures retained from the historical-revival milestone.

generatorFilePath = mfilename('fullpath');
repositoryRoot = fileparts(fileparts(generatorFilePath));
addpath(repositoryRoot);
setupProject();

config = micloc.defaultConfig();
config.durationSeconds = 0.3;
config.microphonePositionsMeters = [ ...
    -0.06, -0.04; ...
     0.06, -0.04; ...
    -0.06,  0.04; ...
     0.06,  0.04];
config.sourcePositionMeters = [0.15, 0.22];
config.referenceMicrophoneIndex = 1;
config.delayMethod = 'fractional';
config.lms.filterLength = 64;
config.lms.stepSize = 0.003;
config.lms.bulkDelaySamples = 24;
config.localization.initialGuessMeters = [0.1, 0.15];
config.localization.lowerBoundsMeters = [-0.5, -0.5];
config.localization.upperBoundsMeters = [1, 1];
config.plot.enabled = false;
config = micloc.validateConfig(config);

snrLevelsDb = [Inf, 30, 20, 10, 0];
trialsPerSnr = 5;
startingSeed = 26000;
experiment = micloc.runEstimatorSNRComparison( ...
    config, snrLevelsDb, trialsPerSnr, startingSeed);
assert(experiment.inputsVerifiedIdentical, ...
    'Estimator inputs were not verified as identical.');

assetDirectory = fullfile(repositoryRoot, 'docs', 'assets');
resultsDirectory = fullfile(repositoryRoot, 'results');
if ~isfolder(assetDirectory)
    mkdir(assetDirectory);
end
if ~isfolder(resultsDirectory)
    mkdir(resultsDirectory);
end
writetable(experiment.summaryTable, fullfile(resultsDirectory, ...
    'v1.0-estimator-snr-summary.csv'));

lmsPhaseMask = experiment.summaryTable.TDOAEstimator == "lms-phase";
lmsPhaseSummary = experiment.summaryTable(lmsPhaseMask, :);
snrFigure = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 1000, 650]);
micloc.plotLocalizationErrorBySNR(lmsPhaseSummary, axes(snrFigure));
title(gca, sprintf( ...
    'LMS phase localization error (%d deterministic trials per SNR)', ...
    trialsPerSnr));
applyDocumentationTheme(snrFigure);
exportgraphics(snrFigure, fullfile(assetDirectory, ...
    'v1.0-error-vs-snr.png'), 'Resolution', 160);
close(snrFigure);

comparisonFigure = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 1000, 650]);
comparisonAxes = axes(comparisonFigure);
hold(comparisonAxes, 'on');
estimatorNames = experiment.estimatorNames;
lineHandles = gobjects(numel(estimatorNames), 1);
for estimatorIndex = 1:numel(estimatorNames)
    estimatorMask = experiment.summaryTable.TDOAEstimator ...
        == estimatorNames(estimatorIndex);
    estimatorSummary = experiment.summaryTable(estimatorMask, :);
    lineHandles(estimatorIndex) = plot(comparisonAxes, ...
        1:numel(snrLevelsDb), estimatorSummary.MeanErrorMeters, ...
        '-o', 'LineWidth', 1.6, ...
        'DisplayName', estimatorNames(estimatorIndex));
end
comparisonAxes.XTick = 1:numel(snrLevelsDb);
comparisonAxes.XTickLabel = ["Clean", compose('%g', snrLevelsDb(2:end))];
xlabel(comparisonAxes, 'Requested SNR (dB)');
ylabel(comparisonAxes, 'Mean localization error (m)');
title(comparisonAxes, sprintf( ...
    'Estimator comparison on identical signals (%d trials per SNR)', ...
    trialsPerSnr));
grid(comparisonAxes, 'on');
legend(comparisonAxes, lineHandles, 'Location', 'best');
hold(comparisonAxes, 'off');
applyDocumentationTheme(comparisonFigure);
exportgraphics(comparisonFigure, fullfile(assetDirectory, ...
    'v1.0-estimator-comparison.png'), 'Resolution', 160);
close(comparisonFigure);

disp(experiment.summaryTable);
fprintf('Selected V1.0 figures written to %s\n', assetDirectory);

function applyDocumentationTheme(figureHandle)
darkText = [0.15, 0.15, 0.15];
axesHandles = findall(figureHandle, 'Type', 'axes');
for axesIndex = 1:numel(axesHandles)
    currentAxes = axesHandles(axesIndex);
    currentAxes.Color = 'white';
    currentAxes.XColor = darkText;
    currentAxes.YColor = darkText;
    currentAxes.GridColor = [0.65, 0.65, 0.65];
    currentAxes.MinorGridColor = [0.8, 0.8, 0.8];
    currentAxes.Title.Color = darkText;
    currentAxes.XLabel.Color = darkText;
    currentAxes.YLabel.Color = darkText;
end
legendHandles = findall(figureHandle, 'Type', 'legend');
set(legendHandles, 'Color', 'white', 'TextColor', darkText, ...
    'EdgeColor', [0.45, 0.45, 0.45]);
end
