function varargout = iOS_Imager(varargin)
% IOS_IMAGER MATLAB code for iOS_Imager.fig
%      IOS_IMAGER, by itself, creates a new IOS_IMAGER or raises the existing
%      singleton*.
%
%      H = IOS_IMAGER returns the handle to a new IOS_IMAGER or the handle to
%      the existing singleton*.
%
%      IOS_IMAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IOS_IMAGER.M with the given input arguments.
%
%      IOS_IMAGER('Property','Value',...) creates a new IOS_IMAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iOS_Imager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iOS_Imager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iOS_Imager

% Last Modified by GUIDE v2.5 02-Apr-2014 15:05:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iOS_Imager_OpeningFcn, ...
                   'gui_OutputFcn',  @iOS_Imager_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before iOS_Imager is made visible.
function iOS_Imager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iOS_Imager (see VARARGIN)

% Choose default command line output for iOS_Imager
handles.output = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Initialize Camera and NIDAQ and set default values
[handles.vid, handles.src, handles.ni] = iOS_Initialization;

if exist('C:\Users\User\Documents','dir') == 7;
    handles.user_dir = 'C:\Users\User\Documents';
    set(handles.pwd_text,'String',['pwd: ' 'C:\Users\User\Documents'])
else
    handles.user_dir = userpath;
    set(handles.pwd_text,'String',['pwd: ' userpath])
end

handles.trial_length = 4.0; %seconds
handles.num_cond = 1; %num of conditions (i.e. how many whiskers will be stimulated)
handles.fps = 59; %frames per second
handles.rise_time = 0.010; %seconds
handles.fall_time = 0.010; %seconds
handles.piez_amp = 5.0; %volts
handles.stim_freq = 20; %Hz
handles.stim_start = 1.0; %seconds
handles.num_trials = 35; %num trials per condition
handles.iti = 8; %seconds
handles.end_buffer = 0.250; %seconds. Adds on this amount of time to trial time. This ensures that the nidaq captures the last frame and that everything has time to get reset to zero after stimulation
handles.hist = 0;
handles.fname = 'test';
handles.sess_name =  's1';
handles.stimulus = 0;
handles.square_high_time = 0.030;
handles.square_low_time = 0.070;
handles.square_amp = 5;
handles.num_steps = 400;
handles.roi_active = 0;
handles.BW = -1;
handles.use_roi = 0;
handles.view_roi = 0;
handles.overwrite_map = 0;
handles.abort_save = 0;
handles.sort = 0;
handles.exp_running = 1;
handles.abort = 0;

set(handles.trial_length_bx,'String',handles.trial_length)
set(handles.num_cond_bx,'String',handles.num_cond)
set(handles.fps_bx,'String',handles.fps)
set(handles.rise_time_bx,'String',handles.rise_time)
set(handles.fall_time_bx,'String',handles.fall_time)
set(handles.piez_amp_bx,'String',handles.piez_amp)
set(handles.stim_freq_bx,'String',handles.stim_freq)
set(handles.stim_start_bx,'String',handles.stim_start)
set(handles.num_trials_bx,'String',handles.num_trials)
set(handles.iti_bx,'String',handles.iti)
set(handles.resp_ratio_axes,'xtick',[],'ytick',[])
set(handles.preview_axes,'xtick',[],'ytick',[])
set(handles.roi_axes,'xtick',[],'ytick',[])
set(handles.live_hist,'Value',0)
set(handles.f_name,'String','test');
set(handles.session_name,'String','s1');
set(handles.square_high_time_bx,'String',handles.square_high_time);
set(handles.square_low_time_bx,'String',handles.square_low_time);
set(handles.square_amp_bx,'String',handles.square_amp);
set(handles.num_steps_bx,'String',handles.num_steps);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iOS_Imager wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iOS_Imager_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function trial_length_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
handles.trial_length = val;
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function trial_length_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_cond_bx_Callback(hObject, eventdata, handles)
val = abs(str2double(get(hObject,'String')));
if val > 2
    warndlg(sprintf('iOS Imager can only run 2 conditions\nMore conditions will be implemented in a future release\nSetting condition number to 2'));
    val = 2;
    set(hObject,'String',num2str(val))
