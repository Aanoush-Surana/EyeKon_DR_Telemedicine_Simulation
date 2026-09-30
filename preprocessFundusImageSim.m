function Y = preprocessFundusImageSim(u)
%#codegen

% Original image
I = u;

% 1. Crop to fundus FOV
gray = rgb2gray(I);
[r,c] = find(gray > 15);

if ~isempty(r)
    I = I(min(r):max(r), min(c):max(c), :);
end

% 2. RGB configuration
I_base = I;

% 3. CLAHE on L channel
I_lab = rgb2lab(I_base);

L = I_lab(:,:,1) / 100;

L = adapthisteq( ...
    L, ...
    'ClipLimit', 0.02, ...
    'NumTiles', [8 8]);

I_lab(:,:,1) = L * 100;

I_proc = lab2rgb(I_lab);

% 4. Clamp to [0,1]
I_proc = min(max(I_proc,0),1);

% 5. Resize
I_proc = imresize(I_proc,[224 224]);

Y = I_proc;

end