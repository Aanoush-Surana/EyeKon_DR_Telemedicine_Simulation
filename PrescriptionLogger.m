classdef PrescriptionLogger < matlab.System

    properties
        OutputFolder = "SimulationResults"
    end

    methods (Access = protected)

        function setupImpl(obj,~,~,~,~)

            coder.extrinsic('mkdir');

            mkdir(obj.OutputFolder);

        end

        function stepImpl(obj,patientID,referable,...
                doctorDone,prescription)

            coder.extrinsic('mkdir');
            coder.extrinsic('fopen');
            coder.extrinsic('fprintf');
            coder.extrinsic('fclose');

            %% Only create prescription for referable patients
            if referable && doctorDone

                id = round(patientID);

                %% Existing patient folder
                patientFolder = fullfile( ...
                    obj.OutputFolder, ...
                    sprintf("Patient_%.0f",id));

                mkdir(patientFolder);

                %% Prescription file
                prescriptionPath = fullfile( ...
                    patientFolder, ...
                    "prescription.txt");

                fid = fopen(prescriptionPath,"w");

                fprintf(fid,"========================================\n");
                fprintf(fid,"       TELEMEDICINE PRESCRIPTION\n");
                fprintf(fid,"========================================\n\n");

                fprintf(fid,"Patient ID        : %.0f\n",id);

                fprintf(fid,"Doctor Review     : COMPLETED\n");

                fprintf(fid,"Prescription      : %s\n", ...
                    prescription);

                fprintf(fid,"\n========================================\n");

                fclose(fid);

                fprintf( ...
                    "Prescription saved for Patient_%.0f\n",id);

            end

        end

        function n = getNumInputsImpl(~)

            n = 4;

        end

        function n = getNumOutputsImpl(~)

            n = 0;

        end

    end
end