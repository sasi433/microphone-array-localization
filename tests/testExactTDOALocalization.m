function tests = testExactTDOALocalization
%TESTEXACTTDOALOCALIZATION Tests localization from noise-free TDOAs.
tests = functiontests(localfunctions);
end

function testPredictsTDOAsRelativeToSelectedReference(testCase)
microphonesMeters = [0, 0; 3, 0; 0, 4; 3, 4];
sourceMeters = [0, 0];

[tdoasSeconds, arrivalTimesSeconds] = micloc.predictTDOAs( ...
    sourceMeters, microphonesMeters, 2, 2);

verifyEqual(testCase, arrivalTimesSeconds, [0; 1.5; 2; 2.5], ...
    'AbsTol', 1e-14);
verifyEqual(testCase, tdoasSeconds, [-1.5; 0; 0.5; 1], ...
    'AbsTol', 1e-14);
verifyEqual(testCase, tdoasSeconds(2), 0);
end

function testExactSourceHasZeroResiduals(testCase)
[microphonesMeters, sourceMeters, speedMetersPerSecond] = createScene();
referenceIndex = 1;
tdoasSeconds = micloc.predictTDOAs(sourceMeters, microphonesMeters, ...
    speedMetersPerSecond, referenceIndex);

[residualsSeconds, predictedTDOAsSeconds] = ...
    micloc.localizationResiduals(sourceMeters, tdoasSeconds, ...
    microphonesMeters, speedMetersPerSecond, referenceIndex);

verifyEqual(testCase, residualsSeconds, zeros(3, 1), 'AbsTol', 1e-18);
verifyEqual(testCase, predictedTDOAsSeconds, tdoasSeconds, ...
    'AbsTol', 1e-18);
end

function testLocalizesExactTDOAsWithNonlinearLeastSquares(testCase)
[microphonesMeters, sourceMeters, speedMetersPerSecond] = createScene();
referenceIndex = 1;
tdoasSeconds = micloc.predictTDOAs(sourceMeters, microphonesMeters, ...
    speedMetersPerSecond, referenceIndex);

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, speedMetersPerSecond, ...
    referenceIndex, createSettings());

verifyTrue(testCase, diagnostics.solverSucceeded, ...
    diagnostics.solverMessage);
verifyGreaterThan(testCase, diagnostics.exitFlag, 0);
verifyEqual(testCase, estimatedMeters, sourceMeters, 'AbsTol', 1e-7);
verifyLessThan(testCase, diagnostics.residualNormSeconds, 1e-9);
verifyEqual(testCase, diagnostics.geometryRank, 2);
verifyFalse(testCase, diagnostics.isLinearGeometry);
end

function testLocalizesWithAlternateReferenceMicrophone(testCase)
[microphonesMeters, sourceMeters, speedMetersPerSecond] = createScene();
referenceIndex = 3;
tdoasSeconds = micloc.predictTDOAs(sourceMeters, microphonesMeters, ...
    speedMetersPerSecond, referenceIndex);

[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, speedMetersPerSecond, ...
    referenceIndex, createSettings());

verifyTrue(testCase, diagnostics.solverSucceeded, ...
    diagnostics.solverMessage);
verifyEqual(testCase, estimatedMeters, sourceMeters, 'AbsTol', 1e-7);
verifyEqual(testCase, tdoasSeconds(referenceIndex), 0);
end

function testCalculatesMetricsFromSolverResult(testCase)
[microphonesMeters, sourceMeters, speedMetersPerSecond] = createScene();
referenceIndex = 2;
tdoasSeconds = micloc.predictTDOAs(sourceMeters, microphonesMeters, ...
    speedMetersPerSecond, referenceIndex);
[estimatedMeters, diagnostics] = micloc.estimateSourcePosition( ...
    tdoasSeconds, microphonesMeters, speedMetersPerSecond, ...
    referenceIndex, createSettings());

metrics = micloc.calculateLocalizationMetrics( ...
    sourceMeters, estimatedMeters, diagnostics);

verifyTrue(testCase, metrics.solverSucceeded);
verifyEqual(testCase, metrics.exitFlag, diagnostics.exitFlag);
verifyEqual(testCase, metrics.coordinateErrorMeters, ...
    estimatedMeters - sourceMeters, 'AbsTol', 1e-15);
verifyEqual(testCase, metrics.absoluteCoordinateErrorMeters, ...
    abs(estimatedMeters - sourceMeters), 'AbsTol', 1e-15);
verifyLessThan(testCase, metrics.localizationErrorMeters, 1e-7);
verifyEqual(testCase, metrics.residualNormSeconds, ...
    diagnostics.residualNormSeconds);
end

function [microphonesMeters, sourceMeters, speedMetersPerSecond] = createScene
microphonesMeters = [0, 0; 1, 0; 0, 1; 1, 1];
sourceMeters = [0.3, 0.7];
speedMetersPerSecond = 343;
end

function settings = createSettings
config = micloc.defaultConfig();
settings = config.localization;
settings.initialGuessMeters = [0.1, 0.2];
settings.lowerBoundsMeters = [-2, -2];
settings.upperBoundsMeters = [2, 2];
settings.maxIterations = 500;
settings.maxFunctionEvaluations = 5000;
settings.functionTolerance = 1e-14;
settings.stepTolerance = 1e-14;
settings.optimalityTolerance = 1e-14;
end
