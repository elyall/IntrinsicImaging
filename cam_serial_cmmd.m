
function [mssg] = cam_serial_cmmd(COM_Port, cmmd)

s = serial(COM_Port);

try
    fopen(s);
    pause(1);
catch
    clear s
    error('iOSImager:CannotEstablishSerialConnection',...
        ['Cannot open serial connection with camera, make sure other applications\n'...
        'that may have connections with the camera are closed. MATLAB may need to\n'...
        'be restarted'])
end

fprintf(s,cmmd);
%without the delay fscanf may read the message prematurely and mess up the
%formatting
pause(1.0)
% get(s)

mssg = {};

%camera always sends a 3 byte 'OK>' message. Pause is needed otherwise
%fscanf times out waiting for message and then returns 'OK>'

mssg_line = 1;
while s.BytesAvailable > 0
    
    if s.BytesAvailable > 3
        mssg_temp = fscanf(s,'%c');
        mssg{mssg_line} = mssg_temp(1:end-2);%get rid of \n and add message to mssg cell
        disp(mssg_temp(1:end-2))
        mssg_line = mssg_line + 1;
    else
        pause(1)
        mssg_temp = fscanf(s,'%c',s.BytesAvailable);
        mssg{mssg_line} = mssg_temp;
        disp(mssg_temp);
        mssg_line = mssg_line + 1;
    end
end


fclose(s);
clear s mssg_line


