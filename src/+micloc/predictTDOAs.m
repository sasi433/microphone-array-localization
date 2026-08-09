function [tdoasSeconds, arrivalTimesSeconds] = predictTDOAs( ...
        sourcePositionMeters, microphonePositionsMeters, ...
        speedOfSoundMetersPerSecond, referenceMicrophoneIndex)
%PREDICTTDOAS Predict ideal TDOAs for a candidate source position.
%   TDOAS = MICLOC.PREDICTTDOAS(SOURCE, MICROPHONES, SPEED, REFERENCE)
%   returns an N-by-1 vector in seconds, one value per microphone. TDOAS(i)
%   is arrivalTime(i) - arrivalTime(REFERENCE), so a positive value means
%   that microphone i receives the signal later than the reference. The
%   reference entry is exactly zero.
%
%   [TDOAS, ARRIVALTIMES] also returns the direct-path arrival times in
%   seconds before reference subtraction. Coordinates are in metres and
%   SPEED is in metres per second.

micloc.validateMicrophonePositions(microphonePositionsMeters);
microphoneCount = size(microphonePositionsMeters, 1);
validateattributes(referenceMicrophoneIndex, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', '>=', 1, '<=', microphoneCount}, ...
    mfilename, 'referenceMicrophoneIndex');

arrivalTimesSeconds = micloc.calculateArrivalTimes( ...
    sourcePositionMeters, microphonePositionsMeters, ...
    speedOfSoundMetersPerSecond);
referenceArrivalTimeSeconds = arrivalTimesSeconds(referenceMicrophoneIndex);
tdoasSeconds = arrivalTimesSeconds - referenceArrivalTimeSeconds;
tdoasSeconds(referenceMicrophoneIndex) = 0;
end