end
handles.num_cond = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function num_cond_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fps_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
if val > 59
    warndlg(sprintf('Frame rate cannot be greater than 59 fps\nSetting Frame Rate to max rate'))
    val = 59;
    set(hObject,'String','59')
end
handles.fps = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function fps_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rise_time_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
if val < 0.001
    warndlg(sprintf('Rise time cannot be less than 0.001s\nSetting to min rise time'))
    val = 0.001;
    set(hObject,'String','0.001')
end
handles.rise_time = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function rise_time_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fall_time_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
if val < 0.001
    warndlg(sprintf('Fall time cannot be less than 0.001s\nSetting to min fall time'))
    val = 0.001;
    set(hObject,'String','0.001')
end
handles.fall_time = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function fall_time_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function piez_amp_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
if val > 5 || val < 0
    warndlg(sprintf('Piezo amplitude cannot exceed the range of 0-5v\nSetting to default'))
    val = 3;
    set(hObject,'String','3.0')
end
handles.piez_amp = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function piez_amp_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stim_freq_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));

if val < 0
    warndlg(sprintf('Stim frequency cant be negative\nSetting to absolute value of entry'))
    val = abs(val);
    set(hObject,'String',num2str(val))
end

wail_lag = ((1/val)-(handles.rise_time + handles.fall_time));

if wail_lag < 0
    val = 1/(handles.rise_time + handles.fall_time);
    warndlg(sprintf(['Stim frequency is to high for current deflection time\nSetting to max possible frequency: ',num2str(val)]))
    set(hObject,'String',num2str(val))
end

handles.stim_freq = val;
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function stim_freq_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stim_start_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
if val >= handles.trial_length
    warndlg('Stim start time cant be greater than trial time\n Setting to half of trial time')
    val = handles.trial_length/2;
    set(hObject,'String',num2str(val))
end
handles.stim_start = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function stim_start_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_trials_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));

if val ~= ceil(val)
    warndlg(sprintf('Number of trials needs to be an integer\nRounding up to nearest int'))
    val = ceil(val);
    set(hObject,'String',num2str(val))
end

handles.num_trials = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function num_trials_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iti_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
handles.iti = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function iti_bx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function trial_preview_Callback(hObject, eventdata, handles)
[stim, ~, cam_trig, t] = iOS_OutputSignals(handles);

figure
plot(t,cam_trig,t,stim,'k')
xlim([t(1) t(end)]);
xlabel('Time (s)')
ylabel('Potential (V)')


% --- Executes on button press in exp_start.
function exp_start_Callback(hObject, eventdata, handles)

if get(hObject,'Value')==0 && handles.exp_running == 1;
    set(hObject,'Value',1)
    disp('Restarted Session')
elseif get(hObject,'Value')==1 && handles.exp_running == 0;
    handles.exp_running = 1;
    guidata(hObject, handles);
end

flushdata(handles.vid)
user_dir = handles.user_dir;
trial_length = handles.trial_length;
num_cond = handles.num_cond;
fps = handles.fps;
rise_time = handles.rise_time;
fall_time = handles.fall_time;
piez_amp = handles.piez_amp;
stim_freq = handles.stim_freq;
stim_start = handles.stim_start;
num_trials = handles.num_trials;
iti = handles.iti;
end_stim_time = trial_length - (trial_length-stim_start)/4;
fname = handles.fname;
sess_name = handles.sess_name;
sr = handles.ni.Rate;
preview_state = get(handles.preview_butt,'Value');
BW = handles.BW;
use_roi = handles.use_roi;
view_roi = handles.view_roi;
repeat_trial = 0;


