function [Image,loc] = UIcentroid(Mean,GreenImage,varargin)

ROI = {[]};
blur = [];
blur = fspecial('gaussian',4,1);
saveFile = '';
savePrompt = false; % allows for default file to be input to saveFile, but still prompts for filename determination

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'ROI'
                ROI = varargin{index+1};
                index = index + 2;
            case 'filter'
                blur = varargin{index+1};
                index = index + 2;
            case {'Save','save','SaveFile', 'saveFile'}
                saveFile = varargin{index+1};
                index = index + 2;
            case 'prompt'
                savePrompt = true;
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

if ~exist('Mean','var') || isempty(Mean)
    [Mean,p] = uigetfile({'.mat'},'Select experiment file');
    if isnumeric(Mean)
        return
    end
    Mean = fullfile(p,Mean);
end
if ischar(Mean)
    load(Mean,'Experiment','-mat');
    Mean = Experiment.Mean;
elseif isstruct(Mean)
    Experiment = Mean;
    Mean = Experiment.Mean;
elseif iscellstr(Mean)
    temp = imread(Mean{1});
    for findex = 1:numel(Mean)
        temp(:,:,findex) = imread(Mean{findex});
    end
    Mean = temp;
end
Mean = double(Mean);
numConditions = size(Mean,3);

if ~exist('GreenImage','var') || isempty(GreenImage)
    if exist('Experiment','var')
        GreenImage = Experiment.GreenImage;
    else
        [GreenImage,p] = uigetfile({'.tif'},'Select corrresponding green image');
        if isnumeric(GreenImage)
            return
        end
        GreenImage = fullfile(p,GreenImage);
    end
end
if ischar(GreenImage)
    GreenImage = imread(GreenImage);
end


%% Filter images
if ~isempty(blur)
    for cindex = 1:numConditions
        Mean(:,:,cindex) = filter2(blur,Mean(:,:,cindex));
    end
end


%% Determine ROI
if ~iscell(ROI)
    ROI = {ROI};
end
if numel(ROI) == 1 && numConditions ~= 1
    ROI = repmat(ROI,1,numConditions);
end

% UI select ROIs
for cindex = 1:numConditions
    if isequal(ROI{cindex},true)
        hF = figure('NumberTitle','off','Name',sprintf('Select ROI %d',cindex));
        imagesc(Mean(:,:,cindex)); colormap(gray);
        fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),get(gca,'YLim'));
        h = impoly(gca,'Closed',1,'PositionConstraintFcn',fcn);
        for p = 3:-1:1;
            set(hF,'Name',sprintf('Closing in %d',p));
            pause(1)
        end 
        ROI{cindex} = createMask(h); % ROI{cindex} = getPosition(h);
        close(hF);
    end
end


%% Determine color limits
CLim = nan(numConditions,2);
for cindex = 1:numConditions
    if ~isempty(ROI{cindex})
        temp = Mean(:,:,cindex);
        CLim(cindex,1) = min(temp(ROI{cindex}));
        CLim(cindex,2) = max(temp(ROI{cindex}));
    else
        temp = Mean(:,:,cindex);
        CLim(cindex,1) = min(temp(:));
        CLim(cindex,2) = max(temp(:));
    end
end


%% Select Centroids
loc = nan(numConditions,2);
hF = figure('NumberTitle','off');
for cindex = 1:numConditions
    hF.Name = sprintf('Select Centroid: condition %d',cindex);
    imagesc(Mean(:,:,cindex),CLim(cindex,:)); % display image
    axis off; colormap gray;
%     if ~isempty(ROI{cindex})
%         hold on;
%         pos = bwboundaries(ROI{cindex});
%         plot(pos{1}([1:end,1],2),pos{1}([1:end,1],1),'r--');
%         hold off;
%     end
    loc(cindex,:) = ginput(1); % ui select centroid
end


%% Display final image
figure(hF);
imagesc(GreenImage); hold on; axis off; colormap gray;
for cindex = 1:numConditions
    plot(loc(cindex,1),loc(cindex,2),'ro'); % overlay centroid
end
Image = getframe(gca);
Image = Image.cdata;
set(hF,'Name','Overlaid Centroids');


%% Save image to file
if ~isempty(saveFile)
    if isequal(saveFile,true) || savePrompt
        if savePrompt
            [saveFile,p] = uiputfile({'*.tif'},'Save centroids image as:',saveFile);
        else
            [saveFile,p] = uiputfile({'*.tif'},'Save centroids image as:');
        end
        if isnumeric(saveFile)
            return
        else
            saveFile = fullfile(p,saveFile);
        end
    end
    imwrite(Image,saveFile);
end

