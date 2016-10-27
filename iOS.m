function iOS

% Initialize Saving
gd.Internal.save.path = cd;
gd.Internal.save.base = '0000_c2';
gd.Internal.save.index = '1';
% gd.Internal.save.filename = fullfile(gd.Internal.save.path, strcat(gd.Internal.save.base, gd.Internal.save.index));

% Initialize Timing
gd.Experiment.timing.baselineDur = .5;      %seconds
gd.Experiment.timing.stimDur = 4;           %seconds
gd.Experiment.timing.postDur = 0;           %seconds
gd.Experiment.timing.ITI = 2;               %seconds
gd.Experiment.timing.numTrials = 35;
gd.Experiment.timing.avgFirst = gd.Experiment.timing.baselineDur;
gd.Experiment.timing.avgLast = gd.Experiment.timing.baselineDur+gd.Experiment.timing.stimDur+gd.Experiment.timing.postDur;

% Initialize Stimulus
gd.Experiment.stim.frequency = 10;          %hz
gd.Experiment.stim.wailDuration = 0.02;     %seconds
gd.Experiment.stim.voltage = 5;             %volts
gd.Experiment.stim.bidirectional = false;   %boolean

% Initialize Imaging
gd.Internal.imaging.port = 'COM5';
gd.Internal.imaging.initFile = 'C:\Users\User\Documents\MATLAB\iOS\CamFiles\T_1m60_12-bits_2_tap_ext_trig.ccf';
gd.Experiment.imaging.frameRate = 59;   %hz
gd.Experiment.GreenImage = [];
% gd.Experiment.imaging.gain = 0;
% gd.Experiment.imaging.exposure = 0;

% Default Settings
gd.Internal.daq.samplingFrequency = 30000;
gd.Internal.daq.piezos = table({true;true},{'Dev3';'Dev3'},{'ao0';'ao1'},'VariableNames',{'Active','Device','Port'});
% gd.Internal.daq.camera = table({'Dev1'},{'port0/line2'},{'D'},'VariableNames',{'Device','Port','Type'});
gd.Internal.isRunning = false;
gd.Internal.viewHandle = [];

% Display parameters
Display.units = 'pixels';
Display.position = [100, 100, 1000, 600];


%% Generate GUI

% Create figure
gd.gui.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'Intrinsic Optical Signal Imaging',...
    'Units',                Display.units,...
    'Position',             Display.position,...
    'ToolBar',              'none',...
    'MenuBar',              'none');

% Create file selection
% panel
gd.gui.file.panel = uipanel(...
    'Title',                'File Information',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .8, 1, .2]);
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
    'Position',             [.25,.3,.5,.5],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject),true));
gd.gui.file.baseText = uicontrol(...
    'Style',                'text',...
    'String',               'Basename',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.25,.8,.5,.2]);
% file index
gd.gui.file.index = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.index,...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.3,.15,.5],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject),false));
gd.gui.file.indexText = uicontrol(...
    'Style',                'text',...
    'String',               'File Index',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.8,.15,.2]);
% display filename
gd.gui.file.filename = uicontrol(...
    'Style',                'text',...
    'String',               '',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.2,.05,.8,.2]);

% Create axes
% panel
gd.gui.axes.panel = uipanel(...
    'Title',                'Images',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .4, 1, .4]);
% first axes
gd.gui.axes.first = axes(...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,.33,1]);
axis off
% second axes
gd.gui.axes.second = axes(...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [.33,0,.34,1]);
axis off
% third axes
gd.gui.axes.third = axes(...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [.66,0,.33,1]);
axis off

% Create image control
gd.gui.control.panel = uipanel(...
    'Title',                'Prep',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0,0,.15,.4]);
% preview
gd.gui.control.preview = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Preview',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,1,.2],...
    'Callback',             @(hObject,eventdata)PreviewImage(hObject, eventdata, guidata(hObject)));
% capture image
gd.gui.control.capture = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Capture Image',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.4,1,.2],...
    'BackgroundColor',      [1,0,0],...
    'Callback',             @(hObject,eventdata)CaptureImage(hObject, eventdata, guidata(hObject)));
% live histogram
gd.gui.control.histogram = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Histogram',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.7,.7,.1]);
% select ROI
gd.gui.control.selectROI = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Select ROI',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.1,1,.2],...
    'BackgroundColor',      [1,0,0],...
    'Callback',             @(hObject,eventdata)SelectROI(hObject, eventdata, guidata(hObject)));
