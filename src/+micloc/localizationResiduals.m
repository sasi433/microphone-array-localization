function [residualsSeconds, predictedTDOAsSeconds] = ...
        localizationResiduals(sourcePositionMeters, measuredTDOAsSeconds, ...
        microphonePositionsMeters, speedOfSoundMetersPerSecond, ...
        referenceMicrophoneIndex)
%LOCALIZATIONRESIDUALS Calculate TDOA localization residuals.
%   RESIDUALS = MICLOC.LOCALIZATIONRESIDUALS(SOURCE, MEASURED, MICROPHONES,
%   SPEED, REFERENCE) predicts an N-by-1 TDOA vector for SOURCE and returns
%   PREDICTED - MEASURED for every non-reference microphone. RESIDUALS is
%   therefore (N-1)-by-1 and is expressed in seconds. MEASURED must contain
%   one value per microphone and an exact zero at REFERENCE.
%
%   [RESIDUALS, PREDICTED] also returns the complete N-by-1 predicted TDOA
%   vector, including the zero reference entry.

micloc.validateMicrophonePositions(microphonePositionsMeters);
microphoneCount = size(microphonePositionsMeters, 1);
validateattributes(measuredTDOAsSeconds, {'numeric'}, ...
    {'real', 'vector', 'finite', 'numel', microphoneCount}, mfilename, ...
    'measuredTDOAsSeconds');
validateattributes(referenceMicrophoneIndex, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', '>=', 1, '<=', microphoneCount}, ...
    mfilename, 'referenceMicrophoneIndex');

measuredTDOAsSeconds = measuredTDOAsSeconds(:);
if measuredTDOAsSeconds(referenceMicrophoneIndex) ~= 0
    error('micloc:localizationResiduals:NonzeroReferenceTDOA', ...
        'The measured TDOA at the reference microphone must be zero.');
end

predictedTDOAsSeconds = micloc.predictTDOAs( ...
    sourcePositionMeters, microphonePositionsMeters, ...
    speedOfSoundMetersPerSecond, referenceMicrophoneIndex);
nonReferenceMask = true(microphoneCount, 1);
nonReferenceMask(referenceMicrophoneIndex) = false;
residualsSeconds = predictedTDOAsSeconds(nonReferenceMask) ...
    - measuredTDOAsSeconds(nonReferenceMask);
end
