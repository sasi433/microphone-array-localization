function tests = testGeometryAndPropagation
%TESTGEOMETRYANDPROPAGATION Tests for array geometry and direct propagation.
tests = functiontests(localfunctions);
end

function testCreatesCenteredHorizontalArray(testCase)
positionsMeters = micloc.createLinearArray(5, 0.25, [1, 2], 0);
expectedMeters = [ ...
    0.50, 2; ...
    0.75, 2; ...
    1.00, 2; ...
    1.25, 2; ...
    1.50, 2];

verifyEqual(testCase, positionsMeters, expectedMeters, 'AbsTol', 1e-14);
verifyEqual(testCase, mean(positionsMeters, 1), [1, 2], ...
    'AbsTol', 1e-14);
end

function testCreatesTranslatedVerticalArray(testCase)
positionsMeters = micloc.createLinearArray(4, 0.2, [-1, 1], pi / 2);

verifyEqual(testCase, positionsMeters(:, 1), -ones(4, 1), ...
    'AbsTol', 1e-14);
verifyEqual(testCase, diff(positionsMeters(:, 2)), 0.2 * ones(3, 1), ...
    'AbsTol', 1e-14);
verifyEqual(testCase, mean(positionsMeters, 1), [-1, 1], ...
    'AbsTol', 1e-14);
end

function testCreatesRotatedArray(testCase)
positionsMeters = micloc.createLinearArray(3, sqrt(2), [2, 3], pi / 4);
expectedMeters = [1, 2; 2, 3; 3, 4];

verifyEqual(testCase, positionsMeters, expectedMeters, 'AbsTol', 1e-14);
end

function testAcceptsArbitraryValidGeometry(testCase)
positionsMeters = [0, 0; 1, 0; 0.2, 0.8; -0.3, 0.4];

verifyEqual(testCase, ...
    micloc.validateMicrophonePositions(positionsMeters), positionsMeters);
end

function testRejectsInvalidLinearArrayInputs(testCase)
invalidCalls = { ...
    @() micloc.createLinearArray(2, 0.1, [0, 0], 0), ...
    @() micloc.createLinearArray(3.5, 0.1, [0, 0], 0), ...
    @() micloc.createLinearArray(3, 0, [0, 0], 0), ...
    @() micloc.createLinearArray(3, 0.1, [0, NaN], 0), ...
    @() micloc.createLinearArray(3, 0.1, [0, 0], Inf)};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function testRejectsInvalidMicrophoneGeometry(testCase)
invalidGeometries = { ...
    [0, 0; 1, 0], ...
    [0, 0; 0, 0; 1, 0], ...
    [0, 0; 1, 0; Inf, 1], ...
    zeros(3, 3), ...
    'coordinates'};

for geometryIndex = 1:numel(invalidGeometries)
    verifyCallFails(testCase, @() micloc.validateMicrophonePositions( ...
        invalidGeometries{geometryIndex}));
end
end

function testCalculatesHandComputedDistances(testCase)
microphonesMeters = [0, 0; 3, 0; 0, 4; 3, 4];

distancesMeters = micloc.calculateDistances([0, 0], microphonesMeters);

verifyEqual(testCase, distancesMeters, [0; 3; 4; 5], 'AbsTol', 1e-14);
verifySize(testCase, distancesMeters, [4, 1]);
end

function testDistancesAreTranslationInvariant(testCase)
microphonesMeters = [-1, 0; 2, 1; 0, 3];
sourceMeters = [0.5, 0.25];
translationMeters = [10, -7];

originalDistances = micloc.calculateDistances( ...
    sourceMeters, microphonesMeters);
translatedDistances = micloc.calculateDistances( ...
    sourceMeters + translationMeters, ...
    microphonesMeters + translationMeters);

verifyEqual(testCase, translatedDistances, originalDistances, ...
    'AbsTol', 1e-14);
end

function testCalculatesHandComputedArrivalTimes(testCase)
microphonesMeters = [0, 0; 3, 0; 0, 4; 3, 4];

arrivalTimesSeconds = micloc.calculateArrivalTimes( ...
    [0, 0], microphonesMeters, 2);

verifyEqual(testCase, arrivalTimesSeconds, [0; 1.5; 2; 2.5], ...
    'AbsTol', 1e-14);
verifySize(testCase, arrivalTimesSeconds, [4, 1]);
end

function testRejectsInvalidPropagationInputs(testCase)
microphonesMeters = [0, 0; 1, 0; 0, 1];
invalidCalls = { ...
    @() micloc.calculateDistances([0, NaN], microphonesMeters), ...
    @() micloc.calculateDistances([0, 0, 0], microphonesMeters), ...
    @() micloc.calculateArrivalTimes([0, 0], microphonesMeters, 0), ...
    @() micloc.calculateArrivalTimes([0, 0], microphonesMeters, Inf)};

for callIndex = 1:numel(invalidCalls)
    verifyCallFails(testCase, invalidCalls{callIndex});
end
end

function verifyCallFails(testCase, functionHandle)
caughtIdentifier = '';
try
    functionHandle();
catch errorInfo
    caughtIdentifier = errorInfo.identifier;
end

verifyNotEmpty(testCase, caughtIdentifier, ...
    'Expected the invalid input to raise an identified error.');
end