% use ROI
gd.gui.control.ROItoggle = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Use ROI?',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Enable',               'off',...
    'Position',             [0,0,1,.1]);

% Create timing control
gd.gui.timing.panel = uipanel(...
    'Title',                'Timing',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.15,0,.2,.4]);
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
% Frame rate
gd.gui.timing.frameRate = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.timing.panel,...
    'String',               gd.Experiment.imaging.frameRate,...
    'Units',                'normalized',...
    'Position',             [.7,.1,.3,.15],...
    'UserData',             {'imaging','frameRate', 0, 59},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.timing.frameRateText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.timing.panel,...
    'String',               'Frame Rate (Hz)',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.1,.65,.1]);

% Create stimulus control
gd.gui.stim.panel = uipanel(...
    'Title',                'Stimulus',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.35,0,.3,.4]);
% Piezo 2 toggle
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

% Create experiment control
gd.gui.experiment.panel = uipanel(...
    'Title',                'Experiment',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.65,0,.35,.4]); % [.6,.1,.4,.3]
% Number of Trials
gd.gui.experiment.numTrials = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               gd.Experiment.timing.numTrials,...
    'Units',                'normalized',...
    'Position',             [0,.7,.5,.15],...
    'UserData',             {'timing','numTrials', 1, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.experiment.numTrialsText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               '# Trials',...
    'HorizontalAlignment',  'center',...
    'Units',                'normalized',...
    'Position',             [0,.85,.5,.1]);
% Frames to average
gd.gui.experiment.avgFirst = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               gd.Experiment.timing.avgFirst,...
    'Units',                'normalized',...
    'Position',             [0,.4,.25,.15],...
    'UserData',             {'timing','avgFirst', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.experiment.avgLast = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               gd.Experiment.timing.avgLast,...
    'Units',                'normalized',...
    'Position',             [.25,.4,.25,.15],...
    'UserData',             {'timing','avgLast', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.experiment.avgText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.experiment.panel,...
    'String',               'Average Range (s)',...
    'HorizontalAlignment',  'center',...
    'Units',                'normalized',...
    'Position',             [0,.55,.5,.1]);
% Run experiment
gd.gui.experiment.run = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Run',...
    'Parent',               gd.gui.experiment.panel,...
    'Units',                'normalized',...
    'Position',             [.5,.7,.5,.3],...
    'BackgroundColor',      'green',...
    'Callback',             @(hObject,eventdata)RunExperiment(hObject, eventdata, guidata(hObject)));
% Restart experiment
gd.gui.experiment.restart = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Restart',...
    'Parent',               gd.gui.experiment.panel,...
    'Units',                'normalized',...
    'Position',             [.5,.35,.5,.3],...
    'Enable',               'off');
% Abort experiment
gd.gui.experiment.abort = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Abort',...
    'Parent',               gd.gui.experiment.panel,...
    'Units',                'normalized',...
    'Position',             [.5,0,.5,.3],...
    'Enable',               'off');

% % Create post processing
% gd.gui.post.panel = uipanel(...
%     'Title',                'Post-processing',...
%     'Parent',               gd.gui.fig,...
%     'Units',                'Normalized',...
%     'Position',             [.6,0,.4,.1]);
% gd.gui.post.centroids = uicontrol(...
%     'Style',                'pushbutton',...
%     'String',               'Select Centroids',...
%     'Parent',               gd.gui.post.panel,...
%     'Units',                'normalized',...
%     'Position',             [0,0,1,1],...
%     'Enable',               'off',...
%     'Callback',             @(hObject,eventdata)SelectCentroids(hObject, eventdata, guidata(hObject)));

gd = CreateFilename(gd,false);    % create initial filename
try
    initCamera(gd);         % initialize camera
catch
    error('Camera not found -> try restarting MATLAB');
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

% Reset base
if reset
    set([gd.gui.control.capture,gd.gui.control.selectROI],'BackgroundColor',[1,0,0]);
    set(gd.gui.control.selectROI,'UserData',[]);
    set(gd.gui.control.ROItoggle,'Enable','off');
    gd.Experiment.GreenImage = [];
end

guidata(gd.gui.fig, gd);

% Check if file exists
if exist([gd.Internal.save.filename,'.mat'], 'file')
    set(gd.gui.file.filename,'BackgroundColor',[1,0,0]);
else
    set(gd.gui.file.filename,'BackgroundColor',[.94,.94,.94]);
end
end

%% Prep
function initCamera(gd)

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

guidata(gd.gui.fig, gd);
end

