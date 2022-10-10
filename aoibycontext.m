% Calculates probability of fixation being directed at faces or
% hands/object as a function of context (e.g., direct/averted gaze and
% object directed action/gesture

% load subject information
subjects = readtable('subids.xlsx');
nsubs = length(subjects.subject);
load('subVisitInfo.mat');
load('summaryData.mat');

% load master data structure
load('MasterDataStruct.mat');
aoibyage{1} = master.M4;
aoibyage{2} = master.M5;
aoibyage{3} = master.M6;
aoibyage{4} = master.M7;
aoibyage{5} = master.M8;
aoibyage{6} = master.M9;
aoibyage{7} = master.M10;
aoibyage{8} = master.M11;
aoibyage{9} = master.M12;
aoibyage{10} = master.M20;

% load and reorganize the context codes
% Columns 1 - 4 correspond to Direct gaze, averted gaze, object action,
% object gesture, respectively.
context = load('contextCodes.mat');
context = context.ans;
allcontext = cell(16,1);
for i = 1:16
    allcontext{i} = [context(i).DirectGaze context(i).ObjectGaze ... 
        context(i).ObjectDirectedAction context(i).GesturewithObject];
end
% 
% % calculate the overall probability of each context occurring (e.g. what is
% % the probability that gaze is direct of all gaze states recorded
% gp = [];
% op = [];
% for i = 1:16
%     gp = [gp; sum(allcontext{i}(:,1))/length(allcontext{i}(:,1))];
%     op = [op; sum(allcontext{i}(:,3))/length(allcontext{i}(:,3))];
% end
% probdirectgaze = mean(gp);
% probobjgaze = 1-probdirectgaze;
% probobjaction = mean(op);
% probobjgesture = 1-probobjaction;

% preallocate arrays for each of the context AOIs
directgaze = nan(nsubs,10,2);
objectgaze = nan(nsubs,10,2);
objaction = nan(nsubs,10,2);
objgesture = nan(nsubs,10,2);

% preallocate arrays for baserates of concurrent fixation contexts
directgaze_br = nan(nsubs,10,2);
objectgaze_br = nan(nsubs,10,2);
objaction_br = nan(nsubs,10,2);
objgesture_br = nan(nsubs,10,2);

% calculate probability of looking at face during each gaze context
for v = 1:10
    visitaois = aoibyage{v};
    for s = 1:nsubs
        whichgaze = [];
        whichgazeany = [];
        whichaction = [];
        whichactionany = [];
%         facefixcount = 0;
        for c = 1:16
            whichaois = visitaois{c}(:,1,s);
            gazecodes = allcontext{c}(1:size(visitaois{c},1),1:2);
            actioncodes = allcontext{c}(1:size(visitaois{c},1),3:4);
            faceind = find(whichaois==1);
            
            whichcode = [];
            whichactcode = [];
            for f = 1:length(faceind)
                whichcode = [whichcode; gazecodes(faceind(f),:)];
                whichactcode = [whichactcode; actioncodes(faceind(f),:)];
                if f == length(faceind)
%                     facefixcount = facefixcount + 1;
                    [~,I] = max(sum(whichcode));
                    [~,II] = max(sum(whichactcode));
                    whichgaze = [whichgaze; I];
                    whichaction = [whichaction; II];
                    whichcode = [];
                    whichactcode = [];
                elseif diff([faceind(f) faceind(f+1)]) > 1
%                     facefixcount = facefixcount + 1;
                    [~,I] = max(sum(whichcode));
                    [~,II] = max(sum(whichactcode));
                    whichgaze = [whichgaze; I];
                    whichaction = [whichaction; II];
                    whichcode = [];
                    whichactcode = [];
                    continue  
                end
                    
            end
            
            % calculate base rate of diff cues occurring for each fixations
            anyind = find(whichaois>0);
            whichcodeany = [];
            whichactcodeany = [];
            for a = 1:length(anyind)
                whichcodeany = [whichcodeany; gazecodes(anyind(a),:)];
                whichactcodeany = [whichactcodeany; actioncodes(anyind(a),:)];
                if a == length(anyind)
                    [~,B] = max(sum(whichcodeany));
                    [~,BB] = max(sum(whichactcodeany));
                    whichgazeany = [whichgazeany; B];
                    whichactionany = [whichactionany; BB];
                    whichcodeany = [];
                    whichactcodeany = [];
                elseif diff([anyind(a) anyind(a+1)]) > 1
                    [~,B] = max(sum(whichcodeany));
                    [~,BB] = max(sum(whichactcodeany));
                    whichgazeany = [whichgazeany; B];
                    whichactionany = [whichactionany; BB];
                    whichcodeany = [];
                    whichactcodeany = [];
                end
            end
        end
        
        directgaze(s,v,1) = sum(whichgaze==1)/length(whichgaze);
        objectgaze(s,v,1) = sum(whichgaze==2)/length(whichgaze);
        objaction(s,v,1) = sum(whichaction==1)/length(whichaction);
        objgesture(s,v,1) = sum(whichaction==2)/length(whichaction);
        
        directgaze_br(s,v,1) = sum(whichgazeany==1)/length(whichgazeany);
        objectgaze_br(s,v,1) = sum(whichgazeany==2)/length(whichgazeany);
        objaction_br(s,v,1) = sum(whichactionany==1)/length(whichactionany);
        objgesture_br(s,v,1) = sum(whichactionany==2)/length(whichactionany);
    end
    
end

% repeat for object/hand fixations
for v = 1:10
    visitaois = aoibyage{v};
    for s = 1:nsubs
        whichgaze = [];
        whichgazeany = [];
        whichaction = [];
        whichactionany = [];
%         facefixcount = 0;
        for c = 1:16
            whichaois = visitaois{c}(:,1,s);
            gazecodes = allcontext{c}(1:size(visitaois{c},1),1:2);
            actioncodes = allcontext{c}(1:size(visitaois{c},1),3:4);
            objind = find(whichaois==2);
            
            whichcode = [];
            whichactcode = [];
            for f = 1:length(objind)
                whichcode = [whichcode; gazecodes(objind(f),:)];
                whichactcode = [whichactcode; actioncodes(objind(f),:)];
                if f == length(objind)
                    [~,I] = max(sum(whichcode));
                    [~,II] = max(sum(whichactcode));
                    whichgaze = [whichgaze; I];
                    whichaction = [whichaction; II];
                    whichcode = [];
                    whichactcode = [];
                elseif diff([objind(f) objind(f+1)]) > 1
                    [~,I] = max(sum(whichcode));
                    [~,II] = max(sum(whichactcode));
                    whichgaze = [whichgaze; I];
                    whichaction = [whichaction; II];
                    whichcode = [];
                    whichactcode = [];
                    continue  
                end
                    
            end
            
            % calculate base rate of diff cues occurring for each fixations
            anyind = find(whichaois>0);
            whichcodeany = [];
            whichactcodeany = [];
            for a = 1:length(anyind)
                whichcodeany = [whichcodeany; gazecodes(anyind(a),:)];
                whichactcodeany = [whichactcodeany; actioncodes(anyind(a),:)];
                if a == length(anyind)
                    [~,B] = max(sum(whichcodeany));
                    [~,BB] = max(sum(whichactcodeany));
                    whichgazeany = [whichgazeany; B];
                    whichactionany = [whichactionany; BB];
                    whichcodeany = [];
                    whichactcodeany = [];
                elseif diff([anyind(a) anyind(a+1)]) > 1
                    [~,B] = max(sum(whichcodeany));
                    [~,BB] = max(sum(whichactcodeany));
                    whichgazeany = [whichgazeany; B];
                    whichactionany = [whichactionany; BB];
                    whichcodeany = [];
                    whichactcodeany = [];
                end
            end
        end
        
        directgaze(s,v,2) = sum(whichgaze==1)/length(whichgaze);
        objectgaze(s,v,2) = sum(whichgaze==2)/length(whichgaze);
        objaction(s,v,2) = sum(whichaction==1)/length(whichaction);
        objgesture(s,v,2) = sum(whichaction==2)/length(whichaction);
        
        directgaze_br(s,v,2) = sum(whichgazeany==1)/length(whichgazeany);
        objectgaze_br(s,v,2) = sum(whichgazeany==2)/length(whichgazeany);
        objaction_br(s,v,2) = sum(whichactionany==1)/length(whichactionany);
        objgesture_br(s,v,2) = sum(whichactionany==2)/length(whichactionany);
    end
    
end

%%  Calculate conditional probabilities
% load and arrange summary data
FaceFixProportion = nan(nsubs,10);
HoFixProportion = nan(nsubs,10);
FaceDurations = nan(nsubs,10);
HoDurations = nan(nsubs,10);
visitarray = [4 5 6 7 8 9 10 11 12 20];
for i = 1:nsubs
    currSub = subjects.subject{i};
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

ConditionalProbabilities(1) = struct('Context',{'Direct Gaze'},'Face',nan(nsubs,10),'Object',nan(nsubs,10));
ConditionalProbabilities(2) = struct('Context',{'Averted Gaze'},'Face',nan(nsubs,10),'Object',nan(nsubs,10));
ConditionalProbabilities(3) = struct('Context',{'Object-directed Action'},'Face',nan(nsubs,10),'Object',nan(nsubs,10));
ConditionalProbabilities(4) = struct('Context',{'Object Gesture'},'Face',nan(nsubs,10),'Object',nan(nsubs,10));

% P(A) provided by summary data arrays
% P(B) provided by ..._br arrays (e.g., directgaze_br)
% P(B|A) provided by directgaze arrays and so on...
% Conditional probability P(A|B) = ( P(A) * P(B|A) ) / P(B)

all_PB = {directgaze_br,objectgaze_br,objaction_br,objgesture_br};
all_PBA = {directgaze,objectgaze,objaction,objgesture};
for p = 1:4
    P_Bface = all_PB{p}(:,:,1);
    P_BAface = all_PBA{p}(:,:,1);
    
    ConditionalProbabilities(p).Face = (FaceFixProportion.*P_BAface)./P_Bface;
    
    P_Bobj = all_PB{p}(:,:,2);
    P_BAobj = all_PBA{p}(:,:,2);
    
    ConditionalProbabilities(p).Object = (HoFixProportion.*P_BAobj)./P_Bobj;
end

%% Plot the conditional probabilities
