clc();
addpath('../'); % adding path for file

%get the video in the same folder
video = 'car.avi';

%oreading vieo and setting values
frames_number = 100; % setting the number of frames
frames_number
tempvideo = VideoReader(video); %reading the video
res_height = tempvideo.Height;      %extracting height and width for resolution
res_height
res_width = tempvideo.Width;
res_width
frame_rate = tempvideo.FrameRate;    %extracting frame rate
frame_rate 

%stack frames to columns of matrix M
M = zeros(frames_number, res_height*res_width);
for i = (1:frames_number)
    frame = read(tempvideo, i);
    frame = rgb2gray(frame);    %converting frames to grayscale
    M(i,:) = reshape(frame,[],1);
end

%calling robust PCA funtion
size(M)
lambda = 1/sqrt(max(size(M)));
lambda
tic
[L,S] = RobustPCA(M, lambda/3, 10*lambda/3, 1e-5);
toc

%defining the output file object
out_obj = VideoWriter('orig_out.mp4');
out_obj.FrameRate = frame_rate;
open(out_obj);
range = 255; %for rgb
map = repmat((0:range)'./range, 1, 3);
%cmap(:, :, 3) = repmat(255:-1:0, 256, 1);
S = medfilt2(S, [5,1]); % median filter in time
for i = (1:size(M, 1))
    frame1 = reshape(M(i,:),res_height,[]);
    frame2 = reshape(L(i,:),res_height,[]);
    frame3 = reshape(abs(S(i,:)),res_height,[]);
    %  threshold
    frame3 = (medfilt2(abs(frame3), [5,5]) > 5).*frame1;
    % stack M, L and S together
    frame = mat2gray(frame3);
    frame = gray2ind(frame,range);
    frame = ind2rgb(frame,map);
    writeVideo(out_obj,frame);
end
close(out_obj);
