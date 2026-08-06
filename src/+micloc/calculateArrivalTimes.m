function arrivalTimesSeconds = calculateArrivalTimes( ...
        sourcePositionMeters, microphonePositionsMeters, ...
        speedOfSoundMetersPerSecond)
%CALCULATEARRIVALTIMES Calculate direct-path acoustic arrival times.
%   TIMES = MICLOC.CALCULATEARRIVALTIMES(SOURCE, MICROPHONES, SPEED)
%   returns an N-by-1 vector of arrival times in seconds. SOURCE and each
%   row of MICROPHONES are two-dimensional coordinates in metres. SPEED is
%   the positive finite propagation speed in metres per second.

validateattributes(speedOfSoundMetersPerSecond, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'positive'}, mfilename, ...
    'speedOfSoundMetersPerSecond');

distancesMeters = micloc.calculateDistances( ...
    sourcePositionMeters, microphonePositionsMeters);
arrivalTimesSeconds = distancesMeters / speedOfSoundMetersPerSecond;
end
