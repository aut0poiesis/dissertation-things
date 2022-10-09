% Collapse all fixation data to their respective frames, for every subject,
% every visit, and every stimulus video, into a 4-dim structure. 
% Use this data structure for entropy analyses.
% y dim -> video frame
% x dim -> subject
% z dim -> visit
% 4th dim -> video

etdatadir = '/Users/eugenemkim/Desktop/Longitudinal Data/Fixations Coregistered/';

load('aois.mat');
vidnames = ans.XLS.SheetNames;
vidframes = [498; 765; 1093; 677; 668; 552; 862; 626; 495; 695; 499; 470; 472; 987; 839; 1220];

load('subVisitInfo.mat');
subids = readtable('subids.xlsx');
nSubs = size(subids.subject,1);
visitind = [4 5 6 7 8 9 10 11 12 20];

f1 = 'Bear1'; f2 = 'Bear2'; f3 = 'Bear3'; f4 = 'Crayons1'; f5 = 'Cup1'; f6 = 'Cup2';
f7 = 'Cup4'; f8 = 'Cup5'; f9 = 'Present2'; f10 = 'Present3'; f11 = 'Puzzle1'; 
f12 = 'Rings1'; f13 = 'Rings2'; f14 = 'Rings4'; f15 = 'Scissors4'; f16 = 'Shapes4';
master = struct(f1,nan(498,nSubs,10),f2,nan(765,nSubs,10),f3,nan(1093,nSubs,10), ...
    f4,nan(677,nSubs,10),f5,nan(668,nSubs,10),f6,nan(552,nSubs,10),f7,nan(862,nSubs,10), ...
    f8,nan(626,nSubs,10),f9,nan(495,nSubs,10),f10,nan(695,nSubs,10),...
    f11,nan(499,nSubs,10),f12,nan(470,nSubs,10),f13,nan(472,nSubs,10),...
    f14,nan(987,nSubs,10),f15,nan(839,nSubs,10),f16,nan(1220,nSubs,10));

for m = 1:10
    vm = num2str(visitind(m));
    eval(['master.M' vm '= cell(16,1);']);
    for i = 1:16
        eval(['master.M' vm '{i} = NaN(vidframes(i),4,nSubs);']);
    end
end

for s = 1:nSubs

    clear subdata
    currSub = subids.subject{s};
    visits = eval(['subVisitInfo.' currSub '.visits']);
    whichtrials = readtable([currSub '.xlsx']);
    
    for v = 1:length(visits)
        % which visit
        cv = num2str(visits(v));
        load([etdatadir '/' currSub '/' cv 'mo/SubjectData_' cv 'mo.mat']);
        
        % get the good trials
        eval(['gt = whichtrials.x' cv 'mo;']);
        
        % pull the relevant data from the subdata structure
        framelist = subdata.FrameList;
        fixdat = subdata.Fixations;
        aoidat = subdata.PrelimAOI;
        
        if isfield(subdata,'VideoType')
            stims = subdata.VideoType;
        else
            stims = subdata.WhatsOn.Names;
        end
        
        for t = 1:length(stims)
            % trial video
            vid = char(stims{t});
            vidind = find(strcmp(vid,vidnames)); 
            eval(['fsize = length(master.' vid ');']);
            triaois = zeros(fsize,1);
            
            if gt(t) == 1
                
                fixind = [fixdat{t}.fixbegin' fixdat{t}.fixend'];
                for f = 1:size(fixind,1)
                    whichaoi = aoidat{t}(f);
                    whichframes = unique(framelist{t}(fixind(f,1):fixind(f,2)))';
                    triaois(whichframes) = whichaoi;
                end
                
                % add pupil data at this step...
                flist = subdata.FrameList{t};
                xcenter = zeros(length(unique(flist)),1); 
                ycenter = zeros(length(unique(flist)),1);
                xpos = subdata.Filtered.FiltX(t,strcmp(subdata.CurrentObject{t},'Video'));
                ypos = subdata.Filtered.FiltY(t,strcmp(subdata.CurrentObject{t},'Video'));
                for j = 1:length(unique(flist))
                    xcenter(j) = nanmean(xpos(flist==j));
                    ycenter(j) = nanmean(ypos(flist==j));
                end
               
               % rows -> frame number
               % columns: 1) AOI ; 2) X position ; 3) Y position ; 4) pupil
               eval(['master.M' cv '{vidind}(1:length(triaois),1,s) = triaois;']);
               eval(['master.M' cv '{vidind}(1:length(xcenter),2:3,s) = [xcenter ycenter];']);
                
            else
                triaois(:) = NaN;
            end
            
            cv2 = str2double(cv);
            tempind = num2str(find(visitind==cv2));
            eval(['master.' vid '(1:length(triaois),s,' tempind ') = triaois;']);
            
        end
        clear subdata 
    end
    
end

clearvars -except master