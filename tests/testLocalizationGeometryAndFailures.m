function tests = testLocalizationGeometryAndFailures
%TESTLOCALIZATIONGEOMETRYANDFAILURES Tests ambiguity and solver reporting.
tests = functiontests(localfunctions);
end

function testLocalizesLinearArrayWithinSelectedHalfPlane(testCase)
[microphonesMeters, sourceMeters, tdoasSeconds] = linearScene();
settings = createLinearSettings();

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings);

verifyTrue(testCase, diagnostics.solverSucceeded, ...
    diagnostics.solverMessage);
verifyEqual(testCase, estimatedMeters, sourceMeters, 'AbsTol', 1e-7);
verifyEqual(testCase, diagnostics.geometryRank, 1);
verifyTrue(testCase, diagnostics.isLinearGeometry);
verifyTrue(testCase, diagnostics.halfPlaneConstraintApplied);
verifyFalse(testCase, diagnostics.mirrorAmbiguityRemains);
end

function testLinearArrayHasMirrorAmbiguityWithoutHalfPlaneBounds(testCase)
[microphonesMeters, sourceMeters, tdoasSeconds] = linearScene();
mirroredSourceMeters = [sourceMeters(1), -sourceMeters(2)];
mirroredTDOAsSeconds = micloc.predictTDOAs( ...
    mirroredSourceMeters, microphonesMeters, 343, 1);
settings = createLinearSettings();
settings.lowerBoundsMeters = [-5, -5];
settings.initialGuessMeters = [0, -1];

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings);

verifyEqual(testCase, mirroredTDOAsSeconds, tdoasSeconds);
verifyTrue(testCase, diagnostics.solverSucceeded, ...
    diagnostics.solverMessage);
verifyEqual(testCase, estimatedMeters, mirroredSourceMeters, ...
    'AbsTol', 1e-7);
verifyFalse(testCase, diagnostics.halfPlaneConstraintApplied);
verifyTrue(testCase, diagnostics.mirrorAmbiguityRemains);
end

function testReportsNonCollinearGeometry(testCase)
microphonesMeters = [0, 0; 1, 0; 0.25, 0.8; 1, 1];
sourceMeters = [0.4, 0.6];
tdoasSeconds = micloc.predictTDOAs( ...
    sourceMeters, microphonesMeters, 343, 1);
settings = createLinearSettings();
settings.lowerBoundsMeters = [-2, -2];
settings.upperBoundsMeters = [2, 2];
settings.initialGuessMeters = [0.1, 0.2];

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings);

verifyTrue(testCase, diagnostics.solverSucceeded, ...
    diagnostics.solverMessage);
verifyEqual(testCase, estimatedMeters, sourceMeters, 'AbsTol', 1e-7);
verifyEqual(testCase, diagnostics.geometryRank, 2);
verifyFalse(testCase, diagnostics.isLinearGeometry);
verifyFalse(testCase, diagnostics.mirrorAmbiguityRemains);
end

function testMinimumCollinearArrayReportsMirrorAmbiguity(testCase)
microphonesMeters = [-0.5, 0; 0, 0; 0.5, 0];
sourceMeters = [0.25, 0.8];
referenceIndex = 2;
tdoasSeconds = micloc.predictTDOAs( ...
    sourceMeters, microphonesMeters, 343, referenceIndex);
settings = createLinearSettings();
settings.initialGuessMeters = [0.2, 0.5];
settings.lowerBoundsMeters = [-Inf, -Inf];
settings.upperBoundsMeters = [Inf, Inf];

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, referenceIndex, settings);

verifyTrue(testCase, diagnostics.solverSucceeded, ...
    diagnostics.solverMessage);
verifyEqual(testCase, estimatedMeters, sourceMeters, 'AbsTol', 1e-7);
verifyEqual(testCase, diagnostics.geometryRank, 1);
verifyTrue(testCase, diagnostics.isLinearGeometry);
verifyFalse(testCase, diagnostics.halfPlaneConstraintApplied);
verifyTrue(testCase, diagnostics.mirrorAmbiguityRemains);
end

function testRejectsDuplicateAndInsufficientGeometry(testCase)
validTDOAsSeconds = zeros(3, 1);
settings = createLinearSettings();

verifyError(testCase, @() micloc.estimateSourcePosition( ...
    validTDOAsSeconds, [0, 0; 1, 0; 1, 0], 343, 1, settings), ...
    'micloc:validateMicrophonePositions:DuplicatePositions');
verifyError(testCase, @() micloc.estimateSourcePosition( ...
    zeros(2, 1), [0, 0; 1, 0], 343, 1, settings), ...
    'micloc:validateMicrophonePositions:TooFewMicrophones');
