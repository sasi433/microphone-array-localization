function metrics = calculateLocalizationMetrics(actualPositionMeters, ...
        estimatedPositionMeters, solverDiagnostics)
%CALCULATELOCALIZATIONMETRICS Summarize localization accuracy and status.
%   METRICS = MICLOC.CALCULATELOCALIZATIONMETRICS(ACTUAL, ESTIMATED,
%   DIAGNOSTICS) compares two 1-by-2 source positions in metres. The signed
%   coordinate error is ESTIMATED - ACTUAL, and localizationErrorMeters is
%   its Euclidean norm.
%
%   DIAGNOSTICS is the scalar structure returned by
%   MICLOC.ESTIMATESOURCEPOSITION. Solver success, exit flag, message, and
%   residual norm are copied into METRICS so that accuracy is never
%   reported without the corresponding solver state.

validatePosition(actualPositionMeters, 'actualPositionMeters');
validatePosition(estimatedPositionMeters, 'estimatedPositionMeters');
validateSolverDiagnostics(solverDiagnostics);

coordinateErrorMeters = estimatedPositionMeters - actualPositionMeters;

metrics.actualPositionMeters = actualPositionMeters;
metrics.estimatedPositionMeters = estimatedPositionMeters;
metrics.coordinateErrorMeters = coordinateErrorMeters;
metrics.absoluteCoordinateErrorMeters = abs(coordinateErrorMeters);
metrics.localizationErrorMeters = norm(coordinateErrorMeters);
metrics.solverSucceeded = solverDiagnostics.solverSucceeded;
metrics.exitFlag = solverDiagnostics.exitFlag;
metrics.solverMessage = solverDiagnostics.solverMessage;
metrics.residualNormSeconds = solverDiagnostics.residualNormSeconds;
end

function validatePosition(positionMeters, argumentName)
validateattributes(positionMeters, {'numeric'}, ...
    {'real', 'finite', 'size', [1, 2]}, mfilename, argumentName);
end

function validateSolverDiagnostics(diagnostics)
if ~(isstruct(diagnostics) && isscalar(diagnostics))
    error('micloc:calculateLocalizationMetrics:InvalidDiagnostics', ...
        'Solver diagnostics must be a scalar structure.');
end

requiredFields = {'solverSucceeded', 'exitFlag', 'solverMessage', ...
    'residualNormSeconds'};
missingFields = requiredFields(~isfield(diagnostics, requiredFields));
if ~isempty(missingFields)
    error('micloc:calculateLocalizationMetrics:MissingDiagnostic', ...
        'Required solver diagnostic %s is missing.', missingFields{1});
end

validateattributes(diagnostics.solverSucceeded, {'logical'}, ...
    {'scalar'}, mfilename, 'solverDiagnostics.solverSucceeded');
validateattributes(diagnostics.exitFlag, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer'}, mfilename, ...
    'solverDiagnostics.exitFlag');
if ~((ischar(diagnostics.solverMessage) ...
        && (isrow(diagnostics.solverMessage) ...
        || isempty(diagnostics.solverMessage))) ...
        || (isstring(diagnostics.solverMessage) ...
        && isscalar(diagnostics.solverMessage)))
    error('micloc:calculateLocalizationMetrics:InvalidSolverMessage', ...
        'The solver message must be a character row or string scalar.');
end
validateattributes(diagnostics.residualNormSeconds, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, ...
    'solverDiagnostics.residualNormSeconds');
end
