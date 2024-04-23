% This script is used for generating events file for design matrix
% generation in NiLearn. 
%
% The file contains 3 columns and is saved as a tsv file for each run
% - onset
% - duration
% - trial_type
%
% TODO: will have 1-session subject and 2-session subject, update code
% accordingly later

clear all
clc

addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/

%% load useful files

subject = "p001";
subject_mri = "P001"; % scott saved with capital P 
ses_num = 1;
pref = "detailed"; % detailed vs. blocked (detailed removed cue and response time)
run_num = 8;
block_num = 18;
saveFolder = "../data/" + subject + "/";

% load blockOrder and trialOrder
trialOrderPath = saveFolder + "trialOrder.mat";
load(trialOrderPath,"trialOrder_full","blockOrder");


%% create event matrix and save  

for run = 1:run_num
    this_event = [];

    this_data_name = dir(fullfile(saveFolder, "*SNpattern_run-0"+string(run))+"*.mat");
    this_data_path = saveFolder + string(this_data_name.name);
    load(this_data_path,"cfg");

    % ------ get trial_type ------
    realBlockOrder = cfg.blockOrder;
    trial_type = realBlockOrder(1:block_num); 
    trial_type = reshape(trial_type,[1,block_num]);
    if pref == "blocked"
        trial_type = [trial_type(1:block_num/2) "FIX" trial_type(block_num/2+1:end)];
        trial_type = ["FIX" trial_type];
        trial_type = [trial_type "FIX"];
    elseif pref == "detailed"
        % TODO: add response time for each trial? 
        trial_per_block = cfg.trialPerBlock;
        trial_num = block_num * trial_per_block;
        trial_type = repmat(trial_type,trial_per_block,1);
        trial_type = [repelem("NI",1,block_num);trial_type;repelem("NI",1,block_num)];
        trial_type = reshape(trial_type,[1,numel(trial_type)]); 
        trial_type = [trial_type(1:numel(trial_type)/2) "FIX" trial_type(numel(trial_type)/2+1:end)];
        trial_type = ["FIX" trial_type];
        trial_type = [trial_type "FIX"];
    end

    % ------ get onset ------
    % onset time of each block
    TR = 2;
    TRperBlock = cfg.blockDur/TR;
    onset = (0:cfg.blockPerRun-1)*TRperBlock*TR + cfg.fixTime;
    onset(cfg.blockPerRun/2+1:end) = onset(cfg.blockPerRun/2+1:end) + cfg.fixTime;
    % regressor tr_num = 237, no need to add dummy scan time
    if pref == "blocked"
        % add fixation time onsets
        onset = [onset(1:block_num/2) onset(block_num/2)+cfg.blockDur onset(block_num/2+1:end)];
        onset = [0 onset];
        onset = [onset onset(end)+cfg.blockDur-cfg.blockIntv];
    elseif pref == "detailed"
        % TODO: not finished yet
        onset = [onset;onset+cfg.taskScreenDur;onset+cfg.taskScreenDur+cfg.trialDur-cfg.respDur];
    end

    % ------ get duration ------
    duration = diff(onset);
    duration = [duration cfg.fixTime];
    
    % ======== save to tsv ========
    this_event = [onset' duration' trial_type'];
    this_table = array2table(this_event,'VariableNames',["onset","duration","trial_type"]);
    this_save_name = "sub-" + subject_mri + "_task-SNpattern_run-0" + string(run) + "_events.csv";
    writetable(this_table,saveFolder+this_save_name);
end



