function ETT = add_FixationAoi(ETT, Subject)
% keyboard
try
  homefold = [cd '\resources\ProjectData - Fixations\'];
  subn = ETT.Subjects(Subject).Name;
  load([homefold subn '\SubjectData_' subn '.mat']);  
  subdata = ett_loadSub(ETT,Subject);
  
  SA = [];
  SA = resLoad('SA'); 
  
  
  % age = subdata.Age;2
  
  if isfield(subdata,'Fixations')
    for T = 1:length(subdata.VideoType)
      subdata.Fixations{T}.fixAOI = [];
      
      vidnum = find(strcmp(subdata.VideoType{T}, ETT.AOICoords.XLS.SheetNames));
      nframes = size(ETT.AOICoords.Coordinates(vidnum).Corners{1},1);
      
      phasebegin = subdata.WhatsOn.Begindices{T}(strcmp(subdata.WhatsOn.Names{T},'Video'));
      lastdata = subdata.TrialLengths(T);
      timevec = subdata.TMicroSeconds(T,phasebegin:lastdata); timevec = timevec - timevec(1);
      picvec = 1:nframes; picvec = 1000*(picvec-1)/30;
      framelist = nan(1,nframes);
      for p = 1:length(timevec)
        framelist(p) = find(timevec(p)>=picvec,1,'last');
      end
      
      subdata.FrameList{T} = framelist;
      
      aoiLocs = SA.aoiLocations(:,:,:,vidnum);
      
      trialFix = subdata.Fixations{T};
      nFix = length(trialFix.fixbegin);
      subdata.Fixations{T}.fixAOI.duration = nan(nFix,7);
      subdata.Fixations{T}.fixAOI.distance = nan(nFix,7);
      
      tData.X = subdata.Filtered.FiltX(T,phasebegin:lastdata);
      tData.Y = subdata.Filtered.FiltY(T,phasebegin:lastdata);
      
      trialFix.fixbegin = trialFix.fixbegin - phasebegin + 1;
      trialFix.fixend = trialFix.fixend - phasebegin + 1;
      subdata.Fixations{T}.centroid = nan(nFix,2);
      for f = 1:nFix
        fBeg = trialFix.fixbegin(f);
        fEnd = trialFix.fixend(f);
        fixTime = fBeg:fEnd;
        
        if fBeg > 0
                    
          frameBeg = framelist(fBeg);
          frameEnd = framelist(fEnd);
          dataFrame = frameBeg:frameEnd;
          fixFrame = framelist(fBeg:fEnd) - framelist(fBeg) + 1;
          fX = tData.X(fixTime)' * ETT.ScreenDim.PixX;
          fY = tData.Y(fixTime)' *ETT.ScreenDim.PixY;
          
          subdata.Fixations{T}.centroid(f,1:2) = [mean(fX),mean(fY)];
          
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
          
          subdata.Fixations{T}.fixAOI.duration(f,1) = sum(faceLook) * (1000/subdata.SampleRate);
          subdata.Fixations{T}.fixAOI.duration(f,2:end) = sum(hoLook) * (1000/subdata.SampleRate);
          subdata.Fixations{T}.fixAOI.distance(f,1) = faceDist;
          subdata.Fixations{T}.fixAOI.distance(f,2:end) = hoDist;
          
          
        end
      end
%         keyboard
      
      
    end
    try
      save([homefold subn '\SubjectData_' subn '.mat'],'subdata');
    catch
      pause(1)
      save([homefold subn '\SubjectData_' subn '.mat'],'subdata');
    end
    data(Subject).duration = subdata.Fixations{T}.fixAOI.duration;
    data(Subject).distance = subdata.Fixations{T}.fixAOI.distance;
    data_save('FixationAOI',data)
  end
catch err
  ett_errorhandle(err)
end