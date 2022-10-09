function overlayfix2(subject,age,video)

load('MasterDataStruct.mat');
overlayoutdir = '/Users/eugenemkim/Desktop/Longitudinal Data/Gaze-Stim Overlay';

whichVid = video;
subdatadir = '/Users/eugenemkim/Desktop/Longitudinal Data/Fixations Coregistered/';
stillsdir = ['/Users/eugenemkim/Desktop/Longitudinal Data/Longitudinal Study Stimulus Stills/' whichVid '/'];
sublist = readtable('subids.xlsx');
subind = find(strcmp(sublist.subject,subject));
visitind = [4 5 6 7 8 9 10 11 12 20];

load([subdatadir '/' subject '/' num2str(age) 'mo/SubjectData_' num2str(age) 'mo.mat'])

eval(['fixaois = master.' video '(:,subind,find(visitind==age));']);

folderContents = dir(stillsdir);
for i = 1:length(folderContents)
    if regexp(folderContents(i).name,whichVid) == 1
        startAtThisIndex = i;
        break
    else
        continue
    end
end

folderContents = folderContents(startAtThisIndex:end);
numstillsinfolder = length(dir([stillsdir, '/*.jpg']));
stills_struct = cell(numstillsinfolder,1);
targetsize = [410 NaN];

imgborder = zeros(410,91,3);
h = waitbar(0,'Importing images...');
for i = 1:numstillsinfolder
    stills_struct{i} = imread([stillsdir '/' folderContents(i).name]); 
    stills_struct{i} = imresize(stills_struct{i},targetsize);
    stills_struct{i} = horzcat(imgborder,stills_struct{i},imgborder);
%     stills_struct{i} = imresize(stills_struct{i},[410 NaN]);
    waitbar(i/numstillsinfolder,h);
end       
close(h);

whichTrial = find(cellfun(@(x) any(strcmp(x,video)),subdata.WhatsOn.Names));

phasebegin = find(strcmp(subdata.CurrentObject{whichTrial},'Video'),1);
phasestop = length(subdata.CurrentObject{whichTrial});

xdata = subdata.Filtered.FiltX(whichTrial,phasebegin:phasestop)*729;
ydata = subdata.Filtered.FiltY(whichTrial,phasebegin:phasestop)*410;

% calculate centroid of xy coordinates
onFrames = subdata.FrameList{whichTrial};
xcenter = zeros(length(unique(onFrames)),1); 
ycenter = zeros(length(unique(onFrames)),1);
for f = 1:length(unique(onFrames))
    xcenter(f) = nanmean(xdata(onFrames==f));
    ycenter(f) = nanmean(ydata(onFrames==f));
end

% get fixation identifier (the nth fixation in sequence). to display on
% overlay so you know the nth fixation being displayed on screen
temp = find(fixaois>0);
nthfix = zeros(length(fixaois),1);
fixseqid = 1;
for k = 1:length(temp)
    while k < length(temp)
        if diff([temp(k) temp(k+1)]) == 1
            nthfix(temp(k)) = fixseqid;
            break
        else
            nthfix(temp(k)) = fixseqid;
            fixseqid = fixseqid + 1;
            break
        end
    end
    if k == length(temp)
        nthfix(temp(k)) = fixseqid;
    end
end


% overlay xy gaze point over still frames
iptsetpref('ImshowBorder','tight');
figure('Visible','off');

uniqframes = unique(onFrames);
for i = 1:length(unique(onFrames))
    onscreenf = uniqframes(i);
    try
        imshow(stills_struct{onscreenf});
    catch errors
    end
    
    if fixaois(i) == 1
        c = [1 1 0];
    elseif fixaois(i) == 2
        c = [0 1 0];
    else
        c = [0 0 1];
    end
    
    ax = gca; set(ax,'Visible','off'); hold on;
    plot(xcenter(i),ycenter(i),'+','MarkerSize',17,'LineWidth',3,'color',c);
    
    fig = gcf;
    scaleImageBy = 0.7;
    newSizeParameters = fig.Position*scaleImageBy;
    set(gcf,'Position',newSizeParameters);
    
    text(495,20,['Fixation # ' num2str(nthfix(i))],'FontSize',16,'Color','y','FontWeight','bold');
    
    fn = num2str(i);
    padding = [num2str(zeros(1,4-length(fn))),fn];
    outstillname = strrep(padding,' ','');
    if exist([overlayoutdir '/' whichVid '_' outstillname '.jpg'],'file')
        clf
        continue
    end
    export_fig([overlayoutdir '/' whichVid '_' outstillname '.jpg']);
    clf
end

end