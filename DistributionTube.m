function [amount,Pin,modulus_distance,Skewness,line,Lower_coef,Upper_coef] = DistributionTube(norm,esd,DataName,plot_individual,plot_line)
%% Quick Usage

% Use with Turn45.m, DataPointDensity.m, ExludeOutliers.m,readHKL.m and the .cif or .hkl file.

% Such as:
%(in folder xxx)
%   ...
%   readHKL.m
%   ExcludeOutliers.m
%   Turn45.m
%   DistributionTube.m
%   DataPointDensity.m
%   O084.cif
%   ...

% Example:
%   O084=readHKL('O084.cif',5);
%   [O084N,O084E,O084I,O084S] = ExcludeOutliers(O084);
%   [O084A,O084Pin,O084M,O084Sk] = DistributionTube(O084N,O084E,'O084',true,true);

% Use with function ExcludeOutliers.m and readHKL.m

%% Input Variables
    % norm - normalized intensity;
    % esd - error/normalized intensity;
    % DataName - name or ID of the crystal in text form, ie. 'SuperSugar' or 'O084'
    % plot_inividual - true or false;
    %- true: show the full norm vs.esd plot of the crystal
    %- false: doesn't show the full plot;
    % plot_line - if plot_individual = ture, show the datapoints on the plot or not
    % works only when plot_individual = ture, otherwise plz leave as false;
    %- true: show boundary lines, but hides all datapoints;
    %- false: show both boundary lines and datapoints;
    
%% Output Variables
    % amount - the selected data points;
    % Pin - upper and lower knee points;
    % modulus_distance - knee point distance;
    % Skewness - skewness measurement;
    % line - the central line of the tube of sampling;
    % Lower_coef - Coefficients for curve fit to the lower boundary of the knee shape;
    % Upper_coef - Coefficients for curve fit to the upper boundary of the knee shape;

%% Window method
    % build a complete description on the points and eradicate all unreasonable points
    pp = [norm,esd];
    for i = 1:length(pp)
        if isnan(pp(i,:))
            pp(i,:)=[];
        end
    end

    % window method practise

    LowCurve = []; % lower curve
    UpCurve = []; % upper curve


    % find a step value and implement it
    pp = unique(sortrows(pp),'rows');
    a = 1:50:length(pp(:,1))-10;

    for n = 1:length(a)
        % find points within the left and right boundaries (window)
        localpp = pp(a(n):(a(n)+10),:);
        % find points with local min(y) and max(y)
        minP = find(localpp(:,2)==min(localpp(:,2)));
        maxP = find(localpp(:,2)==max(localpp(:,2)));
        for i = 1:length(minP)
            LowCurve(end+1,:)=localpp(minP(i),:);
        end
        for j = 1:length(maxP)
            UpCurve(end+1,:)=localpp(maxP(j),:);
        end
    end
    
%% Find the boundaries
    % For more accurate UpCurve, it is better for us to find the upper 1/3
    % of current points;
    newUpCurve=[];
    for n = 1:3:length(UpCurve)-3
        % find points within the left and right boundaries (window)
        localpp = UpCurve(n:n+3,:);
        % find points with local min(y) and max(y)
        maxP = find(localpp(:,2)==max(localpp(:,2)));
        for j = 1:length(maxP)
            newUpCurve(end+1,:)=localpp(maxP(j),:);
        end
    end
    UpCurve = newUpCurve;

    % find boundaries via boundary algorithm
    j = boundary(LowCurve(:,1),LowCurve(:,2));
    j=unique(j);
    LowBound = sortrows(LowCurve(j,:));
    mLow = Inf;
    % Eliminate Rapid rising error of the boundary algorithm
    while mLow > 50
        x1 = LowBound(1,1);
        x2 = LowBound(1,2);
        y1 = LowBound(2,1);
        y2 = LowBound(2,2);
        mLow = (y2-y1)/(x2-x1);
        LowCurve(1,:) = [];
        j = boundary(LowCurve(:,1),LowCurve(:,2));
        j=unique(j);
        LowBound = sortrows(LowCurve(j,:));
    end
    
    % find boundaries via boundary algorithm
    k =boundary(UpCurve(:,1),UpCurve(:,2));
    k=unique(k);
    UpBound = sortrows(UpCurve(k,:));
    
