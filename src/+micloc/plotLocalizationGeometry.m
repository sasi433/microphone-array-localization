function handles = plotLocalizationGeometry(result, targetAxes)
%PLOTLOCALIZATIONGEOMETRY Plot array geometry and localization error.
%   HANDLES = MICLOC.PLOTLOCALIZATIONGEOMETRY(RESULT) creates a figure for
%   the structured output of MICLOC.RUNLOCALIZATIONSIMULATION. Microphones
%   are connected in index order to show array orientation; actual and
%   estimated source coordinates are joined by the localization-error line.
%
%   HANDLES = MICLOC.PLOTLOCALIZATIONGEOMETRY(RESULT, AXES) draws into the
%   supplied scalar axes. HANDLES contains the figure, axes, and plotted
%   graphics objects so callers and tests can inspect or customize them.

validateResult(result);
if nargin < 2 || isempty(targetAxes)
    figureHandle = figure('Name', 'Localization geometry', ...
        'NumberTitle', 'off');
    targetAxes = axes(figureHandle);
else
    validateattributes(targetAxes, {'matlab.graphics.axis.Axes'}, ...
        {'scalar'}, mfilename, 'targetAxes');
    figureHandle = ancestor(targetAxes, 'figure');
end

microphones = result.microphonePositionsMeters;
actual = result.actualPositionMeters;
estimated = result.estimatedPositionMeters;

hold(targetAxes, 'on');
arrayLine = plot(targetAxes, microphones(:, 1), microphones(:, 2), ...
    '-', 'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.2, ...
    'DisplayName', 'Array orientation');
microphoneMarkers = scatter(targetAxes, microphones(:, 1), ...
    microphones(:, 2), 55, 'filled', 'MarkerFaceColor', [0, 0.45, 0.74], ...
    'DisplayName', 'Microphones');
errorLine = plot(targetAxes, [actual(1), estimated(1)], ...
    [actual(2), estimated(2)], '--', 'Color', [0.5, 0.5, 0.5], ...
    'LineWidth', 1.5, 'DisplayName', sprintf( ...
    'Error = %.4g m', result.localizationErrorMeters));
actualMarker = scatter(targetAxes, actual(1), actual(2), 85, 'o', ...
    'filled', 'MarkerFaceColor', [0.47, 0.67, 0.19], ...
    'DisplayName', 'Actual source');
estimatedMarker = scatter(targetAxes, estimated(1), estimated(2), 90, ...
    'x', 'LineWidth', 2, 'MarkerEdgeColor', [0.85, 0.33, 0.1], ...
    'DisplayName', 'Estimated source');

xlabel(targetAxes, 'x coordinate (m)');
ylabel(targetAxes, 'y coordinate (m)');
title(targetAxes, sprintf('Source localization (error %.4g m)', ...
    result.localizationErrorMeters));
axis(targetAxes, 'equal');
grid(targetAxes, 'on');
legend(targetAxes, 'Location', 'best');
hold(targetAxes, 'off');

handles.figure = figureHandle;
handles.axes = targetAxes;
handles.arrayLine = arrayLine;
handles.microphoneMarkers = microphoneMarkers;
handles.errorLine = errorLine;
handles.actualMarker = actualMarker;
handles.estimatedMarker = estimatedMarker;
end

function validateResult(result)
if ~(isstruct(result) && isscalar(result))
    error('micloc:plotLocalizationGeometry:InvalidResult', ...
        'Result must be a scalar structure.');
end
requiredFields = {'microphonePositionsMeters', 'actualPositionMeters', ...
    'estimatedPositionMeters', 'localizationErrorMeters'};
missingFields = requiredFields(~isfield(result, requiredFields));
if ~isempty(missingFields)
    error('micloc:plotLocalizationGeometry:MissingField', ...
        'Required result field %s is missing.', missingFields{1});
end
micloc.validateMicrophonePositions(result.microphonePositionsMeters);
validateattributes(result.actualPositionMeters, {'numeric'}, ...
    {'real', 'finite', 'size', [1, 2]}, mfilename, ...
    'result.actualPositionMeters');
validateattributes(result.estimatedPositionMeters, {'numeric'}, ...
    {'real', 'finite', 'size', [1, 2]}, mfilename, ...
    'result.estimatedPositionMeters');
validateattributes(result.localizationErrorMeters, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, ...
    'result.localizationErrorMeters');
end
