classdef VesselSegmentationSystem < matlab.System

    properties (Access = private)
        net
        lastMask
    end

    methods (Access = protected)

        function setupImpl(obj,~)

            S = load("vesselNet.mat","vesselNet");
            obj.net = S.vesselNet;

            obj.lastMask = zeros(512,512,3,'uint8');

        end

        function vesselMask = stepImpl(obj,rawImage)

            %% Resize
            img = imresize(rawImage,[512 512]);

            %% Green channel
            G = img(:,:,2);

            %% CLAHE
            Gc = adapthisteq(G, ...
                'ClipLimit',0.02, ...
                'NumTiles',[8 8]);

            %% Black Top-Hat
            T = imbothat(Gc,strel('disk',7));

            %% =====================================================
            % FRANGI VESSELNESS
            % ======================================================

            Gf = single(Gc);
            Gf = Gf ./ max(Gf(:));

            sigmas = [1 2 3 4 5];
            beta = 0.5;
            gamma = 15;

            F = zeros(512,512,'single');

            for s = sigmas

                sigma = double(s);

                radius = ceil(4*sigma);
                x = (-radius:radius)';

                g = exp(-(x.^2)/(2*sigma^2));
                g = g/sum(g);

                g1 = -(x/(sigma^2)).*g;
                g2 = ((x.^2-sigma^2)/(sigma^4)).*g;

                Dxx = imfilter( ...
                    imfilter(Gf,g,'symmetric','conv'), ...
                    g2','symmetric','conv');

                Dyy = imfilter( ...
                    imfilter(Gf,g2,'symmetric','conv'), ...
                    g','symmetric','conv');

                Dxy = imfilter( ...
                    imfilter(Gf,g1,'symmetric','conv'), ...
                    g1','symmetric','conv');

                traceH = Dxx + Dyy;

                delta = sqrt( ...
                    ((Dxx-Dyy)/2).^2 + Dxy.^2);

                lambda1 = traceH/2-delta;
                lambda2 = traceH/2+delta;

                swap = abs(lambda1)>abs(lambda2);

                temp = lambda1(swap);
                lambda1(swap) = lambda2(swap);
                lambda2(swap) = temp;

                lambda2Safe = max(lambda2,1e-10);

                Rb = abs(lambda1)./lambda2Safe;

                S = sqrt(lambda1.^2+lambda2.^2);

                V = exp(-(Rb.^2)/(2*beta^2)).* ...
                    (1-exp(-(S.^2)/(2*gamma^2)));

                V(lambda2<=0) = 0;

                F = max(F,V);

            end

            %% Normalize Frangi
            if max(F(:))>0
                F = F./max(F(:));
            end

            %% =====================================================
            % NORMALIZED GREEN CHANNEL
            % ======================================================

            Gn = (double(Gc)-mean(Gc(:))) ./ ...
                 (std(double(Gc(:)))+eps);

            Gn = mat2gray(Gn);

            %% =====================================================
            % MODEL INPUT
            % ======================================================

            X = cat(3, ...
                single(Gn), ...
                single(F), ...
                single(double(T)/255));

            X = reshape(X,[512 512 3 1]);

            Xdl = dlarray(X,'SSCB');

            %% =====================================================
            % VESSEL NETWORK
            % ======================================================

            logits = predict(obj.net,Xdl);

            %% Sigmoid
            prob = 1./(1+exp(-extractdata(logits)));

            prob = squeeze(prob);

            %% Threshold
            mask = prob>=0.7;

            %% Remove small objects
            mask = bwareaopen(mask,50);

            %% RGB white-vessel mask
            mask8 = uint8(mask)*255;

            vesselMask = cat(3,mask8,mask8,mask8);

            obj.lastMask = vesselMask;

        end

        function resetImpl(obj)

            obj.lastMask = zeros(512,512,3,'uint8');

        end

        function sz = getOutputSizeImpl(~)
            sz = [512 512 3];
        end

        function dt = getOutputDataTypeImpl(~)
            dt = 'uint8';
        end

        function c = isOutputComplexImpl(~)
            c = false;
        end

        function f = isOutputFixedSizeImpl(~)
            f = true;
        end

        function n = getNumInputsImpl(~)
            n = 1;
        end

        function n = getNumOutputsImpl(~)
            n = 1;
        end

    end
end