function gd = UImean(Trial,GreenImage,varargin)

first = [];
last = [];
ROI = [];

% Display parameters
units = 'normalized';
position = [.1, .8, .1, .1];

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'first'
                first = varargin{index+1};
                index = index + 2;
            case 'last'
                last = varargin{index+1};
                index = index + 2;
            case 'ROI'
                ROI = varargin{index+1};
                index = index + 2;
            case 'units'
                units = varargin{index+1};
                index = index + 2;
            case 'position'
                position = varargin{index+1};
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

if ~exist('Trial','var') || isempty(Trial)
    [Trial,p] = uigetfile({'.mat'},'Select previous experiment file');
    if isnumeric(Trial)
        return
    end
    Trial = fullfile(p,Trial);
end
if ischar(Trial)
    load(Trial,'Experiment','-mat');
    Trial = Experiment;
end
if isstruct(Trial)
    Experiment = Trial;
    Trial = Experiment.Trial;
end
gd.numStim = size(Trial,4);

if ~exist('GreenImage','var') || isempty(GreenImage)
    if exist('Experiment','var')
        GreenImage = Experiment.GreenImage;
    else
        GreenImage = zeros(512,512);
    end
elseif ischar(GreenImage)
    GreenImage = imread(GreenImage);
end

if isempty(first)
    if exist('Experiment','var')
        first = Experiment.timing.avgFirst;
    else
        first = 1;
    end
end
if numel(first)~=gd.numStim
    first = repmat(first,1,gd.numStim);
end

if isempty(last)
    if exist('Experiment','var')
        last = Experiment.timing.avgLast;
    else
        last = size(Trial,3);
    end
end
if numel(last)~=gd.numStim
    last = repmat(last,1,gd.numStim);
end

if isempty(ROI)
    if exist('Experiment','var')
        ROI = Experiment.ROI;
    else
        ROI = true(size(Trial,1),size(Trial,2));
    end
end
if size(ROI,2)~=gd.numStim
    ROI = repmat(ROI,1,1,gd.numStim);
end


%% Load data
gd.data.Trial = Trial;
gd.data.GreenImage = GreenImage;
gd.data.first = first;
gd.data.last = last;
gd.data.ROI = ROI;


%% Generate GUI

% Generate master figure
gd.gui.master.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'UImean',...
    'Units',                units,...
    'Position',             position,...
    'ToolBar',              'none',...
    'MenuBar',              'none');
% Save Button
gd.gui.master.save = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Save Out',...
    'Parent',               gd.gui.master.fig,...
    'Units',                'normalized',...
    'Position',             [0,.2,1,.8],...
    'Callback',             @(hObject,eventdata)SaveOut(hObject, eventdata, guidata(hObject)));
gd.gui.master.link = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Link?',...
    'Parent',               gd.gui.master.fig,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.2],...
    'Callback',             @(hObject,eventdata)Link(hObject, eventdata, guidata(hObject)));

