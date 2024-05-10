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

subject = "p002";
subject_mri = "p002"; % scott saved with capital P 
ses_num = 2;
pref = "detailed"; % detailed vs. blocked (detailed removed cue and response time)
run_num = 9; % might have run orders duplicated runs for some subjects, make sure to fix mat data first 
block_num = 18;
saveFolder = "../data/" + subject + "/";

% load blockOrder and trialOrder
trialOrderPath = saveFolder + "trialOrder.mat";
load(trialOrderPath,"trialOrder_full","blockOrder");

ses_order = [1,1,1,1,2,2,2,2,2]; % should have length of run_num, indicating which session each run is in

%% create event matrix and save  

% run_idx is order index of current run, independent of block contents
% order_idx is block order index, e.g. which block order current run used

for run = 1:run_num

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
        % add block interval (as "FIX" at end of each block)
        trial_type = [trial_type;repelem("FIX",1,block_num)];
        trial_type = reshape(trial_type,[1,block_num*2]);
        % add fixation time 
        trial_type = [trial_type(1:length(trial_type)/2) "FIX" trial_type(length(trial_type)/2+1:end)];
        trial_type = trial_type(1:end-1); % remove last block interval
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
        trial_dur = cfg.blockDur - cfg.blockIntv;
        % add block interval times
        onset = [onset;onset+trial_dur];
        onset = reshape(onset,[1,block_num*2]);
        % add fixation times 
        onset = [onset(1:length(onset)/2) onset(length(onset)/2)+cfg.blockIntv onset(length(onset)/2+1:end)];
        onset = [0 onset];
    end

    % ------ get duration ------
    duration = diff(onset);
    duration = [duration cfg.fixTime];
    
    % ======== save to tsv ========
    this_event = [onset' duration' trial_type'];
    this_table = array2table(this_event,'VariableNames',["onset","duration","trial_type"]);
    this_save_name = "sub-" + subject_mri + "_ses-0" + string(ses_order(run)) + "_task-SNpattern_run-0" + string(run) + "_events.csv";
    writetable(this_table,saveFolder+this_save_name);
end



