classdef ActualFundusImageSource < matlab.System
    % ActualFundusImageSource
    %
    % Supplies actual fundus PNG images from SIH_data to Simulink.
    %
    % Input:
    %   captureRequest - boolean pulse from QueueEngine
    %
    % Outputs:
    %   rawImage       - fixed 1050x1050x3 uint8 fundus image
    %   imageNumber    - sequential image/patient number

    properties
        DatasetRoot = "SIH_TEST"
    end

    properties (Access = private)
        fileList
        currentIndex = 0
        previousRequest = false
        currentImage
    end

    methods (Access = protected)

        %% =========================================================
        % OUTPUT SIZE
        % =========================================================

        function [sz1,sz2] = getOutputSizeImpl(~)

            sz1 = [1050 1050 3];
            sz2 = [1 1];

        end

        %% =========================================================
        % OUTPUT DATA TYPE
        % =========================================================

        function [dt1,dt2] = getOutputDataTypeImpl(~)

            dt1 = 'uint8';
            dt2 = 'double';

        end

        %% =========================================================
        % OUTPUT COMPLEXITY
        % =========================================================

        function [cp1,cp2] = isOutputComplexImpl(~)

            cp1 = false;
            cp2 = false;

        end

        %% =========================================================
        % OUTPUT FIXED SIZE
        % =========================================================

        function [fs1,fs2] = isOutputFixedSizeImpl(~)

            fs1 = true;
            fs2 = true;

        end

        %% =========================================================
        % INITIALIZATION
        % =========================================================

        function setupImpl(obj,~)

            % -----------------------------------------------------
            % Check dataset folder
            % -----------------------------------------------------

            if ~isfolder(obj.DatasetRoot)

                error( ...
                    'ActualFundusImageSource:DatasetNotFound', ...
                    ['SIH_data folder not found. ' ...
                     'Set DatasetRoot to the full path of your SIH_data folder.']);

            end

            % -----------------------------------------------------
            % Start with empty file list
            % -----------------------------------------------------

            obj.fileList = {};

            % -----------------------------------------------------
            % Collect PNG images from Grade 0,1,2,3,4 folders
            % -----------------------------------------------------

            for grade = 0:4

                gradeFolder = ...
                    fullfile(obj.DatasetRoot,string(grade));

                if isfolder(gradeFolder)

                    files = dir( ...
                        fullfile(gradeFolder,"*.png"));

                    for k = 1:numel(files)

                        obj.fileList{end+1,1} = ...
                            string(fullfile( ...
                            files(k).folder, ...
                            files(k).name));

                    end
                end
            end

            % -----------------------------------------------------
            % Check that images were found
            % -----------------------------------------------------

            if isempty(obj.fileList)

                error( ...
                    'ActualFundusImageSource:NoImages', ...
                    'No PNG fundus images were found in SIH_data/0...4.');

            end

            % -----------------------------------------------------
            % Start before first image
            % -----------------------------------------------------

            obj.currentIndex = 0;

            obj.currentImage = ...
                zeros(1050,1050,3,'uint8');

            obj.previousRequest = false;

        end

        %% =========================================================
        % MAIN EXECUTION
        % =========================================================

        function [rawImage,imageNumber] = ...
                stepImpl(obj,captureRequest)

            % -----------------------------------------------------
            % Detect rising edge of capture request
            % -----------------------------------------------------

            newCapture = ...
                captureRequest && ~obj.previousRequest;

            % -----------------------------------------------------
            % New patient / new camera capture
            % -----------------------------------------------------

            if newCapture

                % Move to next image
                obj.currentIndex = ...
                    obj.currentIndex + 1;

                % Loop back when dataset is exhausted
                if obj.currentIndex > numel(obj.fileList)

                    obj.currentIndex = 1;

                end

                % -------------------------------------------------
                % Load actual image
                % -------------------------------------------------

                img = imread( ...
                    obj.fileList{obj.currentIndex});

                % -------------------------------------------------
                % Make grayscale images RGB
                % -------------------------------------------------

                if ndims(img) == 2

                    img = cat(3,img,img,img);

                end

                % -------------------------------------------------
                % Remove alpha channel if present
                % -------------------------------------------------

                if size(img,3) > 3

                    img = img(:,:,1:3);

                end

                % -------------------------------------------------
                % Force every image to 1050x1050
                % -------------------------------------------------

                img = imresize(img,[1050 1050]);

                % -------------------------------------------------
                % Make sure output is uint8
                % -------------------------------------------------

                if ~isa(img,'uint8')

                    img = im2uint8(img);

                end

                % -------------------------------------------------
                % Store current image
                % -------------------------------------------------

                obj.currentImage = img;

            end

            % -----------------------------------------------------
            % Remember current request state
            % -----------------------------------------------------

            obj.previousRequest = captureRequest;

            % -----------------------------------------------------
            % Outputs
            % -----------------------------------------------------

            rawImage = obj.currentImage;

            imageNumber = obj.currentIndex;

        end

        %% =========================================================
        % RESET
        % =========================================================

        function resetImpl(obj)

            obj.currentIndex = 0;

            obj.previousRequest = false;

            obj.currentImage = ...
                zeros(1050,1050,3,'uint8');

        end

        %% =========================================================
        % NUMBER OF INPUTS
        % =========================================================

        function n = getNumInputsImpl(~)

            n = 1;

        end

        %% =========================================================
        % NUMBER OF OUTPUTS
        % =========================================================

        function n = getNumOutputsImpl(~)

            n = 2;

        end

    end
end