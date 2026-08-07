function [noisySignal, noise, diagnostics] = addNoiseAtSNR( ...
        cleanSignal, snrDb, randomSeed)
%ADDNOISEATSNR Add deterministic Gaussian noise at a measured target SNR.
%   NOISY = MICLOC.ADDNOISEATSNR(CLEAN, SNRDB, SEED) adds independently
%   generated zero-mean Gaussian noise to each column of CLEAN. Noise is
%   scaled using each channel's measured mean-square clean power so that
%   the measured SNR is SNRDB. A vector is treated as one channel and its
%   row or column orientation is preserved. Matrix rows are samples and
%   columns are channels. Outputs are double precision.
%
%   Positive infinity requests no noise and returns CLEAN unchanged. A
%   finite SNR cannot be defined for a zero-power channel and raises an
%   error. Generation uses a local random stream and does not modify
%   MATLAB's global random state.

validateattributes(cleanSignal, {'numeric'}, ...
    {'real', '2d', 'nonempty', 'finite'}, mfilename, 'cleanSignal');
if ~(isnumeric(snrDb) && isreal(snrDb) && isscalar(snrDb) ...
        && ~isnan(snrDb) && (isfinite(snrDb) || snrDb == Inf))
    error('micloc:addNoiseAtSNR:InvalidSNR', ...
        'SNR must be a finite real scalar or positive infinity.');
end
validateattributes(randomSeed, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', 'nonnegative', ...
    '<=', double(intmax('uint32'))}, mfilename, 'randomSeed');

inputWasRowVector = isrow(cleanSignal);
if isvector(cleanSignal)
    cleanMatrix = double(cleanSignal(:));
else
    cleanMatrix = double(cleanSignal);
end

cleanSignalPower = mean(cleanMatrix .^ 2, 1);
if isinf(snrDb)
    noiseMatrix = zeros(size(cleanMatrix));
    targetNoisePower = zeros(size(cleanSignalPower));
else
    if any(cleanSignalPower == 0)
        error('micloc:addNoiseAtSNR:ZeroSignalPower', ...
            'Finite-SNR noise requires positive clean power in every channel.');
    end
    targetNoisePower = cleanSignalPower / (10 ^ (snrDb / 10));
    randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
    rawNoise = randn(randomStream, size(cleanMatrix));
    rawNoisePower = mean(rawNoise .^ 2, 1);
    noiseMatrix = rawNoise .* sqrt(targetNoisePower ./ rawNoisePower);
end

noisyMatrix = cleanMatrix + noiseMatrix;
measuredNoisePower = mean(noiseMatrix .^ 2, 1);
measuredSnrDb = Inf(size(cleanSignalPower));
nonzeroNoiseChannels = measuredNoisePower > 0;
measuredSnrDb(nonzeroNoiseChannels) = 10 * log10( ...
    cleanSignalPower(nonzeroNoiseChannels) ...
    ./ measuredNoisePower(nonzeroNoiseChannels));

if inputWasRowVector
    noisySignal = noisyMatrix.';
    noise = noiseMatrix.';
else
    noisySignal = noisyMatrix;
    noise = noiseMatrix;
end

diagnostics.cleanSignalPower = cleanSignalPower;
diagnostics.targetSnrDb = snrDb;
diagnostics.targetNoisePower = targetNoisePower;
diagnostics.measuredNoisePower = measuredNoisePower;
diagnostics.measuredSnrDb = measuredSnrDb;
diagnostics.randomSeed = randomSeed;
end