function PreviewImage(hObject, eventdata, gd)
if get(hObject,'Value')
    set(gd.gui.experiment.panel,'Visible','off');
    set([gd.gui.control.capture,gd.gui.control.selectROI,gd.gui.control.histogram],'Enable','off');
    set(hObject,'String','Stop Preview','BackgroundColor',[0,0,0],'ForegroundColor',[1,1,1]);
    temp_img = zeros(gd.Internal.imaging.vid.Videoresolution);  %initialize image
    hImage = image(temp_img,'Parent',gd.gui.axes.first);        %initialize handle
    if get(gd.gui.control.histogram,'Value')                           %check if need to show live histogram
        setappdata(hImage,'UpdatePreviewWindowFcn',@iOS_update_livehistogram_display);
    end
    preview(gd.Internal.imaging.vid,hImage)                                 %start preview
else
    set(hObject,'String','Stopping...'); drawnow;
    stoppreview(gd.Internal.imaging.vid);                                    %stop preview
    set(gd.gui.experiment.panel,'Visible','on');
    set([gd.gui.control.capture,gd.gui.control.selectROI,gd.gui.control.histogram],'Enable','on');
    set(hObject,'String','Preview','BackgroundColor',[.94,.94,.94],'ForegroundColor',[0,0,0]);
end
end

function iOS_update_livehistogram_display(obj,event,hImage)
set(hImage,'CData',event.Data);
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
img = captureSingleFrame(gd);
gd.Experiment.GreenImage = img;
guidata(hObject,gd);
imwrite(img,strcat(gd.Internal.save.basename,'_','green_image.tif')); %save to file (overwrites any previous image)
set(hObject,'String','Capture Image','BackgroundColor',[0,1,0]);
end

function img = captureSingleFrame(gd)
temp_img = zeros(get(gd.Internal.imaging.vid,'Videoresolution'));   %initialize image
hImage = image(temp_img,'Parent',gd.gui.axes.first);    %initialize handle
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
if ~gd.Internal.isRunning
    img = captureSingleFrame(gd);
elseif ~isempty(gd.Experiment.GreenImage)
    img = gd.Experiment.GreenImage;
else
    error('Experiment is running and no green image is saved!');
