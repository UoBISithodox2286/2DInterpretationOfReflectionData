function [normlized_intensity,sigma_over_I,intensity,sigma] = ExcludeOutliers(reflection_data)
%% Usage

% Use with readHKL.m and the .cif or .hkl file.

% Such as:
%(in folder xxx)
%   ...
%   readHKL.m
%   ExcludeOutliers.m
%   O084.cif
%   ...

% Example:
%   O084=readHKL('O084.cif',5);
%   [O084N,O084E,O084I,O084S] = ExcludeOutliers(O084);

% It simply takes in the reflection_data in full.
% This simple function is set to exclude outliers in knee shaped
% interpretation of the reflection data in hkl files, process them to
% extract the Normalized Intensity and sigma/Norm(I). Along with the raw
% Intensity and Sigma data for correction purposes.

% reflection_data - full 5 column matrix, containing h, k and l index data,
% reflection intensity and uncertainty measured as sigma.

% normlized_intensity - normalized intensity data;
% sigma_over_I - sigma/normalized intensity data;
% intensity - intensity of relection data;
% sigma - uncertainty measurement data;



%% Function
intensity = reflection_data(:,4);
sigma = reflection_data(:,5);

normlized_intensity = normalize(intensity);
sigma_over_I = sigma./intensity;

idx = find(abs(sigma_over_I)<=2);

sigma_over_I = abs(sigma_over_I(idx));
normlized_intensity = normlized_intensity(idx);

end

