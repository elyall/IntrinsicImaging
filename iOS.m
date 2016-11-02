function iOS(numConditions)

if ~exist('numConditions','var')
    numConditions = 2;
end

% Initialize Saving
gd.Internal.save.path = cd;
gd.Internal.save.base = '0000_c1c2';
gd.Internal.save.index = '1';

% Initialize Timing
gd.Experiment.timing.baselineDur = 2;       %seconds
gd.Experiment.timing.stimDur = 4;           %seconds
gd.Experiment.timing.postDur = 1;           %seconds
gd.Experiment.timing.ITI = 25;              %seconds
gd.Experiment.timing.numTrials = 35;
gd.Experiment.timing.avgFirst = 2.5;        %seconds
gd.Experiment.timing.avgLast = 7;           %seconds
% gd.Experiment.timing.avgFirst = gd.Experiment.timing.baselineDur;
% gd.Experiment.timing.avgLast = gd.Experiment.timing.baselineDur+gd.Experiment.timing.stimDur+gd.Experiment.timing.postDur;

% Initialize Stimulus
gd.Experiment.stim.frequency = 10;          %hz
gd.Experiment.stim.wailDuration = 0.0499;   %seconds
gd.Experiment.stim.voltage = 5;             %volts
gd.Experiment.stim.bidirectional = true;    %boolean
if numConditions == 1
    gd.Internal.daq.piezos = table({true},{'Dev3'},{'ao0'},'VariableNames',{'Active','Device','Port'});
elseif numConditions == 2
    gd.Internal.daq.piezos = table({true;true},{'Dev3';'Dev3'},{'ao0';'ao1'},'VariableNames',{'Active','Device','Port'});
end

% Initialize Imaging
gd.Internal.imaging.port = 'COM5';
gd.Internal.imaging.initFile = 'C:\Users\User\Documents\MATLAB\iOS\CamFiles\T_1m60_12-bits_2_tap_ext_trig.ccf';
gd.Internal.imaging.dim = [512,512];
gd.Internal.imaging.subsampleFactor = 2;
gd.Experiment.imaging.frameRate = 59;   %hz
gd.Experiment.imaging.numFrames2Avg = floor(59/2); % half second averaging of frames
gd.Experiment.GreenImage = zeros(gd.Internal.imaging.dim);

% Default Settings
gd.Experiment.Trial = [];
gd.Internal.daq.samplingFrequency = 30000;
gd.Internal.isRunning = false;
gd.Internal.viewHandle = [];
gd.Internal.ROI.pos = [];
gd.Internal.ROI.handle = [];

% Display parameters
gd.Internal.Display.units = 'normalized';
gd.Internal.Display.position = [.225, .15, .5, .75];


%% GREG'S SETTINGS
% gd.Experiment.timing.baselineDur = 1;       %seconds
% gd.Experiment.timing.stimDur = 1.5;         %seconds
% gd.Experiment.timing.postDur = 1.5;         %seconds
% gd.Experiment.timing.ITI = 8;               %seconds
% gd.Experiment.timing.numTrials = 35;
% gd.Experiment.timing.avgFirst = 1;          %seconds
% gd.Experiment.timing.avgLast = 4;           %seconds
% gd.Experiment.stim.frequency = 20;          %hz
% gd.Experiment.stim.wailDuration = 0.02;     %seconds
% gd.Experiment.stim.voltage = 5;             %volts
% gd.Experiment.stim.bidirectional = false;   %boolean


%% Generate GUI
fprintf('Starting up...\n');

% Create figure
gd.gui.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'Intrinsic Optical Signal Imaging',...
    'Units',                gd.Internal.Display.units,...
    'Position',             gd.Internal.Display.position,...
    'ToolBar',              'none',...
    'MenuBar',              'none',...
    'Visible',              'off');

% Panels
gd.gui.file.panel = uipanel(...
    'Title',                'File Information',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .9, 1, .1]);
gd.gui.control.panel = uipanel(...
    'Title',                'Prep',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0,0,.4,.6]);
gd.gui.timing.panel = uipanel(...
    'Title',                'Timing',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0,.6,.25,.3]);
gd.gui.stim.panel = uipanel(...
    'Title',                'Stimulus',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.25,.6,.35,.3]);
gd.gui.experiment.panel = uipanel(...
    'Title',                'Experiment',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.6,.6,.4,.3]);
for cindex = 1:numConditions
    gd.gui.data(cindex).panel = uipanel(...
        'Title',                sprintf('Stimulus %d',cindex),...
        'Parent',               gd.gui.fig,...
        'Units',                'Normalized',...
        'Position',             [.4,.6-cindex*.6/numConditions,.6,.6/numConditions]);
end

% File selection

% select directory
gd.gui.file.dir = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Dir',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,.2,1],...
    'Callback',             @(hObject,eventdata)ChooseDir(hObject, eventdata, guidata(hObject)));
% basename input
gd.gui.file.base = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.base,...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.3,.4,.4,.6],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject),true));
gd.gui.file.baseText = uicontrol(...
    'Style',                'text',...
    'String',               'Basename',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.2,.4,.1,.6]);
% file index
gd.gui.file.index = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.index,...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.4,.2,.6],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject),false));
gd.gui.file.indexText = uicontrol(...
    'Style',                'text',...
    'String',               'File Index',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.7,.4,.1,.6]);
% display filename
gd.gui.file.filename = uicontrol(...
    'Style',                'text',...
    'String',               '',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.2,0,.8,.35]);

% Image control

% preview
gd.gui.control.preview = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Preview',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.9,.33,.1],...
    'Callback',             @(hObject,eventdata)PreviewImage(hObject, eventdata, guidata(hObject)));
% capture image
gd.gui.control.capture = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Capture Image',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [.33,.9,.34,.1],...
    'BackgroundColor',      [0,1,0],...
    'Callback',             @(hObject,eventdata)CaptureImage(hObject, eventdata, guidata(hObject)));
% select ROI
gd.gui.control.ROI = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Select ROI',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [.67,.9,.33,.1],...
    'Enable',               'off',...
    'Callback',             @(hObject,eventdata)SelectROI(hObject, eventdata, guidata(hObject)));
