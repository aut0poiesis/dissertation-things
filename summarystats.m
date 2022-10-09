etdatadir = '/Users/eugenemkim/Desktop/Longitudinal Data/Fixations Coregistered/';

load('subVisitInfo.mat');
subids = readtable('subids.xlsx');
nSubs = size(subids.subject,1);

allData = [];

for s = 1:nSubs
    clear subdata
    currSub = subids.subject{s};
    visits = eval(['subVisitInfo.' currSub '.visits']);
    whichtrials = readtable([currSub '.xlsx']);
    eval(['allData.' currSub '= [];']);
    
    for v = 1:length(visits)
        tp = num2str(visits(v));
        gtind = ['x' tp 'mo'];
        load([etdatadir '/' currSub '/' tp 'mo/SubjectData_' tp 'mo.mat']);
        goodtrials = eval(['whichtrials.' gtind]);
        
        propFixFace = [];
        propFixHo = [];
        duraFace = [];
        duraHo = [];
        for t = 1:length(goodtrials)
            
            if goodtrials(t) == 1
                
                numFix = length(subdata.PrelimAOI{t});
%                 numFix = length(subdata.HMM{t}.est.state);
                
                % Calculate relative proportion of fixations to face and
                % hands/objects
                propFixFace = [propFixFace; sum(subdata.PrelimAOI{t}==1)/numFix];
                propFixHo = [propFixHo; sum(subdata.PrelimAOI{t}==2)/numFix];
%                 propFixFace = [propFixFace; sum(subdata.HMM{t}.est.state==1)/numFix];
%                 propFixHo = [propFixHo; sum(subdata.HMM{t}.est.state==2)/numFix];
                
                % Calculate fix durations to face and hands/objects
                faceInd = subdata.PrelimAOI{t}==1;
                hoInd = subdata.PrelimAOI{t}==2;
                duraFace = [duraFace; subdata.Fixations{t}.fixdurations(faceInd)'];
                duraHo = [duraHo; subdata.Fixations{t}.fixdurations(hoInd)'];
                
                
            else
                continue
            end
            
        end
        
        eval(['allData.' currSub '.mo' tp '.PropFixFace = propFixFace;']);
        eval(['allData.' currSub '.mo' tp '.PropFixHo = propFixHo;']);
        eval(['allData.' currSub '.mo' tp '.FaceFixDurations = duraFace;']);
        eval(['allData.' currSub '.mo' tp '.HoFixDurations = duraHo;']);
        
        
    end
end

% rows are subjects, and columns are visits
FaceFixProportion = nan(nSubs,10);
HoFixProportion = nan(nSubs,10);
FaceDurations = nan(nSubs,10);
HoDurations = nan(nSubs,10);
visitarray = [4 5 6 7 8 9 10 11 12 20];
for i = 1:nSubs
    currSub = subids.subject{i};
    visits = eval(['subVisitInfo.' currSub '.visits']);
    
    for j = 1:length(visits)
        currVisit = num2str(visits(j));
        visitind = find(visitarray==visits(j));
        eval(['FaceFixProportion(i,visitind) = mean(allData.' currSub '.mo' currVisit '.PropFixFace);']);
        eval(['HoFixProportion(i,visitind) = mean(allData.' currSub '.mo' currVisit '.PropFixHo);']);
        eval(['FaceDurations(i,visitind) = mean(allData.' currSub '.mo' currVisit '.FaceFixDurations);']);
        eval(['HoDurations(i,visitind) = mean(allData.' currSub '.mo' currVisit '.HoFixDurations);']);
    end
    
end

% draw preliminary figures

%% Proportion of fixations to face across age
figure()
y = FaceFixProportion;
x = repmat(1:10,nSubs,1);
sc = scatter(x(:),y(:));
xlim([0.5 10.5]);
ylim([0 1]);
hold on

% draw a smooth fitting curve through data points
xx = 1:10;
yy = nanmean(FaceFixProportion,1);
xq = 0.8:0.02:10.2;
p = polyfit(xx,yy,3);
v = polyval(p,xq);
pl = plot(xx,yy,'o',xq,v,'-','LineWidth',3);

% proportion of fixations to hands/objects across age
y = HoFixProportion;
y(y==0) = NaN;
sc = scatter(x(:),y(:));
xlim([0.5 10.5]);
ylim([0 1]);
hold on

yy = nanmean(y,1);
p = polyfit(xx,yy,3);
v = polyval(p,xq);
pl = plot(xx,yy,'o',xq,v,'-','LineWidth',6);

% adjust plot graphics
sc.MarkerEdgeColor = 'k';
sc.MarkerFaceColor = 'b';
sc.MarkerFaceAlpha = 0.5;
sc.SizeData = 100;

pl(1).MarkerEdgeColor = 'k';
pl(1).MarkerFaceColor = 'b';
pl(1).LineWidth = 1;
pl(1).MarkerSize = 10;
pl(2).Color = [0 0 0];
pl(2).LineWidth = 6;

%% Fixation durations across age

% Face
y = FaceDurations;
y(y==0) = NaN;
sc = scatter(x(:),y(:));
xlim([0.9 10.1]);
ylim([min(min(y))-100 max(max(y))+100]);
hold on
sc.MarkerEdgeColor = 'k';
sc.MarkerFaceColor = 'b';
sc.MarkerFaceAlpha = 0.5;
sc.SizeData = 100;

yy = nanmean(y,1);
p = polyfit(xx,yy,3);
v = polyval(p,xq);
pl = plot(xx,yy,'o',xq,v,'-','LineWidth',6);

pl(1).MarkerEdgeColor = 'k';
pl(1).MarkerFaceColor = 'b';
pl(1).LineWidth = 1;
pl(1).MarkerSize = 10;
pl(2).Color = [0 0 0];
pl(2).LineWidth = 6;

% Hands/objects
y = HoDurations;
y(y==0) = NaN;
sc = scatter(x(:),y(:));
xlim([0.9 10.1]);
ylim([min(min(y))-100 max(max(y))+100]);
hold on
sc.MarkerEdgeColor = 'k';
sc.MarkerFaceColor = 'r';
sc.MarkerFaceAlpha = 0.5;
sc.SizeData = 100;

yy = nanmean(y,1);
p = polyfit(xx,yy,3);
v = polyval(p,xq);
pl = plot(xx,yy,'o',xq,v,'-','LineWidth',6);

pl(1).MarkerEdgeColor = 'k';
pl(1).MarkerFaceColor = 'r';
pl(1).LineWidth = 1;
pl(1).MarkerSize = 10;
pl(2).Color = [0 0 0];
pl(2).LineWidth = 6;