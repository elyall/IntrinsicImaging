function [Fit, zfit, fiterr, zerr, resnorm, rr] = fit2DGauss(Image,ROI,init,varargin)
% fit2DGauss Fit 2D Gaussian to intrinsic imaging data. Utilizes FMGAUSSFIT
% (https://www.mathworks.com/matlabcentral/fileexchange/41938-fit-2d-gaussian-with-optimization-toolbox)
%   FIT = fit2DGauss() prompts the user to select one or more tif files,
%   and then fits 2D Gaussians to the loaded images. The initial guess at
%   the Gaussian's centroid is the brightest pixel. FIT is a Nx7 vector
%   specifying: [Amplitude AxisAngle Sigma_X Sigma_Y Mu_X Mu_Y ?] for each
%   Gaussian fit.
%
%   fit2DGauss(IMAGE), IMAGE can be an emptry matrix to prompt the user for
%   file selection, a cell array of strings of filenames to load, or an HxWxN matrix to
%   fit N 2D Gaussians to.
%
%   fit2DGauss(IMAGE,ROI) restricts the 2D Gaussian fit to the data within
%   the polygon specified by ROI, a Px2 matrix of the perimeter's
%   points. Set ROI to true to prompt for user selection of the polygon.
%   Leave ROI as an empty matrix to not use an ROI. To specify different
%   ROI parameters for each image, ROI can be a cell array of length equal
%   to the number of images input.
%
%   fit2DGauss(IMAGE,ROI,INIT) specifies the initial [X,Y] guess of the
%   Gaussian's centroid to be INIT. Set INIT to true to prompt for user
%   selection of the centroid's initial guess. Leave INIT empty to use the
%   default initial guess: the image's brightest pixel. To specify
%   different INIT parameters for each image, INIT can be a cell array of
%   length equal to the number of images input.
%
%   fit2DGauss(...,'Filter',FILTER) applies the 2D filter to the image(s)
%   (created by fspecial) prior to fitting. (default =
%   fspecial('gaussian',5,1))
%
%   fit2DGauss(...,'Invert') toggles inverting the image prior to fitting.
%   (default = false)
%
%   fit2DGauss(...,'Verbose') toggles displaying the result of the fit
%   using overlayGauss. (default = true)
%
%   [Fit, zfit, fiterr, zerr, resnorm, rr] = fit2DGauss(...) returns all
%   outputs of FMGAUSSFIT. (doesn't work for multiple files currently)
%

% Default parameters that can be adjusted
Filter = fspecial('gaussian',5,1);  % false or filtering object created with fspecial
invert = false;                     % booleon specifying whether to invert image
verbose = true;                     % booleon specifying whether to display fit

% Placeholders
directory = cd; % default directory when prompting user to select a file

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Filter','filter'}
                Filter = varargin{index+1};
                index = index + 2;
            case {'Invert','invert'}
                invert = ~invert;
                index = index + 1;
            case {'Verbose','verbose'}
                verbose = ~verbose;
                index = index + 1;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

if ~exist('Image','var') || isempty(Image)
    [Image,p] = uigetfile({'*.tif'},'Choose iOS image',directory,'MultiSelect','on');
    if isnumeric(Image)
        return
    end
    Image = fullfile(p,Image);
end
if ischar(Image)
    Image = {Image};
end

if ~exist('ROI','var')
    ROI = {[]};
elseif ~iscell(ROI)
    ROI = {ROI};
end

if ~exist('init','var')
    init = {[]};
elseif ~iscell(init)
    init = {init};
end

%% Load and transform image
if iscellstr(Image)
    for findex = 1:numel(Image)
        Image{findex} = imread(Image{findex});
    end
    Image = cat(3,Image{:});
end
[H,W,numFiles] = size(Image);
if invert
    switch class(Image)
        case {'single','double'}
            Image = realmax(class(Image)) - Image;
        otherwise
            Image = intmax(class(Image)) - Image;
    end
end
if ~isa(Image,'double')
    Image = double(Image);
end
if ~isequal(Filter,false)
    Image = imfilter(Image,Filter);
end


%% UI
if numel(ROI)==1 && numFiles>1
    ROI = repmat(ROI,numFiles,1);
end
if numel(init)==1 && numFiles>1
    init = repmat(init,numFiles,1);
end
if any(cellfun(@(x) isequal(x,true), ROI)) || any(cellfun(@(x) isequal(x,true), init))
    hF = figure('NumberTitle','off');
    for findex = 1:numFiles
        
        % Define ROI
        if isequal(ROI{findex},true)
            set(hF,'Name',sprintf('%d: Select ROI',findex));
            imagesc(Image(:,:,findex)); colormap(gray);
            fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),get(gca,'YLim'));
            h = impoly(gca,'Closed',1,'PositionConstraintFcn',fcn);
            pause(2);
            ROI{findex} = getPosition(h);
        end
        
        % Make guess at centroid
        if isequal(init{findex},true)
            set(hF,'Name',sprintf('%d: Select centroid',findex));
            imagesc(Image(:,:,findex)); colormap(gray);
            init{findex} = round(flip(ginput(1)));
        end
        
    end
    close(hF);
end

%% Fit 2D Gaussian
[xx,yy] = meshgrid(1:H,1:W);
Fit = nan(numFiles,7);
for findex = 1:numFiles
    temp = Image(:,:,findex);
    if ~isempty(ROI{findex})
        mask = poly2mask(ROI{findex}(:,1),ROI{findex}(:,2),H,W);
        temp(~mask) = mean(temp(:));
    end
    [Fit(findex,:), zfit, fiterr, zerr, resnorm, rr] = fmgaussfit(xx,yy,temp,init{findex});
end

%% Display output
if verbose
    for findex = 1:numFiles
        figure;
        imagesc(Image(:,:,findex)); hold on;
        overlayGauss(Fit(findex,5:6), Fit(findex,2), Fit(findex,3:4));
        if ~isempty(ROI{findex})
            plot(ROI{findex}([1:end,1],1),ROI{findex}([1:end,1],2),'r--','LineWidth',2);
        end
    end
end

