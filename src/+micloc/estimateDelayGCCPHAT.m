function [relativeDelaySamples, diagnostics] = ...
        estimateDelayGCCPHAT(comparisonSignal, referenceSignal)
%ESTIMATEDELAYGCCPHAT Estimate integer relative delay using GCC-PHAT.
%   DELAYSAMPLES = MICLOC.ESTIMATEDELAYGCCPHAT(COMPARISON, REFERENCE)
%   computes a phase-transform-weighted generalized cross-correlation using
%   independently written FFT operations. Positive delay means COMPARISON
%   arrives later than REFERENCE. Equal-length, finite, real signal vectors
%   containing at least two samples are required.
%
%   The FFT is zero-padded for linear correlation. The initial estimator
%   searches every feasible signed lag and returns the unique largest
%   correlation magnitude at integer-sample resolution. Zero cross-spectra
%   and exactly tied peaks are rejected as unidentifiable.
%
%   [DELAYSAMPLES, DIAGNOSTICS] also returns the signed lag axis, GCC-PHAT
%   sequence, peak statistics, FFT length, and normalization floor. This
%   implementation does not call the Phased Array System Toolbox GCCPHAT
%   function.

narginchk(2, 2);
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
maximumLagSamples = sampleCount - 1;
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
relativeDelaySamples = searchedLagsSamples(peakIndex);
remainingMagnitudes = searchedMagnitudes;
remainingMagnitudes(peakIndex) = [];
secondPeakMagnitude = max(remainingMagnitudes);
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
diagnostics.maximumLagSamples = maximumLagSamples;
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
diagnostics.integerDelaySamples = relativeDelaySamples;
diagnostics.relativeDelaySamples = relativeDelaySamples;
diagnostics.resolutionSamples = 1;
diagnostics.tdoaSignConvention = ...
    'comparison arrival minus reference arrival';
end