%% Eliminate Positive Slopes
    % Slope Lowbound
    slopeL = [];
    slopeU = [];
    
    for i = 1:length(LowBound)-1
        % Extract coordinates
        x1 = LowBound(i,1);
        x2 = LowBound(i+1,1);
        y1 = LowBound(i,2);
        y2 = LowBound(i+1,2);
        
        % Do slope calculation
        
        slopeL(end+1) = (y2-y1)/(x2-x1);
    end

    for j = 1:length(UpBound)-1
        % Extract coordinates
        x1 = UpBound(j,1);
        x2 = UpBound(j+1,1);
        y1 = UpBound(j,2);
        y2 = UpBound(j+1,2);
        
        % Do slope calculation
        
        m=(y2-y1)/(x2-x1);
        slopeU(end+1) = m;
    end

    % take out unqualified points
    LowBound(find(slopeL>=0),:) = [];
    slopeL(find(slopeL>=0))=[];
    UpBound(find(slopeU>=0),:) = [];
    slopeU(find(slopeU>=0))=[];
    
%% Fitting for funtions
ft = fittype('(a/(b^x))+c');
LowerLine=fit(LowBound(:,1),LowBound(:,2),ft,'StartPoint',[0,1,min(LowBound(:,2))]);
UpperLine=fit(UpBound(:,1),UpBound(:,2),ft,'StartPoint',[0,1,min(UpBound(:,2))]);

Lower_coef = [LowerLine.a,LowerLine.b,LowerLine.c];
Upper_coef = [UpperLine.a,UpperLine.b,UpperLine.c];

FitLow = LowerLine(LowBound(:,1));
FitHigh = UpperLine(UpBound(:,1));
%% Find Lower Knee via approximating with slope
   idxL = Inf;
    % Slope method, Lowbound
    trunPoint = Inf;
    for i = 1:length(slopeL)
        slope = abs(slopeL(i));
        if and(idxL==Inf,slopeL(i)>=-1)
           idxL = i;
           trunPoint = slope;
        elseif and(idxL~=Inf,slope>trunPoint)
           % test whether this is a local turning point or global turnning
           % point;
           idxL = Inf;
           trunPoint = Inf;
        end
    end
    
    p1 = LowBound(idxL,:);

%% Find Higher Knee via approximating with slope
    idxU = Inf;
    % Slope method, Upbound
    trunPoint = Inf;
    for i = 1:length(slopeU)
        slope = abs(slopeU(i));
        if and(idxU==Inf,slopeU(i)>=-1)
           idxU = i;
           trunPoint = slope;
        elseif and(idxU~=Inf,slope>trunPoint)
           % test whether this is a local turning point or global turnning
           % point;
           idxU = Inf;
           trunPoint = Inf;
        end
    end

    p2 = UpBound(idxU,:);

%% Calculate the distance between points
points_d = [p1;p2];
modulus_distance = pdist(points_d,'euclidean');

%% Construct y=x line
    fLine = @(x) (x-p1(1))+p1(2);
    xVals = linspace(p1(1),max(UpCurve(:,1)),1000);
    yVals = fLine(xVals);
    
%% Find cross point of thy line with upper points
    idx_crs = Inf;
    allX = UpCurve(:,1);
    allY = UpCurve(:,2);
    for i = 1:length(xVals)
        locX = xVals(i);
        locY = yVals(i);
        range = find(allX>=locX);
        rangeY = allY(range);
        Vals = find(rangeY>=locY);
        if isempty(Vals)
            if idx_crs==Inf
                idx_crs = i;
            end
        end
    end
    Pcrs = [xVals(idx_crs),yVals(idx_crs)];
    % Restric the limit of the line
    
    xVals = linspace(min(pp(:,1)),Pcrs(1),1000);
    yVals = fLine(xVals);
    line = [xVals',yVals'];
    
%% Find data-points bounded by two lines
    lineH = @(x) (x-p1(1))+p1(2)+0.05;
    lineL = @(x) (x-p1(1))+p1(2)-0.05;
    yH = lineH(xVals);
    yL = lineL(xVals);
    
    % find points
    index = [];
    for i = 1:length(pp)
        % if point below lineH
        if pp(i,2) < lineH(pp(i,1))
            % if the point above lineL
            if pp(i,2) > lineL(pp(i,1))
                index(end+1) = i;
            end
        end
    end
    
    Pin = pp(index,:);

