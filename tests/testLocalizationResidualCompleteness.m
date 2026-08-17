function tests = testLocalizationResidualCompleteness
%TESTLOCALIZATIONRESIDUALCOMPLETENESS Verify all microphone residuals matter.
tests = functiontests(localfunctions);
end

function testEachNonReferenceMeasurementMapsToOneResidual(testCase)
[microphonesMeters, sourceMeters, exactTDOAsSeconds] = createScene();
referenceIndex = 2;
perturbationSeconds = 4e-5;
nonReferenceIndices = setdiff(1:size(microphonesMeters, 1), ...
    referenceIndex, 'stable');

for index = nonReferenceIndices
    measuredTDOAsSeconds = exactTDOAsSeconds;
    measuredTDOAsSeconds(index) = measuredTDOAsSeconds(index) ...
        + perturbationSeconds;
    residualsSeconds = micloc.localizationResiduals( ...
        sourceMeters, measuredTDOAsSeconds, microphonesMeters, 343, ...
        referenceIndex);
    expectedResidualsSeconds = zeros(numel(nonReferenceIndices), 1);
    expectedResidualsSeconds(nonReferenceIndices == index) = ...
        -perturbationSeconds;

    verifyEqual(testCase, residualsSeconds, expectedResidualsSeconds, ...
        'AbsTol', 1e-18);
end
end

function testFinalMicrophoneChangesLocalizationObjective(testCase)
[microphonesMeters, sourceMeters, exactTDOAsSeconds] = createScene();
referenceIndex = 2;
settings = createSettings(sourceMeters);

[exactEstimateMeters, exactDiagnostics] = micloc.estimateSourcePosition( ...
    exactTDOAsSeconds, microphonesMeters, 343, referenceIndex, settings);
perturbedTDOAsSeconds = exactTDOAsSeconds;
perturbedTDOAsSeconds(end) = perturbedTDOAsSeconds(end) + 4e-5;
[perturbedEstimateMeters, perturbedDiagnostics] = ...
    micloc.estimateSourcePosition(perturbedTDOAsSeconds, ...
    microphonesMeters, 343, referenceIndex, settings);

verifyTrue(testCase, exactDiagnostics.solverSucceeded, ...
    exactDiagnostics.solverMessage);
verifyTrue(testCase, perturbedDiagnostics.solverSucceeded, ...
    perturbedDiagnostics.solverMessage);
verifyEqual(testCase, exactEstimateMeters, sourceMeters, 'AbsTol', 1e-9);
verifyGreaterThan(testCase, ...
    norm(perturbedEstimateMeters - exactEstimateMeters), 1e-4);
verifyGreaterThan(testCase, perturbedDiagnostics.residualNormSeconds, 0);
end

function [microphonesMeters, sourceMeters, tdoasSeconds] = createScene
microphonesMeters = [ ...
    -0.90, -0.15; ...
    -0.35, -0.75; ...
     0.40, -0.65; ...
     0.95,  0.05; ...
     0.50,  0.90; ...
    -0.65,  0.70];
sourceMeters = [0.23, 0.37];
tdoasSeconds = micloc.predictTDOAs( ...
    sourceMeters, microphonesMeters, 343, 2);
end

function settings = createSettings(sourceMeters)
config = micloc.defaultConfig();
settings = config.localization;
settings.initialGuessMeters = sourceMeters;
settings.lowerBoundsMeters = [-2, -2];
settings.upperBoundsMeters = [2, 2];
settings.maxIterations = 500;
settings.maxFunctionEvaluations = 5000;
settings.functionTolerance = 1e-14;
settings.stepTolerance = 1e-14;
settings.optimalityTolerance = 1e-14;
end
