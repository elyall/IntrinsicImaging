function iOS_ImageMerge(handles)

img_dir = handles.user_dir;


green_dir_struct = dir([handles.user_dir filesep handles.fname '*' 'green_image.tif']);

if isempty(green_dir_struct)
    warndlg(sprintf('green image not found. Take image and try again\nMake sure image is saved to save directory as other iOS images'))
    return
end

green_img_name = green_dir_struct.name;
green_img = single(imread([handles.user_dir filesep green_img_name]));
green_img = green_img*(1/max(max(green_img)));
green_img_name(green_img_name == '_') = ' ';
dir_struct = dir([handles.user_dir filesep handles.fname '*.mat']);

if isempty(dir_struct)
    warndlg(sprintf('iOS images not found. Take images again and try again\nMake sure images are in same directory as green image'));
    return
end


for sessions = 1:length(dir_struct)
    fname = dir_struct(sessions).name;
    data_cell = open([handles.user_dir filesep fname]);
    proc_image_cell = data_cell.proc_image_cell;
    BW = data_cell.BW;    
    if BW == -1
        temp = figure;
        imshow(green_img)
        title(green_img_name)        
        choice = menu('Choose an option','No ROI','New ROI');
        close(temp)
    else
        temp = figure;
        imshow(green_img)
        hold on
        plot(handles.roi_x,handles.roi_y)
        hold off
        title(green_img_name)
        choice = menu('Choose an option','No ROI','New ROI','Old ROI');
        close(temp)
    end
    
    if choice == 2
        h2 = figure;
        [BW, ~, ~] = roipoly(green_img);
        close(h2)
    end
    
    total_cond = size(proc_image_cell,1);
    combo_centers = [];
    combo_img_ind = [];
    for cond = 1:total_cond
        proc_img = proc_image_cell{cond,1};
        deltai = proc_image_cell{cond,2};
        
        if choice == 2 || choice == 3
            roi_deltai = deltai(BW);
            roi_min_val = mean2(roi_deltai)-3*std2(roi_deltai);
            
            shift2zero = roi_deltai - roi_min_val;
            roi_max_val = mean2(shift2zero)+3*std2(shift2zero);
            scale_vals = shift2zero*(1/roi_max_val);
            scale_vals(scale_vals < 0.15) = 0;
            roi_proc_img = ones(size(BW));
            roi_proc_img(BW) = scale_vals;
            proc_img = roi_proc_img;
        end
        
        proc_img(proc_img < 0.20) = 0;
        proc_img(proc_img > 1) = 1;
        h1 = figure;
        imagesc(proc_img);
        colormap('gray');
        title('click on the center of the intrinsic signal')
        [xcorrd, ycorrd] = ginput(1);
        close(h1)
%         b=abs(max(proc_img(:))-proc_img);
%         c=im2bw(b,.9);
%         SE = strel('disk',3,8);
%         d=imdilate(c,SE);
%         rois = bwlabel(d);
%         info = regionprops(rois);
%         [~,index]= max([info(:).Area]);
%         xcorrds = info(index).Centroid;
%         
        h1 = figure;
        imshow(green_img);hold on;
        plot(xcorrd,ycorrd,'or'); hold off
        saveas(h1,[handles.user_dir filesep fname(1:(end-4)) '_cond_' num2str(cond) '_' 'merged.tif'])
        close(h1)
        
        combo_centers = [combo_centers;[xcorrd,ycorrd]];
        
        signal_ind = find(proc_img<0.20);
        combo_img_ind = union(combo_img_ind,signal_ind);
%         merged_img = green_img;
%         merged_img(signal_ind) = 0;
%         merged_img = merged_img*(2^8-1);
%         merged_img = uint8(merged_img);
%         imwrite(merged_img,[handles.user_dir filesep fname(1:(end-4)) '_cond_' num2str(cond) '_' 'merged.tif'])
        
        proc_img = uint8(proc_img*(2^8-1));
        if handles.overwrite_map
            imwrite(proc_img,[handles.user_dir filesep fname(1:(end-4)) 'roi_cond_' num2str(cond) '_' 'map.tif'])
        end
        
        if cond == total_cond && cond > 1
            
            h1 = figure;
            imshow(green_img);hold on
            plot(combo_centers(:,1),combo_centers(:,2),'or'); hold off
            saveas(h1,[img_dir filesep fname(1:(end-4)) '_combo_merged.tif'])
            close(h1)
            
%             merged_img = green_img;
%             merged_img(combo_img_ind) = 0;
%             merged_img = merged_img*(2^8-1);
%             merged_img = uint8(merged_img);
%             imwrite(merged_img,[img_dir filesep fname(1:(end-4)) '_combo_merged.tif'])
            
            combo_mat = 255*ones(size(proc_img),'uint8');
            combo_mat(combo_img_ind) = uint8(0);
            imwrite(combo_mat,[img_dir filesep fname(1:(end-4)) '_combo_map_merged.tif'])
        end
        
    end
end




