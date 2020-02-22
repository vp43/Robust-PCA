%% inpainting RobustPCA example: moon picture corrupted with some text
addpath('../');

% read image and add the mask
img = double(imread('marie.jpg'))/255;
size(img)
img = img(141:140+676, 51:50+676);

msk = zeros(size(img));

im2 = double(imread('ii4.png'))/255;
%im21 = im2bw(im21,1);
im21= rgb2gray(im2);
msk(150:405,500:755) = imresize(im21, 1);
size(im21)
img_corrupted = img;
img_corrupted(msk > 0) = nan;



fprintf(1, '%d corrupted entries\n', nnz(isnan(img_corrupted)));

% create a matrix X from overlapping patches
ws = 26; % window size
no_patches = size(img, 1) / ws;
X = zeros(size(img));
k = 1;
for i = (1:no_patches*2-1)
    for j = (1:no_patches*2-1)
        r1 = 1+(i-1)*ws/2:(i+1)*ws/2;
        r2 = 1+(j-1)*ws/2:(j+1)*ws/2;
        patch = img_corrupted(r1, r2);
        X(k,:) = patch(:);
        k = k + 1;
    end
end

% apply Robust PCA
lambda = 0.02; % close to the default one, but works better
tic
[L, S] = RobustPCA(X, lambda, 1.0, 1e-5);
toc

imshow(L)

% reconstruct the image from the overlapping patches in matrix L
img_reconstructed = zeros(size(img));
img_noise = zeros(size(img));
k = 1;
for i = (1:no_patches*2-1)
    for j = (1:no_patches*2-1)
        % average patches to get the image back from L and S
        % todo: in the borders less than 4 patches are averaged
        patch = reshape(L(k,:), ws, ws);
        r1 = 1+(i-1)*ws/2:(i+1)*ws/2;
        r2 = 1+(j-1)*ws/2:(j+1)*ws/2;
        img_reconstructed(r1, r2) = img_reconstructed(r1, r2) + 0.25*patch;
        patch = reshape(S(k,:), ws, ws);
        img_noise(r1, r2) = img_noise(r1, r2) + 0.25*patch;
        k = k + 1;
    end
end
img_final = img_reconstructed;
%imshow(img_final)
img_final(~isnan(img_corrupted)) = img_corrupted(~isnan(img_corrupted));


% show the results
figure;
subplot(2,2,1), imshow(img_corrupted), title('Corrupted image')
subplot(2,2,2), imshow(img_final), title('Recovered image')
subplot(2,2,3), imshow(img_reconstructed), title('Recovered low-rank')
subplot(2,2,4), imshow(img_noise), title('Recovered sparse')

fprintf(1, 'ws=%d\tlambda=%f\trank(L)=%d\tcard(S)=%d\terr=%f\n', ...
       ws, lambda, rank(L), nnz(S), norm(img - img_final, 'fro'));