%% Turn things by 45 degree
    flat = Turn45(Pin);
    
%% Count the amount of points by window method
    xLim = linspace(min(flat(:,1)),max(flat(:,1)),100);
    count = [];
    localX = [];
    for i = 1:length(xLim)-1
        x1 = xLim(i);
        x2 = xLim(i+1);
        localP = flat(find(flat(:,1)>=x1),:);
        Pid = find(localP(:,1)<x2);
        count(end+1) = length(Pid);
        localX(end+1) = x1;
    end
    amount = [localX',count'];
    
%% Skewness
    occurance_vector = DataPointDensity(amount);
    Skewness = skewness(occurance_vector);
    
%% Plot
    if plot_individual(1) == true
        figure; grid on; hold on;
        xticks(min(norm):0.1:max(norm));
        yticks(min(esd):0.1:max(esd));
        xlim([min(xVals),max(xVals)])
        ylim([min(yVals),max(yVals)]);
        if plot_line == true
            plot(Pin(:,1),Pin(:,2),'co');
        end
        plot(p1(1),p1(2),'r*');
        plot(p2(1),p2(2),'g*');
        plot(points_d(:,1),points_d(:,2),'g-');
        plot(Pcrs(1),Pcrs(2),'m*');
        if plot_line == true
            legend('Selected Points','Lower Elbow Point','Upper Elbow Point','Elbow Distance'...
            ,'Furtherest Point in Range','Location','northwest','AutoUpdate','off')
        else
            legend('Lower Knee Point','Upper Knee Point','Between Knee Distance'...
            ,'End of the Tube','Location','northwest','AutoUpdate','off')
        end
        
        plot(LowBound(:,1),LowBound(:,2),'Color','#7E2F8E'); 
        plot(UpBound(:,1),UpBound(:,2),'Color','#7E2F8E'); 
        if plot_line == true
            plot(norm(:),esd(:),'.'); 
        end
        plot(points_d(:,1),points_d(:,2),'g-');
        plot(p1(1),p1(2),'r*');
        plot(p2(1),p2(2),'g*');
        plot(xVals(:),yH(:),'k--');
        plot(xVals(:),yL(:),'k--');
        plot(xVals(:),yVals(:),'Color','#77AC30'); hold off
        plot_1_title = append('Data Selected of',' ',DataName);
        title(plot_1_title);
        xlabel('Normalised Intensity');
        ylabel('sigma/I');

        figure;grid on; 
        plot(amount(:,1),smooth(amount(:,2)));
        plot_2_title = append('Point distribution',' ',DataName);
        title(plot_2_title);
        xlabel('Normalised Intensity');
        ylabel('Amount of Datapoints');
        
        figure; hold on; grid on;
        plot_3_title = append('Curve fitting result',' ',DataName);
        plot(LowBound(:,1),FitLow(:),'r--'); 
        plot(UpBound(:,1),FitHigh(:),'b--'); 
        plot(LowBound(:,1),LowBound(:,2),'c-'); 
        plot(UpBound(:,1),UpBound(:,2),'g-'); 
        legend('Fitted Curve for Lower Boundary','Fitted Curve for Upper Boundary'...
            ,'Lower Boundary','Upper Boundary')
        title(plot_3_title);
        hold off
    end
%% Text Output
    formatSpec1 = append('Skewness of',' ',DataName,': %.4f\n');
    fprintf(formatSpec1,Skewness);
    
    formatSpec2 = append(DataName,' best fitted Curve of its Lower boundary:\n');
    fprintf(formatSpec2);
    fprintf('%.4d.2/(%.4d^x) + %.4d\n',Lower_coef(1),Lower_coef(2),Lower_coef(3));
    
    formatSpec3 = append(DataName,' best fitted Curve of its Upper boundary:\n');
    fprintf(formatSpec3);
    fprintf('%.4d/(%.4d^x) + %.4d\n\n',Upper_coef(1),Upper_coef(2),Upper_coef(3));
end

