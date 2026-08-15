function [relativeDelaySamples, diagnostics] = ...
        estimateDelayGCCPHAT(comparisonSignal, referenceSignal, ...
        maximumLagSamples)
%ESTIMATEDELAYGCCPHAT Estimate relative delay using GCC-PHAT.
%   DELAYSAMPLES = MICLOC.ESTIMATEDELAYGCCPHAT(COMPARISON, REFERENCE)
%   computes a phase-transform-weighted generalized cross-correlation using
%   independently written FFT operations. Positive delay means COMPARISON
%   arrives later than REFERENCE. Equal-length, finite, real signal vectors
%   containing at least two samples are required.
%
%   DELAYSAMPLES = MICLOC.ESTIMATEDELAYGCCPHAT(COMPARISON, REFERENCE,
%   MAXIMUMLAGSAMPLES) limits the signed peak search to the supplied
%   nonnegative integer bound. Use MICLOC.CALCULATEMAXIMUMTDOASAMPLES to
%   derive physical pairwise bounds from microphone geometry. A bound wider
%   than the finite-signal range is capped and reported in diagnostics.
%
%   The FFT is zero-padded for linear correlation. The estimator searches
%   the selected feasible signed lags and selects the unique largest
%   correlation magnitude. A three-point quadratic fit around an interior
%   peak provides a sub-sample estimate. The integer estimate is retained
%   when interpolation is numerically unsafe or the peak is on the search
%   boundary. Zero cross-spectra and exactly tied peaks are rejected as
%   unidentifiable.
%
%   [DELAYSAMPLES, DIAGNOSTICS] also returns the signed lag axis, GCC-PHAT
%   sequence, peak statistics, FFT length, and normalization floor. This
%   implementation does not call the Phased Array System Toolbox GCCPHAT
%   function.

narginchk(2, 3);
validateattributes(comparisonSignal, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, ...
    'comparisonSignal');
validateattributes(referenceSignal, {'numeric'}, ...
    {'real', 'vector', 'finite', 'nonempty'}, mfilename, ...
    'referenceSignal');
if numel(comparisonSignal) ~= numel(referenceSignal)
    error('micloc:estimateDelayGCCPHAT:MismatchedSignalLengths', ...
        'Comparison and reference signals must have equal lengths.');
end
sampleCount = numel(comparisonSignal);
if sampleCount < 2
    error('micloc:estimateDelayGCCPHAT:SignalTooShort', ...
        'At least two signal samples are required.');
end
fullMaximumLagSamples = sampleCount - 1;
if nargin < 3 || isempty(maximumLagSamples)
    requestedMaximumLagSamples = fullMaximumLagSamples;
    lagConstraintApplied = false;
