function handles = plotLMSDiagnostics(result, microphoneIndex, targetFigure)
%PLOTLMSDIAGNOSTICS Plot LMS convergence and a learned pairwise filter.
%   HANDLES = MICLOC.PLOTLMSDIAGNOSTICS(RESULT, MICROPHONEINDEX) creates a
%   two-panel figure for one non-reference microphone pair. The first panel
%   shows squared a-priori error versus update on a logarithmic scale. The
%   second shows learned zero-delay-first FIR coefficients and marks the
%   configured bulk-delay coefficient.
%
%   HANDLES = MICLOC.PLOTLMSDIAGNOSTICS(..., FIGURE) draws into an empty
%   scalar figure and returns the layout, axes, and plotted objects.

validateResult(result);
microphoneCount = numel(result.lmsDiagnostics);
validateattributes(microphoneIndex, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', '>=', 1, ...
    '<=', microphoneCount}, mfilename, 'microphoneIndex');
pair = result.lmsDiagnostics{microphoneIndex};
if pair.isReferenceMicrophone
    error('micloc:plotLMSDiagnostics:ReferenceMicrophone', ...
        'The reference microphone has no pairwise LMS diagnostics.');
end

if nargin < 3 || isempty(targetFigure)
    targetFigure = figure('Name', sprintf( ...
        'LMS diagnostics: microphone %d', microphoneIndex), ...
        'NumberTitle', 'off');
else
    validateattributes(targetFigure, {'matlab.ui.Figure'}, ...
        {'scalar'}, mfilename, 'targetFigure');
    delete(targetFigure.Children);
end

layout = tiledlayout(targetFigure, 2, 1, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
convergenceAxes = nexttile(layout);
squaredError = pair.lms.squaredErrorHistory(:);
errorFloor = max(eps, max(squaredError) * eps);
convergenceLine = semilogy(convergenceAxes, ...
    1:numel(squaredError), max(squaredError, errorFloor), ...
    'Color', [0, 0.45, 0.74], 'LineWidth', 1);
xlabel(convergenceAxes, 'LMS update');
ylabel(convergenceAxes, 'Squared error');
title(convergenceAxes, sprintf( ...
    'Convergence: M%d relative to reference M%d', ...
    microphoneIndex, result.config.referenceMicrophoneIndex));
grid(convergenceAxes, 'on');

filterAxes = nexttile(layout);
coefficients = pair.learnedCoefficients(:);
coefficientLags = (0:(numel(coefficients) - 1)).';
filterStem = stem(filterAxes, coefficientLags, coefficients, 'filled', ...
    'Color', [0.85, 0.33, 0.1], 'MarkerSize', 3, ...
    'DisplayName', 'Learned coefficients');
hold(filterAxes, 'on');
bulkDelayLine = xline(filterAxes, result.config.lms.bulkDelaySamples, ...
    '--', 'Bulk delay', 'Color', [0.35, 0.35, 0.35], ...
    'DisplayName', 'Zero-TDOA lag');
hold(filterAxes, 'off');
xlabel(filterAxes, 'Causal coefficient lag (samples)');
ylabel(filterAxes, 'Coefficient value');
title(filterAxes, sprintf( ...
    'Learned FIR: estimated TDOA %.4g samples', ...
    pair.estimatedTDOASamples));
grid(filterAxes, 'on');
legend(filterAxes, 'Location', 'best');

handles.figure = targetFigure;
handles.layout = layout;
handles.convergenceAxes = convergenceAxes;
handles.filterAxes = filterAxes;
handles.convergenceLine = convergenceLine;
handles.filterStem = filterStem;
handles.bulkDelayLine = bulkDelayLine;
handles.microphoneIndex = microphoneIndex;
end

function validateResult(result)
if ~(isstruct(result) && isscalar(result))
    error('micloc:plotLMSDiagnostics:InvalidResult', ...
        'Result must be a scalar structure.');
end
requiredFields = {'config', 'lmsDiagnostics'};
missingFields = requiredFields(~isfield(result, requiredFields));
if ~isempty(missingFields)
    error('micloc:plotLMSDiagnostics:MissingField', ...
        'Required result field %s is missing.', missingFields{1});
end
config = micloc.validateConfig(result.config);
microphoneCount = size(config.microphonePositionsMeters, 1);
if ~(iscell(result.lmsDiagnostics) ...
        && numel(result.lmsDiagnostics) == microphoneCount)
    error('micloc:plotLMSDiagnostics:InvalidDiagnostics', ...
        'LMS diagnostics must contain one cell per microphone.');
end
end