% axis
gd.gui.control.axes = axes(...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'UserData',             cindex,...
    'Position',             [0,0,1,.9]);
axis off

% Timing control

% Baseline duration
gd.gui.timing.baselineDur = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.timing.baselineDur,...
    'Units',                'normalized',...
    'Position',             [.7,.85,.3,.15],...
    'UserData',             {'timing','baselineDur', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.baselineDurText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'Baseline (s)',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.85,.65,.1]);
% Stimulus duration
gd.gui.timing.stimDur = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.timing.stimDur,...
    'Units',                'normalized',...
    'Position',             [.7,.7,.3,.15],...
    'UserData',             {'timing','stimDur', 0.001, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.stimDurText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'Stimulus (s)',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.7,.65,.1]);
% Post stimulus duration
gd.gui.timing.ITI = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.timing.postDur,...
    'Units',                'normalized',...
    'Position',             [.7,.55,.3,.15],...
    'UserData',             {'timing','postDur', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.ITIText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'Post-Stim (s)',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.55,.65,.1]);
% ITI
gd.gui.timing.ITI = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.timing.ITI,...
    'Units',                'normalized',...
    'Position',             [.7,.4,.3,.15],...
    'UserData',             {'timing','ITI', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.ITIText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'ITI (s)',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.4,.65,.1]);
% Frames to average
gd.gui.timing.avgFirst = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.timing.avgFirst,...
    'Units',                'normalized',...
    'Position',             [.4,.15,.3,.15],...
    'UserData',             {'timing','avgFirst', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.avgLast = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.timing.avgLast,...
    'Units',                'normalized',...
    'Position',             [.7,.15,.3,.15],...
    'UserData',             {'timing','avgLast', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.experiment.avgText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'Average (s)',...
    'HorizontalAlignment',  'center',...
    'Units',                'normalized',...
    'Position',             [0,.15,.4,.1]);
% Frame rate
gd.gui.timing.frameRate = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.imaging.frameRate,...
    'Units',                'normalized',...
    'Position',             [.7,0,.3,.15],...
    'UserData',             {'imaging','frameRate', 0, 59},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.frameRateText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'Frame Rate (Hz)',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,0,.65,.1]);

% Stimulus control

% Piezo toggle
gd.gui.stim.piezos = uitable(...
    'Parent',               gd.gui.stim.panel,...
    'Units',                'normalized',...
    'Position',             [0,.6,1,.4],...
    'ColumnName',           {'Active?','Device','Port'},...
    'ColumnEditable',       [true, false, false],...
    'ColumnFormat',         {'logical','char','char','char'},...
    'ColumnWidth',          {50,50,75,50},...
    'Data',                 table2cell(gd.Internal.daq.piezos));
% stimulus frequency
gd.gui.stim.frequency = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.stim.panel,...
    'String',               gd.Experiment.stim.frequency,...
    'Units',                'normalized',...
    'Position',             [.35,.4,.15,.15],...
    'UserData',             {'stim','frequency', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.stim.frequencyText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Frequency',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.4,.35,.1]);
% voltage
gd.gui.stim.voltage = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.stim.panel,...
    'String',               gd.Experiment.stim.voltage,...
    'Units',                'normalized',...
    'Position',             [.85,.4,.15,.15],...
    'UserData',             {'stim','voltage', 0, 5},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.stim.voltageText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Voltage',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [.5,.4,.35,.1]);
% wail duration
gd.gui.stim.wailDuration = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.stim.panel,...
    'String',               gd.Experiment.stim.wailDuration,...
    'Units',                'normalized',...
    'Position',             [.35,.2,.15,.15],...
    'UserData',             {'stim','wailDuration', 0.02, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.stim.wailDurationText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Wail Duration',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.2,.35,.1]);
% bidirectional toggle
gd.gui.stim.bidirectional = uicontrol(...
    'Style',                'checkbox',...
    'Parent',               gd.gui.stim.panel,...
    'Value',               gd.Experiment.stim.bidirectional,...
    'Units',                'normalized',...
    'Position',             [.9,.2,.1,.15],...
    'Callback',             @(hObject,eventdata)ChangeWail(hObject, eventdata, guidata(hObject)));
gd.gui.stim.bidirectionalText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Bidirectional',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [.5,.2,.35,.1]);
% View triggers
gd.gui.stim.view = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'View',...
    'Parent',               gd.gui.stim.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,.5,.2],...
    'Callback',             @(hObject,eventdata)ViewTriggers(hObject, eventdata, guidata(hObject)));
% Test stimuli
gd.gui.stim.test = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Test',...
    'Parent',               gd.gui.stim.panel,...
    'Units',                'normalized',...
    'Position',             [.5,0,.5,.2],...
    'Callback',             @(hObject,eventdata)TestTriggers(hObject, eventdata, guidata(hObject)));

% Experiment control

% Link
gd.gui.experiment.link = uicontrol(...
    'Style',                'checkbox',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               'Link?',...
    'Units',                'normalized',...
    'Position',             [0,.85,.5,.15],...
    'Enable',               'off',...
    'Value',                true,...
    'Callback',             @(hObject,eventdata)Link(hObject, eventdata, guidata(hObject)));
if numConditions == 1
    set(gd.gui.experiment.link,'Visible','off');
end
% Number of Trials
gd.gui.experiment.numTrials = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               gd.Experiment.timing.numTrials,...
    'Units',                'normalized',...
    'Position',             [.7,.85,.3,.15],...
    'UserData',             {'timing','numTrials', 1, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.experiment.numTrialsText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               '# Trials',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [.5,.85,.2,.1]);
% Run experiment
gd.gui.experiment.run = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Run',...
    'Parent',               gd.gui.experiment.panel,...
    'Units',                'normalized',...
    'Position',             [0,.5,1,.35],...
    'Enable',               'off',...
    'Callback',             @(hObject,eventdata)RunExperiment(hObject, eventdata, guidata(hObject)));