dsamp_n = 5; % downsample factor to make processing faster
dsamp_Fs = floor(sr/dsamp_n);
t = 0:1/dsamp_Fs:(trial_length - 1/dsamp_Fs);
running_indices = find(t > 0 & t < end_stim_time);
[smooth_win, FWHM] = MakeGaussWindow(round(dsamp_Fs*1.0),23.5/2, dsamp_Fs);
sw_len = length(smooth_win);

if preview_state == 1
    set(handles.preview_butt,'Value',0)    
end

set(handles.exp_status,'String','Exp Status: RUNNING')
set(hObject,'String','RESTART','BackgroundColor',[1 119/255 0],'ForegroundColor',[0 0 0])
temp_img = zeros(get(handles.vid,'Videoresolution'));
hImage = image(temp_img,'Parent',handles.preview_axes);
axes(handles.resp_ratio_axes)

% Make cell for collecting raw data
raw_sum_cell = cell(handles.num_cond,1); %update with running sum
vidRes = [get(handles.vid,'Videoresolution'),1,handles.fps*handles.trial_length]; %images are saved in a 4 dimensional matrix
for cond_num = 1:handles.num_cond
    raw_sum_cell{cond_num,1} = zeros(vidRes,'single');
end

% Make output signals
[stim, nostim, cam_trig, ~] = iOS_OutputSignals(handles);

