function [kdvec,bandwidth] = DataPointDensity(amount)
%% Usage:
    % Part of coding in DistributionTube.m. Please don't use it
    % individually.

%% CODE:
    k = nnz(amount(:,2));
    for i = 1:k
        if amount(i,2) == 0
            amount(i,:) = [];
        end
    end


    xval = amount(:,1);
    count = amount(:,2);



    kdvec = [];
    for i = 1:size(amount,1)
        u = repelem(xval(i),count(i));
        kdvec = [kdvec u];
    end
    [f, xi,bw] = ksdensity(kdvec);



    % Finding local maxima of the kernal distrubutios
    bandwidth = bw;
end