% Restart experiment
gd.gui.experiment.restart = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Restart',...
    'Parent',               gd.gui.experiment.panel,...
    'Units',                'normalized',...
    'Position',             [0,.25,1,.25],...
    'Enable',               'off');

% Identify centroids
gd.gui.experiment.save = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Save & Mark',...
    'Parent',               gd.gui.experiment.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.25],...
    'Enable',               'off',...
    'Callback',             @(hObject,eventdata)Save(hObject, eventdata, guidata(hObject)));

% Data Displays

for cindex = 1:numConditions
    % second axes
    gd.gui.data(cindex).axesImg = axes(...
        'Parent',               gd.gui.data(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [0,.2,.5,.8]);
    axis off
    % select frame slider
    gd.gui.data(cindex).slider = uicontrol(...
        'Style',                'slider',...
        'Parent',               gd.gui.data(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [.1,.1,.4,.1],...
        'UserData',             cindex,...
        'Enable',               'off',...
        'Callback',             @(hObject,eventdata)ChangeImage(hObject, eventdata, guidata(hObject)));
    gd.gui.data(cindex).sliderText = uicontrol(...
        'Style',                'text',...
        'String',               '',...
        'Parent',               gd.gui.data(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Enable',               'off',...
        'Position',             [0,.1,.09,.1]);
    % set first button
    gd.gui.data(cindex).first = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'First',...
        'Parent',               gd.gui.data(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [0,0,.25,.1],...
        'UserData',             {cindex,'first',[]},...
        'Enable',               'off',...
        'Callback',             @(hObject,eventdata)SetMean(hObject, eventdata, guidata(hObject)));
    % button to set last
    gd.gui.data(cindex).last = uicontrol(...
        'Style',                'pushbutton',...
        'String',               'Last',...
        'Parent',               gd.gui.data(cindex).panel,...
        'Units',                'normalized',...
        'Position',             [.25,0,.25,.1],...
        'UserData',             {cindex,'last',[]},...
        'Enable',               'off',...
        'Callback',             @(hObject,eventdata)SetMean(hObject, eventdata, guidata(hObject)));
    % mean axes
    gd.gui.data(cindex).axesMean = axes(...
        'Parent',               gd.gui.data(cindex).panel,...
        'Units',                'normalized',...
        'UserData',             cindex,...
        'Position',             [.5,0,.5,1]);
    axis off
end

try
    gd = initCamera(gd);         % initialize camera
    CreateFilename(gd,false);    % create initial filename
    set(gd.gui.fig,'Visible','on')
catch
    CreateFilename(gd,false);    % create initial filename
    set(gd.gui.fig,'Visible','on')
    error('Camera not found -> try restarting MATLAB  (figure visible only for testing)');
end
end


%% File Saving
function ChooseDir(hObject, eventdata, gd)
temp = uigetdir(gd.Internal.save.path, 'Choose directory to save to');
if ischar(temp)
    gd.Internal.save.path = temp;
    guidata(hObject, gd);
end
CreateFilename(gd,true);
end

function gd = CreateFilename(gd,reset)

% Create filename
gd.Internal.save.basename = fullfile(gd.Internal.save.path, get(gd.gui.file.base,'String'));
gd.Internal.save.filename = strcat(gd.Internal.save.basename, '_', get(gd.gui.file.index,'String'));
set(gd.gui.file.filename,'String',gd.Internal.save.filename);

% Determine if green image exists
if ~isempty(dir([gd.Internal.save.basename,'*']))
    gd.Experiment.GreenImage = imread([gd.Internal.save.basename,'_green_image.tif']);
    set(gd.gui.control.capture,'BackgroundColor',[.94,.94,.94]);
    set(gd.gui.experiment.run,'Enable','on','BackgroundColor',[0,1,0]);
    axes(gd.gui.control.axes);
    imagesc(gd.Experiment.GreenImage); % display green image
    if ~isempty(gd.Internal.ROI.pos)
        gd=placeROI(gd);
    end
    axis off; colormap gray;
    set(gd.gui.control.ROI,'Enable','on');
else
    set(gd.gui.control.capture,'BackgroundColor',[0,1,0]);
    set(gd.gui.experiment.run,'Enable','off','BackgroundColor',[.94,.94,.94]);
    gd.Experiment.GreenImage = [];
    axes(gd.gui.control.axes);
    imagesc(zeros(gd.Internal.imaging.dim)); % display green image
    axis off; colormap gray;
end

if reset
    set(gd.gui.control.ROI,'Value',false,'String','Select ROI');
    gd.Internal.ROI.handle = [];
    gd.Internal.ROI.pos = [];
end

guidata(gd.gui.fig, gd);

% Check if file exists
if ~isempty(dir([gd.Internal.save.filename,'*']))
    set(gd.gui.file.filename,'BackgroundColor',[1,0,0]);
else
    set(gd.gui.file.filename,'BackgroundColor',[.94,.94,.94]);
end
end

%% Prep
function gd = initCamera(gd)

% Initialize camera
gd.Internal.imaging.vid = videoinput('dalsa', 1, gd.Internal.imaging.initFile);
gd.Internal.imaging.src = getselectedsource(gd.Internal.imaging.vid);
gd.Internal.imaging.vid.FramesPerTrigger = 1;

imaqmem(2000000000); %set aside 2GB of memory for image frames (this should be changed depending on num of frames to be acquired

gd.Internal.imaging.vid.TriggerRepeat = Inf; %set number of triggers to expect. set to Inf so any number of frames can be captured
triggerconfig(gd.Internal.imaging.vid, 'hardware', 'risingEdge-ttl', 'automatic'); %set camera to be triggered on rising edge of ttl pulse

cam_serial_cmmd(gd.Internal.imaging.port,'sem 3');
cam_serial_cmmd(gd.Internal.imaging.port,'sec 0');

mssg = cam_serial_cmmd(gd.Internal.imaging.port,'gcp');

sem_check = 0;
sec_check = 0;
for k = 1:numel(mssg)
    if regexp(mssg{k},'Exposure Control.*disabled') %'.' = any single character, '*' = 0 or more times consecutively)
        sec_check = 1;
        disp('Exposure Control Set to ''disabled''')
    elseif regexp(mssg{k},'Exposure Mode.*3')
        sem_check = 1;
        disp('Exposure Mode set to ''3''')
    end
end
if sem_check == 0;
    error('iOS:camExpMode','Could not change camera to proper external tirgger mode (mode 3)')
elseif sec_check == 0;
    error('iOS:camExpControl','Could not set camera exposure control to disabled')
end
end

function PreviewImage(hObject, eventdata, gd)
if get(hObject,'Value') % start preview
    % Update GUI
    set(gd.gui.experiment.panel,'Visible','off');
    set(gd.gui.control.capture,'Enable','off');
    set(hObject,'String','Stop Preview','BackgroundColor',[0,0,0],'ForegroundColor',[1,1,1]);
    
    % Display stream
    temp_img = zeros(gd.Internal.imaging.vid.Videoresolution);  % initialize image
    hImage = image(temp_img,'Parent',gd.gui.control.axes);      % initialize handle
    pos = get(gd.gui.fig,'Position');
    figure('Units','normalized','Position',[pos(1)+.21,pos(2),.3,.3]);
    h = axes; 
    set(gd.Internal.imaging.vid,'UserData',h);                  % set histogram axis
    setappdata(hImage,'UpdatePreviewWindowFcn',@iOS_update_livehistogram_display);
    preview(gd.Internal.imaging.vid,hImage); % start preview
    
else % stop preview
    set(hObject,'String','Stopping...'); drawnow;
    stoppreview(gd.Internal.imaging.vid); % stop preview
    h = get(gd.Internal.imaging.vid,'UserData');
    if ishghandle(h)
        delete(get(h,'Parent')); % delete histogram figure
    end
    axes(gd.gui.control.axes);
    if ~isempty(gd.Experiment.GreenImage)
        imagesc(gd.Experiment.GreenImage); %display subsampled image (so ROI has right dimensions)
    else
        imagesc(zeros(gd.Internal.imaging.dim));
    end
    axis off;
    if ~isempty(gd.Internal.ROI.pos)
        placeROI(gd);
    end
    set(gd.gui.experiment.panel,'Visible','on');
    set(gd.gui.control.capture,'Enable','on');
    set(hObject,'String','Preview','BackgroundColor',[.94,.94,.94],'ForegroundColor',[0,0,0]);
end
end

function iOS_update_livehistogram_display(obj,event,hImage)
set(hImage,'CData',event.Data);
axes(get(gcbo,'UserData'));
counts = imhist(event.Data);
imhist(event.Data)
% ylim([0 255^2])
perc_255 = (counts(end)/sum(counts))*100;
perc_254 = (counts(end-1)/sum(counts))*100;
img_mean = mean2(event.Data);
ymax = max(ylim)-max(ylim)*0.1;
hold on
text(25,ymax,['perc @ 255: ' num2str(perc_255)])
text(25,ymax-ymax*0.1,['perc @ 254: ' num2str(perc_254)])
text(25,ymax-ymax*0.2,['mean: ' num2str(img_mean)])
hold off
drawnow
end

function CaptureImage(hObject, eventdata, gd)
set(hObject,'String','Capturing...'); drawnow;
axes(gd.gui.control.axes);
img = captureSingleFrame(gd);
gd.Experiment.GreenImage = img(1:gd.Internal.imaging.subsampleFactor:end,1:gd.Internal.imaging.subsampleFactor:end);
axes(gd.gui.control.axes);
imagesc(gd.Experiment.GreenImage); % display subsampled image (so ROI has right dimensions)
axis off;
if ~isempty(gd.Internal.ROI.pos)
    placeROI(gd);
else
    guidata(hObject,gd);
end
imwrite(gd.Experiment.GreenImage,strcat(gd.Internal.save.basename,'_','green_image.tif')); %save to file (overwrites any previous image)
set(hObject,'String','Capture Image','BackgroundColor',[.94,.94,.94]);
set(gd.gui.control.ROI,'Enable','on');
set(gd.gui.experiment.run,'Enable','on','BackgroundColor',[0,1,0]);
end

function img = captureSingleFrame(gd)
temp_img = zeros(get(gd.Internal.imaging.vid,'Videoresolution'));   %initialize image
hImage = image(temp_img,'Parent',gd.gui.control.axes);  %initialize handle
flushdata(gd.Internal.imaging.vid)                      %remove any previous data
triggerconfig(gd.Internal.imaging.vid, 'manual');       %change trigger
preview(gd.Internal.imaging.vid,hImage);                %preview image
start(gd.Internal.imaging.vid);                         %start recording
pause(0.100)                                            %ensures recording started
trigger(gd.Internal.imaging.vid);                       %manually trigger frame
pause(0.100) %for some reason no data is collected if there is no pause. this is what makes it work!!!
stoppreview(gd.Internal.imaging.vid);                   %stop preview
stop(gd.Internal.imaging.vid);                          %stop recording
triggerconfig(gd.Internal.imaging.vid, 'hardware', 'risingEdge-ttl', 'automatic'); %change trigger back to external
vid_data = getdata(gd.Internal.imaging.vid);            %collect recorded frame
img = uint8(single(vid_data)/(2^12-1)*(2^8-1));    %convert frame to uint8
end


function SelectROI(hObject, eventdata, gd)
if get(hObject,'Value')
    placeROI(gd);
    set(hObject,'String','Delete ROI');
else
    delete(gd.Internal.ROI.handle);
    gd.Internal.ROI.handle = [];
    gd.Internal.ROI.pos = [];
    guidata(hObject,gd);
    if ~isempty(gd.Experiment.Trial)
        if get(gd.gui.experiment.link,'Value')
            UpdatePlots(1,gd);
        else
            for cindex = 1:gd.Experiment.numStim
                UpdatePlots(cindex,gd);
            end
        end
    end
    set(hObject,'String','Select ROI');
end
end

function gd = placeROI(gd)
fcn = makeConstrainToRectFcn('impoly',get(gd.gui.control.axes,'XLim'),get(gd.gui.control.axes,'YLim'));
if isempty(gd.Internal.ROI.pos)
    gd.Internal.ROI.handle = impoly(gd.gui.control.axes,'Closed',1,'PositionConstraintFcn',fcn);
else
    gd.Internal.ROI.handle = impoly(gd.gui.control.axes,gd.Internal.ROI.pos,'Closed',1,'PositionConstraintFcn',fcn);
end
addNewPositionCallback(gd.Internal.ROI.handle,@MoveROI);
gd.Internal.ROI.pos = getPosition(gd.Internal.ROI.handle);
guidata(gd.gui.fig,gd);
if ~isempty(gd.Experiment.Trial)
    if get(gd.gui.experiment.link,'Value')
        UpdatePlots(1,gd);
    else
        for cindex = 1:gd.Experiment.numStim
            UpdatePlots(cindex,gd);
        end
    end
end
end

function MoveROI(pos)
h = get(gco,'Parent');
gd = guidata(h);
gd.Internal.ROI.pos = pos;
guidata(h,gd);
if ~isempty(gd.Experiment.Trial)
    if get(gd.gui.experiment.link,'Value')
        UpdatePlots(1,gd);
    else
        for cindex = 1:gd.Experiment.numStim
            UpdatePlots(cindex,gd);
        end
    end
end
end


%% Stimuli
function ChangeStim(hObject, eventdata, gd)
newValue = str2num(get(hObject,'String'));
UD = get(hObject,'UserData');
if isempty(newValue)                                                    % not a number
    set(hObject,'String',gd.Experiment.(hObject.UserData{1}).(hObject.UserData{2}));
elseif ~isempty(UD{3}) && newValue < UD{3}  % lower bound
    set(hObject,'String',UD{3});
    gd.Experiment.(UD{1}).(UD{2}) = UD{3};
    guidata(hObject,gd);
elseif ~isempty(UD{4}) && newValue > UD{4}  % upper bound
    set(hObject,'String',UD{4});
    gd.Experiment.(UD{1}).(UD{2}) = UD{4};
    guidata(hObject,gd);
else                                                                    % valid input
    gd.Experiment.(UD{1}).(UD{2}) = newValue;
    guidata(hObject, gd);
end
if get(gd.gui.stim.view,'Value')
    ViewTriggers(gd.gui.stim.view, [], gd);
end
end

function ChangeWail(hObject, eventdata, gd)
gd.Experiment.stim.bidirectional = get(hObject,'Value');
guidata(hObject,gd);
if get(gd.gui.stim.view,'Value')
    ViewTriggers(gd.gui.stim.view, [], gd);
end
end

function ViewTriggers(hObject, eventdata, gd)
if get(hObject,'Value')
    Fs = gd.Internal.daq.samplingFrequency;
    Triggers = generateTriggers(gd);
    if isempty(gd.Internal.viewHandle) || ~ishghandle(gd.Internal.viewHandle) % figure doesn't exist
        pos = get(gd.gui.fig,'OuterPosition');
        pos2 = get(gd.gui.stim.panel,'Position');
        pos = [pos(1),.1,pos(3),pos(2)+pos(4)*pos2(2)-.11];
        gd.Internal.viewHandle = figure('NumberTitle','off','Name','Single Trial Triggers',...
            'Units','normalized','OuterPosition',pos);
        guidata(hObject,gd);
    else
        figure(gd.Internal.viewHandle);
    end
    cla; hold on;
    Color = {'r','b','g','c'};
    x = [0,gd.Experiment.timing.baselineDur];
    y = [min(Triggers(:)),max(Triggers(:))];
    patch(x([1,1,2,2]),[y,flip(y)],Color{4},'EdgeAlpha',0,'FaceAlpha',.2);
    x = [gd.Experiment.timing.avgFirst,gd.Experiment.timing.avgLast];
    patch(x([1,1,2,2]),[y,flip(y)],Color{3},'EdgeAlpha',0,'FaceAlpha',.2);
    % area([0,gd.Experiment.timing.baselineDur],repmat(max(Triggers(:)),1,2),'FaceColor',Color{3},'EdgeColor',Color{3});
    % area([gd.Experiment.timing.avgFirst,gd.Experiment.timing.avgLast],repmat(max(Triggers(:)),1,2),'FaceColor',Color{4},'EdgeColor',Color{4});
    x = 0:1/Fs:(size(Triggers,1)-1)/Fs;
    for index = 1:2
        plot(x,Triggers(:,index),Color{index});
    end
    axis tight
    ylabel('Voltage');
    xlabel('Time (s)');
    legend('Baseline','Avg Period','Piezo','Camera');
    hold off;
else
    if ~isempty(gd.Internal.viewHandle) && ishghandle(gd.Internal.viewHandle) % figure doesn't exist
        delete(gd.Internal.viewHandle);
    end
end
end

function TestTriggers(hObject, eventdata, gd)
if get(hObject,'Value')
    DAQ = daq.createSession('ni');
    DAQ.Rate = gd.Internal.daq.samplingFrequency;
    PD = get(gd.gui.stim.piezos,'Data');
    ActivePiezos = [PD{:,1}];
    if ~any(ActivePiezos)
        set(hObject,'Value',false);
        error('Requires at least one active piezo!');
    end
    for index = find(ActivePiezos)
        [~,id] = DAQ.addAnalogOutputChannel(gd.Internal.daq.piezos.Device{index},gd.Internal.daq.piezos.Port{index},'Voltage');
        DAQ.Channels(id).Name = sprintf('O_Piezo%d',index);
    end
    
    Triggers = generateTriggers(gd);
    Triggers = repmat(Triggers(:,1),1,nnz(ActivePiezos));
    
    set(hObject,'String','Testing...'); drawnow;
    while get(hObject,'Value')
        DAQ.queueOutputData(Triggers);
        DAQ.startForeground;
        if ~get(hObject,'Value')
            break
        end
    end
    clear DAQ;
    set(hObject,'String','Test');
else
    set(hObject,'String','Stopping...'); drawnow;
end
end

function Triggers = generateTriggers(gd)
t = gd.Experiment.timing;
s = gd.Experiment.stim;
Fs = gd.Internal.daq.samplingFrequency;
Fr = gd.Experiment.imaging.frameRate;

% Initialize Triggers
trialDuration = t.baselineDur + t.stimDur + t.postDur;
numScansPerTrial = round(trialDuration*Fs);
Triggers = zeros(numScansPerTrial,2);

% Build piezo triggers
piezoTrigs = generatePiezoTrig(s.wailDuration, s.bidirectional, s.frequency, ceil(t.stimDur*Fs), Fs);
piezoTrigs = piezoTrigs*s.voltage; % scale to proper voltage
startTrig = round(t.baselineDur*Fs)+1;
endTrig = startTrig+numel(piezoTrigs)-1;
Triggers(startTrig:endTrig,1) = piezoTrigs;

% Add camera triggers
Triggers(1:ceil(Fs/Fr):end,2) = 1;
end

function trig = generatePiezoTrig(duration, bidirectional, freq, numScans, Fs)

% Create half wave
f = 1/duration;
t = (0:1/Fs:duration/2)';
halfwave = -0.5*cos(2*pi*f*t)+0.5;

% Create wave
if ~bidirectional
    wave = [halfwave;flip(halfwave)];
else
    
    % Create full wave
    f = 1/(2*duration);
    t = (0:1/Fs:duration)';
    midwave = cos(2*pi*f*t);

    wave = [halfwave;midwave;-flip(halfwave)];
end

% Determine if duration of wave is longer than single period for desired frequency
numScansPerWail = round(1/freq*Fs);
stim_lag = numScansPerWail - numel(wave);
if stim_lag < 0 %wave is longer than single period
    warning('Wail duration parameter is longer than single period for desired frequency. Frequency will set to the maximum frequency allowed with the given duration.');
    stim_lag = 0;
end

% Build single wail
single_stim = [wave;zeros(stim_lag,1)]; %single period
numScansPerWail = numel(single_stim);

% Build for entire duraiton
numWails = floor(numScans/numScansPerWail);
trig = repmat(single_stim,numWails,1);

end


%% Experiment
function RunExperiment(hObject, eventdata, gd)
if get(hObject,'Value')
    
    %% Check if any piezos are active
    PD = get(gd.gui.stim.piezos,'Data');
    ActivePiezos = [PD{:,1}];
    if ~any(ActivePiezos)
        set(hObject,'Value',false);
        error('No piezos active -> at least one piezo needs to be active');
    end
    
    %% Determine filename to save to
    if exist([gd.Internal.save.filename,'.mat'], 'file')
        answer = questdlg(sprintf('File already exists! Continue?\n%s', gd.Internal.save.filename), 'Overwrite file?', 'Yes', 'No', 'No');
        if strcmp(answer, 'No')
            set(hObject,'Value',false);
            return
        end
    end
    
    %% Update GUI
    set(hObject,'String','Stop','BackgroundColor',[0,1,0]);
    gd.Experiment.numStim = nnz(ActivePiezos);
    set(gd.gui.experiment.save,'BackgroundColor',[.94,.94,.94]);
    set([gd.gui.control.preview,gd.gui.control.capture,gd.gui.experiment.save],'Enable','off');
    set(gd.gui.experiment.restart,'Enable','on');
    if gd.Experiment.numStim>1
        set(gd.gui.experiment.link,'Enable','on');
    end
    gd.Internal.isRunning = true;
    guidata(hObject,gd);
    
    %% Initialize DAQ
    Fs = gd.Internal.daq.samplingFrequency;
    
    % Initialize DAQ
    DAQ = daq.createSession('ni');
    DAQ.Rate = Fs;
    % Piezos
    for index = find(ActivePiezos)
        [~,id] = DAQ.addAnalogOutputChannel(gd.Internal.daq.piezos.Device{index},gd.Internal.daq.piezos.Port{index},'Voltage');
        DAQ.Channels(id).Name = sprintf('O_Piezo%d',index);
    end
    % Camera
    [~,id]=DAQ.addDigitalChannel('Dev3','port0/line0','OutputOnly'); % camera trigger
    DAQ.Channels(id).Name = 'O_CameraTrigger';
    
    %% Create Triggers
    
    % Initialize Experiment struct
    gd.Experiment.filename = gd.Internal.save.filename;    % record file saved to
    gd.Experiment.timing.init = datestr(now);              % record date & time information
    
    % Create triggers
    Triggers = generateTriggers(gd);
    totalFrames = sum(Triggers(:,2)==1);
    frameTime = find(Triggers(:,2)==1)/Fs;
    badFrames = frameTime < .150; % camera doesn't expose fully until after ~150ms
    numBadFrames = nnz(badFrames);
    numFrames = floor((totalFrames-numBadFrames)/gd.Experiment.imaging.numFrames2Avg);
    lastFrameIndex = totalFrames - rem(totalFrames-numBadFrames,gd.Experiment.imaging.numFrames2Avg);
    
    % Determine frames to average over for baseline and stim

    firstFrame = frameTime(numBadFrames+1:gd.Experiment.imaging.numFrames2Avg:end);
    lastFrame = frameTime(numBadFrames+gd.Experiment.imaging.numFrames2Avg:gd.Experiment.imaging.numFrames2Avg:end);
    numBaselineFrames = nnz(lastFrame<=gd.Experiment.timing.baselineDur);
    first = repmat(find(firstFrame>=str2num(get(gd.gui.timing.avgFirst,'String')),1),1,gd.Experiment.numStim);
    last = repmat(find(lastFrame<=str2num(get(gd.gui.timing.avgLast,'String')),1,'last'),1,gd.Experiment.numStim);
    clear frameTime firstFrame lastFrame % save space in memory
    
    %% Initialize output and displays
    gd.Experiment.Trial = zeros(gd.Internal.imaging.dim(1),gd.Internal.imaging.dim(2),numFrames,gd.Experiment.numStim,'double');
    guidata(hObject,gd); % in case sliders are played with before first trial collected
    
    % Set values and update plots
    set([gd.gui.data(:).sliderText,gd.gui.data(:).slider],'Enable','on');
    for cindex = 1:gd.Experiment.numStim
        
        % Set slider values
        set(gd.gui.data(cindex).slider,'Min',1,'Max',numFrames,...
            'SliderStep',[1/(numFrames-1),min(10/(numFrames-1),numFrames)],...
            'Value',round(numFrames/2));
        set(gd.gui.data(cindex).first,'String',sprintf('First = %d',first(cindex)),...
            'UserData',{cindex,'first',first(cindex)});
        set(gd.gui.data(cindex).last,'String',sprintf('Last = %d',last(cindex)),...
            'UserData',{cindex,'last',last(cindex)});
        
        % Display images
        UpdatePlots(cindex,gd);
    end
    
    % Enable sliders and frame selections
    if get(gd.gui.experiment.link,'Value') % enable first condition
        set([gd.gui.data(2:end).slider],'Enable','off');
        set([gd.gui.data(1).first,gd.gui.data(1).last],'Enable','on');
    else % enable everything
        set([gd.gui.data(:).first,gd.gui.data(:).last],'Enable','on');
    end

    
    %% Run Experiment
    
    tindex = 1;
    while tindex < str2double(get(gd.gui.experiment.numTrials,'String')) && get(hObject,'Value')
        cindex = 1;
        while cindex <= gd.Experiment.numStim && get(hObject,'Value')
            fprintf('Sending triggers for trial %d, condition %d...\n',tindex,cindex);
            
            try
                % Initialize camera
                flushdata(gd.Internal.imaging.vid);
                % preview(gd.Internal.imaging.vid,hImage);
                try
                    start(gd.Internal.imaging.vid);
                catch % errored in previous session
                    stop(gd.Internal.imaging.vid);
                    flushdata(gd.Internal.imaging.vid);
                    start(gd.Internal.imaging.vid);
                end
                
                % Run trial
                currentTriggers = [repmat(Triggers(:,1),1,nnz(ActivePiezos)),Triggers(:,2)];
                currentTriggers(:,setdiff(1:gd.Experiment.numStim,cindex)) = 0;
                DAQ.queueOutputData(currentTriggers);
                DAQ.startBackground;
                while DAQ.IsRunning
                    pause(.2); % frees up command line for online analysis
                end
                time = tic;
                
                % Stop camera & gather frames
                % stoppreview(gd.Internal.imaging.vid);
                stop(gd.Internal.imaging.vid);
                vid_data = getdata(gd.Internal.imaging.vid,gd.Internal.imaging.vid.FramesAvailable);
                vid_data = squeeze(vid_data(1:gd.Internal.imaging.subsampleFactor:end,1:gd.Internal.imaging.subsampleFactor:end,1,numBadFrames+1:lastFrameIndex));
                vid_data = double(vid_data);
                vid_data = reshape(vid_data,gd.Internal.imaging.dim(1),gd.Internal.imaging.dim(2),gd.Experiment.imaging.numFrames2Avg,numFrames);
                vid_data = squeeze(mean(vid_data,3));
                
                % Analyze frames

                baseline = mean(vid_data(:,:,1:numBaselineFrames),3); % compute baseline
                vid_data = bsxfun(@rdivide,bsxfun(@minus,vid_data,baseline),baseline); % compute dI/I
                % vid_data = bsxfun(@minus, vid_data, permute(median(reshape(vid_data,prod(gd.Internal.imaging.dim),numFrames),1),[1,3,2])); % subtract off frame by frame median
                % vid_data = bsxfun(@minus, vid_data, permute(min(reshape(vid_data,prod(gd.Internal.imaging.dim),numFrames),[],1),[1,3,2]))+1; % rectify so minimal value is 1
                
                if tindex ~= 1
                    gd = guidata(hObject); % refresh ROI
                end
                if tindex == 1
                    gd.Experiment.Trial(:,:,:,cindex) = vid_data;
                else %if tindex < 10
                    gd.Experiment.Trial(:,:,:,cindex) = (tindex-1)/tindex*gd.Experiment.Trial(:,:,:,cindex) + 1/tindex*vid_data;
%                 else
%                     gd.Experiment.Trial(:,:,:,cindex) = .9*gd.Experiment.Trial(:,:,:,cindex) + .1*vid_data;
                end
                guidata(hObject,gd);
                
                % Update display
                UpdatePlots(cindex,gd);
                
                % Pause rest of ITI
                pause(toc(time)-gd.Experiment.timing.ITI);
                
                cindex = cindex + 1;
            catch
                fprintf('Last trial failed... trying again\n');
            end
            
            % Check if need to restart
            if get(gd.gui.experiment.restart,'Value')
                fprintf('User Restarted\n');
                tindex = 1;
                cindex = 1;
                set(gd.gui.experiment.restart,'Value',false);
            end
            
        end %condition
        tindex = tindex + 1;     
    end %trials
    
    % Record # of trials actually presented & update status
    gd.Experiment.timing.numTrials = tindex-1;
    gd.Internal.isRunning = false;
    guidata(hObject,gd);
    
    % Update GUI
    set(hObject,'Value',false); % in case max # of trials reached    
    set([gd.gui.control.preview,gd.gui.control.capture],'Enable','on');
    set(gd.gui.experiment.restart,'Enable','off');
    set(gd.gui.experiment.save,'Enable','on','BackgroundColor',[0,1,0]);
    set(hObject,'String','Run','BackgroundColor',[.94,.94,.94]);
    
else
    set(hObject,'String','Stopping...','BackgroundColor',[.94,.94,.94]);
    set(gd.gui.experiment.restart,'Enable','off');
end
end


function Link(hObject, eventdata, gd)
if get(hObject,'Value') % link axes
    set(gd.gui.data(2:end).slider,'Enable','off');
    set([gd.gui.data(2:end).first,gd.gui.data(2:end).last],'Enable','off');
else % unlink axes
    set(gd.gui.data(2:end).slider,'Enable','on');
    set([gd.gui.data(2:end).first,gd.gui.data(2:end).last],'Enable','on');
end
for cindex = 2:gd.Experiment.numStim
    UpdatePlots(cindex,gd);
end
end


function UpdatePlots(cindex, gd)
ChangeImage(gd.gui.data(cindex).slider, [], gd); % change one or all selection axes
if ~get(gd.gui.experiment.link,'Value')
    UpdateMean(cindex,gd); % change current mean axis
else
    for index = 1:gd.Experiment.numStim % change all mean axes
        UpdateMean(index,gd);
    end
end
end

function ChangeImage(hObject, eventdata, gd)
cindex = get(hObject,'UserData');
if cindex==1 || ~get(gd.gui.experiment.link,'Value')
    val = round(get(hObject,'Value'));
    rindex = cindex;
else
    val = round(get(gd.gui.data(1).slider,'Value'));
    set(gd.gui.data(cindex).slider,'Value',val);
    rindex = 1;
end
set(gd.gui.data(cindex).sliderText,'String',val);
img = gd.Experiment.Trial(:,:,val,cindex);
axes(gd.gui.data(cindex).axesImg);
if isempty(gd.Internal.ROI.pos)
    imagesc(img);
    axis off;
else
    temp = createMask(gd.Internal.ROI.handle);
    CLim = [min(min(img(temp))),max(max(img(temp)))];
    if any(CLim)
        imagesc(img,CLim);
    else
        imagesc(img);
    end
    axis off;
    hold on;
    plot(gd.Internal.ROI.pos([1:end,1],1),gd.Internal.ROI.pos([1:end,1],2),'r-','LineWidth',2);
    hold off;
end

if cindex==1 && get(gd.gui.experiment.link,'Value')
    for index = 2:gd.Experiment.numStim
        ChangeImage(gd.gui.data(index).slider,[],gd);
    end
end
end

function SetMean(hObject, eventdata, gd)
temp = get(hObject,'UserData');
cindex = temp{1};
val = round(get(gd.gui.data(cindex).slider,'Value'));
switch temp{2}
    case 'first'
        set(hObject,'String',sprintf('First = %d',val),'UserData',{cindex,'first',val});
    case 'last'
        set(hObject,'String',sprintf('Last = %d',val),'UserData',{cindex,'last',val});
end
if ~get(gd.gui.experiment.link,'Value')
    UpdateMean(cindex,gd);
else
    for index = 1:gd.Experiment.numStim
        UpdateMean(index,gd);
    end
end
end

function UpdateMean(cindex, gd)
if ~get(gd.gui.experiment.link,'Value')
    index = cindex;
else
    index = 1;
end
f = get(gd.gui.data(index).first,'UserData');
l = get(gd.gui.data(index).last,'UserData');
Mean = mean(gd.Experiment.Trial(:,:,f{3}:l{3},cindex),3);
axes(gd.gui.data(cindex).axesMean);
if isempty(gd.Internal.ROI.pos)
    imagesc(Mean);
    axis off;
else
    temp = createMask(gd.Internal.ROI.handle);
    CLim = [min(min(Mean(temp))),max(max(Mean(temp)))];
    if any(CLim)
        imagesc(Mean,CLim);
    else
        imagesc(Mean);
    end
    axis off;
    hold on;
    plot(gd.Internal.ROI.pos([1:end,1],1),gd.Internal.ROI.pos([1:end,1],2),'r-','LineWidth',2);
    hold off;
end
end


function Save(hObject, eventdata, gd)
set(hObject,'String','Saving...','BackgroundColor',[1,0,0],'Enable','off');

% Collect analyses
Experiment = gd.Experiment;
if isempty(gd.Internal.ROI.pos)
    Experiment.ROI = [];
else
    Experiment.ROI = createMask(gd.Internal.ROI.handle);
end
Mean = nan(gd.Internal.imaging.dim(1),gd.Internal.imaging.dim(2),Experiment.numStim);
for cindex = 1:Experiment.numStim
    if get(gd.gui.experiment.link,'Value')
        index = 1;
    else
        index = cindex;
    end
    temp = get(gd.gui.data(index).first,'UserData');
    Experiment.timing.avgFirst(cindex) = temp{3};
    temp = get(gd.gui.data(index).last,'UserData');
    Experiment.timing.avgLast(cindex) = temp{3};
    Mean(:,:,cindex) = mean(Experiment.Trial(:,:,Experiment.timing.avgFirst(cindex):Experiment.timing.avgLast(cindex),cindex),3);
end
Experiment.Trial = []; % saving is much faster

% Determine CLim
CLim = nan(Experiment.numStim,2);
for cindex = 1:Experiment.numStim
    temp = Mean(:,:,cindex);
    if ~isempty(Experiment.ROI)
        CLim(cindex,:) = [min(temp(Experiment.ROI)),max(temp(Experiment.ROI))];
    else
        CLim(cindex,:) = [min(temp(:)),max(temp(:))];
    end
end

% Save outputs to files
fprintf('Saving %d trials to file...',Experiment.timing.numTrials);
save([Experiment.filename,'.mat'],'Experiment','Mean','-v7.3');
for cindex = 1:gd.Experiment.numStim
    figure('Name',sprintf('Stimulus %d final',cindex));
    imagesc(Mean(:,:,cindex),CLim(cindex,:)); colormap gray; axis off;
    Image = getframe(gca);
    Image = Image.cdata;
    imwrite(Image,[Experiment.filename,'_cond',num2str(cindex),'.tif']); % needs to have CLim
end
fprintf('\tComplete\n');
        
% Select Centroids
loc = UIcentroid(Mean,Experiment.GreenImage,...
    'ROI',Experiment.ROI,...
    'Save',[Experiment.filename,'_centroids.tif']);
save([Experiment.filename,'.mat'],'loc','-append');

% Update GUI
set(gd.gui.file.index,'String',num2str(str2num(get(gd.gui.file.index,'String'))+1)); % update index
CreateFilename(gd,false); % update filename

set(hObject,'String','Save & Mark','BackgroundColor',[.94,.94,.94],'Enable','on');
end