end
img = double(img);
img = (img-min(img(:)))/range(img(:));
h = figure;
BW = roipoly(img);
% BW = roipoly(single(img)./(2^12-1));
close(h);
set(hObject,'UserData',BW,'BackgroundColor',[0,1,0]); % save ROI to UserData
set(gd.gui.control.ROItoggle,'Enable','on');
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
    if isempty(gd.Internal.viewHandle) || ~isvalid(gd.Internal.viewHandle) % figure doesn't exist
        gd.Internal.viewHandle = figure('NumberTitle','off','Name','Single Trial Triggers');
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
    if ~isempty(gd.Internal.viewHandle) && isvalid(gd.Internal.viewHandle) % figure doesn't exist
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
    
    %% Determine filename to save to
    if exist([gd.Internal.save.filename,'.mat'], 'file')
        answer = questdlg(sprintf('File already exists! Continue?\n%s', gd.Internal.save.filename), 'Overwrite file?', 'Yes', 'No', 'No');
        if strcmp(answer, 'No')
            set(hObject,'Value',false);
            return
        end
    end
    
    %% Update GUI
    set([gd.gui.experiment.abort,gd.gui.experiment.restart],'Enable','on');
    gd.Internal.isRunning = true;
    guidata(hObject,gd);
    
    %% Initialize DAQ
    Fs = gd.Internal.daq.samplingFrequency;
    
    % Determine active piezos
    PD = get(gd.gui.stim.piezos,'Data');
    ActivePiezos = [PD{:,1}];
    if ~any(ActivePiezos)
        error('No piezos active -> at least one piezo needs to be active');
    end
    numConditions = nnz(ActivePiezos);
    
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
    Experiment = gd.Experiment;
    Experiment.filename = gd.Internal.save.filename;    % record file saved to
    Experiment.timing.init = datestr(now);              % record date & time information
    
    % Create triggers
    Triggers = generateTriggers(gd);
    numFrames = sum(Triggers(:,2)==1);
    numBaselineFrames = sum(Triggers(1:round(Experiment.timing.baselineDur*Fs),2));
    frameTime = find(Triggers(:,2)==1)/Fs;
    
    %% Run Experiment

    % Update gui
    set(hObject,'String','Stop & Save');
    
    % Initialize display
    dim = gd.Internal.imaging.vid.Videoresolution;
    image(zeros(dim),'Parent',gd.gui.axes.second); axis off;
    image(zeros(dim),'Parent',gd.gui.axes.third); axis off;
    
    delta = nan(dim(1), dim(2), numConditions, numFrames, gd.gui.timing.numTrials);
    tindex = 1;
    while tindex < gd.gui.timing.numTrials && get(hObject,'Value') && ~get(gd.gui.experiment.abort,'Value')
        for cindex = 1:numConditions
            fprintf('Sending triggers for trial %d, condition %d...\n',tindex,cindex);
            
            % Initialize camera
            flushdata(gd.Internal.imaging.vid);
            % preview(gd.Internal.imaging.vid,hImage);
            start(gd.Internal.imaging.vid);
            
            % Run trial
            currentTriggers = [repmat(Triggers(:,1),1,numel(ActivePiezos)),Triggers(:,2)];
            currentTriggers(:,setdiff(1:numConditions,cindex)) = 0;
            DAQ.queueOutputData(currentTriggers);
            DAQ.startForeground;
            
            % Stop camera & gather frames
            % stoppreview(gd.Internal.imaging.vid);
            stop(gd.Internal.imaging.vid);
            time = tic;
            vid_data = getdata(gd.Internal.imaging.vid,gd.Internal.imaging.vid.FramesAvailable);
            
            % Analyze frames
            baseline = mean(vid_data(:,:,1,1:numBaselineFrames),4);
            delta(:,:,cindex,:,tindex) = bsxfun(@rdivide,bsxfun(@minus,vid_data(:,:,1,:),baseline),baseline);
            first = find(frameTime>=str2num(get(gd.gui.timing.avgFirst,'String')),1);
            last = find(frameTime<=str2num(get(gd.gui.timing.avgLast,'String')),1,'last');
            Mean = nanmean(nanmean(delta(:,:,cindex,first:last,:),5),4); % mean across trials, then across frames
            
            % Display updated images
            axes(gd.gui.axes.second);
            imagesc(Mean); axis off;
            if get(gd.gui.control.ROItoggle,'Value')
                axes(gd.gui.axes.third);
                Mean(~get(gd.gui.control.selectROI,'UserData')) = -inf;
                imagesc(Mean); axis off;
            end
            
            % Check if need to restart
            if get(gd.gui.experiment.restart,'Value')
                fprintf('User Restarted\n');
                delta = nan(dim(1), dim(2), numConditions, numFrames, gd.gui.timing.numTrials);
                tindex = 1;
                set(gd.gui.experiment.restart,'Value',false);
            end
            
            pause(toc(time)-Experiment.timing.ITI); % pause rest of ITI
        end %condition
        tindex = tindex + 1;
    end %trials
    
    % Save results
    if ~get(gd.gui.experiment.abort,'Value')
        
        % Save outputs to struct
        Experiment.timing.numTrials = tindex-1;
        Experiment.timing.avgFirst = find(frameTime>=str2num(get(gd.gui.timing.avgFirst,'String')),1);
        Experiment.timing.avgLast = find(frameTime<=str2num(get(gd.gui.timing.avgLast,'String')),1,'Last');
        Experiment.ROI = get(gd.gui.control.selectROI,'UserData');
        Experiment.Trial = nanmean(delta,5);
        Experiment.Mean = mean(Experiment.Trial(:,:,:,Experiment.timing.avgFirst:Experiment.timing.avgLast),4);
        
        % Save outputs to files
        fprintf('Saving %d trials to file...',Experiment.timing.numTrials);
        save([Experiment.filename,'.mat'],'Experiment');
        for cindex = 1:numConditions
            imwrite(Experiment.Mean(:,:,cindex),[Experiment.filename,'_cond',num2str(cindex),'.tif']);
        end
        fprintf('\tComplete\n');
        
        % Select Centroids
        UIcentroid([Experiment.filename,'.mat'],[],'Save',[Experiment.filename,'_centroids.tif']);
        
        % Update GUI
        set(gd.gui.file.index,'String',num2str(str2num(get(gd.gui.file.index,'String'))+1)); % update index
        CreateFilename(gd,false); % update filename
        
    else % user aborted
        fprintf('User Aborted\n');
        set(gd.gui.experiment.abort,'Value',false);
        set(hObject,'Value',false);
    end
    
    % Update GUI
    gd.Internal.isRunning = false;
    set([gd.gui.experiment.abort,gd.gui.experiment.restart],'Enable','off');
    guidata(hObject,gd);
    set(hObject,'String','Run');
    
else
    set(hObject,'String','Stopping...');
end
end

