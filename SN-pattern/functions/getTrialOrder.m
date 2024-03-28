function [trialOrder, blockOrder] = getTrialOrder(runNum,blockPerRun,trialPerRun)
% This function is used for creating trial order, and it's only ran once at
% first run, then the trial order will be saved for the subject, and 
% There will be 
% - 8 runs
% - 12 blocks per run (1 condition in each block)
% - 4 trials per block (~25s is optimal)
%
% Input: 
% - runNum: number of runs
% - blockPerRun: number of blocks per run
% - trialPerRun: number of trials per run
% 
% 'S' for spatial task, 'N' for nonspatial task
% 'L' for left hemisphere, 'R' for right hemisphere
% 'F' for full HRTF, 'L' for ILD, 'T' for ITD
% 'T' for contains target, 'F' for no target 

% create list of all possible conditions 
taskPool = ["S","N"];
dirPool = ["L","R"];
spaCuePool = ["F","L","T"];

trialPerBlock = trialPerRun/blockPerRun;
condList = reshape(reshape(taskPool + dirPool',1,[]) + spaCuePool',[],1);

% generate a shuffle map for block orders 
% TODO: confirm with Abby what we want to do
blockList = strings(blockPerRun,runNum);

for i = 1:runNum
    shuffle_map = randperm(length(condList));
    blockList(:,i) = condList(shuffle_map);
end

% repeat shuffled items for trials 
trialList = repelem(blockList,trialPerBlock,1);

% generate random T/F maps 
tarPool = ["T","F"];
tarList = repmat(tarPool',trialPerRun/2,runNum); % each run is balanced
for i = 1:runNum
    tarList(:,i) = tarList(randperm(trialPerRun),i);
end

% combine trial with isTar
trialOrder = trialList + tarList;
blockOrder = blockList;

end

