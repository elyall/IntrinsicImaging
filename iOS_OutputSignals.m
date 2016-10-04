
function [stim, nostim, cam_trig, t] = iOS_OutputSignals(handles)

%trial_length, stim_on_time, cam_fps, rise_time, fall_time)

h = handles;

fps = h.fps;
sr = h.ni.Rate;
trial_length = h.trial_length;
rise_time = h.rise_time;
fall_time = h.fall_time;
piez_amp = h.piez_amp;
stim_freq = h.stim_freq;
stim_start = h.stim_start;
end_buffer = h.end_buffer;
stimulus = handles.stimulus;
square_high_time = handles.square_high_time;
square_low_time = handles.square_low_time;
square_amp = handles.square_amp;
num_steps = handles.num_steps;


%% Create Camera Trigger Vector
pulse_width = ceil(0.001*sr);
t = (0:1/sr:(trial_length+end_buffer))'; %trial time vector

num_frame_samples = round(((1/fps)*sr));
go_pulse = zeros(num_frame_samples,1);
go_pulse(2:(pulse_width+1),1) = 1;
cam_trig = repmat(go_pulse,(fps*trial_length)+1,1);%captures an extra frame so the first one can be discarded

vector_diff = length(t)-length(cam_trig);

if vector_diff > 0
    cam_trig = [cam_trig;zeros(vector_diff,1)];
elseif vector_diff < 0
    vector_diff = abs(vector_diff)-1;
    cam_trig((end-vector_diff):end) = [];
    cam_trig(end) = 0;
end

%% Create Piezo Stimulus Vector

if stimulus < 2
    
    if stimulus == 0
        rise_period = 2*rise_time;
        rise_f = 1/rise_period;
        rise_t = (0:1/sr:rise_time)';
        rise_wave = (-0.5*cos(2*pi*rise_f*rise_t)+0.5)*piez_amp;
        
        fall_period = 2*fall_time;
        fall_f = 1/fall_period;
        fall_t = (0:1/sr:fall_time)';
        fall_wave = (0.5*cos(2*pi*fall_f*fall_t)+0.5)*piez_amp;
    elseif stimulus ==1
        rise_time = square_high_time;
        fall_time = square_low_time;
        num_high_samples = ceil(rise_time*sr);
        num_low_samples = ceil(fall_time*sr);
        rise_wave = ones(num_high_samples,1)*square_amp;
        rise_wave(1) = 0;
        fall_wave = zeros(num_low_samples,1);
    end
    
    
    stim_lag = ((1/stim_freq)-(rise_time + fall_time));
    
    %if stim freq is faster than freq of single wail, this produces the maximum
    %stimulation frequency possible with the given wail parameters
    if stim_lag >= 0;
        stim_lag = ceil(stim_lag*sr); %num of samples between wails
    elseif stim_lag < 0;
        stim_lag = 0;
    end
    
    single_stim = [rise_wave;fall_wave;zeros(stim_lag,1)];
    stim_sequence = repmat(single_stim,[ceil((trial_length-stim_start)*0.5*stim_freq),1]);
    
    stim_length = (trial_length-stim_start)*0.5*sr;
    
    %if wail sequence is longer than trial sequence then wail sequence is made
    %shorter by removing right most values
    if length(stim_sequence) > stim_length
        ind2remove = uint64((stim_length+1)):uint64(length(stim_sequence));
        stim_sequence(ind2remove) = [];
    end
    
    %if wail sequence does not end at zero this will replace non-zero values
    %in last to first direction (i.e. if a wail was cutoff by above operation
    %this ensures that the analog output is set to zero so there is no output
    %during inter trial intervals).
    if stim_sequence(end) ~= 0
        remove_cutoff = 1;
    else
        remove_cutoff = 0;
    end
    
    cutoff_ind = length(stim_sequence);
    while remove_cutoff == 1
        stim_sequence(cutoff_ind) = 0;
        if stim_sequence(cutoff_ind-1) == 0
            remove_cutoff = 0;
        else
            cutoff_ind = cutoff_ind -1;
        end
    end
    
    stim_start_ind = stim_start*sr;
    stim_end_ind = length(stim_sequence)+stim_start_ind-1;
    stim = zeros(length(t),1);
    nostim = zeros(length(t),1);
    stim(stim_start_ind:stim_end_ind,1) = stim_sequence;
end

if stimulus == 2
nostim = zeros(length(t),1);
stim = nostim;
end




