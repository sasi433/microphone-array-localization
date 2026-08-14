function exported = exportLocalizationExperiment( ...
        experiment, outputDirectory, fileStem)
%EXPORTLOCALIZATIONEXPERIMENT Export experiment tables and an SNR plot.
%   EXPORTED = MICLOC.EXPORTLOCALIZATIONEXPERIMENT(EXPERIMENT, DIRECTORY)
%   writes the trial table, summary table, and localization-error plot to
%   DIRECTORY as CSV, CSV, and PNG files. EXPERIMENT must be a scalar
%   structure containing the trialTable produced by an experiment runner.
%
%   EXPORTED = MICLOC.EXPORTLOCALIZATIONEXPERIMENT(..., FILESTEM) selects
%   the shared filename prefix; the default is "localization-experiment".
%   Existing files with the selected names are replaced intentionally.
%   EXPORTED contains the three output paths and the in-memory summary
%   table. Generated output should normally remain under the ignored
%   results directory.

if ~(isstruct(experiment) && isscalar(experiment) ...
        && isfield(experiment, 'trialTable') ...
        && istable(experiment.trialTable))
    error('micloc:exportLocalizationExperiment:InvalidExperiment', ...
        'Experiment must be a scalar structure containing a trial table.');
end
if nargin < 3
    fileStem = "localization-experiment";
end
outputDirectory = validateTextScalar(outputDirectory, 'outputDirectory');
fileStem = validateTextScalar(fileStem, 'fileStem');
if any(contains(fileStem, {'/', '\'})) ...
        || any(fileStem == [".", ".."])
    error('micloc:exportLocalizationExperiment:InvalidFileStem', ...
        'File stem must be a filename without path separators.');
end
if ~isfolder(outputDirectory)
    [created, message] = mkdir(outputDirectory);
    if ~created
        error('micloc:exportLocalizationExperiment:CreateDirectoryFailed', ...
            'Could not create output directory: %s', message);
    end
end

summaryTable = micloc.summarizeLocalizationTrials(experiment);
trialTablePath = fullfile(outputDirectory, fileStem + "-trials.csv");
summaryTablePath = fullfile(outputDirectory, fileStem + "-summary.csv");
plotPath = fullfile(outputDirectory, fileStem + "-error-by-snr.png");

writetable(experiment.trialTable, trialTablePath);
writetable(summaryTable, summaryTablePath);
figureHandle = figure('Visible', 'off', 'Name', ...
    'Localization error by SNR', 'NumberTitle', 'off');
figureCleanup = onCleanup(@() close(figureHandle));
targetAxes = axes(figureHandle);
micloc.plotLocalizationErrorBySNR(summaryTable, targetAxes);
exportgraphics(targetAxes, plotPath, 'Resolution', 150);

exported.trialTablePath = char(trialTablePath);
exported.summaryTablePath = char(summaryTablePath);
exported.plotPath = char(plotPath);
exported.summaryTable = summaryTable;
end

function value = validateTextScalar(value, argumentName)
if ischar(value)
    valid = isrow(value) && ~isempty(value);
elseif isstring(value)
    valid = isscalar(value) && ~ismissing(value) && strlength(value) > 0;
else
    valid = false;
end
if ~valid
    error('micloc:exportLocalizationExperiment:InvalidText', ...
        '%s must be a nonempty character vector or string scalar.', ...
        argumentName);
end
value = string(value);
end
