classdef GradCAMSystem < matlab.System
    % Automatic multiclass Grad-CAM for Simulink

    properties (Access = private)
        net
        targetLayer = 'x_conv5_Conv'
        calculated = false
        lastImage
    end

    methods (Access = protected)

        %% INITIALIZATION
        function setupImpl(obj,~,~)

            S = load("multiNet.mat","multiNet");

            obj.net = S.multiNet;

            obj.calculated = false;

            obj.lastImage = ...
                zeros(224,224,3,'single');

        end


        %% MAIN EXECUTION
        function gradcamImage = stepImpl(obj,X,runFlag)

            % Default output
            gradcamImage = obj.lastImage;

            % Calculate only when imageReady is true
            if runFlag && ~obj.calculated

                %% Convert Simulink input to CNN format

                % Simulink gives 224x224x3
                X = reshape(X,[224 224 3 1]);

                % Convert to dlarray
                Xdl = dlarray(X,'SSCB');


                %% Grad-CAM forward + gradients

                [featAct,gradAct,scores] = ...
                    dlfeval( ...
                    @gradcamForward, ...
                    obj.net, ...
                    Xdl, ...
                    obj.targetLayer);


                %% Get prediction

                scoresVec = extractdata(scores);

                scoresVec = scoresVec(:);

                [~,predClass] = max(scoresVec);


                %% Calculate confidence

                z = double(scoresVec);

                z = z - max(z);

                probs = exp(z)./sum(exp(z));

                confidence = probs(predClass);


                %% Extract activations and gradients

                featData = extractdata(featAct);

                gradData = extractdata(gradAct);


                %% Global average pooling of gradients

                weights = mean(mean(gradData,1),2);


                %% Weighted activation maps

                cam = sum( ...
                    featData .* weights, ...
                    3);


                %% ReLU

                cam = max(cam,0);


                %% Normalize CAM

                if max(cam(:)) > 0
                    cam = cam ./ max(cam(:));
                end


                %% Resize CAM

                cam = imresize( ...
                    gather(cam), ...
                    [224 224]);


                %% Undo ImageNet normalization

                visImg = extractdata(Xdl);

                meanVec = reshape( ...
                    single([0.485 0.456 0.406]), ...
                    1,1,3);

                stdVec = reshape( ...
                    single([0.229 0.224 0.225]), ...
                    1,1,3);

                visImg = ...
                    visImg .* stdVec + meanVec;

                visImg = ...
                    min(max(visImg,0),1);


                % Remove batch dimension
                visImg = visImg(:,:,:,1);


                %% Create heatmap

                heatmap = ind2rgb( ...
                    uint8(cam*255), ...
                    jet(256));

                heatmap = single(heatmap);


                %% Overlay

                alpha = 0.45;

                gradcamImage = ...
                    (1-alpha).*visImg + ...
                    alpha.*heatmap;


                gradcamImage = ...
                    min(max(gradcamImage,0),1);


                %% Store result

                obj.lastImage = gradcamImage;

                obj.calculated = true;


                %% Command Window information

                fprintf('\nGrad-CAM generated.\n');

                fprintf( ...
                    'Predicted Grade: %d\n', ...
                    predClass-1);

                fprintf( ...
                    'Confidence: %.2f%%\n', ...
                    confidence*100);

            end

        end


        %% RESET

        function resetImpl(obj)

            obj.calculated = false;

            obj.lastImage = ...
                zeros(224,224,3,'single');

        end


        %% OUTPUT SIZE

        function sz = getOutputSizeImpl(~)

            sz = [224 224 3];

        end


        %% OUTPUT DATA TYPE

        function dt = getOutputDataTypeImpl(~)

            dt = 'single';

        end


        %% OUTPUT COMPLEXITY

        function c = isOutputComplexImpl(~)

            c = false;

        end


        %% OUTPUT FIXED SIZE

        function f = isOutputFixedSizeImpl(~)

            f = true;

        end


        %% NUMBER OF INPUTS

        function n = getNumInputsImpl(~)

            n = 2;

        end

    end
end


%% =========================================================
% Grad-CAM forward pass
% =========================================================

function [featAct,gradAct,scores] = ...
    gradcamForward(net,Xdl,layerName)

    %% Forward pass

    [featAct,scores] = forward( ...
        net, ...
        Xdl, ...
        'Outputs',{ ...
            layerName, ...
            net.OutputNames{1} ...
        });


    %% Get predicted class

    scoresVec = extractdata(scores);

    scoresVec = scoresVec(:);

    [~,predIdx] = max(scoresVec);


    %% Score of predicted class

    targetScore = scores(predIdx);


    %% Gradient of class score
    % with respect to feature activations

    gradAct = dlgradient( ...
        targetScore, ...
        featAct);

end