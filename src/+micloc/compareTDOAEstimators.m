function comparison = compareTDOAEstimators( ...
        baseConfig, estimatorNames)
%COMPARETDOAESTIMATORS Compare delay estimators on identical signals.
%   COMPARISON = MICLOC.COMPARETDOAESTIMATORS(CONFIG) runs lms-peak,
%   lms-phase, and gcc-phat using the same validated configuration and
%   deterministic seed. The function verifies that every run produced
%   exactly identical source, clean microphone, noisy microphone, and noise
%   samples before comparing delay estimates.
%
%   COMPARISON = MICLOC.COMPARETDOAESTIMATORS(CONFIG, ESTIMATORS) selects a
%   nonempty unique text vector containing any of those method names.
%   COMPARISON retains the complete per-method results and common signals,
%   and reports mean absolute, root-mean-square, and maximum absolute TDOA
%   errors in samples. Reference-microphone zero entries are excluded from
%   aggregate error metrics.

baseConfig = micloc.validateConfig(baseConfig);
if nargin < 2 || isempty(estimatorNames)
    estimatorNames = ["lms-peak", "lms-phase", "gcc-phat"];
end
estimatorNames = validateEstimatorNames(estimatorNames);
estimatorCount = numel(estimatorNames);
microphoneCount = size(baseConfig.microphonePositionsMeters, 1);
referenceIndex = baseConfig.referenceMicrophoneIndex;
nonReferenceMask = true(microphoneCount, 1);
nonReferenceMask(referenceIndex) = false;

results = cell(estimatorCount, 1);
estimatedTDOAsSamples = zeros(microphoneCount, estimatorCount);
tdoaErrorSamples = zeros(microphoneCount, estimatorCount);
meanAbsoluteTDOAErrorSamples = zeros(estimatorCount, 1);
rootMeanSquareTDOAErrorSamples = zeros(estimatorCount, 1);
maximumAbsoluteTDOAErrorSamples = zeros(estimatorCount, 1);

for estimatorIndex = 1:estimatorCount
    methodConfig = baseConfig;
    methodConfig.tdoaEstimator = char(estimatorNames(estimatorIndex));
    methodResult = micloc.runLocalizationSimulation(methodConfig);
    if estimatorIndex == 1
        commonSourceSignal = methodResult.sourceSignal;
        commonCleanMicrophoneSignals = methodResult.cleanMicrophoneSignals;
        commonMicrophoneSignals = methodResult.microphoneSignals;
        commonNoiseSamples = methodResult.noiseSamples;
        trueTDOAsSamples = methodResult.trueTDOAsSeconds ...
            * baseConfig.sampleRateHz;
    else
        verifyIdenticalSignals(methodResult, commonSourceSignal, ...
            commonCleanMicrophoneSignals, commonMicrophoneSignals, ...
            commonNoiseSamples);
    end

    results{estimatorIndex} = methodResult;
    estimatedTDOAsSamples(:, estimatorIndex) = ...
        methodResult.estimatedTDOAsSamples;
    tdoaErrorSamples(:, estimatorIndex) = ...
        methodResult.estimatedTDOAsSamples - trueTDOAsSamples;
    nonReferenceErrors = ...
        tdoaErrorSamples(nonReferenceMask, estimatorIndex);
    meanAbsoluteTDOAErrorSamples(estimatorIndex) = ...
        mean(abs(nonReferenceErrors));
    rootMeanSquareTDOAErrorSamples(estimatorIndex) = ...
        sqrt(mean(nonReferenceErrors .^ 2));
    maximumAbsoluteTDOAErrorSamples(estimatorIndex) = ...
        max(abs(nonReferenceErrors));
end

delayMetricsTable = table(estimatorNames(:), ...
    meanAbsoluteTDOAErrorSamples, rootMeanSquareTDOAErrorSamples, ...
    maximumAbsoluteTDOAErrorSamples, 'VariableNames', { ...
    'TDOAEstimator', 'MeanAbsoluteTDOAErrorSamples', ...
    'RootMeanSquareTDOAErrorSamples', ...
    'MaximumAbsoluteTDOAErrorSamples'});

comparison.baseConfig = baseConfig;
comparison.estimatorNames = estimatorNames;
comparison.results = results;
comparison.sourceSignal = commonSourceSignal;
comparison.cleanMicrophoneSignals = commonCleanMicrophoneSignals;
comparison.microphoneSignals = commonMicrophoneSignals;
comparison.noiseSamples = commonNoiseSamples;
comparison.trueTDOAsSamples = trueTDOAsSamples;
comparison.estimatedTDOAsSamples = estimatedTDOAsSamples;
comparison.tdoaErrorSamples = tdoaErrorSamples;
comparison.delayMetricsTable = delayMetricsTable;
comparison.inputsVerifiedIdentical = true;
end

function estimatorNames = validateEstimatorNames(estimatorNames)
if ischar(estimatorNames)
    estimatorNames = string(estimatorNames);
elseif iscellstr(estimatorNames)
    estimatorNames = string(estimatorNames);
elseif ~isstring(estimatorNames)
    error('micloc:compareTDOAEstimators:InvalidEstimators', ...
        'Estimator names must be text values.');
end
if isempty(estimatorNames) || ~isvector(estimatorNames) ...
        || any(ismissing(estimatorNames)) ...
        || any(strlength(estimatorNames) == 0)
    error('micloc:compareTDOAEstimators:InvalidEstimators', ...
        'Estimator names must form a nonempty text vector.');
end
estimatorNames = lower(estimatorNames(:).');
allowedEstimators = ["lms-peak", "lms-phase", "gcc-phat"];
if any(~ismember(estimatorNames, allowedEstimators))
    error('micloc:compareTDOAEstimators:UnsupportedEstimator', ...
        'Supported estimators are lms-peak, lms-phase, and gcc-phat.');
end
if numel(unique(estimatorNames)) ~= numel(estimatorNames)
    error('micloc:compareTDOAEstimators:DuplicateEstimator', ...
        'Estimator names must be unique.');
end
end

function verifyIdenticalSignals(result, sourceSignal, cleanSignals, ...
        microphoneSignals, noiseSamples)
signalsMatch = isequal(result.sourceSignal, sourceSignal) ...
    && isequal(result.cleanMicrophoneSignals, cleanSignals) ...
    && isequal(result.microphoneSignals, microphoneSignals) ...
    && isequal(result.noiseSamples, noiseSamples);
if ~signalsMatch
    error('micloc:compareTDOAEstimators:NonidenticalInputs', ...
        'All estimators must receive exactly identical generated signals.');
end
end
