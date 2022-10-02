function overlayfix2(etdata,video)

overlayoutdir = '/Users/eugenemkim/Desktop/Longitudinal Data/Gaze-Stim Overlay';

whichVid = video;
stillsdir = ['/Users/eugenemkim/Desktop/Longitudinal Data/Longitudinal Study Stimulus Stills/' whichVid '/'];

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
targetsize = [1080 NaN];

imgborder = zeros(1080,240,3);
h = waitbar(0,'Importing images...');
for i = 1:numstillsinfolder
    stills_struct{i} = imread([stillsdir '/' folderContents(i).name]); 
    stills_struct{i} = imresize(stills_struct{i},targetsize);
    stills_struct{i} = horzcat(imgborder,stills_struct{i},imgborder);
    stills_struct{i} = imresize(stills_struct{i},[800 NaN]);
    waitbar(i/numstillsinfolder,h);
end       
close(h);

whichTrial = find(cellfun(@(x) any(strcmp(x,'Puzzle1')),etdata.WhatsOn.Names));

phasebegin = find(strcmp(etdata.CurrentObject{whichTrial},'Video'),1);
phasestop = length(etdata.CurrentObject{whichTrial});

xdata = etdata.Filtered.FiltX(whichTrial,phasebegin:phasestop)*1423;
ydata = etdata.Filtered.FiltY(whichTrial,phasebegin:phasestop)*800;

% calculate centroid of xy coordinates
onFrames = etdata.FrameList{whichTrial};
xcenter = zeros(length(unique(onFrames)),1); 
ycenter = zeros(length(unique(onFrames)),1);
for f = 1:length(unique(onFrames))
    xcenter(f) = nanmean(xdata(onFrames==f));
    ycenter(f) = nanmean(ydata(onFrames==f));
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
    
    ax = gca; set(ax,'Visible','off'); hold on;
    plot(xcenter(i),ycenter(i),'+','MarkerSize',22,'LineWidth',3,'color','y');
    fig = gcf;
    scaleImageBy = 0.5;
    newSizeParameters = fig.Position*scaleImageBy;
    set(gcf,'Position',newSizeParameters);
    
    fn = num2str(i);
    padding = [num2str(zeros(1,4-length(fn))),fn];
    outstillname = strrep(padding,' ','');
    export_fig([overlayoutdir '/' whichVid '_' outstillname '.jpg']);
    clf
end

end