% Generate condition figures
for cindex = 1:gd.numStim
    
    current = [position(1)+position(3),1-.3*cindex,.3,.2];
    
    % Create figure
    gd.gui.stim(cindex).fig = figure(...
        'NumberTitle',          'off',...
        'Name',                 sprintf('Stimulus %d',cindex),...
        'Units',                'normalized',...
        'Position',             current,...
        'ToolBar',              'none',...
        'MenuBar',              'none',...
        'UserData',             cindex);
    
    % first axes
    gd.gui.stim(cindex).axes1 = axes(...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [0,.1,.33,.9]);
    axis off
    % create ROI button
    gd.gui.stim(cindex).newROI = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'New ROI',...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'Position',             [0,0,.17,.1],...
        'UserData',             cindex,...
        'Callback',             @(hObject,eventdata)NewROI(hObject, eventdata, guidata(hObject)));
    % delete ROI button
    gd.gui.stim(cindex).deleteROI = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'Delete ROI',...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'Position',             [.17,0,.16,.1],...
        'UserData',             cindex,...
        'Callback',             @(hObject,eventdata)DeleteROI(hObject, eventdata, guidata(hObject)));
    % second axes
    gd.gui.stim(cindex).axes2 = axes(...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.33,.2,.34,.8]);
    axis off
    % select frame slider
    gd.gui.stim(cindex).slider = uicontrol(...
        'Style',                'slider',...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'Position',             [.38,.1,.29,.1],...
        'UserData',             cindex,...
        'Callback',             @(hObject,eventdata)ChangeImage(hObject, eventdata, guidata(hObject)));
    gd.gui.stim(cindex).sliderText = uicontrol(...
        'Style',                'text',...
        'String',               '',...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.33,.1,.05,.07]);
    % set first button
    gd.gui.stim(cindex).first = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'First',...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'Position',             [.33,0,.17,.1],...
        'UserData',             {cindex,'first'},...
        'Callback',             @(hObject,eventdata)SetMean(hObject, eventdata, guidata(hObject)));
    % button to set last
    gd.gui.stim(cindex).last = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'Last',...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'Position',             [.5,0,.17,.1],...
        'UserData',             {cindex,'last'},...
        'Callback',             @(hObject,eventdata)SetMean(hObject, eventdata, guidata(hObject)));
    % third axes
    gd.gui.stim(cindex).axes3 = axes(...
        'Parent',               gd.gui.stim(cindex).fig,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.67,0,.33,1]);
    axis off
    gd.gui.stim(cindex).ROI.handle = [];
end

guidata(gd.gui.master.fig,gd);


%% Initialize
for cindex = 1:gd.numStim
    
    % Set slider values
    N = size(gd.data.Trial,3);
    set(gd.gui.stim(cindex).slider,'Min',1,'Max',N,...
        'SliderStep',[1/(N-1),N/5],'Value',round(N/2));
    set(gd.gui.stim(cindex).first,'String',sprintf('First = %d',gd.data.first(cindex)));
    set(gd.gui.stim(cindex).last,'String',sprintf('Last = %d',gd.data.last(cindex)));
    
    % Axes1: Display green image
    axes(gd.gui.stim(cindex).axes1);
    imagesc(gd.data.GreenImage);
    
    % Axes1: Overlay ROI (if one exists)
    % Axes2: Display single frame
    % Axes3: Set first & last, & calculate and display mean
    if ~all(all(gd.data.ROI(:,:,cindex)))
        NewROI(gd.gui.stim(cindex).newROI, false, gd);
    else
        UpdatePlots(gd,cindex);
    end

end


%% Callbacks

function Link(hObject, eventdata, gd)
if get(hObject,'Value')
    for cindex = 2:gd.numStim
        gd.data.ROI(:,:,cindex) = gd.data.ROI(:,:,1);
        delete(gd.gui.stim(cindex).ROI.handle);
    end
    set([gd.gui.stim(2:end).newROI,gd.gui.stim(2:end).deleteROI],'Enable','off');
    set([gd.gui.stim(2:end).slider,gd.gui.stim(2:end).sliderText],'Enable','off');
else
    for cindex = 2:gd.numStim
        gd.gui.stim(cindex).ROI.handle = impoly(gd.gui.stim(cindex).axes1,pos,'Closed',1);
        addNewPositionCallback(gd.gui.stim(cindex).ROI.handle,@MoveROI);
        fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),get(gca,'YLim'));
        setPositionConstraintFcn(gd.gui.stim(cindex).ROI.handle, fcn);
        gd.data.ROI(:,:,cindex) = createMask(gd.gui.stim(cindex).ROI.handle);
    end
    set([gd.gui.stim(2:end).newROI,gd.gui.stim(2:end).deleteROI],'Enable','on');
    set([gd.gui.stim(2:end).slider,gd.gui.stim(2:end).sliderText],'Enable','on');
end
guidata(hObject,gd);
for cindex = 2:gd.numStim
    UpdatePlots(gd,cindex);
end

function NewROI(hObject, eventdata, gd)
if get(gd.gui.master.link,'Value')
    cindex = 1;
