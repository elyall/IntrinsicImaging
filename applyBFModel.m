function [Model,Dict] = applyBFModel(Centroids,Labels,varargin)
% applyBFModel Register model of barrel field to 3 or more input centroids.
%   [MODEL,DICT] = applyBFModel(CENTROIDS,LABELS), fits model of barrel
%   field to CENTROIDS, an Nx2 list of intrinsic image centroids with
%   columns [Medial-Lateral, Rostral-Caudal] and N greater than 2. LABELS
%   is 1xN or Nx1 cell array of strings where each cell contains the label
%   of the corresponding centroid input.
%
%   [MODEL,DICT] = applyBFModel(CENTROIDS,LABELS,'verbose') will display
%   the resulting registered model.
%
%   [MODEL,DICT] = applyBFModel(CENTROIDS,LABELS,'Image',IMAGE) will
%   display the resulting registered model overlayed on IMAGE.
%

ModelFile = '/home/elyall/Documents/Code/MATLAB/IntrinsicImaging/knutsen barrel centroids.xlsx'; % user-defined path to dictionary file


%% Parse input arguments
Image = [];

index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'Image'
                Image = varargin{index+1};
                index = index + 2;
            case {'Verbose','verbose'}
                Image = true;
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

%% Error checking
if ~exist(ModelFile,'file')
    error('Cannot locate spreadsheet containing the model. Make sure the file path is defined correctly in ''applyBFModel.m''');
end
N = size(Centroids,1);
if N ~= numel(Labels)
    error('Need one label per centroid');
elseif N < 3
    error('Need at least 3 barrel centroids input');
end

%% Load model and dictionary
[Model,Dict]=xlsread(ModelFile);
Model = Model(1:2,:)';
Dict = Dict(1,2:end);
if any(~ismember(Labels,Dict))
    error('Ensure all labels input match a whisker in the dictionary');
end

%% Determine which whiskers are input
index = cellfun(@(x) find(strcmp(x,Dict)),Labels); % match input whiskers to relative whisker in model

%% Transform model
tform = fitgeotrans(Model(index,:),Centroids,'similarity'); % determine transformation
Model = transformPointsForward(tform, Model);               % apply transformation

%% Display registration
if ~isempty(Image)
    if ischar(Image)
        Image = imread(Image);
    end
    
    figure;
    if ~isequal(Image,true)
        if size(Image,3)==1
            imagesc(Image); colormap gray;
        elseif size(Image,3)==3
            image(Image);
        end
        axis off;
    else
        ylabel('Rostral-Caudal axis');
        xlabel('Medial-Lateral axis');
    end
    hold on;
    plot(Centroids(:,1),Centroids(:,2),'bo');
    plot(Model(:,1),Model(:,2),'r.','MarkerSize',10);
    hold off;
    legend('input','model','Location','NorthEastOutside');
    
end

