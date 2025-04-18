function imshow3D(volumeData, numCols)
% show3DMontage displays a 3D volume (H x W x N) as a montage in one figure.
%
% INPUTS:
%   volumeData - 3D matrix (Height x Width x Frames)
%   numCols    - (optional) Number of columns in the montage
%
% Example:
%   load mri; V = squeeze(D); imshow3D(V);

    if ndims(volumeData) ~= 3
        error('Input must be a 3D matrix [Height x Width x Frames]');
    end

    % Normalize for display
    volumeData = double(volumeData);
    volumeData = volumeData - min(volumeData(:));
    volumeData = volumeData / max(volumeData(:));

    % Number of slices
    numSlices = size(volumeData, 3);

    % Determine montage layout
    if nargin < 2 || isempty(numCols)
        numCols = ceil(sqrt(numSlices)); % Auto layout
    end
    numRows = ceil(numSlices / numCols);

    % Pad with blank slices if needed
    totalFrames = numRows * numCols;
    if totalFrames > numSlices
        blank = zeros(size(volumeData,1), size(volumeData,2), totalFrames - numSlices);
        volumeData = cat(3, volumeData, blank);
    end

    % Rearrange into grid
    tileRows = [];
    for r = 1:numRows
        rowTiles = [];
        for c = 1:numCols
            idx = (r-1)*numCols + c;
            slice = volumeData(:,:,idx);
            rowTiles = [rowTiles, slice]; %#ok<AGROW>
        end
        tileRows = [tileRows; rowTiles]; %#ok<AGROW>
    end

    % Display
    figure;
    imshow(tileRows, []);
    title(sprintf('Montage of %d slices (%d rows × %d cols)', numSlices, numRows, numCols));
end