else
    validateattributes(maximumLagSamples, {'numeric'}, ...
        {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, ...
        mfilename, 'maximumLagSamples');
    requestedMaximumLagSamples = double(maximumLagSamples);
    lagConstraintApplied = true;
end
maximumLagSamples = min( ...
    requestedMaximumLagSamples, fullMaximumLagSamples);

comparisonColumn = double(comparisonSignal(:));
referenceColumn = double(referenceSignal(:));
linearCorrelationLength = 2 * sampleCount - 1;
fftLength = 2 ^ nextpow2(linearCorrelationLength);
comparisonSpectrum = fft(comparisonColumn, fftLength);
referenceSpectrum = fft(referenceColumn, fftLength);
crossSpectrum = comparisonSpectrum .* conj(referenceSpectrum);
crossSpectrumMagnitudes = abs(crossSpectrum);
if any(~isfinite(crossSpectrumMagnitudes))
    error('micloc:estimateDelayGCCPHAT:NumericalFailure', ...
        'The cross-spectrum contains nonfinite values.');
end
maximumCrossSpectrumMagnitude = max(crossSpectrumMagnitudes);
if maximumCrossSpectrumMagnitude == 0
    error('micloc:estimateDelayGCCPHAT:ZeroCrossSpectrum', ...
        'A zero cross-spectrum does not identify a delay.');
end

normalizationFloor = max(eps(maximumCrossSpectrumMagnitude), eps);
phatCrossSpectrum = crossSpectrum ...
    ./ max(crossSpectrumMagnitudes, normalizationFloor);
gccPhatCircular = real(ifft(phatCrossSpectrum));
gccPhat = fftshift(gccPhatCircular);
lagsSamples = (-fftLength / 2:fftLength / 2 - 1).';
searchMask = abs(lagsSamples) <= maximumLagSamples;
searchedCorrelation = gccPhat(searchMask);
searchedLagsSamples = lagsSamples(searchMask);
searchedMagnitudes = abs(searchedCorrelation);
peakMagnitude = max(searchedMagnitudes);
peakIndices = find(searchedMagnitudes == peakMagnitude);
if numel(peakIndices) ~= 1
    error('micloc:estimateDelayGCCPHAT:AmbiguousPeak', ...
        'GCC-PHAT has multiple equal-magnitude largest peaks.');
end

peakIndex = peakIndices(1);
integerDelaySamples = searchedLagsSamples(peakIndex);
[fractionalOffsetSamples, interpolationApplied, interpolationReason] = ...
    interpolatePeak(searchedMagnitudes, peakIndex);
relativeDelaySamples = integerDelaySamples + fractionalOffsetSamples;
remainingMagnitudes = searchedMagnitudes;
remainingMagnitudes(peakIndex) = [];
if isempty(remainingMagnitudes)
    secondPeakMagnitude = 0;
else
    secondPeakMagnitude = max(remainingMagnitudes);
end
if secondPeakMagnitude == 0
    peakToSecondPeakRatio = Inf;
else
    peakToSecondPeakRatio = peakMagnitude / secondPeakMagnitude;
end

diagnostics.method = 'gcc-phat';
diagnostics.sampleCount = sampleCount;
diagnostics.fftLength = fftLength;
diagnostics.linearCorrelationLength = linearCorrelationLength;
diagnostics.normalizationFloor = normalizationFloor;
diagnostics.requestedMaximumLagSamples = requestedMaximumLagSamples;
diagnostics.maximumLagSamples = maximumLagSamples;
diagnostics.lagConstraintApplied = lagConstraintApplied;
diagnostics.lagsSamples = lagsSamples;
diagnostics.correlation = gccPhat;
diagnostics.searchMask = searchMask;
diagnostics.searchedLagsSamples = searchedLagsSamples;
diagnostics.searchedCorrelation = searchedCorrelation;
diagnostics.peakIndex = peakIndex;
diagnostics.peakCorrelation = searchedCorrelation(peakIndex);
diagnostics.peakMagnitude = peakMagnitude;
diagnostics.secondPeakMagnitude = secondPeakMagnitude;
diagnostics.peakToSecondPeakRatio = peakToSecondPeakRatio;
diagnostics.integerDelaySamples = integerDelaySamples;
diagnostics.fractionalOffsetSamples = fractionalOffsetSamples;
diagnostics.subsampleInterpolationApplied = interpolationApplied;
diagnostics.subsampleInterpolationReason = interpolationReason;
diagnostics.relativeDelaySamples = relativeDelaySamples;
diagnostics.integerLagGridSpacingSamples = 1;
diagnostics.tdoaSignConvention = ...
    'comparison arrival minus reference arrival';
end

function [offsetSamples, applied, reason] = interpolatePeak( ...
        correlationMagnitudes, peakIndex)
offsetSamples = 0;
applied = false;
if peakIndex == 1 || peakIndex == numel(correlationMagnitudes)
    reason = 'search-boundary';
    return
end

leftMagnitude = correlationMagnitudes(peakIndex - 1);
peakMagnitude = correlationMagnitudes(peakIndex);
rightMagnitude = correlationMagnitudes(peakIndex + 1);
curvatureDenominator = ...
    leftMagnitude - 2 * peakMagnitude + rightMagnitude;
curvatureTolerance = eps(max( ...
    [leftMagnitude, peakMagnitude, rightMagnitude]));
if curvatureDenominator >= -curvatureTolerance
    reason = 'flat-or-nonconcave-peak';
    return
end

candidateOffset = 0.5 * (leftMagnitude - rightMagnitude) ...
    / curvatureDenominator;
if ~isfinite(candidateOffset) || abs(candidateOffset) > 1
    reason = 'offset-outside-neighborhood';
    return
end

offsetSamples = candidateOffset;
applied = true;
reason = 'applied';
end
