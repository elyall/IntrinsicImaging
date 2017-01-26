function [Model,Dict] = applyBFModel(Centroids,Labels,varargin)
% Centroids is Nx2 matrix  with columns: [Medial-Lateral,Rostral-Caudal],
% where N is greater than 2.

DictFile = '/home/elyall/Documents/Code/MATLAB/IntrinsicImaging/knutsen barrel centroids.xlsx';

verbose = false;

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'verbose','Verbose'}
                verbose = true;
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

%% Load model and dictionary
[Model,Dict]=xlsread(DictFile);
Model = Model(1:2,:)';
Dict = Dict(1,2:end);

%% Determine which whiskers are input
N = size(Centroids,1);
if N ~= numel(Labels)
    error('Need one label per centroid');
elseif N < 3
    error('Need at least 3 whiskers');
elseif any(~ismember(Labels,Dict))
    error('Ensure all labels input match a whisker in the dictionary');
end

index = cellfun(@(x) find(strcmp(x,Dict)),Labels); % match input whiskers to relative whisker in model

%% Transform model
tform = fitgeotrans(Model(index,:),Centroids,'similarity'); % determine transformation
Model = transformPointsForward(tform, Model);               % apply transformation

%% Display registration
if verbose
    figure; hold on;
    plot(Centroids(:,1),Centroids(:,2),'ko');
    plot(Model(:,1),Model(:,2),'r.','MarkerSize',10);
    legend('input','model','Location','best');
    legend boxoff
    ylabel('Rostral-Caudal axis');
    xlabel('Medial-Lateral axis');
end

