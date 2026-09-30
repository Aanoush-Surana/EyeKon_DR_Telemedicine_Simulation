classdef PatientResultLogger < matlab.System

    properties
        OutputFolder = "SimulationResults"
    end

    properties (Access = private)
        previousCapture = false
        previousReady = false
    end

    methods (Access = protected)

        function setupImpl(obj,~,~,~,~,~,~,~,~,~)

            coder.extrinsic('mkdir');

            mkdir(obj.OutputFolder);

            obj.previousCapture = false;
            obj.previousReady = false;

        end

        function stepImpl(obj, imageReady, captureRequest, imageNumber, processedImage,gradcamImage,rawImage,...
                vesselMask,...
                binaryProbabilities,gradeProbabilities)

            coder.extrinsic('mkdir');
            coder.extrinsic('imwrite');
            coder.extrinsic('fprintf');
            coder.extrinsic('fopen');
            coder.extrinsic('fclose');

            newCapture = captureRequest && ~obj.previousCapture;
            newReady = imageReady && ~obj.previousReady;

            %% =========================================================
            % RAW IMAGE
            % ==========================================================

            if newCapture

                patientID = round(imageNumber);

                patientFolder = fullfile( ...
                    obj.OutputFolder, ...
                    sprintf("Patient_%.0f",patientID));

                mkdir(patientFolder);

                rawPath = fullfile( ...
                    patientFolder,"raw.png");

                imwrite(rawImage,rawPath);

                fprintf( ...
                    "Saved raw image: Patient_%.0f\n", ...
                    patientID);

            end


            %% =========================================================
            % FINAL PATIENT RESULTS
            % ==========================================================

            if newReady

                patientID = round(imageNumber);

                patientFolder = fullfile( ...
                    obj.OutputFolder, ...
                    sprintf("Patient_%.0f",patientID));

                mkdir(patientFolder);


                %% -----------------------------------------------------
                % PROCESSED IMAGE
                % ------------------------------------------------------

                processedToSave = prepareImage(processedImage);

                processedPath = fullfile( ...
                    patientFolder,"processed.png");

                imwrite(processedToSave,processedPath);


                %% -----------------------------------------------------
                % GRAD-CAM
                % ------------------------------------------------------

                gradcamToSave = prepareImage(gradcamImage);

                gradcamPath = fullfile( ...
                    patientFolder,"gradcam.png");

                imwrite(gradcamToSave,gradcamPath);


                %% -----------------------------------------------------
                % VESSEL SEGMENTATION
                % ------------------------------------------------------

                vesselToSave = prepareImage(vesselMask);

                vesselPath = fullfile( ...
                    patientFolder,"vessel.png");

                imwrite(vesselToSave,vesselPath);


                %% =====================================================
                % DETERMINE BINARY PREDICTION
                % ======================================================

                binaryProbabilities = gather(binaryProbabilities);
                binaryProbabilities = double(binaryProbabilities(:));

                [binaryConfidence,binaryIndex] = ...
                    max(binaryProbabilities);

                if binaryIndex == 1

                    drStatus = "NonReferable";
                    doctorReview = "NO";

                else

                    drStatus = "Referable";
                    doctorReview = "YES";

                end


                %% =====================================================
                % DETERMINE DR GRADE
                % ======================================================

                gradeProbabilities = gather(gradeProbabilities);
                gradeProbabilities = double(gradeProbabilities(:));

                [gradeConfidence,gradeIndex] = ...
                    max(gradeProbabilities);

                gradeNumber = gradeIndex - 1;

                gradeText = sprintf( ...
                    "Grade %.0f",gradeNumber);


                %% =====================================================
                % CREATE PATIENT REPORT
                % ======================================================

                reportPath = fullfile( ...
                    patientFolder,"report.txt");

                fid = fopen(reportPath,"w");

                fprintf(fid,"========================================\n");
                fprintf(fid,"          DIABETIC RETINOPATHY REPORT\n");
                fprintf(fid,"========================================\n\n");

                fprintf(fid,"Patient ID       : %.0f\n",patientID);

                fprintf(fid,"DR Status        : %s\n",drStatus);

                fprintf(fid,"DR Grade         : %s\n",gradeText);

                fprintf(fid,"Binary Confidence: %.2f%%\n", ...
                    binaryConfidence*100);

                fprintf(fid,"Grade Confidence : %.2f%%\n", ...
                    gradeConfidence*100);

                fprintf(fid,"Doctor Review    : %s\n", ...
                    doctorReview);

                fprintf(fid,"\n----------------------------------------\n");

                fprintf(fid,"Binary Probabilities\n");
                fprintf(fid,"  NonReferable : %.6f\n", ...
                    binaryProbabilities(1));

                fprintf(fid,"  Referable    : %.6f\n", ...
                    binaryProbabilities(2));

                fprintf(fid,"\nMulti-class Probabilities\n");

                fprintf(fid,"  Grade 0 : %.6f\n", ...
                    gradeProbabilities(1));

                fprintf(fid,"  Grade 1 : %.6f\n", ...
                    gradeProbabilities(2));

                fprintf(fid,"  Grade 2 : %.6f\n", ...
                    gradeProbabilities(3));

                fprintf(fid,"  Grade 3 : %.6f\n", ...
                    gradeProbabilities(4));

                fprintf(fid,"  Grade 4 : %.6f\n", ...
                    gradeProbabilities(5));

                fprintf(fid,"========================================\n");

                fclose(fid);


                %% Console message

                fprintf( ...
                    "Saved complete patient report: Patient_%.0f | %s | %s | Doctor Review: %s\n", ...
                    patientID, ...
                    drStatus, ...
                    gradeText, ...
                    doctorReview);

            end


            %% Update previous signals

            obj.previousCapture = captureRequest;
            obj.previousReady = imageReady;

        end


        function resetImpl(obj)

            obj.previousCapture = false;
            obj.previousReady = false;

        end


        function n = getNumInputsImpl(~)

            n = 9;

        end


        function n = getNumOutputsImpl(~)

            n = 0;

        end

    end
end


%% =========================================================
% IMAGE PREPARATION
% ==========================================================

function outputImage = prepareImage(inputImage)

    inputImage = gather(inputImage);

    if isa(inputImage,'uint8')

        outputImage = inputImage;

        return;

    end

    inputImage = single(inputImage);

    inputImage = min(max(inputImage,0),1);

    outputImage = im2uint8(inputImage);

end