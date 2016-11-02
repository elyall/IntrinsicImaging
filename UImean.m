function gd = UImean(Trial,GreenImage,varargin)

first = [];
last = [];
ROI = [];
% online = false;

% Display parameters
units = 'normalized';
position = [.3, .425, .4, .2];


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
%             case 'online'
%                 online = true;
%                 index = index + 1;
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


%% Set dimensions
position(2) = position(2)-(gd.numStim-1)*position(end);
position(end) = gd.numStim*position(end);


%% Generate GUI

% Generate figure
gd.gui.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'UImean',...
    'Units',                units,...
    'Position',             position,...
    'ToolBar',              'none',...
    'MenuBar',              'none');

% Create panel
gd.gui.master.panel = uipanel(...
    'Title',                'Main',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0,0,.1,1]);
% Save Button
gd.gui.master.save = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Save Out',...
    'Parent',               gd.gui.master.panel,...
    'Units',                'normalized',...
    'Position',             [0,.2,1,.8],...
    'Callback',             @(hObject,eventdata)SaveOut(hObject, eventdata));
gd.gui.master.link = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Link?',...
    'Parent',               gd.gui.master.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.2],...
    'Callback',             @(hObject,eventdata)Link(hObject, eventdata));

% Generate condition figures
for cindex = 1:gd.numStim
    
    current = [.1,1-cindex*1/gd.numStim,.9,1/gd.numStim];
    
    % panel
    gd.gui.stim(cindex).panel = uipanel(...
    'Title',                sprintf('Stimulus %d',cindex),...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             current,...
    'UserData',             cindex);
    % first axes
    gd.gui.stim(cindex).axes1 = axes(...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [0,.1,.33,.9]);
    axis off
    % create ROI button
    gd.gui.stim(cindex).newROI = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'New ROI',...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [0,0,.17,.1],...
        'UserData',             cindex,...
        'Callback',             @(hObject,eventdata)NewROI(hObject, eventdata));
    % delete ROI button
    gd.gui.stim(cindex).deleteROI = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'Delete ROI',...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [.17,0,.16,.1],...
        'UserData',             cindex,...
        'Callback',             @(hObject,eventdata)DeleteROI(hObject, eventdata));
    % second axes
    gd.gui.stim(cindex).axes2 = axes(...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.33,.2,.34,.8]);
    axis off
    % select frame slider
    gd.gui.stim(cindex).slider = uicontrol(...
        'Style',                'slider',...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [.38,.1,.29,.1],...
        'UserData',             cindex,...
        'Callback',             @(hObject,eventdata)ChangeImage(hObject, eventdata));
    gd.gui.stim(cindex).sliderText = uicontrol(...
        'Style',                'text',...
        'String',               '',...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.33,.1,.05,.07]);
    % set first button
    gd.gui.stim(cindex).first = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'First',...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [.33,0,.17,.1],...
        'UserData',             {cindex,'first'},...
        'Callback',             @(hObject,eventdata)SetMean(hObject, eventdata));
    % button to set last
    gd.gui.stim(cindex).last = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'Last',...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [.5,0,.17,.1],...
        'UserData',             {cindex,'last'},...
        'Callback',             @(hObject,eventdata)SetMean(hObject, eventdata));
    % third axes
    gd.gui.stim(cindex).axes3 = axes(...
        'Parent',               gd.gui.stim(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.67,0,.33,1]);
    axis off
    gd.gui.stim(cindex).ROI.handle = [];
    gd.gui.stim(cindex).ROI.pos = [];
end

% guidata(gd.gui.master.fig,gd);


%% Initialize
for cindex = 1:gd.numStim
    
    % Set slider values
    N = size(gd.data.Trial,3);
    set(gd.gui.stim(cindex).slider,'Min',1,'Max',N,...
        'SliderStep',[1/(N-1),min(10/(N-1),N)],'Value',round(N/2));
    set(gd.gui.stim(cindex).first,'String',sprintf('First = %d',gd.data.first(cindex)));
    set(gd.gui.stim(cindex).last,'String',sprintf('Last = %d',gd.data.last(cindex)));
    
    % Axes1: Display green image
    axes(gd.gui.stim(cindex).axes1);
    imagesc(gd.data.GreenImage);
    
    % Axes1: Overlay ROI (if one exists)
    % Axes2: Display single frame
    % Axes3: Set first & last, & calculate and display mean
    if ~all(all(gd.data.ROI(:,:,cindex)))
        gd.gui.stim(cindex).ROI.pos = bwboundaries(gd.data.ROI(:,:,cindex));
        NewROI(gd.gui.stim(cindex).newROI, false);
    else
        UpdatePlots(cindex);
    end
    
end


% %% Run online mode
% if online
%     gd.newData = false;
% end
% while online
%     pause(1);
%     if gd.newData
%         UpdatePlots(gd.newData);
%         gd.newData = false;
%     end
%     if ~ishghandle(gd.gui.fig)
%         return
%     end
% end

