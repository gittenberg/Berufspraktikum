%-------------------------------------
%   Count cells dapi/fitc
%
%   Compare cytosol/nucleus
%
%   Christian Ebbesen, 29.07.2011
%-------------------------------------

% Good sites:
% http://blogs.mathworks.com/steve/2006/06/02/cell-segmentation/
% http://www.mathworks.com/products/demos/image/watershed/ipexwatershed.html
% 
% 
% 

clear all;
close all;


%
% First, a loop to open all the files.
%

folder = 'wt_20h';

list=dir(folder);

% for ii=3:length(list)

    ii = 3;
    
navn = list(ii).name;


fname = [folder '/' navn];

% % 
% % list = 
% % 
% % 13x1 struct array with fields:
% %     name
% %     date
% %     bytes
% %     isdir
% %     datenum

%-----------------------------------
% Now, count the cells in the dapi image
%-----------------------------------

I_pre = imread(fname, 1);
I = imclearborder(I_pre);
    
figure(1);

subplot(3, 3, 1);
imshow(I_pre,[])
title('Orig. image')

subplot(3, 3, 2); 
I_eq = adapthisteq(I); % contrast-limited adaptive histogram equalization. CLAHE. 
imshow(I_eq,[])
title('Image w. clearborder und CLAHE')
% % Histogram for billedet.
% [pixelCount grayLevels] = imhist(img1);
% subplot(3, 3, 2); 
% bar(pixelCount); title('Histogram af grey og invert');
% %xlim([0 20]) 
% xlim([0 grayLevels(end)]); % Scale x axis manually.


%Calc stuff

%bw2 = imfill(bw,4,'holes'); % 4 or 8 connected unn�tig

SE = strel('disk',2);
clearim = imopen(I_eq, SE);%remove noise with radius smaller than 5

subplot (3, 3, 3);
imshow(clearim,[])
title('Image filtered w. disks w. R=2 px')
% Clear mursten paa randen
clearim1 = imclearborder(clearim);


% Fjern smaa objekter, 8conn 40 px
clearim2 = bwareaopen(clearim1, 200);
clearim2_perim = bwperim(clearim2);
%overlay1 = imoverlay(I_eq, bw5_perim, [.3 1 .3]); tool nicht vorhanden...
% 
% subplot(3, 3, r); 
% imshow(clearim2_perim)
% title('Cell perimiters')

subplot(3, 3, 4); 
bw_pre_clear_b = im2bw(clearim2, graythresh(I_eq)); % chooses the threshold to minimize the intraclass variance of the black and white pixels.
bw = imclearborder(bw_pre_clear_b);
% SE1 = strel('disk',5);
% bw = imopen(bw,SE1)
bw = imfill(bw,'holes');
imshow(bw)
title('Binary image')

% SE1 = strel ('disk', 1);
% erodedBW = imerode (bw, SE1);% not a useful method
%subplot(3, 3, 9); 
%imshow(erodedBW)

%im_er = imerode(bw5_perim, SE);
labeledImage = bwlabel(bw); %, 8); Hvorfor 8?     % Label each blob so we can make measurements of it
coloredLabels = label2rgb(labeledImage); % igen, hvad er det her: , 'hsv', 'k', 'shuffle'); % pseudo random color labels


subplot(3, 3, 5); 
imagesc(coloredLabels);


% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
blobMeasurements = regionprops(bw, I, 'all');   
numberOfBlobs = size(blobMeasurements, 1);

fontSize = 14;	% Used to control size of "blob number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the coins.
blobECD = zeros(1, numberOfBlobs);
% Print header line in the command window.
fprintf(1,'Blob #      Mean Intensity  Area   Perimeter    Centroid       Diameter\n');
% Loop over all blobs printing their measurements to the command window.
for k = 1 : numberOfBlobs           % Loop through all blobs.
	% Find the mean of each blob.  (R2008a has a better way where you can pass the original image
	% directly into regionprops.  The way below works for all versions including earlier versions.)
    thisBlobsPixels = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
    meanGL = mean(I(thisBlobsPixels)); % Find mean intensity (in original image!)
	meanGL2008a = blobMeasurements(k).MeanIntensity; % Mean again, but only for version >= R2008a
	
	blobArea = blobMeasurements(k).Area;		% Get area.
	blobPerimeter = blobMeasurements(k).Perimeter;		% Get perimeter.
	blobCentroid = blobMeasurements(k).Centroid;		% Get centroid.
	blobECD(k) = sqrt(4 * blobArea / pi);					% Compute ECD - Equivalent Circular Diameter.
    fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f\n', k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k));
	% Put the "blob number" labels on the "boundaries" grayscale image.
	text(blobCentroid(1) + labelShiftX, blobCentroid(2), num2str(k), 'FontSize', fontSize, 'FontWeight', 'Bold');
end


noCells = num2str(numberOfBlobs);
title(['Labeled regions. No. of cells is ' noCells])