else
    cindex = get(hObject,'UserData');
end

% Create UI ROI
if ~isequal(eventdata,false)
    gd.gui.stim(cindex).ROI.handle = impoly(gd.gui.stim(cindex).axes1,'Closed',1);
else
    pos = bwboundaries(gd.data.ROI(:,:,cindex));
    gd.gui.stim(cindex).ROI.handle = impoly(gd.gui.stim(cindex).axes1,pos,'Closed',1);
end
addNewPositionCallback(gd.gui.stim(cindex).ROI.handle,@MoveROI);
fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(gd.gui.stim(cindex).ROI.handle, fcn);
gd.gui.ROI.pos = getPosition(gd.gui.stim(cindex).ROI.handle);
gd.data.ROI(:,:,cindex) = createMask(gd.gui.stim(cindex).ROI.handle);
guidata(hObject,gd);
UpdatePlots(gd,cindex);


function MoveROI(pos)
hObject=gco;
gd = guidata(hObject);
gd.gui.stim(cindex).ROI.pos = pos;
gd.data.ROI = createMask(gd.gui.stim(cindex).ROI.handle);
guidata(hObject,gd);
UpdatePlots(gd,cindex);


function DeleteROI(hObject, eventdata, gd)
if get(gd.gui.master.link,'Value')
    cindex = 1;
else
    cindex = get(hObject,'UserData');
end
delete(gd.gui.stim(cindex).ROI.handle);
gd.gui.stim(cindex).ROI.handle = [];
gd.data.ROI(:,:,cindex) = ones(size(gd.data.Trial,1),size(gd.data.Trial,2));
guidata(hObject,gd);
UpdatePlots(gd,cindex);


function UpdatePlots(gd,cindex)
ChangeImage(gd.gui.stim(cindex).slider, [], gd);
UpdateMean(gd,cindex);


function ChangeImage(hObject, eventdata, gd)
if get(gd.gui.master.link,'Value')
    cindex = 1;
else
    cindex = get(hObject,'UserData');
end
val = round(get(gd.gui.stim(cindex).slider,'Value'));
set(gd.gui.stim(cindex).sliderText,'String',val);
axes(gd.gui.stim(cindex).axes2);
imagesc(gd.data.Trial(:,:,val,cindex));
axis off;
if ~all(all(gd.data.ROI(:,:,cindex)))
    hold on;
    plot(gd.gui.stim(cindex).ROI.pos([1:end,1],1),gd.gui.stim(cindex).ROI.pos([1:end,1],2),'r-','LineWidth',2);
    hold off;
end


function SetMean(hObject, eventdata, gd)
temp = get(hObject,'UserData');
cindex = temp{1};
switch temp{2}
    case 'first'
        gd.data.first(cindex) = round(get(gd.gui.stim(cindex).slider,'Value'));
        set(gd.gui.first,'String',sprintf('First = %d',gd.data.first(cindex)));
    case 'last'
        gd.data.last(cindex) = round(get(gd.gui.stim(cindex).slider,'Value'));
        set(gd.gui.stim(cindex).last,'String',sprintf('Last = %d',gd.data.last(cindex)));
end
guidata(hObject,gd);
UpdateMean(gd,cindex);


function UpdateMean(gd,cindex)
Mean = mean(gd.data.Trial(:,:,gd.data.first:gd.data.last,cindex),3);
axes(gd.gui.stim(cindex).axes3);
if all(all(gd.data.ROI(:,:,cindex)))
    imagesc(Mean);
    axis off;
else
    CLim = [min(min(Mean(gd.data.ROI(:,:,cindex)))),max(max(Mean(gd.data.ROI(:,:,cindex))))];
    imagesc(Mean,CLim);
    axis off;
    hold on;
    plot(gd.gui.stim(cindex).ROI.pos([1:end,1],1),gd.gui.stim(cindex).ROI.pos([1:end,1],2),'r-','LineWidth',2);
    hold off;
end


function SaveOut(hObject, eventdata, gd)