end

function testRejectsFullyCollapsedGeometry(testCase)
settings = createLinearSettings();

verifyError(testCase, @() micloc.estimateSourcePosition( ...
    zeros(3, 1), zeros(3, 2), 343, 1, settings), ...
    'micloc:validateMicrophonePositions:DuplicatePositions');
end

function testReportsFunctionEvaluationLimitAsFailure(testCase)
[microphonesMeters, ~, tdoasSeconds] = linearScene();
settings = createLinearSettings();
settings.initialGuessMeters = [4, 4];
settings.maxIterations = 1;
settings.maxFunctionEvaluations = 1;

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings);
metrics = micloc.calculateLocalizationMetrics( ...
    [0.3, 1.2], estimatedMeters, diagnostics);

verifyFalse(testCase, diagnostics.solverSucceeded);
verifyLessThanOrEqual(testCase, diagnostics.exitFlag, 0);
verifyEqual(testCase, diagnostics.terminationReason, ...
    "function-evaluation-limit");
verifyNotEmpty(testCase, diagnostics.solverMessage);
verifyGreaterThanOrEqual(testCase, diagnostics.functionEvaluationCount, 1);
verifyFalse(testCase, metrics.solverSucceeded);
verifyEqual(testCase, metrics.exitFlag, diagnostics.exitFlag);
end

function testReportsIterationLimitAsFailure(testCase)
[microphonesMeters, ~, tdoasSeconds] = linearScene();
settings = createLinearSettings();
settings.initialGuessMeters = [4, 4];
settings.maxIterations = 1;
settings.maxFunctionEvaluations = 5000;

[~, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings);

verifyFalse(testCase, diagnostics.solverSucceeded);
verifyEqual(testCase, diagnostics.exitFlag, 0);
verifyEqual(testCase, diagnostics.terminationReason, "iteration-limit");
verifyGreaterThan(testCase, diagnostics.functionEvaluationCount, 1);
verifyNotEmpty(testCase, diagnostics.solverMessage);
end

function testRejectsInvalidSolverDomainBeforeOptimization(testCase)
[microphonesMeters, ~, tdoasSeconds] = linearScene();
settings = createLinearSettings();
settings.lowerBoundsMeters = [1, 0];
settings.upperBoundsMeters = [0, 5];

verifyError(testCase, @() micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings), ...
    'micloc:estimateSourcePosition:InvalidBounds');

settings = createLinearSettings();
settings.initialGuessMeters = [6, 1];
verifyError(testCase, @() micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, 343, 1, settings), ...
    'micloc:estimateSourcePosition:InitialGuessOutsideBounds');
end

function testRejectsInvalidMeasuredTDOAsWithIdentifiedErrors(testCase)
[microphonesMeters, ~, tdoasSeconds] = linearScene();
settings = createLinearSettings();

verifyError(testCase, @() micloc.estimateSourcePosition( ...
    tdoasSeconds(1:end-1), microphonesMeters, 343, 1, settings), ...
    'micloc:estimateSourcePosition:InvalidMeasuredTDOAs');
invalidTDOAsSeconds = tdoasSeconds;
invalidTDOAsSeconds(end) = NaN;
verifyError(testCase, @() micloc.estimateSourcePosition( ...
    invalidTDOAsSeconds, microphonesMeters, 343, 1, settings), ...
    'micloc:estimateSourcePosition:InvalidMeasuredTDOAs');
invalidTDOAsSeconds = tdoasSeconds;
invalidTDOAsSeconds(1) = eps;
verifyError(testCase, @() micloc.estimateSourcePosition( ...
    invalidTDOAsSeconds, microphonesMeters, 343, 1, settings), ...
    'micloc:estimateSourcePosition:NonzeroReferenceTDOA');
end

function [microphonesMeters, sourceMeters, tdoasSeconds] = linearScene
microphonesMeters = micloc.createLinearArray(6, 0.2, [0, 0], 0);
sourceMeters = [0.3, 1.2];
tdoasSeconds = micloc.predictTDOAs( ...
    sourceMeters, microphonesMeters, 343, 1);
end

function settings = createLinearSettings
config = micloc.defaultConfig();
settings = config.localization;
settings.initialGuessMeters = [0, 1];
settings.lowerBoundsMeters = [-5, 0];
settings.upperBoundsMeters = [5, 5];
settings.maxIterations = 500;
settings.maxFunctionEvaluations = 5000;
settings.functionTolerance = 1e-14;
settings.stepTolerance = 1e-14;
settings.optimalityTolerance = 1e-14;
end
