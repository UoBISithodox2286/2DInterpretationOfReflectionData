function [hkl] = readHKL(filename,values)
%% Usage Instructions:
% To use this function, put it in the same folder as the .hkl files needed in
% input!

% Such as:
%(in folder xxx)
%   ...
%   readHKL.m
%   O084.cif
%   ...

% Example:
% O084=readHKL('O084.cif',5);

% Then the useage is hkl = readHKL(filename,values).
% filename - the full id of the file, including extension type(ie. .hkl or .cif);
% values - number of columns in the .hkl file ;
% hkl - content of the hkl file, have either 5 or 6 columns of readings;


%% Main Body:
% This would read the content of the .hkl file into a matrix. One file at a
% time.
    if values == 5
        formatSpec = '%d %d %d %f %f';
        ID = fopen(filename,'r');
        sizeA = [5 Inf];
        hkl = fscanf(ID,formatSpec,sizeA);
        hkl = hkl';
        fclose(ID);
    elseif values == 6
        formatSpec = '%d %d %d %f %f %f';
        ID = fopen(filename,'r');
        sizeA = [6 Inf];
        hkl = fscanf(ID,formatSpec,sizeA);
        hkl = hkl';
        fclose(ID);
    else
        error('.hkl file can only have 5 or 6 columns. Other number or variables is not acceptable.')
    end
end
    