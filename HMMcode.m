% names of states
hmmProps.stateNames = {'Face','Obj','Neither'};

% transition matrix
hmmProps.tr = [.5,0.49,0.01;0.49,.5,0.01;.25,.25,.5]; %90% stay

% emission probabilities
% for each state, pick a distribution shape and parameters
hmmProps.emit.distance.param = {'exp',100,1;'exp',100,1;'unif',0,1000};

% we have to discretize our data; pick a discretization size
hmmProps.emit.distance.xVals = [0:10:1000];

% size of bins
hmmProps.emit.distance.xTick = mean(diff(hmmProps.emit.distance.xVals));


% make the emission distributions
for s = 1:length(hmmProps.stateNames)
    hmmProps.emit.distance.p(s,:) = pdf(hmmProps.emit.distance.param{s,1},...
        hmmProps.emit.distance.xVals,hmmProps.emit.distance.param{s,2},hmmProps.emit.distance.param{s,3});
end



disp('Calculating Fixations and HMM')

% do this for each subject
nS = length(SA.ETT.Subjects);

% for each subject
for s = 1:nS


    % % % % load in the subject's data % % % %
    subdata.Fixations = 'LOAD YOUR DATA HERE';

    % % subdata.Fixations has this form:
    % subdata.Fixations{T}.fixAOI.distance(f,1) = faceDist;
    % subdata.Fixations{T}.fixAOI.distance(f,2:end) = hoDist;
    % % where T is the trial number, f is the fixation number.
    % % I looked through each trial, then looped through each fixation. 
    % % for each, I calculate the distance to the 'face' AOI = faceDist,
    % % and the distance to each of the hand/obj AOIs = (vector) hoDist;
    % % this means column 1 = face, 2&3 = hands, 4:end = objs


    % loop through each trial
    nT = length(subdata.Fixations);
    subdata.HMM = [];
    for t = 1:nT
        % % Grab the calculated distances and convert them into bins

        % distances on this trial
        dist = subdata.Fixations{t}.fixAOI.distance;

        % compute the smallest distance to an object (if you also want to
        % include hands, include columns 2 & 3 here). For whatever reason,
        % we only did it based on objects. /shrug
        minObjDist = min(dist(:,4:end),[],2); 

        % concatenate them and transpose to work with the hmm functions
        foDist = [dist(:,1),minObjDist,]';

        % compute the difference between the face dist and obj dist. this
        % is used to determine if the 'neither' state is a good fit.
        % Basically if dist to face is high and dist to objs is high, dist
        % to 'neither' ends up being low. This is evidence that it's
        % 'neither'
        foDist(3,:) = abs(diff(foDist));

        % discretize into bins
        distBin = max(1,...
            min(floor(foDist / hmmProps.emit.distance.xTick),...
            length(hmmProps.emit.distance.xVals)));

        % Feed the distances and the properties of the hmm into the
        % built-in classifier function

        % est.state is the estimated state vector
        % vStore is the emission probability, aka p(observedData |
        % assignedState). I don't use it but it might be interesting
        [hmmProps.est.state,hmmProps.est.vStore] = ...
            hmmviterbi_multi3(distBin,hmmProps.tr,hmmProps.emit.distance.p);

        hmmProps.subData{s,t} = hmm;
        subdata.HMM{t} = hmm;
    end


end