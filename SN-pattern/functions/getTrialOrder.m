function trialOrder = getTrialOrder(runNum,trialPerRun)
% This function is used for creating trial order. 
% For now, I'm just creating 4 runs, each contains only 1 task type 
% for targets in 1 hemispher. 
% Input: 
% - runNum: number of runs
% - trialPerRun: number of trials per run
% 
% 'S' for spatial task, 'N' for nonspatial task
% 'L' for left hemisphere, 'R' for right hemisphere
% 'T' for contains target, 'F' for no target 

spaArr = repmat(["S","N"],trialPerRun,runNum/2);
dirArr = repmat(["L","L","R","R"],trialPerRun,runNum/4);

tarPool = ["T","F"];
randidx = randi(numel(tarPool),trialPerRun,runNum);
tarArr = tarPool(randidx);

trialOrder = spaArr + dirArr + tarArr;
end