function replace_dcm_imgs(matDir, dicomDir, outputDir)
% Replaces the pixel data in DICOM files with offline-reconstructed images
% storede in .mat files.
% 
% Parameters:
%   - matDir   : directory containing .mat files with offline reconstructed
%                images
%   - dicomDir : directory containing DICOM files exported from the scanner
%   - outputDir: directory where the new dicom files with updated pixel
%                will be saved.
%
% Folder structure requirements:
%   - Each folder inside dicomDir and outputDir must have the same name as
%     the corresponding .mat filename (without the extension). For example:
%
%     matDir: XX/XX/XX/
%        |____ sp2fisp_2C.mat
%        |____ sp2fisp_3C.mat
%        |____ ...
%
%     dicomDir: XX/XX/XX/
%        |____ sp2fisp_2C/
%        |        |____ xxxx.dcm 
%        |        |____ xxxx.dcm % Additinal file if number of frames > 100
%        |____ sp2fisp_3C/
%        |        |____ xxxx.dcm
%        |        |____ xxxx.dcm
%        |____ ...
%
%     outputDir: should follow the same folder structure as dicomDir.
%
% (c) 2025, Kang Yan, University of Virginia.
%
    files = dir(fullfile(matDir, '*.mat'));
    for nf = 1:length(files)
        matFile = fullfile(matDir, files(nf).name);
        dicomFolder  = fullfile(dicomDir , files(nf).name(1:end-4), '\');
        outputFolder = fullfile(outputDir, files(nf).name(1:end-4), '\'); 
        
        data     = load(matFile);
        imgData  = data.recon;
        
        % double to uint16
        for i = 1:size(imgData, 3)
            imgData(:,:,i) = abs(imgData(:,:,i));
            imgData(:,:,i) = imgData(:,:,i) / max(imgData(:) + eps);
        end
        imgData = uint16(imgData * 65535);

        [rows, cols, totalFrames] = size(imgData);
        
        dicomFiles = dir(fullfile(dicomFolder, '*.dcm'));
        dicomFiles = sort({dicomFiles.name}); % natural order sorting
        
        frameStart = 1;
        
        for i = 1:length(dicomFiles)
            dicomPath = fullfile(dicomFolder, dicomFiles{i});
            info = dicominfo(dicomPath);
            
            % Read current DICOM image stack (original frames)
            original = dicomread(info);
            
            % Determine how many frames are in this file
            if ndims(original) == 3
                numFrames = size(original, 3);
            elseif isfield(info, 'NumberOfFrames')
                numFrames = info.NumberOfFrames;
            else
                numFrames = 1; % fallback
            end
            
            % Extract corresponding frames from imgData
            frameEnd   = min(frameStart + numFrames - 1, totalFrames);
            newFrames  = imgData(:, :, frameStart:frameEnd);
            frameCount = frameEnd - frameStart + 1;
        
            if frameCount ~= numFrames
                fprintf('Frame mismatch: DICOM expects %d, MAT provides %d\n', numFrames, framCount);
            end
        
            % Reshape to 3D or 4D depending on frame count
            if frameCount == 1
                pixelData = uint16(newFrames);
            else
                pixelData = reshape(uint16(newFrames), rows, cols, 1, frameCount);
            end
            
            % Write new DICOM with original metadata
            outPath = fullfile(outputFolder, dicomFiles{i});
            dicomwrite(pixelData, outPath, info, ...
                'CreateMode', 'Copy', ...
                'MultiFrameSingleFile', true);
            
            fprintf('* Replaced %3d frames in %s\n', numFrames, dicomFiles{i});
            
            frameStart = frameEnd + 1;
        end
    end
    

