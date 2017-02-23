function overlayGauss(mu, angle, sigma)
% overlayGauss Overlays a 2D Gaussian on the current plot axes. (derived
% from fit_ellipse by Ohad Gal:
% https://www.mathworks.com/matlabcentral/fileexchange/3215-fit-ellipse)
%   overlayGauss(MU, ANGLE, SIGMA) plots a 2D Gaussian on the current plot
%   axes. MU ([1x2]) is the [X,Y] center of the axes. ANGLE is a scalar
%   specifying the angle of the Guassian's axes from horizontal/vertical in
%   degrees. SIGMA ([1x2]) is the [X,Y] standard deviation of the Gaussian.


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
hold on;
plot(new_ver_line(1,:),new_ver_line(2,:),'r' );
plot(new_horz_line(1,:),new_horz_line(2,:),'r' );
plot(rotated_ellipse(1,:),rotated_ellipse(2,:),'r' );
% plot(ver_line(1,:),ver_line(2,:),'b');
% plot(horz_line(1,:),horz_line(2,:),'b');
% plot(ellipse_x_r,ellipse_y_r,'b');

