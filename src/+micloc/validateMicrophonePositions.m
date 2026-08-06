function microphonePositionsMeters = validateMicrophonePositions( ...
        microphonePositionsMeters)
%VALIDATEMICROPHONEPOSITIONS Validate two-dimensional microphone geometry.
%   POSITIONS = MICLOC.VALIDATEMICROPHONEPOSITIONS(POSITIONS) requires a
%   finite numeric N-by-2 coordinate matrix in metres with at least three
%   unique microphone positions. Valid linear arrays are accepted. The
%   validated matrix is returned unchanged.

validateattributes(microphonePositionsMeters, {'numeric'}, ...
    {'real', '2d', 'finite', 'ncols', 2}, mfilename, ...
    'microphonePositionsMeters');

microphoneCount = size(microphonePositionsMeters, 1);
if microphoneCount < 3
    error('micloc:validateMicrophonePositions:TooFewMicrophones', ...
        'At least three microphone positions are required.');
end

if size(unique(microphonePositionsMeters, 'rows'), 1) ~= microphoneCount
    error('micloc:validateMicrophonePositions:DuplicatePositions', ...
        'Microphone positions must not contain duplicate coordinate rows.');
end
end
