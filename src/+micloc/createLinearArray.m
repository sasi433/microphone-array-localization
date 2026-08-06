function microphonePositionsMeters = createLinearArray( ...
        microphoneCount, spacingMeters, originMeters, orientationRadians)
%CREATELINEARARRAY Create a centered two-dimensional linear array.
%   POSITIONS = MICLOC.CREATELINEARARRAY(COUNT, SPACING, ORIGIN, ANGLE)
%   returns a COUNT-by-2 matrix of microphone coordinates in metres.
%   SPACING is the adjacent-microphone spacing in metres. ORIGIN is the
%   1-by-2 coordinate of the array centroid. ANGLE is measured in radians
%   counterclockwise from the positive x-axis. Microphones are ordered from
%   the negative-axis end of the array to the positive-axis end.

validateattributes(microphoneCount, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'integer', '>=', 3}, mfilename, ...
    'microphoneCount');
validateattributes(spacingMeters, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'positive'}, mfilename, 'spacingMeters');
validateattributes(originMeters, {'numeric'}, ...
    {'real', 'finite', 'size', [1, 2]}, mfilename, 'originMeters');
validateattributes(orientationRadians, {'numeric'}, ...
    {'real', 'scalar', 'finite'}, mfilename, 'orientationRadians');

centeredIndices = (0:(microphoneCount - 1)).' ...
    - (microphoneCount - 1) / 2;
offsetsMeters = centeredIndices * spacingMeters;
arrayDirection = [cos(orientationRadians), sin(orientationRadians)];

microphonePositionsMeters = originMeters + offsetsMeters .* arrayDirection;
end
