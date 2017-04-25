function h = overlayGauss(mu, angle, sigma, varargin)
% overlayGauss Overlays a 2D Gaussian on the current plot axes. (derived
% from fit_ellipse by Ohad Gal:
% https://www.mathworks.com/matlabcentral/fileexchange/3215-fit-ellipse)
%   HANDLE = overlayGauss(MU, ANGLE, SIGMA) plots a 2D Gaussian on the
%   current plot axes. MU ([1x2]) is the [X,Y] center of the axes. ANGLE is
%   a scalar specifying the angle of the Guassian's axes from
%   horizontal/vertical in degrees. SIGMA ([1x2]) is the [X,Y] standard
%   deviation of the Gaussian. HANDLE is a 1x3 matrix containing the
%   handles of the 3 plotted lines.
%
%   overlayGauss(...,'Axes',AXESHANDLE) specifies overlay to be placed on
%   the axes specified by its handle AXESHANDLE. (default = gca)
%
%   overlayGauss(...,'Color',COLOR) specifies the color of the plot to be
%   [R,G,B] vector COLOR. (default = [1,0,0])
%
%   overlayGauss(...,'LineWidth',LineWidth) specifies width of line to be
%   LINEWIDTH, a scalar. (default = 1)
%
%   overlayGauss(...,'LineStyle',LINESTYLE) specifies style of line to be
%   LINESTYLE, a string. (default = '--')
%

% Defaults that can be changed
AxesHandle = gca;
Color = [1,0,0];
LineWidth = 1;
LineStyle = '--';


%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'Color'
                Color = varargin{index+1};
                index = index + 2;
            case 'LineWidth'
                LineWidth = varargin{index+1};
                index = index + 2;
            case 'LineStyle'
                LineStyle = varargin{index+1};
                index = index + 2;
            case 'AxesHandle'
                AxesHandle = varargin{index+1};
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


%% Overlay gaussian

% the axes
horz_line = [sigma(1)*[-1 1];0,0];
ver_line  = [0,0;sigma(2)*[-1 1]];

% the ellipse
theta_r     = linspace(0,2*pi);
ellipse_x_r = sigma(1)*cos(theta_r);
ellipse_y_r = sigma(2)*sin(theta_r);
ellipse     = [ellipse_x_r;ellipse_y_r];

% the rotation matrix
cos_phi = cos(angle/360*2*pi);
sin_phi = sin(angle/360*2*pi);
R       = [cos_phi -sin_phi;sin_phi cos_phi];

% Rotate
rotated_ellipse = R*ellipse;
new_ver_line    = R*ver_line;
new_horz_line   = R*horz_line;

% Add mean
rotated_ellipse = bsxfun(@plus, rotated_ellipse, mu');
new_ver_line = bsxfun(@plus, new_ver_line, mu');
new_horz_line = bsxfun(@plus, new_horz_line, mu');

% Overlay
axes(AxesHandle);
state = get(AxesHandle,'NextPlot');
hold on;
h(1) = plot(new_ver_line(1,:),new_ver_line(2,:),'Color',Color,'LineWidth',LineWidth,'LineStyle',LineStyle);
h(2) = plot(new_horz_line(1,:),new_horz_line(2,:),'Color',Color,'LineWidth',LineWidth,'LineStyle',LineStyle);
h(3) = plot(rotated_ellipse(1,:),rotated_ellipse(2,:),'Color',Color,'LineWidth',LineWidth,'LineStyle',LineStyle);
% plot(ver_line(1,:),ver_line(2,:),'b-');
% plot(horz_line(1,:),horz_line(2,:),'b-');
% plot(ellipse_x_r,ellipse_y_r,'b-');
if strcmp(state,'replace')
    hold off;
end
