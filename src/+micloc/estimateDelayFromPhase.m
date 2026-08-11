function [relativeDelaySamples, diagnostics] = estimateDelayFromPhase( ...
        filterCoefficients, sampleRateHz, bulkDelaySamples, ...
        frequencyBandHz, relativeMagnitudeThreshold, ...
        fixedGroupDelaySamples)
%ESTIMATEDELAYFROMPHASE Estimate signed delay from unwrapped FIR phase.
%   DELAYSAMPLES = MICLOC.ESTIMATEDELAYFROMPHASE(COEFFICIENTS, SAMPLERATE,
%   BULKDELAY) fits unwrapped phase over 5% to 45% of SAMPLERATE, retaining
%   bins whose magnitude is at least 10% of the response maximum. For
%   normalized angular frequency omega, an ideal causal delay D has phase
%   -D*omega, so the negative fitted slope estimates D in samples.
%
%   DELAYSAMPLES = MICLOC.ESTIMATEDELAYFROMPHASE(..., FREQUENCYBANDHZ,
%   RELATIVEMAGNITUDETHRESHOLD, FIXEDGROUPDELAYSAMPLES) selects a two-value
%   frequency band, a threshold in [0,1), and a known nonnegative fixed
%   group delay to remove. The returned microphone TDOA is
%   rawDelay - FIXEDGROUPDELAYSAMPLES - BULKDELAY. Positive TDOA means the
%   comparison microphone received the signal later than the reference.
%
%   [DELAYSAMPLES, DIAGNOSTICS] reports selected bins, slope, intercept,
%   raw and compensated delays, phase-fit RMSE, R-squared, and a fit-quality
%   label. A fit with R-squared below 0.95 is labeled poor, not hidden.

narginchk(3, 6);
validateattributes(filterCoefficients, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, ...
    'filterCoefficients');
validateattributes(sampleRateHz, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'positive'}, mfilename, 'sampleRateHz');
validateattributes(bulkDelaySamples, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, ...
    'bulkDelaySamples');

if nargin < 4 || isempty(frequencyBandHz)
    frequencyBandHz = [0.05, 0.45] * sampleRateHz;
end
validateattributes(frequencyBandHz, {'numeric'}, ...
    {'real', 'finite', 'size', [1, 2], 'nonnegative'}, mfilename, ...
    'frequencyBandHz');
if frequencyBandHz(1) >= frequencyBandHz(2) ...
        || frequencyBandHz(2) > sampleRateHz / 2
    error('micloc:estimateDelayFromPhase:InvalidFrequencyBand', ...
        'Frequency band must increase and remain at or below Nyquist.');
end

if nargin < 5 || isempty(relativeMagnitudeThreshold)
    relativeMagnitudeThreshold = 0.1;
end
validateattributes(relativeMagnitudeThreshold, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, ...
    'relativeMagnitudeThreshold');
if relativeMagnitudeThreshold >= 1
    error('micloc:estimateDelayFromPhase:InvalidMagnitudeThreshold', ...
        'Relative magnitude threshold must be smaller than one.');
end

if nargin < 6 || isempty(fixedGroupDelaySamples)
    fixedGroupDelaySamples = 0;
end
validateattributes(fixedGroupDelaySamples, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, ...
    'fixedGroupDelaySamples');

frequencyBinCount = 4096;
[frequencyResponse, frequenciesHz] = freqz( ...
    filterCoefficients(:), 1, frequencyBinCount, sampleRateHz);
responseMagnitude = abs(frequencyResponse);
maximumMagnitude = max(responseMagnitude);
if maximumMagnitude == 0
    error('micloc:estimateDelayFromPhase:ZeroResponse', ...
        'A zero frequency response does not identify a delay.');
end

inFrequencyBand = frequenciesHz >= frequencyBandHz(1) ...
    & frequenciesHz <= frequencyBandHz(2);
aboveMagnitudeThreshold = responseMagnitude ...
    >= relativeMagnitudeThreshold * maximumMagnitude;
selectedBins = inFrequencyBand & aboveMagnitudeThreshold;
if nnz(selectedBins) < 3
    error('micloc:estimateDelayFromPhase:InsufficientFrequencyBins', ...
        'At least three valid frequency bins are required for a phase fit.');
end

selectedFrequenciesHz = frequenciesHz(selectedBins);
selectedAngularFrequencies = ...
    2 * pi * selectedFrequenciesHz / sampleRateHz;
selectedUnwrappedPhaseRadians = unwrap(angle(frequencyResponse(selectedBins)));
phaseFitCoefficients = polyfit( ...
    selectedAngularFrequencies, selectedUnwrappedPhaseRadians, 1);
fittedPhaseRadians = polyval( ...
    phaseFitCoefficients, selectedAngularFrequencies);
phaseResidualsRadians = selectedUnwrappedPhaseRadians - fittedPhaseRadians;

rawDelaySamples = -phaseFitCoefficients(1);
causalDelaySamples = rawDelaySamples - fixedGroupDelaySamples;
relativeDelaySamples = causalDelaySamples - bulkDelaySamples;
phaseResidualSumOfSquares = sum(phaseResidualsRadians .^ 2);
centeredPhase = selectedUnwrappedPhaseRadians ...
    - mean(selectedUnwrappedPhaseRadians);
phaseTotalSumOfSquares = sum(centeredPhase .^ 2);
if phaseTotalSumOfSquares == 0
    phaseFitRSquared = double(phaseResidualSumOfSquares == 0);
else
    phaseFitRSquared = 1 ...
        - phaseResidualSumOfSquares / phaseTotalSumOfSquares;
end
phaseFitRootMeanSquaredErrorRadians = sqrt( ...
    mean(phaseResidualsRadians .^ 2));
if phaseFitRSquared >= 0.95
    fitQuality = 'good';
else
    fitQuality = 'poor';
end

diagnostics.method = 'unwrapped-phase-slope';
diagnostics.sampleRateHz = sampleRateHz;
diagnostics.frequencyBandHz = frequencyBandHz;
diagnostics.relativeMagnitudeThreshold = relativeMagnitudeThreshold;
diagnostics.frequencyBinCount = frequencyBinCount;
diagnostics.selectedFrequencyBinCount = nnz(selectedBins);
diagnostics.selectedFrequenciesHz = selectedFrequenciesHz;
diagnostics.selectedUnwrappedPhaseRadians = ...
    selectedUnwrappedPhaseRadians;
diagnostics.phaseSlopeRadiansPerRadian = phaseFitCoefficients(1);
diagnostics.phaseInterceptRadians = phaseFitCoefficients(2);
diagnostics.rawDelaySamples = rawDelaySamples;
diagnostics.fixedGroupDelaySamples = fixedGroupDelaySamples;
diagnostics.causalDelaySamples = causalDelaySamples;
diagnostics.bulkDelaySamples = bulkDelaySamples;
diagnostics.relativeDelaySamples = relativeDelaySamples;
diagnostics.phaseFitResidualsRadians = phaseResidualsRadians;
diagnostics.phaseFitRootMeanSquaredErrorRadians = ...
    phaseFitRootMeanSquaredErrorRadians;
diagnostics.phaseFitRSquared = phaseFitRSquared;
diagnostics.fitQuality = fitQuality;
diagnostics.tdoaSignConvention = ...
    'comparison arrival minus reference arrival';
end