curr_trial = 1;
cond_num = 1;
drawnow
while curr_trial <= num_trials
    
    if strcmp(get(handles.vid,'Running'),'off')
        
        while cond_num <= num_cond
            
            if repeat_trial
                repeat_trial = 0;
            end
            
            if handles.stimulus < 2
                if cond_num == 1
                    output_waves = [stim, nostim, cam_trig, nostim, nostim];
                elseif cond_num == 2
                    output_waves = [nostim, stim, cam_trig, nostim, nostim];
                end
            elseif handles.stimulus == 2;
                stepper_signals = iOS_StepperControl(handles);
                output_waves = [nostim, nostim, cam_trig, stepper_signals];
            end
                    
            
            
            flushdata(handles.vid)
            preview(handles.vid,hImage)
            start(handles.vid)
            
            handles.ni.queueOutputData(output_waves);
            if ~handles.ni.IsRunning
                disp(['Sending data for trial number: ' num2str(curr_trial) ' cond: ' num2str(cond_num)])
                data = handles.ni.startForeground;
            end
            
            disp('done sending waves')
            
            stoppreview(handles.vid)
            stop(handles.vid);

            frames_available = handles.vid.FramesAvailable;
            if frames_available
                vid_data = getdata(handles.vid,frames_available);
                
                %Process Signal
                tic;

                
                x_t = downsample(data,dsamp_n);
                x_t(end+1:end+sw_len) = x_t(end); %pad with last value for length of                                                             smoothing kernel
                d_smooth_win = [0;diff(smooth_win)]/(1/dsamp_Fs);
                dx_dt = conv(x_t,d_smooth_win,'same');
                dx_dt(end-sw_len+1:end) = []; %remove values produced by convolving                                                  kernel with padded values

                if handles.sort && mean(dx_dt(running_indices)) > 100
                    cont_processing = 1;
                elseif ~handles.sort;
                    cont_processing = 1;
                else
                    cont_processing = 0;
                end
                
                if cont_processing
                    try
                        raw_sum_cell{cond_num,1} = raw_sum_cell{cond_num,1} + single(vid_data(:,:,1,2:end)); %drops first frame which occurrs before the real trial begins
                    catch
                        
                        disp('ERROR when adding frames, saving data')
                        proc_time = toc;
                        proc_image_cell = cell(size(raw_sum_cell,1),2);
                        for k = 1:size(raw_sum_cell,1)
                            [proc_image_cell{k,1}, proc_image_cell{k,2}] = iOS_OnlineProcessor(raw_sum_cell{k,1}, curr_trial, handles);
                        end
                        save([user_dir filesep fname '_' sess_name '.mat'],...
                            'proc_image_cell','user_dir','trial_length','num_cond','fps','rise_time',...
                            'fall_time','piez_amp','stim_freq','stim_start','num_trials','iti',...
                            'fname','sess_name','sr','BW')
                    end
                    clear vid_data
                    [proc_img, deltai] = iOS_OnlineProcessor(raw_sum_cell{cond_num,1}, curr_trial, handles);
                    proc_time = toc;
                    time_remaining = handles.iti - proc_time;
                    
                    if time_remaining < handles.iti
                        pause(time_remaining)
                    end
                    
                    %Plot Processed Signal, Use ROI if active
                    axes(handles.resp_ratio_axes)
                    
                    if curr_trial == 1
                        cla(handles.resp_ratio_axes,'reset')
                    end
                    
                    %                 proc_img(proc_img < 0.15) = 0;
                    imshow(proc_img)
                    
                    if view_roi
                        hold on
                        plot(handles.roi_x,handles.roi_y)
                        hold off
                    end
                    
                    if use_roi
                        roi_deltai = deltai(BW);
                        roi_min_val = mean2(roi_deltai)-3*std2(roi_deltai);
                        
                        shift2zero = roi_deltai - roi_min_val;
                        roi_max_val = mean2(shift2zero)+3*std2(shift2zero);
                        scale_vals = shift2zero*(1/roi_max_val);
                        scale_vals(scale_vals < 0.15) = 0;
                        roi_proc_img = ones(size(proc_img));
                        roi_proc_img(BW) = scale_vals;
                        axes(handles.roi_axes)
                        
                        if curr_trial == 1
                            cla(handles.roi_axes,'reset')
                        end
                        
                        imshow(roi_proc_img)
                        
                        if view_roi
                            hold on
                            plot(handles.roi_x,handles.roi_y)
                            hold off
                        end
                    end
                    disp(['Completed Trial: ' num2str(curr_trial)])                    
                    cond_num = cond_num + 1;
                else
                    disp('Animal was not running, repeating trial')
                    repeat_trial = 1;
                end
                drawnow
                if get(handles.abort_butt,'Value');
                    stop(handles.vid);
                    disp('aborted');
                    break
                elseif get(handles.abort_and_save_butt,'Value')
                    stop(handles.vid);
                    proc_image_cell = cell(size(raw_sum_cell,1),2);
                    for k = 1:size(raw_sum_cell,1)
                        [proc_image_cell{k,1}, proc_image_cell{k,2}] = iOS_OnlineProcessor(raw_sum_cell{k,1}, curr_trial, handles);
                    end
                    disp('saving')
                    save([user_dir filesep fname '_' sess_name '.mat'],...
                        'proc_image_cell','user_dir','trial_length','num_cond','fps','rise_time',...
                        'fall_time','piez_amp','stim_freq','stim_start','num_trials','iti',...
                        'fname','sess_name','sr','BW')
                    disp('aborted')
                    break
                end
            end
            if get(handles.abort_butt,'Value') | get(handles.abort_and_save_butt,'Value')
                break
            end
        end
        cond_num = 1;
    end
    
    curr_trial = curr_trial + 1;
    if get(handles.abort_butt,'Value') | get(handles.abort_and_save_butt,'Value')
        break
    end
end

proc_image_cell = cell(size(raw_sum_cell,1),2);

