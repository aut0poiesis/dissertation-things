% Calculates probability of fixation being directed at faces or
% hands/object as a function of context (e.g., direct/averted gaze and
% object directed action/gesture

% load subject information
subjects = readtable('subids.xlsx');
nsubs = length(subjects.subject);

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

% preallocate arrays for each of the context AOIs
directgaze = nan(nsubs,10,2);
objectgaze = nan(nsubs,10,2);
objaction = nan(nsubs,10,2);
objgesture = nan(nsubs,10,2);

% calculate probability of looking at face during each gaze context
for v = 1:10
    visitaois = aoibyage{v};
    for s = 1:nsubs
        whichgaze = [];
        whichaction = [];
        facefixcount = 0;
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
                    facefixcount = facefixcount + 1;
                    [~,I] = max(sum(whichcode));
                    [~,II] = max(sum(whichactcode));
                    whichgaze = [whichgaze; I];
                    whichaction = [whichaction; II];
                    whichcode = [];
                    whichactcode = [];
                    break
                elseif diff([faceind(f) faceind(f+1)]) > 1
                    facefixcount = facefixcount + 1;
                    [~,I] = max(sum(whichcode));
                    [~,II] = max(sum(whichactcode));
                    whichgaze = [whichgaze; I];
                    whichaction = [whichaction; II];
                    whichcode = [];
                    whichactcode = [];
                    continue  
                end
                    
            end
        end
        
        directgaze(s,v,1) = sum(whichgaze==1)/facefixcount;
        objectgaze(s,v,1) = sum(whichgaze==2)/facefixcount;
        objaction(s,v,1) = sum(whichaction==1)/facefixcount;
        objgesture(s,v,1) = sum(whichaction==2)/facefixcount;
    end
    
end