% specify directory for ET data
etdatadir = '/Users/eugenemkim/Desktop/Longitudinal Data/Subject Data Preprocessed';
etoutdir = '/Users/eugenemkim/Desktop/Longitudinal Data/Fixations Coregistered/';

load('AOICoords.mat');
load('subVisitInfo.mat');
subids = readtable('subids.xlsx');
nSubs = size(subids.subject,1);
tempaoistruct = load('aoiOrganized.mat');
allAOIs = tempaoistruct.dat;

%% set all HMM parameters
% names of states

% hmmProps.stateNames = {'Face','Obj','Neither'};
% % transition matrix
% hmmProps.tr = [.5,0.49,0.01;0.49,.5,0.01;.25,.25,.5]; %90% stay
% % emission probabilities
% % for each state, pick a distribution shape and parameters
% hmmProps.emit.distance.param = {'exp',100,1;'exp',100,1;'unif',0,1000};
% % we have to discretize our data; pick a discretization size
% hmmProps.emit.distance.xVals = [0:10:1000];
% % size of bins
% hmmProps.emit.distance.xTick = mean(diff(hmmProps.emit.distance.xVals));
% % make the emission distributions
% for s = 1:length(hmmProps.stateNames)
%     hmmProps.emit.distance.p(s,:) = pdf(hmmProps.emit.distance.param{s,1},...
%         hmmProps.emit.distance.xVals,hmmProps.emit.distance.param{s,2},hmmProps.emit.distance.param{s,3});
% end

%% Coregister fixations to AOIs
% Looping through each subject
for s = 1:nSubs
    clear subdata
    
    currSub = subids.subject{s};
    visits = eval(['subVisitInfo.' currSub '.visits']);
    if ~exist([etoutdir '/' currSub],'dir')
        mkdir(etoutdir,currSub);
    end
    
    % looping through each visit
    for vt = 1:length(visits)
        
        tp = num2str(visits(vt));
        if exist([etoutdir '/' currSub '/' tp 'mo/SubjectData_' tp 'mo.mat'],'file');
            continue
        end
        load([etdatadir '/' currSub '/' tp 'mo/SubjectData_' tp 'mo.mat']);
        mkdir([etoutdir '/' currSub],[tp 'mo']);
        
        subdata.HMM = [];
        subdata.PrelimAOI = [];
        
        if isfield(subdata,'Fixations')
            
            % looping through each trial of current visit
            for t = 1:length(subdata.CurrentObject)
                subdata.Fixations{t}.fixAOI = [];
                
                if isfield(subdata,'VideoType')
                    vidnum = find(strcmp(subdata.VideoType{t}, AOICoords.XLS.SheetNames));
                else
                    vidnum = find(strcmp(subdata.WhatsOn.Names{t}, AOICoords.XLS.SheetNames));
                end
                nframes = size(AOICoords.Coordinates(vidnum).Corners{1},1);

                phasebegin = find(strcmp(subdata.CurrentObject{t},'Video'),1);
                lastdata = subdata.TrialLengths(t);
                timevec = subdata.TMicroSeconds(t,phasebegin:lastdata);
                timevec = timevec - timevec(1);
                picvec = 1:nframes; picvec = 1000*(picvec-1)/30;
                framelist = nan(1,nframes);
                for p = 1:length(timevec)
                    framelist(p) = find(timevec(p)>=picvec,1,'last');
                end
                
                % update subdata.TrialLength to reflect adjusted length
                % after removing AG frames at beginning of trial
                subdata.TrialLengths(t) = length(subdata.CurrentObject{t}(phasebegin:end));
                
                subdata.FrameList{t} = framelist;
                
                aoiLocs = allAOIs(:,:,:,vidnum);
                
                trialFix = subdata.Fixations{t};
                tData.X = subdata.Filtered.FiltX(t,phasebegin:lastdata);
                tData.Y = subdata.Filtered.FiltY(t,phasebegin:lastdata);
                
                trialFix.fixbegin = trialFix.fixbegin - phasebegin + 1;
                trialFix.fixend = trialFix.fixend - phasebegin + 1;
                removeIndices = trialFix.fixbegin>1;
                trialFix.fixbegin = trialFix.fixbegin(removeIndices);
                trialFix.fixend = trialFix.fixend(removeIndices);
                subdata.Fixations{t}.fixbegin = trialFix.fixbegin;
                subdata.Fixations{t}.fixend = trialFix.fixend;
                subdata.Fixations{t}.fixdurations = subdata.Fixations{t}.fixdurations(removeIndices);
                
                nFix = length(trialFix.fixbegin);
                subdata.Fixations{t}.fixAOI.duration = nan(nFix,7);
                subdata.Fixations{t}.fixAOI.distance = nan(nFix,7);
                
                subdata.Fixations{t}.centroid = nan(nFix,2);
                
                subdata.PrelimAOI{t} = zeros(nFix,1);
                for f = 1:nFix
                    fBeg = trialFix.fixbegin(f);
                    fEnd = trialFix.fixend(f);
                    fixTime = fBeg:fEnd;
                    if fBeg > 0
                        frameBeg = framelist(fBeg);
                        frameEnd = framelist(fEnd);
                        dataFrame = frameBeg:frameEnd;
                        fixFrame = framelist(fBeg:fEnd) - framelist(fBeg) + 1;
                        fX = tData.X(fixTime)' *1920;
                        fY = tData.Y(fixTime)' *1080;
                        
                        subdata.Fixations{t}.centroid(f,1:2) = [mean(fX),mean(fY)];
                        
                        aoiBox = aoiLocs(dataFrame,:,:);
                        faceBox = aoiBox(:,1,:);
                        hoBox = aoiBox(:,4:end,:);
                        faceCntr = [mean(faceBox(:,:,1)+.5*diff(faceBox(:,:,[1,3]),1,3));...
                          mean(faceBox(:,:,2)+.5*diff(faceBox(:,:,[2,4]),1,3))];
                        hoCntr = [mean(hoBox(:,:,1)+.5*diff(hoBox(:,:,[1,3]),1,3),1);...
                          mean(hoBox(:,:,2)+.5*diff(hoBox(:,:,[2,4]),1,3),1)];
          
                        faceLook = fX >= faceBox(fixFrame,:,1) & fX <= faceBox(fixFrame,:,3) & ...
                          fY >= faceBox(fixFrame,:,2) & fY <= faceBox(fixFrame,:,4);
                        fXr = repmat(fX,[1,6,1]);
                        fYr = repmat(fY,[1,6,1]);
                        hoLook = fXr >= hoBox(fixFrame,:,1) & fXr <= hoBox(fixFrame,:,3) & ...
                          fYr >= hoBox(fixFrame,:,2) & fYr <= hoBox(fixFrame,:,4);
          
                        faceDist = sqrt(sum([mean(fX - faceCntr(1));mean(fY - faceCntr(2))].^2));
                        hoDist = sqrt(sum(cat(3,mean(fXr - repmat(hoCntr(1,:),size(fXr,1),1)),...
                          mean(fYr - repmat(hoCntr(2,:),size(fYr,1),1))).^2,3));
                      
                        subdata.Fixations{t}.fixAOI.duration(f,1) = sum(faceLook) * (1000/subdata.SampleRate);
                        subdata.Fixations{t}.fixAOI.duration(f,2:end) = sum(hoLook) * (1000/subdata.SampleRate);
                        subdata.Fixations{t}.fixAOI.distance(f,1) = faceDist;
                        subdata.Fixations{t}.fixAOI.distance(f,2:end) = hoDist;
                        
                        minDistVal = min(subdata.Fixations{t}.fixAOI.distance(f,:));
                        if minDistVal > 300
                            subdata.PrelimAOI{t}(f) = 3;
                        else
                            minDistAll = min(subdata.Fixations{t}.fixAOI.distance(f,:));
                            minDistInd = find(subdata.Fixations{t}.fixAOI.distance(f,:)==minDistVal);
                            if minDistInd == 1
                            subdata.PrelimAOI{t}(f) = 1;
                            else
                            subdata.PrelimAOI{t}(f) = 2;
                            end
                        end
                    end
                end
                
