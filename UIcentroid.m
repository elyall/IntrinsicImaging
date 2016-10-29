function [Image,loc] = UIcentroid(Mean,GreenImage,varargin)

ROI = [];
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
end

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
elseif ischar(GreenImage)
    GreenImage = imread(GreenImage);
end


%% Determine color limits
numConditions = size(Mean,3);
CLim = nan(numConditions,2);
if ~isempty(ROI)
    for cindex = 1:numConditions
        temp = Mean(:,:,cindex);
        CLim(cindex,1) = min(temp(ROI));
        CLim(cindex,2) = max(temp(ROI));
    end
else
    for cindex = 1:numConditions
        temp = Mean(:,:,cindex);
        CLim(cindex,1) = min(temp(:));
        CLim(cindex,2) = max(temp(:));
    end
end


%% Select Centroids
loc = nan(numConditions,2);
hF = figure('Name','Select Centroid','NumberTitle','off');
for cindex = 1:numConditions
    imagesc(Mean(:,:,cindex),CLim(cindex,:)); % display image
    axis off;
    loc(cindex,:) = ginput(1); % ui select centroid
end


%% Display final image
figure(hF);
imagesc(GreenImage); hold on; axis off;
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