%     Compute the distance transform of the complement of the binary image.

    D = bwdist(~bw,'quasi-euclidean');
    figure, imshow(D,[],'InitialMagnification','fit')
    title('Distance transform of ~bw')
    figure, imshow(~bw,[])
%     Complement the distance transform, and force pixels that don't belong to the objects to be at -Inf.

    D = -D;
    D(~bw) = -Inf;

%     Compute the watershed transform and display the resulting label matrix as an RGB images.

    L = watershed(D);
    rgb = label2rgb(L,'jet',[.5 .5 .5]);
    figure, imshow(rgb,'InitialMagnification','fit')
    title('Watershed transform of D')











%erode image to seperate cells.

SE1 = strel ('disk', 3);
bw_er=bw;
for k=1:4
bw_er = imerode (bw_er, SE1);% not a useful method
end

SE2 = strel ('disk', 2);
bw_er = imdilate(bw_er, SE2);
% COmplement image to make valleys out of the peaks

er_in = imcomplement(bw_er);

subplot(3, 3, 6); 
imshow(bw_er)
title('4x eroded, 2x dilated, inverted')


bw_half=0.5*bw;

I_mod = imimposemin(bw_half,bw_er);


L = watershed(I_mod);

subplot(3,3,7)
imshow(label2rgb(L))
title('Watershed of original image using markers')

% multiply to get only the nucleus:

nuc = L.*bw;

subplot(3,3,8)
imshow(nuc)

title('Final image w. separated cells')


labeledImage = bwlabel(nuc); %, 8); Hvorfor 8?     % Label each blob so we can make measurements of it
coloredLabels = label2rgb(labeledImage); % igen, hvad er det her: , 'hsv', 'k', 'shuffle'); % pseudo random color labels


subplot(3, 3, 9); 
imagesc(coloredLabels);


% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
blobMeasurements = regionprops(bw, I, 'all');   
numberOfBlobs = size(blobMeasurements, 1);

fontSize = 14;	% Used to control size of "blob number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the coins.
blobECD = zeros(1, numberOfBlobs);
% Print header line in the command window.
fprintf(1,'Blob #      Mean Intensity  Area   Perimeter    Centroid       Diameter\n');
% Loop over all blobs printing their measurements to the command window.
for k = 1 : numberOfBlobs           % Loop through all blobs.
	% Find the mean of each blob.  (R2008a has a better way where you can pass the original image
	% directly into regionprops.  The way below works for all versions including earlier versions.)
    thisBlobsPixels = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
    meanGL = mean(I(thisBlobsPixels)); % Find mean intensity (in original image!)
	meanGL2008a = blobMeasurements(k).MeanIntensity; % Mean again, but only for version >= R2008a
	
	blobArea = blobMeasurements(k).Area;		% Get area.
	blobPerimeter = blobMeasurements(k).Perimeter;		% Get perimeter.
	blobCentroid = blobMeasurements(k).Centroid;		% Get centroid.
	blobECD(k) = sqrt(4 * blobArea / pi);					% Compute ECD - Equivalent Circular Diameter.
    fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f\n', k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k));
	% Put the "blob number" labels on the "boundaries" grayscale image.
	text(blobCentroid(1) + labelShiftX, blobCentroid(2), num2str(k), 'FontSize', fontSize, 'FontWeight', 'Bold');
end


nDAPI = num2str(numberOfBlobs);
title(['Labeled regions. No. of cells is ' noCells])





%-----------------------------------
% Now, count the cells in the fitc image
%-----------------------------------

I_pre = imread(fname, 2);
I = imclearborder(I_pre);
    
figure(2);

subplot(3, 3, 1);
imshow(I_pre,[])
title('Orig. image')

subplot(3, 3, 2); 
I_eq = adapthisteq(I); % contrast-limited adaptive histogram equalization. CLAHE. 
imshow(I_eq,[])
title('Image w. clearborder und CLAHE')
% % Histogram for billedet.
% [pixelCount grayLevels] = imhist(img1);
% subplot(3, 3, 2); 
% bar(pixelCount); title('Histogram af grey og invert');
% %xlim([0 20]) 
% xlim([0 grayLevels(end)]); % Scale x axis manually.


%Calc stuff

%bw2 = imfill(bw,4,'holes'); % 4 or 8 connected unn�tig

SE = strel('disk',2);
clearim = imopen(I_eq, SE);%remove noise with radius smaller than 5

subplot (3, 3, 3);
imshow(clearim,[])
title('Image filtered w. disks w. R=2 px')
% Clear mursten paa randen
clearim1 = imclearborder(clearim);


% Fjern smaa objekter, 8conn 40 px
clearim2 = bwareaopen(clearim1, 200);
clearim2_perim = bwperim(clearim2);
%overlay1 = imoverlay(I_eq, bw5_perim, [.3 1 .3]); tool nicht vorhanden...
% 
% subplot(3, 3, r); 
% imshow(clearim2_perim)
% title('Cell perimiters')

subplot(3, 3, 4); 
bw_pre_clear_b = im2bw(clearim2, 0.4*graythresh(I_eq)); % chooses the threshold to minimize the intraclass variance of the black and white pixels.
bw = imclearborder(bw_pre_clear_b);
imshow(0.5*bw)
title('Binary image')