for k = 1:size(raw_sum_cell,1)
    stim_on_frame = ceil(handles.stim_start*fps);
    baseline_start_frame = ceil(0.150*fps);
    baseline_frames = baseline_start_frame:(stim_on_frame); %intensities level out around 0.150s, measuring anything before this introduces outliers
    raw_frame_sums = raw_sum_cell{k,1};
    total_frames = size(raw_frame_sums,4);
    response_start_frame = floor(stim_on_frame + (total_frames-stim_on_frame)/4);
    response_end_frame = floor(stim_on_frame + (total_frames-stim_on_frame)*3/4);
    
    stim_frames = response_start_frame:response_end_frame; %find mid-point of last frame and stim on frame, take last half of stim frames
    
    avg_frames = single(raw_frame_sums(:,:,1,:)./num_trials);
    avg_baseline = sum(avg_frames(:,:,1,baseline_frames),4)./length(baseline_frames);
    avg_stim_frames = sum(avg_frames(:,:,1,stim_frames),4)./(length(stim_frames));
    
    baseline_subtracted = avg_stim_frames - avg_baseline;
    deltai = baseline_subtracted./avg_baseline;
    min_val = mean2(deltai)-3*std2(deltai);
    
    shift2zero = deltai - min_val;
    max_val = mean2(shift2zero)+3*std2(shift2zero);
    proc_img = shift2zero*(1/max_val);
    proc_img(proc_img < 0.15) = 0;
    proc_img = uint8(proc_img*(2^8-1));
    imwrite(proc_img,[handles.user_dir filesep handles.fname '_' handles.sess_name...
        '_cond_' num2str(k) '_' 'map.tif'])
    
    if use_roi
        
        roi_deltai = deltai(BW);
        roi_min_val = mean2(roi_deltai)-3*std2(roi_deltai);
        
        shift2zero = roi_deltai - roi_min_val;
        roi_max_val = mean2(shift2zero)+3*std2(shift2zero);
        scale_vals = shift2zero*(1/roi_max_val);
        scale_vals(scale_vals < 0.15) = 0;
        roi_proc_img = ones(size(BW));
        roi_proc_img(BW) = scale_vals;
        roi_proc_img = uint8(roi_proc_img*(2^8-1));
        imwrite(roi_proc_img,[handles.user_dir filesep handles.fname '_' handles.sess_name...
            'roi_cond_' num2str(k) '_' 'map.tif']);
    end
    
    [proc_image_cell{k,1}, proc_image_cell{k,2}] = iOS_OnlineProcessor(raw_sum_cell{k,1}, curr_trial, handles);
    
end



if curr_trial > handles.num_trials
    set(handles.exp_status,'String','Exp Status: DONE')
    set(hObject,'Value',0,'String','START EXPERIMENT','BackgroundColor',[0 1 0],'ForegroundColor',[0 0 0])
disp('saving')
save([user_dir filesep fname '_' sess_name '.mat'],...
    'proc_image_cell','user_dir','trial_length','num_cond','fps','rise_time',...
    'fall_time','piez_amp','stim_freq','stim_start','num_trials','iti',...
    'fname','sess_name','sr','BW')
disp('done saving')
elseif get(handles.abort_butt,'Value')
    set(handles.exp_status,'String','Exp Status: ABORTED')
    set(hObject,'Value',0,'String','START EXPERIMENT','BackgroundColor',[0 1 0],'ForegroundColor',[0 0 0])
    set(handles.abort_butt,'Value',0)
elseif get(handles.abort_and_save_butt,'Value')
    set(handles.exp_status,'String','Exp Status: ABORTED AND SAVED')
    set(hObject,'Value',0,'String','START EXPERIMENT','BackgroundColor',[0 1 0],'ForegroundColor',[0 0 0])
    set(handles.abort_and_save_butt,'Value',0)
end

guidata(hObject, handles);




% --- Executes on button press in preview_butt.
function preview_butt_Callback(hObject, eventdata, handles)
exp_stats = get(handles.exp_start,'Value');
temp_img = zeros(get(handles.vid,'Videoresolution'));
prev_butt_stats = get(hObject,'Value');

if exp_stats ~= 0 && prev_butt_stats;
    set(hObject,'Value',0)
elseif exp_stats == 0 && prev_butt_stats == 1
    hImage = image(temp_img,'Parent',handles.preview_axes);
    if handles.hist
        setappdata(hImage,'UpdatePreviewWindowFcn',@iOS_update_livehistogram_display);
    end
    preview(handles.vid,hImage)