%                 % apply HMM to preliminary AOI classifications
%                 dist = subdata.Fixations{t}.fixAOI.distance;
%                 
%                 % compute the smallest distance to an object (if you also want to
%                 % include hands, include columns 2 & 3 here).
%                 minObjDist = min(dist(:,4:end),[],2); 
%                 
%                 % concatenate them and transpose to work with the hmm functions
%                 foDist = [dist(:,1),minObjDist,]';
%                 
%                 % compute the difference between the face dist and obj dist. this
%                 % is used to determine if the 'neither' state is a good fit.
%                 % Basically if dist to face is high and dist to objs is high, dist
%                 % to 'neither' ends up being low. This is evidence that it's
%                 % 'neither'
%                 foDist(3,:) = abs(diff(foDist));
%                 
%                 % discretize into bins
%                 distBin = max(1,...
%                   min(floor(foDist / hmmProps.emit.distance.xTick),...
%                   length(hmmProps.emit.distance.xVals)));
%                 
%                 % Feed the distances and the properties of the hmm into the
%                 % built-in classifier function
% 
%                 % est.state is the estimated state vector
%                 % vStore is the emission probability, aka p(observedData |
%                 % assignedState). I don't use it but it might be interesting
%                 try
%                     [hmmProps.est.state,hmmProps.est.vStore] = ...
%                       hmmviterbi(distBin,hmmProps.tr,hmmProps.emit.distance.p);
%                 catch errors
%                 end
% 
%                 % hmmProps.subData{s,t} = hmm;
%                 subdata.HMM{t} = hmmProps;
                
            end  
        end
        
        % save the updated subdata file for this visit to new directory
        save([etoutdir currSub '/' tp 'mo/SubjectData_' tp 'mo.mat'],'subdata')
        
    end
    
end