%% Callbacks

    


    function NewROI(hObject, eventdata)
        cindex = get(hObject,'UserData');
        
        % Create UI ROI
        fcn = makeConstrainToRectFcn('impoly',get(gd.gui.stim(cindex).axes1,'XLim'),get(gd.gui.stim(cindex).axes1,'YLim'));
        if ~isequal(eventdata,false)
            gd.gui.stim(cindex).ROI.handle = impoly(gd.gui.stim(cindex).axes1,'Closed',1,'PositionConstraintFcn',fcn);
        else
            gd.gui.stim(cindex).ROI.handle = impoly(gd.gui.stim(cindex).axes1,gd.gui.stim(cindex).ROI.pos,'Closed',1,'PositionConstraintFcn',fcn);
        end
        addNewPositionCallback(gd.gui.stim(cindex).ROI.handle,@MoveROI);
        set(gd.gui.stim(cindex).ROI.handle,'UserData',cindex);
        gd.gui.stim(cindex).ROI.pos = getPosition(gd.gui.stim(cindex).ROI.handle);
        
        % Update Plots
        UpdatePlots(cindex);
    end


    function MoveROI(pos)
        cindex = get(get(gco,'Parent'),'UserData');
        gd.gui.stim(cindex).ROI.pos = pos;
        UpdatePlots(cindex);
    end


    function DeleteROI(hObject, eventdata)
        cindex = get(hObject,'UserData');
        delete(gd.gui.stim(cindex).ROI.handle);
        gd.gui.stim(cindex).ROI.handle = [];
        gd.gui.stim(cindex).ROI.pos = [];
        UpdatePlots(cindex);
    end


    function UpdatePlots(cindex)
        ChangeImage(gd.gui.stim(cindex).slider, []); % change one or all selection axes
        if ~get(gd.gui.master.link,'Value')
            UpdateMean(cindex); % change current mean axis
        else
            for index = 1:gd.numStim % change all mean axes
                UpdateMean(index);
            end
        end
    end

    function ChangeImage(hObject, eventdata)
        cindex = get(hObject,'UserData');
        if cindex==1 || ~get(gd.gui.master.link,'Value')
            val = round(get(hObject,'Value'));
            rindex = cindex;
        else
            val = round(get(gd.gui.stim(1).slider,'Value'));
            set(gd.gui.stim(cindex).slider,'Value',val);
            rindex = 1;
        end
        set(gd.gui.stim(cindex).sliderText,'String',val);
        axes(gd.gui.stim(cindex).axes2);
        imagesc(gd.data.Trial(:,:,val,cindex));
        axis off;
        if ~isempty(gd.gui.stim(rindex).ROI.pos)
            hold on;
            plot(gd.gui.stim(rindex).ROI.pos([1:end,1],1),gd.gui.stim(rindex).ROI.pos([1:end,1],2),'r-','LineWidth',2);
            hold off;
        end
        if cindex==1 && get(gd.gui.master.link,'Value')
            for temp = 2:gd.numStim
                ChangeImage(gd.gui.stim(temp).slider,[]);
            end
        end
    end

    function SetMean(hObject, eventdata)
        temp = get(hObject,'UserData');
        cindex = temp{1};
        switch temp{2}
            case 'first'
                gd.data.first(cindex) = round(get(gd.gui.stim(cindex).slider,'Value'));
                set(gd.gui.stim(cindex).first,'String',sprintf('First = %d',gd.data.first(cindex)));
            case 'last'
                gd.data.last(cindex) = round(get(gd.gui.stim(cindex).slider,'Value'));
                set(gd.gui.stim(cindex).last,'String',sprintf('Last = %d',gd.data.last(cindex)));
        end
        if ~get(gd.gui.master.link,'Value')
            UpdateMean(cindex);
        else
            for index = 1:gd.numStim
                UpdateMean(index);
            end
        end
    end

    function UpdateMean(cindex)
        if ~get(gd.gui.master.link,'Value')
            index = cindex;
        else
            index = 1;
        end
        Mean = mean(gd.data.Trial(:,:,gd.data.first(index):gd.data.last(index),cindex),3);
        axes(gd.gui.stim(cindex).axes3);
        if isempty(gd.gui.stim(index).ROI.pos)
            imagesc(Mean);
            axis off;
        else
            temp = createMask(gd.gui.stim(index).ROI.handle);
            CLim = [min(min(Mean(temp))),max(max(Mean(temp)))];
            if any(CLim)
                imagesc(Mean,CLim);
            else
                imagesc(Mean);
            end
            axis off;
            hold on;
            plot(gd.gui.stim(index).ROI.pos([1:end,1],1),gd.gui.stim(index).ROI.pos([1:end,1],2),'r-','LineWidth',2);
            hold off;
        end
    end

    function SaveOut(hObject, eventdata)
%         gd.data.ROI(:,:,cindex) = createMask(gd.gui.stim(cindex).ROI.handle);
%         gd.data.ROI(:,:,cindex) = ones(size(gd.data.Trial,1),size(gd.data.Trial,2));
    end

end