elseif exp_stats == 0 && prev_butt_stats == 0
    stoppreview(handles.vid)
end

guidata(hObject, handles);


% --- Executes on button press in live_hist.
function live_hist_Callback(hObject, eventdata, handles)
val = get(hObject,'Value');
handles.hist = val;
guidata(hObject, handles);




function iOS_update_livehistogram_display(obj,event,hImage)
set(hImage,'CData',event.Data);
[counts,x] = imhist(event.Data);
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


% --- Executes on button press in capture_img.
function capture_img_Callback(hObject, eventdata, handles)
exp_stats = get(handles.exp_start,'Value');
temp_img = zeros(get(handles.vid,'Videoresolution'));
prev_butt_stats = get(handles.preview_butt,'Value');


if exp_stats == 0; %does nothing if experiment is running
    if prev_butt_stats == 1;
        set(handles.preview_butt,'Value',0)
        stoppreview(handles.vid)
    end
    stop(handles.vid) %stops camera if it is running, doesn't error out if it is not running
    hImage = image(temp_img,'Parent',handles.preview_axes);    
    flushdata(handles.vid)
    triggerconfig(handles.vid, 'manual');
    preview(handles.vid,hImage);
    start(handles.vid);
    pause(0.100)
    trigger(handles.vid);
    pause(0.100) %for some reason no data is collected if there is no pause. this is what makes it work!!!
    stoppreview(handles.vid);    
    stop(handles.vid);
    triggerconfig(handles.vid, 'hardware', 'risingEdge-ttl', 'automatic');
    vid_data = getdata(handles.vid);
    vid_data = uint8(single(vid_data)/(2^12-1)*(2^8-1));
    imwrite(vid_data,[handles.user_dir filesep handles.fname...
        '_' handles.sess_name '_' 'green_image.tif'])
end



function f_name_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of f_name as text
%        str2double(get(hObject,'String')) returns contents of f_name as a double
val = get(hObject,'String');
handles.fname = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function f_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to f_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function session_name_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of session_name as text
%        str2double(get(hObject,'String')) returns contents of session_name as a double
val = get(hObject,'String');
handles.sess_name = val;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function session_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to session_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dir_select.
function dir_select_Callback(hObject, eventdata, handles)
% hObject    handle to dir_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
user_dir = uigetdir(handles.user_dir,'Select Destination Directory for Raw and Processed Images');

if ~user_dir
    warndlg('Directory Not Selected!');
else
    set(handles.pwd_text,'String',['pwd: ' user_dir])
    handles.user_dir = user_dir;
    guidata(hObject,handles)
end


% --- Executes on button press in stim_prev.
function stim_prev_Callback(hObject, eventdata, handles)
% hObject    handle to stim_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
drawnow

while get(hObject,'Value')
    [stim, nostim, ~, ~] = iOS_OutputSignals(handles);

    if handles.stimulus < 2      
        output_waves = [stim, stim, nostim, nostim, nostim];
        handles.ni.queueOutputData(output_waves);
        if ~handles.ni.IsRunning
            disp('sending waves')
            handles.ni.startForeground;
        end
        disp('done sending waves')
        
        drawnow
        if ~get(hObject,'Value');
            set(hObject,'Value',0)
            break
        end
    elseif handles.stimulus == 2      
        stepper_signals = iOS_StepperControl(handles);
        output_waves = [nostim, nostim, nostim, stepper_signals];
        handles.ni.queueOutputData(output_waves);
        if ~handles.ni.IsRunning
            disp('sending waves')
            handles.ni.startForeground;
        end
        disp('done sending waves')
        drawnow
        if ~get(hObject,'Value');
            set(hObject,'Value',0)
            break
        end
    end
end


% --- Executes on button press in merge_butt.
function merge_butt_Callback(hObject, eventdata, handles)
iOS_ImageMerge(handles)



