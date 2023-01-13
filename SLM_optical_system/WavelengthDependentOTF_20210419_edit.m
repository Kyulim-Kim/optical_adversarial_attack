clear all, close all, clc

%% Make input
padsize = 1;

m = 224; % Pixel mumber of SLMksd
factor = 2; % For Nyquist sampling
factor2 = 1; % 추가됨
M = m * factor * factor2; % Image size

inputIntensity = imread('syringe.png');
%niqe(inputIntensity)
inputIntensity = imresize(inputIntensity, [M M]);

inputIntensity_R = inputIntensity(:,:,1);
inputIntensity_G = inputIntensity(:,:,2);
inputIntensity_B = inputIntensity(:,:,3);


%% Set parameter for making CTF

f              = 100000;           % Focal length of relay lens in um 
lambda         = [0.61 0.53 0.47]; % Wavelength in um [Red Green Blue]. Note that center wavelegth is green color.
fov            = 290000;           % Field-of-view in um
eff_pixelsize  = fov/M;            % Effective pixel size
slm_pixelsize  = 30;               % Pixel size of SLM in um
slm_pixelnum   = m;                % 추가

% 변경 사항

PhySizeSLM = slm_pixelnum * slm_pixelsize;
MaxFreqSLM = PhySizeSLM ./ lambda / f / 2;
DelFreqSLM = slm_pixelsize / min(lambda) / f; % 기준은 가장 High frequency를 전달할 수 있는 Blue channel

u              = DelFreqSLM*[-M/2:M/2-1];
[uu, vv]       = meshgrid(u);

% CTF_R   = double( sqrt(uu.^2 + vv.^2) < MaxFreqSLM(1) );
% CTF_G   = double( sqrt(uu.^2 + vv.^2) < MaxFreqSLM(2) );
CTF_B   = double( sqrt(uu.^2 + vv.^2) < MaxFreqSLM(3) * factor2 ); % 바뀜

%% Set up coherent transfer function
% 전체적으로 변동이 많아서 다 바꾸는게 나을듯 싶습니다.

inputIntensityFT_R = fftshift(fft2(inputIntensity_R));
inputIntensityFT_G = fftshift(fft2(inputIntensity_G));
inputIntensityFT_B = fftshift(fft2(inputIntensity_B));


cent = M/2 +1;
slm = imresize(rand(m,m),factor2,'nearest'); % 바뀜
slm2 = 2 * rand(m, m) - 1;
figure, imshow(slm2);
colormap(viridis)
slm = slm.* CTF_B(cent-M/4:cent+M/4-1,cent-M/4:cent+M/4-1); % Physicially displayed SLM pattern % 바뀜


Ratio = MaxFreqSLM / MaxFreqSLM(3); % Radius ratio of each color channel

slm_R = Ratio(1) * imresize(slm,Ratio(1),'nearest'); % resize method는 뭐가 맞을지 모르겠음.. 일단 Interpolation 없는 것으로 하였음
slm_G = Ratio(2) * imresize(slm,Ratio(2),'nearest');
slm_B = slm;


slm_r = zeros(M);
slm_g = zeros(M);
slm_b = zeros(M);

% M x M matrix에 resized slm에 의한 color channel 별 phase delay를 센터에 맞춰 넣어주기
[x y]= size(slm_R);
slm_r(M/2+1 + floor(-y/2) +1:M/2+1 + floor(y/2),M/2+1 + floor(-x/2) +1:M/2+1 + floor(x/2)) = slm_R;
[x y]= size(slm_G);
slm_g(M/2+1 + floor(-y/2) +1:M/2+1 + floor(y/2),M/2+1 + floor(-x/2) +1:M/2+1 + floor(x/2)) = slm_G;
[x y]= size(slm_B);
slm_b(M/2+1 + floor(-y/2) +1:M/2+1 + floor(y/2),M/2+1 + floor(-x/2) +1:M/2+1 + floor(x/2)) = slm_B;

