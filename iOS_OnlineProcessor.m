

function [proc_img, deltai_mat] = iOS_OnlineProcessor(raw_sum_cell, curr_trial, handles)

fps = handles.fps;
stim_on_time = handles.stim_start;
stim_on_frame = ceil(stim_on_time*fps);
start_frame = ceil(0.150*fps); %intensities reach steady state at 150ms, before this frames seem to be underexposed
baseline_frames = single(start_frame:(stim_on_frame));
raw_frame_sums = raw_sum_cell(:,:,1,:);
clear raw_sum_cell
total_frames = size(raw_frame_sums,4);
stim_start_frame = stim_on_frame + floor((total_frames-stim_on_frame)/4);
stim_end_frame = stim_on_frame + floor((total_frames-stim_on_frame)*3/4);
stim_frames = single(stim_start_frame:stim_end_frame); %take last half of stim on time and first half of stim off

avg_frames = single(raw_frame_sums(:,:,1,:)./curr_trial);
clear raw_frame_sums
avg_baseline = sum(avg_frames(:,:,1,baseline_frames),4)./length(baseline_frames);
avg_stim_frames = sum(avg_frames(:,:,1,stim_frames),4)./(length(stim_frames));

baseline_subtracted = avg_stim_frames - avg_baseline;
deltai = baseline_subtracted./avg_baseline;
min_val = mean2(deltai)-3*std2(deltai);
shifted_vals = deltai-min_val;
max_val = mean2(shifted_vals)+3*std2(shifted_vals);
scale2one = shifted_vals*(1/max_val);
scale2one(scale2one < 0) = 0;
proc_img = scale2one;
deltai_mat = deltai;

clear avg_frames avg_baseline avg_stim_frames baseline_subtracted deltai...
    min_val max_val shifted_vals scale2one