function square_high_time_bx_Callback(hObject, eventdata, handles)
val = abs(str2double(get(hObject,'String')));
handles.square_high_time = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function square_high_time_bx_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function square_low_time_bx_Callback(hObject, eventdata, handles)
val = abs(str2double(get(hObject,'String')));
handles.square_low_time = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function square_low_time_bx_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function square_amp_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
if val > 5 || val < 0
    warndlg(sprintf('Analog amplitude cannot exceed the range of 0-5v\nSetting to default'))
    val = 3;
    set(hObject,'String','3.0')
end
handles.square_amp = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function square_amp_bx_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_steps_bx_Callback(hObject, eventdata, handles)
val = str2double(get(hObject,'String'));
handles.num_steps = val;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function num_steps_bx_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag')
    case 'piez_select'
        handles.stimulus = 0;
    case 'square_select'
        handles.stimulus = 1;
        warndlg(sprintf('MAKE SURE PIEZO IS DISCONNECTED\nSQUARE PULSES CAN DAMAGE WAFER'))
    case 'stepper_select'
        handles.stimulus = 2;
        warndlg(sprintf('MAKE SURE PIEZO IS DISCONNECTED\nSQUARE PULSES CAN DAMAGE WAFER'))
end
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function uipanel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in roi_select.
function roi_select_Callback(hObject, eventdata, handles)
exp_stats = get(handles.exp_start,'Value');
temp_img = zeros(get(handles.vid,'Videoresolution'));
prev_butt_stats = get(handles.preview_butt,'Value');


if exp_stats == 0; %does nothing if experiment is running
    if prev_butt_stats == 1;
        set(handles.preview_butt,'Value',0)
        stoppreview(handles.vid)
    end
    stop(handles.vid) %stops camera if it is running, doesn't error out if it is not running
    hImage = image(temp_img,'Parent',handles.preview_axes);    
    flushdata(handles.vid)
    triggerconfig(handles.vid, 'manual');
    preview(handles.vid,hImage);
    start(handles.vid);
    pause(0.100)
    trigger(handles.vid);
    pause(0.100) %for some reason no data is collected if there is no pause. this is what makes it work!!!
    stoppreview(handles.vid);    
    stop(handles.vid);
    triggerconfig(handles.vid, 'hardware', 'risingEdge-ttl', 'automatic');
    vid_data = getdata(handles.vid);
end

max(max(vid_data))
h = figure;
[BW, roi_x, roi_y] = roipoly(single(vid_data)./(2^12-1));
close(h)

handles.BW = BW;
handles.roi_x = roi_x;
handles.roi_y = roi_y;

guidata(hObject,handles)


% --- Executes on button press in view_roi.
function view_roi_Callback(hObject, eventdata, handles)
val = get(hObject,'Value');

if val == 1
    if handles.BW == -1
        warndlg('ROI has not been selected')
        val = 0;
        set(hObject,'Value',0)
    end
end


handles.view_roi = val;
guidata(hObject, handles);


% --- Executes on button press in use_roi_butt.
function use_roi_butt_Callback(hObject, eventdata, handles)
val = get(hObject,'Value');

if val == 1
    if handles.BW == -1
        warndlg('ROI has not been selected')
        val = 0;
        set(hObject,'Value',0)
    end
end
handles.use_roi = val;
guidata(hObject, handles);


% --- Executes on button press in overwrite_map_butt.
function overwrite_map_butt_Callback(hObject, eventdata, handles)
val = get(hObject,'Value');
handles.overwrite_map = val;
guidata(hObject, handles);


% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
switch get(eventdata.NewValue,'Tag')
    case 'no_sort'
        handles.sort = 0;
    case 'sort'
        handles.sort = 1;
end
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function uipanel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in abort_butt.
function abort_butt_Callback(hObject, eventdata, handles)
guidata(hObject, handles);


% --- Executes on button press in abort_and_save_butt.
function abort_and_save_butt_Callback(hObject, eventdata, handles)
guidata(hObject, handles);