% SE1 = strel ('disk', 1);
% erodedBW = imerode (bw, SE1);% not a useful method
%subplot(3, 3, 9); 
%imshow(erodedBW)

%im_er = imerode(bw5_perim, SE);
labeledImage = bwlabel(bw); %, 8); Hvorfor 8?     % Label each blob so we can make measurements of it
coloredLabels = label2rgb(labeledImage); % igen, hvad er det her: , 'hsv', 'k', 'shuffle'); % pseudo random color labels


subplot(3, 3, 5); 
imagesc(coloredLabels);


% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
blobMeasurements = regionprops(bw, I, 'all');   
numberOfBlobs = size(blobMeasurements, 1);

fontSize = 14;	% Used to control size of "blob number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the coins.
blobECD = zeros(1, numberOfBlobs);
% Print header line in the command window.
fprintf(1,'Blob #      Mean Intensity  Area   Perimeter    Centroid       Diameter\n');
% Loop over all blobs printing their measurements to the command window.
for k = 1 : numberOfBlobs           % Loop through all blobs.
	% Find the mean of each blob.  (R2008a has a better way where you can pass the original image
	% directly into regionprops.  The way below works for all versions including earlier versions.)
    thisBlobsPixels = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
    meanGL = mean(I(thisBlobsPixels)); % Find mean intensity (in original image!)
	meanGL2008a = blobMeasurements(k).MeanIntensity; % Mean again, but only for version >= R2008a
	
	blobArea = blobMeasurements(k).Area;		% Get area.
	blobPerimeter = blobMeasurements(k).Perimeter;		% Get perimeter.
	blobCentroid = blobMeasurements(k).Centroid;		% Get centroid.
	blobECD(k) = sqrt(4 * blobArea / pi);					% Compute ECD - Equivalent Circular Diameter.
    fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f\n', k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k));
	% Put the "blob number" labels on the "boundaries" grayscale image.
	text(blobCentroid(1) + labelShiftX, blobCentroid(2), num2str(k), 'FontSize', fontSize, 'FontWeight', 'Bold');
end


noCells = num2str(numberOfBlobs);
title(['Labeled regions. No. of cells is ' noCells])


%erode image to seperate cells.

SE1 = strel ('disk', 3);
bw_er=bw;
for k=1:4
bw_er = imerode (bw_er, SE1);% not a useful method
end

SE2 = strel ('disk', 2);
bw_er = imdilate(bw_er, SE2);
% COmplement image to make valleys out of the peaks

er_in = imcomplement(bw_er);

subplot(3, 3, 6); 
imshow(bw_er)
title('4x eroded, 2x dilated, inverted')


bw_half=0.5*bw;

I_mod = imimposemin(bw_half,bw_er);


L = watershed(I_mod);

subplot(3,3,7)
imshow(label2rgb(L))
title('Watershed of original image using markers')

% multiply to get only the nucleus:

nuc = L.*bw;

subplot(3,3,8)
imshow(nuc)

title('Final image w. separated cells')


labeledImage = bwlabel(nuc); %, 8); Hvorfor 8?     % Label each blob so we can make measurements of it
coloredLabels = label2rgb(labeledImage); % igen, hvad er det her: , 'hsv', 'k', 'shuffle'); % pseudo random color labels


subplot(3, 3, 9); 
imagesc(coloredLabels);


% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
blobMeasurements = regionprops(bw, I, 'all');   
numberOfBlobs = size(blobMeasurements, 1);

fontSize = 14;	% Used to control size of "blob number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the coins.
blobECD = zeros(1, numberOfBlobs);
% Print header line in the command window.
fprintf(1,'Blob #      Mean Intensity  Area   Perimeter    Centroid       Diameter\n');
% Loop over all blobs printing their measurements to the command window.
for k = 1 : numberOfBlobs           % Loop through all blobs.
	% Find the mean of each blob.  (R2008a has a better way where you can pass the original image
	% directly into regionprops.  The way below works for all versions including earlier versions.)
    thisBlobsPixels = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
    meanGL = mean(I(thisBlobsPixels)); % Find mean intensity (in original image!)
	meanGL2008a = blobMeasurements(k).MeanIntensity; % Mean again, but only for version >= R2008a
	
	blobArea = blobMeasurements(k).Area;		% Get area.
	blobPerimeter = blobMeasurements(k).Perimeter;		% Get perimeter.
	blobCentroid = blobMeasurements(k).Centroid;		% Get centroid.
	blobECD(k) = sqrt(4 * blobArea / pi);					% Compute ECD - Equivalent Circular Diameter.
    fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f\n', k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k));
	% Put the "blob number" labels on the "boundaries" grayscale image.
	text(blobCentroid(1) + labelShiftX, blobCentroid(2), num2str(k), 'FontSize', fontSize, 'FontWeight', 'Bold');
end


nFITC = num2str(numberOfBlobs);
title(['Labeled regions. No. of cells is ' noCells])










