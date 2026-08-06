function distancesMeters = calculateDistances( ...
        sourcePositionMeters, microphonePositionsMeters)
%CALCULATEDISTANCES Calculate source-to-microphone Euclidean distances.
%   DISTANCES = MICLOC.CALCULATEDISTANCES(SOURCE, MICROPHONES) returns an
%   N-by-1 vector containing the direct-path distance in metres from the
%   1-by-2 SOURCE coordinate to each row of the N-by-2 MICROPHONES matrix.

validateattributes(sourcePositionMeters, {'numeric'}, ...
    {'real', 'finite', 'size', [1, 2]}, mfilename, ...
    'sourcePositionMeters');
micloc.validateMicrophonePositions(microphonePositionsMeters);

coordinateDifferencesMeters = microphonePositionsMeters ...
    - sourcePositionMeters;
distancesMeters = sqrt(sum(coordinateDifferencesMeters .^ 2, 2));
end
