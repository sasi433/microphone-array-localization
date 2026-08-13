function handles = plotTDOAComparison(result, targetAxes)
%PLOTTDOACOMPARISON Plot true and estimated microphone TDOAs.
%   HANDLES = MICLOC.PLOTTDOACOMPARISON(RESULT) plots grouped bars in
%   samples using the structured output of RUNLOCALIZATIONSIMULATION.
%   Per-microphone estimation errors are overlaid, and the reference
%   microphone is identified in the title.
%
%   HANDLES = MICLOC.PLOTTDOACOMPARISON(RESULT, AXES) draws into the
%   supplied scalar axes and returns inspectable graphics handles.

validateResult(result);
if nargin < 2 || isempty(targetAxes)
    figureHandle = figure('Name', 'TDOA comparison', 'NumberTitle', 'off');
    targetAxes = axes(figureHandle);
else
    validateattributes(targetAxes, {'matlab.graphics.axis.Axes'}, ...
        {'scalar'}, mfilename, 'targetAxes');
    figureHandle = ancestor(targetAxes, 'figure');
end

sampleRateHz = result.config.sampleRateHz;
referenceIndex = result.config.referenceMicrophoneIndex;
trueTDOAsSamples = result.trueTDOAsSeconds(:) * sampleRateHz;
estimatedTDOAsSamples = result.estimatedTDOAsSamples(:);
tdoaErrorsSamples = estimatedTDOAsSamples - trueTDOAsSamples;
microphoneIndices = (1:numel(trueTDOAsSamples)).';

groupedBars = bar(targetAxes, microphoneIndices, ...
    [trueTDOAsSamples, estimatedTDOAsSamples], 'grouped');
groupedBars(1).DisplayName = 'True TDOA';
groupedBars(2).DisplayName = 'Estimated TDOA';
groupedBars(1).FaceColor = [0, 0.45, 0.74];
groupedBars(2).FaceColor = [0.85, 0.33, 0.1];
hold(targetAxes, 'on');
errorMarkers = plot(targetAxes, microphoneIndices, tdoaErrorsSamples, ...
    'kd', 'MarkerFaceColor', [0.95, 0.75, 0.1], ...
    'DisplayName', 'Estimation error');
referenceMarker = plot(targetAxes, referenceIndex, 0, 'kp', ...
    'MarkerSize', 12, 'LineWidth', 1.5, ...
    'DisplayName', 'Reference microphone');
yline(targetAxes, 0, ':', 'HandleVisibility', 'off');

xlabel(targetAxes, 'Microphone index');
ylabel(targetAxes, 'TDOA (samples)');
title(targetAxes, sprintf('True and estimated TDOAs (reference M%d)', ...
    referenceIndex));
xticks(targetAxes, microphoneIndices);
xlim(targetAxes, [0.5, numel(microphoneIndices) + 0.5]);
grid(targetAxes, 'on');
legend(targetAxes, 'Location', 'best');
hold(targetAxes, 'off');

handles.figure = figureHandle;
handles.axes = targetAxes;
handles.groupedBars = groupedBars;
handles.errorMarkers = errorMarkers;
handles.referenceMarker = referenceMarker;
handles.trueTDOAsSamples = trueTDOAsSamples;
handles.estimatedTDOAsSamples = estimatedTDOAsSamples;
handles.tdoaErrorsSamples = tdoaErrorsSamples;
end

function validateResult(result)
if ~(isstruct(result) && isscalar(result))
    error('micloc:plotTDOAComparison:InvalidResult', ...
        'Result must be a scalar structure.');
end
requiredFields = {'config', 'trueTDOAsSeconds', ...
    'estimatedTDOAsSamples'};
missingFields = requiredFields(~isfield(result, requiredFields));
if ~isempty(missingFields)
    error('micloc:plotTDOAComparison:MissingField', ...
        'Required result field %s is missing.', missingFields{1});
end
config = micloc.validateConfig(result.config);
microphoneCount = size(config.microphonePositionsMeters, 1);
validateattributes(result.trueTDOAsSeconds, {'numeric'}, ...
    {'real', 'vector', 'finite', 'numel', microphoneCount}, mfilename, ...
    'result.trueTDOAsSeconds');
validateattributes(result.estimatedTDOAsSamples, {'numeric'}, ...
    {'real', 'vector', 'finite', 'numel', microphoneCount}, mfilename, ...
    'result.estimatedTDOAsSamples');
end