% Amplitude는 전부 1로 할 것이 때문에..
CTF_R = double(slm_r~=00);
CTF_G = double(slm_g~=00);
CTF_B = double(slm_b~=00);


atk_CTF_R = CTF_R.*exp(1j*slm_r);
atk_CTF_G = CTF_G.*exp(1j*slm_g);
atk_CTF_B = CTF_B.*exp(1j*slm_b);


%% Make MTF with and without ATTACK

CTF_R = (CTF_R);
CTF_G = (CTF_G);
CTF_B = (CTF_B);

atk_CTF_R = (atk_CTF_R);
atk_CTF_G = (atk_CTF_G);
atk_CTF_B = (atk_CTF_B);

ft_CTF_R = fft2(fftshift(CTF_R));
MTF_R = ifftshift(ifft2((ft_CTF_R.*conj(ft_CTF_R))));

ft_CTF_G = fft2(fftshift(CTF_G));
MTF_G = ifftshift(ifft2((ft_CTF_G.*conj(ft_CTF_G))));

ft_CTF_B = fft2(fftshift(CTF_B));
MTF_B = ifftshift(ifft2((ft_CTF_B.*conj(ft_CTF_B))));

MTF_R = MTF_R./max(max(abs(MTF_R)));
MTF_G = MTF_G./max(max(abs(MTF_G)));
MTF_B = MTF_B./max(max(abs(MTF_B)));

ft_atk_CTF_R = fft2(fftshift(atk_CTF_R));
atk_MTF_R = ifftshift(ifft2((ft_atk_CTF_R.*conj(ft_atk_CTF_R))));

ft_atk_CTF_G = fft2(fftshift(atk_CTF_G));
atk_MTF_G = ifftshift(ifft2((ft_atk_CTF_G.*conj(ft_atk_CTF_G))));

ft_atk_CTF_B = fft2(fftshift(atk_CTF_B));
atk_MTF_B = ifftshift(ifft2((ft_atk_CTF_B.*conj(ft_atk_CTF_B))));

atk_MTF_R = atk_MTF_R./max(max(abs(atk_MTF_R)));
atk_MTF_G = atk_MTF_G./max(max(abs(atk_MTF_G)));
atk_MTF_B = atk_MTF_B./max(max(abs(atk_MTF_B)));


%% Generate output intensity image with and without AATACK
% With ATTACK

inputIntensityFT_R = (inputIntensityFT_R);
inputIntensityFT_G = (inputIntensityFT_G);
inputIntensityFT_B = (inputIntensityFT_B);

atk_outputFT_R = atk_MTF_R.*inputIntensityFT_R;
atk_outputFT_G = atk_MTF_G.*inputIntensityFT_G;
atk_outputFT_B = atk_MTF_B.*inputIntensityFT_B;


atk_outputIntensity(:,:,1) = uint8(abs(ifft2(ifftshift(atk_outputFT_R))));
atk_outputIntensity(:,:,2) = uint8(abs(ifft2(ifftshift(atk_outputFT_G))));
atk_outputIntensity(:,:,3) = uint8(abs(ifft2(ifftshift(atk_outputFT_B))));


% Without ATTACK
outputFT_R = MTF_R.*inputIntensityFT_R;
outputFT_G = MTF_G.*inputIntensityFT_G;
outputFT_B = MTF_B.*inputIntensityFT_B;

outputIntensity(:,:,1) = uint8(abs(ifft2(ifftshift(outputFT_R))));
outputIntensity(:,:,2) = uint8(abs(ifft2(ifftshift(outputFT_G))));
outputIntensity(:,:,3) = uint8(abs(ifft2(ifftshift(outputFT_B))));

% 바꿈.. 정수배가 아니라서..
output = imresize(outputIntensity,[224 224],'box');
atk_output = imresize(atk_outputIntensity,[224 224],'box');


%figure,
%subplot(3,1,1), imagesc(atk_output)
%subplot(3,1,2), imagesc(output)
%subplot(3,1,3), imagesc(inputIntensity)
%truesize

