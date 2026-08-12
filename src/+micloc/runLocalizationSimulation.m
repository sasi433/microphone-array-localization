function result = runLocalizationSimulation(config)
%RUNLOCALIZATIONSIMULATION Run deterministic LMS source localization.
%   RESULT = MICLOC.RUNLOCALIZATIONSIMULATION(CONFIG) validates CONFIG and
%   executes source generation, direct-path propagation, optional noise,
%   pairwise LMS adaptation, phase-slope TDOA estimation, bounded source
%   localization, and accuracy calculation. RESULT contains the validated
%   configuration and seed, geometry, generated and received signals, true
%   arrival times and TDOAs, estimated TDOAs and errors, source coordinates,
%   accuracy metrics, solver diagnostics, and per-pair LMS diagnostics.

config = micloc.validateConfig(config);
sampleRateHz = config.sampleRateHz;
microphoneCount = size(config.microphonePositionsMeters, 1);
referenceIndex = config.referenceMicrophoneIndex;

[sourceSignal, timeSeconds] = micloc.generateSourceSignal(config);
arrivalTimesSeconds = micloc.calculateArrivalTimes( ...
    config.sourcePositionMeters, config.microphonePositionsMeters, ...
    config.speedOfSoundMetersPerSecond);
propagationDelaySamples = arrivalTimesSeconds * sampleRateHz;
if strcmpi(char(config.delayMethod), 'integer')
    appliedDelaySamples = round(propagationDelaySamples);
else
    appliedDelaySamples = propagationDelaySamples;
end
[cleanMicrophoneSignals, propagationDiagnostics] = ...
    micloc.simulateMicrophoneSignals(sourceSignal, appliedDelaySamples, ...
    config.delayMethod);

if config.noise.enabled
    [microphoneSignals, noise, noiseDiagnostics] = micloc.addNoiseAtSNR( ...
        cleanMicrophoneSignals, config.noise.snrDb, config.randomSeed + 1);
else
    microphoneSignals = double(cleanMicrophoneSignals);
    noise = zeros(size(microphoneSignals));
    noiseDiagnostics = createDisabledNoiseDiagnostics( ...
        cleanMicrophoneSignals, config.randomSeed + 1);
end

appliedTDOAsSamples = appliedDelaySamples ...
    - appliedDelaySamples(referenceIndex);
validateLMSDelayRange(appliedTDOAsSamples, config.lms);
estimatedTDOAsSamples = zeros(microphoneCount, 1);
pairDiagnostics = cell(microphoneCount, 1);

for microphoneIndex = 1:microphoneCount
    if microphoneIndex == referenceIndex
        pairDiagnostics{microphoneIndex} = struct( ...
            'isReferenceMicrophone', true, ...
            'estimatedTDOASamples', 0);
        continue
    end

    [adaptiveInput, desiredSignal, alignmentDiagnostics] = ...
        micloc.alignMicrophonePairForLMS( ...
        microphoneSignals(:, referenceIndex), ...
        microphoneSignals(:, microphoneIndex), ...
        config.lms.bulkDelaySamples);
    [learnedCoefficients, ~, ~, lmsDiagnostics] = micloc.adaptiveLMS( ...
        adaptiveInput, desiredSignal, config.lms.filterLength, ...
        config.lms.stepSize, [], config.lms.storeCoefficientHistory);
    [estimatedTDOAsSamples(microphoneIndex), phaseDiagnostics] = ...
        micloc.estimateDelayFromPhase(learnedCoefficients, sampleRateHz, ...
        config.lms.bulkDelaySamples);

    pairDiagnostics{microphoneIndex} = struct( ...
        'isReferenceMicrophone', false, ...
        'estimatedTDOASamples', ...
        estimatedTDOAsSamples(microphoneIndex), ...
        'learnedCoefficients', learnedCoefficients, ...
        'alignment', alignmentDiagnostics, ...
        'lms', lmsDiagnostics, ...
        'phase', phaseDiagnostics);
end

estimatedTDOAsSeconds = estimatedTDOAsSamples / sampleRateHz;
[estimatedPositionMeters, solverDiagnostics] = ...
    micloc.estimateSourcePosition(estimatedTDOAsSeconds, ...
    config.microphonePositionsMeters, ...
    config.speedOfSoundMetersPerSecond, referenceIndex, ...
    config.localization);
metrics = micloc.calculateLocalizationMetrics( ...
    config.sourcePositionMeters, estimatedPositionMeters, ...
    solverDiagnostics);

trueTDOAsSeconds = arrivalTimesSeconds - arrivalTimesSeconds(referenceIndex);

result.config = config;
result.randomSeed = config.randomSeed;
result.microphonePositionsMeters = config.microphonePositionsMeters;
result.sourceSignal = sourceSignal;
result.sourceTimeSeconds = timeSeconds;
result.cleanMicrophoneSignals = cleanMicrophoneSignals;
result.microphoneSignals = microphoneSignals;
result.noiseSamples = noise;
result.actualPositionMeters = config.sourcePositionMeters;
result.estimatedPositionMeters = estimatedPositionMeters;
result.trueArrivalTimesSeconds = arrivalTimesSeconds;
result.trueTDOAsSeconds = trueTDOAsSeconds;
result.appliedDelaySamples = appliedDelaySamples;
result.appliedTDOAsSamples = appliedTDOAsSamples;
result.estimatedTDOAsSamples = estimatedTDOAsSamples;
result.estimatedTDOAsSeconds = estimatedTDOAsSeconds;
result.tdoaErrorsSeconds = estimatedTDOAsSeconds - trueTDOAsSeconds;
result.metrics = metrics;
result.localizationErrorMeters = metrics.localizationErrorMeters;
result.solverSucceeded = solverDiagnostics.solverSucceeded;
result.diagnostics.propagation = propagationDiagnostics;
result.diagnostics.noise = noiseDiagnostics;
result.diagnostics.pairs = pairDiagnostics;
result.diagnostics.solver = solverDiagnostics;
result.solverDiagnostics = solverDiagnostics;
result.lmsDiagnostics = pairDiagnostics;
end

function validateLMSDelayRange(tdoasSamples, lmsSettings)
minimumCausalLag = lmsSettings.bulkDelaySamples + min(tdoasSamples);
maximumCausalLag = lmsSettings.bulkDelaySamples + max(tdoasSamples);
if minimumCausalLag < 0 || maximumCausalLag >= lmsSettings.filterLength
    error('micloc:runLocalizationSimulation:UnrepresentableTDOA', ...
        ['Configured bulk delay and filter length cannot represent the ' ...
        'simulated TDOA range.']);
end
end

function diagnostics = createDisabledNoiseDiagnostics(cleanSignals, seed)
diagnostics.cleanSignalPower = mean(double(cleanSignals) .^ 2, 1);
diagnostics.targetSnrDb = Inf;
diagnostics.targetNoisePower = zeros(1, size(cleanSignals, 2));
diagnostics.measuredNoisePower = zeros(1, size(cleanSignals, 2));
diagnostics.measuredSnrDb = Inf(1, size(cleanSignals, 2));
diagnostics.randomSeed = seed;
diagnostics.noiseEnabled = false;
end
