

function [vid, src, ni] = iOS_Initialization
% Establishes initial connection and configuration of dalsa 1m60 camera.
% This function will error out if the camera cannot be connected to or
% configured properly. If the initialization is successful
% iOS_Initialization will return a camera handle and src handle and a
% handle to the nidaq card.
%
%G.Telian
%Adesnik Lab
%UC Berkeley
%20131203

%% Detect and Verify Dalsa Hardware/Adaptors

%imaqhwinfo detects dalsa hardware and makes the serial mapping available
%to MATLAB. If imaqhwinfo is NOT run or imaqtool is not opened COM5 or
%whatever COM port the frame grabber is mapped to WILL NOT BE FOUND!
cam_hw = imaqhwinfo; 
num_adaptors = length(cam_hw.InstalledAdaptors);

dalsa_found = 0;
for k = 1:num_adaptors
    if strfind(cam_hw.InstalledAdaptors{k},'dalsa')
        dalsa_found = 1;
        disp('Dalsa Adaptor Found')
    end
end

if dalsa_found == 0
    error('iOSImager:adaptorNotFound','Dalsa adaptor was not found')
end

%% Check Camera Serial Port Availability
cam_com_port = 'COM5'; %Cam is currently  mounted to COM5. Allow user to change camera COM mapping in future?
serialinfo = instrhwinfo('serial');
num_com_ports = length(serialinfo.SerialPorts);

com_port_found = 0;
for k = 1:num_com_ports
    if strfind(serialinfo.SerialPorts{k},cam_com_port)
        com_port_found = 1;
        disp('Camera port found')
    end
end

if com_port_found == 0;
    error('iOSImager:COMPortNotFound','Camera serial port not found, make sure it is mapped to correct COM port')
end

num_avail_com_ports = length(serialinfo.AvailableSerialPorts);
com_port_available = 0;

for k = 1:num_avail_com_ports
    if strfind(serialinfo.AvailableSerialPorts{k},cam_com_port)
        com_port_available = 1;
        disp('Camera port available')
    end
end

if com_port_available == 0;
    error('iOSImager:COMPortNotAvailable',...
        ['Camera port is not available. Make sure other applications that may \n'...
        'communicate with camera are closed. MATLAB may have to be restarted'])
end

%% Load Camera File

cam_config_file = 'C:\Users\User\Documents\MATLAB\iOS\CamFiles\T_1m60_12-bits_2_tap_ext_trig.ccf';
disp('Loading camera config file:')
disp(cam_config_file)
vid = videoinput('dalsa', 1, cam_config_file);
src = getselectedsource(vid);
vid.FramesPerTrigger = 1;

imaqmem(2000000000); %set aside 2GB of memory for image frames (this should be changed depending on num of frames to be acquired

vid.TriggerRepeat = Inf; %set number of triggers to expect. set to Inf so any number of frames can be captured
triggerconfig(vid, 'hardware', 'risingEdge-ttl', 'automatic'); %set camera to be triggered on rising edge of ttl pulse

%% Establish Serial Communication With Camera, Set and Check Exposure Parameters
disp('Sending sem 3 command')
cam_serial_cmmd(cam_com_port,'sem 3');
disp('Sending sec 0 command')
cam_serial_cmmd(cam_com_port,'sec 0');

mssg = cam_serial_cmmd(cam_com_port,'gcp');
num_mssg_lines = length(mssg);

sem_check = 0;
sec_check = 0;

for k = 1:num_mssg_lines
    if regexp(mssg{k},'Exposure Control.*disabled') %'.' = any single character, '*' = 0 or more times consecutively)
        sec_check = 1;
        disp('Exposure Control Set to ''disabled''')
    elseif regexp(mssg{k},'Exposure Mode.*3')
        sem_check = 1;
        disp('Exposure Mode set to ''3''')
    end
end

if sem_check == 0;
    error('iOSImager:camExpMode','Could not change camera to proper external tirgger mode (mode 3)')
    
elseif sec_check == 0;
    error('iOSImager:camExpControl','Could not set camera exposure control to disabled')
end

%% NIDAQ Initialization
sr = 30000;
disp('initializing NIDAQ')
ni = daq.createSession('ni');
[ach0,aidx0] = ni.addAnalogOutputChannel('Dev3',0,'Voltage');
[ach1,aidx1] = ni.addAnalogOutputChannel('Dev3',1,'Voltage');
[dch0,didx0]=ni.addDigitalChannel('Dev3','port0/line0','OutputOnly'); % camera trigger
[dch1,didx1]=ni.addDigitalChannel('Dev3','port0/line1','OutputOnly');
[dch2,didx2]=ni.addDigitalChannel('Dev3','port0/line2','OutputOnly');
% [dch3,didx3]=ni.addDigitalChannel('Dev3','port0/line3','OutputOnly');
% [dch4,didx4]=ni.addDigitalChannel('Dev3','port0/line4','OutputOnly');
ni.addCounterInputChannel('Dev3','ctr0','EdgeCount'); %Counter 1 for digital encoder run frequency
ni.Rate = sr;

disp('Initialization Complete')












