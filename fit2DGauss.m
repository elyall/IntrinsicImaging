function [Fit, zfit, fiterr, zerr, resnorm, rr] = fit2DGauss(Image,ROI,init,varargin)
% fit2DGauss Fit 2D Gaussian to intrinsic imaging data. Utilizes FMGAUSSFIT
% (https://www.mathworks.com/matlabcentral/fileexchange/41938-fit-2d-gaussian-with-optimization-toolbox)
%   FIT = fit2DGauss() prompts the user to select a tif file, and then fits
%   a 2D Gaussian to loaded image. The initial guess at the Gaussian's
%   centroid is the brightest pixel. FIT is a 1x7 vector specifying:
%   [Amplitude AxisAngle Sigma_X Sigma_Y Mu_X Mu_Y ?]
%
%   fit2DGauss(IMAGE), IMAGE can be an emptry matrix to prompt the user for
%   file selection, a filename of an image to load, or an N x M matrix to
%   fit a 2D Gaussian to.
%
%   fit2DGauss(IMAGE,ROI) restricts the 2D Gaussian fit to the data within
%   the polygon specified by ROI, an N x 2 matrix of the perimeter's
%   points. Set ROI to true to prompt for user selection of the polygon.
%   Leave ROI as an empty matrix to not use an ROI.
%
%   fit2DGauss(IMAGE,ROI,INIT) specifies the initial [X,Y] guess of the
%   Gaussian's centroid to be INIT. Set INIT to true to prompt for user
%   selection of the centroid's initial guess. Leave INIT empty to use the
%   default initial guess: the image's brightest pixel.
%
%   fit2DGauss(...,'Filter',FILTER) applies the 2D filter to the image
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
%   outputs of FMGAUSSFIT.
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
    [Image,p] = uigetfile({'*.tif'},'Choose iOS image',directory);
    if isnumeric(Image)
        return
    end
    Image = fullfile(p,Image);
end

if ~exist('ROI','var')
    ROI = [];
end

if ~exist('init','var')
    init = [];
end

%% Load and transform image
if ischar(Image)
    Image = imread(Image);
end
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

% Define ROI
if isequal(ROI,true)
    hF = figure('NumberTitle','off','Name','Select ROI');
    imagesc(Image); colormap(gray);
    fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),get(gca,'YLim'));
    h = impoly(gca,'Closed',1,'PositionConstraintFcn',fcn);
    ROI = getPosition(h);
    close(hF);
end

% Make guess at centroid
if isequal(init,true)
    hF = figure('NumberTitle','off','Name','Select guess of centroid');
    imagesc(Image); colormap(gray);
    init = round(flip(ginput(1)));
    close(hF);
end


%% Fit 2D Gaussian
temp = Image;
if ~isempty(ROI)
    mask = poly2mask(ROI(:,1),ROI(:,2),size(Image,1),size(Image,2));
    temp(~mask) = mean(temp(:));
end
[xx,yy] = meshgrid(1:size(Image,1),1:size(Image,2));
[Fit, zfit, fiterr, zerr, resnorm, rr] = fmgaussfit(xx,yy,temp,init);


%% Display output
if verbose
    figure;
    imagesc(Image); hold on;
    overlayGauss(Fit(5:6), Fit(2), Fit(3:4));
    if ~isempty(ROI)
        plot(ROI([1:end,1],1),ROI([1:end,1],2),'r--','LineWidth',2);
    end
end

