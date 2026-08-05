function tests = testConfiguration
%TESTCONFIGURATION Tests for simulation configuration and validation.
tests = functiontests(localfunctions);
end

function testDefaultConfigurationIsDeterministicAndValid(testCase)
firstConfig = micloc.defaultConfig();
secondConfig = micloc.defaultConfig();

verifyEqual(testCase, firstConfig, secondConfig);
verifyEqual(testCase, micloc.validateConfig(firstConfig), firstConfig);
verifyEqual(testCase, size(firstConfig.microphonePositionsMeters), [6, 2]);
verifyGreaterThan(testCase, firstConfig.sampleRateHz, 0);
verifyGreaterThan(testCase, firstConfig.durationSeconds, 0);
verifyGreaterThan(testCase, firstConfig.speedOfSoundMetersPerSecond, 0);
end

function testHistoricalStylePresetIsValid(testCase)
config = micloc.historicalStyleConfig();

verifyEqual(testCase, micloc.validateConfig(config), config);
verifyEqual(testCase, size(config.microphonePositionsMeters), [6, 2]);
verifyEqual(testCase, config.microphonePositionsMeters(:, 2), zeros(6, 1));
verifyEqual(testCase, config.delayMethod, 'integer');
verifyFalse(testCase, config.noise.enabled);
end

function testModernDemoPresetIsValid(testCase)
config = micloc.modernDemoConfig();

verifyEqual(testCase, micloc.validateConfig(config), config);
verifyEqual(testCase, size(config.microphonePositionsMeters), [8, 2]);
verifyGreaterThan(testCase, ...
    numel(unique(config.microphonePositionsMeters(:, 2))), 1);
verifyEqual(testCase, config.delayMethod, 'fractional');
verifyTrue(testCase, config.noise.enabled);
end

function testRejectsInvalidPhysicalScalars(testCase)
baseConfig = micloc.defaultConfig();

invalidValues = {0, -1, Inf, NaN};
fieldNames = {'sampleRateHz', 'durationSeconds', ...
    'speedOfSoundMetersPerSecond'};
for fieldIndex = 1:numel(fieldNames)
    for valueIndex = 1:numel(invalidValues)
        config = baseConfig;
        config.(fieldNames{fieldIndex}) = invalidValues{valueIndex};
        verifyValidationFails(testCase, config);
    end
end
end

function testRejectsInvalidRandomSeeds(testCase)
baseConfig = micloc.defaultConfig();
invalidSeeds = {-1, 1.5, NaN, Inf, double(intmax('uint32')) + 1};

for seedIndex = 1:numel(invalidSeeds)
    config = baseConfig;
    config.randomSeed = invalidSeeds{seedIndex};
    verifyValidationFails(testCase, config);
end
end

function testRejectsInvalidMicrophoneGeometry(testCase)
baseConfig = micloc.defaultConfig();
invalidGeometries = { ...
    [0, 0; 1, 0], ...
    [0, 0; 0, 0; 1, 0], ...
    [0, 0; 1, 0; NaN, 0], ...
    zeros(3, 3), ...
    'not numeric'};

for geometryIndex = 1:numel(invalidGeometries)
    config = baseConfig;
    config.microphonePositionsMeters = invalidGeometries{geometryIndex};
    verifyValidationFails(testCase, config);
end
end

function testRejectsInvalidSourcePositions(testCase)
baseConfig = micloc.defaultConfig();
invalidPositions = {1, [1, NaN], [1, Inf], [1, 2; 3, 4], 'xy'};

for positionIndex = 1:numel(invalidPositions)
    config = baseConfig;
    config.sourcePositionMeters = invalidPositions{positionIndex};
    verifyValidationFails(testCase, config);
end
end

function testRejectsInvalidReferenceMicrophoneIndices(testCase)
baseConfig = micloc.defaultConfig();
microphoneCount = size(baseConfig.microphonePositionsMeters, 1);
invalidIndices = {0, microphoneCount + 1, 1.5, NaN, Inf};

for index = 1:numel(invalidIndices)
    config = baseConfig;
    config.referenceMicrophoneIndex = invalidIndices{index};
    verifyValidationFails(testCase, config);
end
end

function testRejectsInvalidSNRValues(testCase)
baseConfig = micloc.defaultConfig();
invalidSNRValues = {NaN, -Inf, 1 + 1i, [10, 20], '30'};

for valueIndex = 1:numel(invalidSNRValues)
    config = baseConfig;
    config.noise.snrDb = invalidSNRValues{valueIndex};
    verifyValidationFails(testCase, config);
end

infiniteSNRConfig = baseConfig;
infiniteSNRConfig.noise.snrDb = Inf;
verifyEqual(testCase, ...
    micloc.validateConfig(infiniteSNRConfig), infiniteSNRConfig);
end

function testRejectsInvalidLMSSettings(testCase)
baseConfig = micloc.defaultConfig();

invalidConfigs = cell(4, 1);
invalidConfigs{1} = baseConfig;
invalidConfigs{1}.lms.filterLength = 0;
invalidConfigs{2} = baseConfig;
invalidConfigs{2}.lms.stepSize = 0;
invalidConfigs{3} = baseConfig;
invalidConfigs{3}.lms.bulkDelaySamples = -1;
invalidConfigs{4} = baseConfig;
invalidConfigs{4}.lms.storeCoefficientHistory = 1;

for configIndex = 1:numel(invalidConfigs)
    verifyValidationFails(testCase, invalidConfigs{configIndex});
end
end

function testRejectsInvalidLocalizationSettings(testCase)
baseConfig = micloc.defaultConfig();

invalidConfigs = cell(5, 1);
invalidConfigs{1} = baseConfig;
invalidConfigs{1}.localization.initialGuessMeters = [6, 1];
invalidConfigs{2} = baseConfig;
invalidConfigs{2}.localization.lowerBoundsMeters = [1, 1];
invalidConfigs{2}.localization.upperBoundsMeters = [0, 2];
invalidConfigs{3} = baseConfig;
invalidConfigs{3}.localization.maxIterations = 0;
invalidConfigs{4} = baseConfig;
invalidConfigs{4}.localization.functionTolerance = 0;
invalidConfigs{5} = baseConfig;
invalidConfigs{5}.localization.solverDisplay = 'verbose';

for configIndex = 1:numel(invalidConfigs)
    verifyValidationFails(testCase, invalidConfigs{configIndex});
end
end

function testRejectsUnsupportedDelayMethodAndMissingField(testCase)
config = micloc.defaultConfig();
config.delayMethod = 'unknown';
verifyValidationFails(testCase, config);

config = rmfield(micloc.defaultConfig(), 'sourcePositionMeters');
verifyError(testCase, @() micloc.validateConfig(config), ...
    'micloc:validateConfig:MissingField');
end

function verifyValidationFails(testCase, config)
caughtIdentifier = '';
try
    micloc.validateConfig(config);
catch errorInfo
    caughtIdentifier = errorInfo.identifier;
end

verifyNotEmpty(testCase, caughtIdentifier, ...
    'Expected configuration validation to raise an identified error.');
end
