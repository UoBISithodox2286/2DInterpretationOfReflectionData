function [new_points] = Turn45(points)
%% Usage:
    % Part of coding in DistributionTube.m. Please don't use it
    % individually.
    
    % Used to turn a group of points 45 degrees to the right.

    % How it turns a group of points 45 degree to the right:
    %x_new = (x – xc)cos(θ) – (y – yc)sin(θ) + xc
    %y_new = (x – xc)sin(θ) + (y – yc)cos(θ) + yc

%% CODE:
    xc = points(1,1);
    yc = points(1,2);
    r = sqrt(2)/2;
    new_points = [];
    for i = 1:length(points(:,1))
        x = points(i,1);
        y = points(i,2);
        x1 = (x-xc)*r+(y-yc)*r+xc;
        y1 = (x-xc)*r-(y-yc)*r+yc;
        new_points(end+1,:)=[x1,y1];
    end
end

