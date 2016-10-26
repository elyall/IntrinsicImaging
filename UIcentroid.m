function [Image,loc] = UIcentroid(Experiment,GreenImage,varargin)

saveFile = '';

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Save','save','SaveFile', 'saveFile'}
                saveFile = varargin{index+1};
                index = index + 2;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

if ~exist('Experiment','var') || isempty(Experiment)
    [Experiment,p] = uigetfile({'.mat'},'Select previous experiment file');
    if isnumeric(Experiment)
        return
    end
    Experiment = fullfile(p,Experiment);
end
if ischar(Experiment)
    load(Experiment,'Experiment','-mat');
end

if ~exist('GreenImage','var') || isempty(GreenImage)
    GreenImage = Experiment.GreenImage;
elseif ischar(GreenImage)
    GreenImage = imread(GreenImage);
end


%% Select Centroids
numConditions = size(Experiment.Mean,3);
loc = nan(numConditions,2);

hF = figure('Name','Select Centroid','NumberTitle','off');
for cindex = 1:numConditions
    imagesc(Experiment.Mean(:,:,cindex));   % display image
    axis off;
    loc(cindex,:) = ginput(1);          % ui select centroid
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
    imwrite(Image,saveFile);
end

