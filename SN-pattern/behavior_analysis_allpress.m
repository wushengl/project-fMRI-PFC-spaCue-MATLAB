% this script is for behavior and eyetracker data analysis 
% starting from p003, changed to always press a key, press index (2) for
% same, middle (3) for different 

clear all
clc
addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/

%% behavior 

% This script will form the data into a format easy to analysis in R, as
% it'd be easiest to make plots and do stats and all different types of
% comparisons in R. 


subject = '138';
run_list = (1:8); % (5:8)
block_num = 18;
trial_per_block = 4;
saveFolder = "../data/" + subject + "/";


% load all cfg (for trialOrder) and responses
taskTypes = repelem("",block_num*trial_per_block,length(run_list)); 
tarDirs = repelem("",block_num*trial_per_block,length(run_list));
spaCues = repelem("",block_num*trial_per_block,length(run_list));
answers = nan(block_num*trial_per_block,length(run_list));
resps = nan(block_num*trial_per_block,length(run_list));
scores = nan(block_num*trial_per_block,length(run_list));
idx = 1;
for run = run_list
    this_data_name = dir(fullfile(saveFolder, "*SNpattern_run-0"+string(run))+"*.mat");

    if length(this_data_name) > 1
        fprintf("Run %d has more than 1 saved file, using %s\n",run,this_data_name(end).name)
        this_data_name = this_data_name(end);
    end
    this_data_path = saveFolder + string(this_data_name.name);
    load(this_data_path);
    disp(this_data_path);
    % cfgs.("run_0"+string(run)) = load(this_data_path,"cfg");
    % resps.("run_0"+string(run)) = load(this_data_path,"responses");

    % extract answers 
    %this_trial_order = cfgs.("run_0"+string(run)).cfg.trialOrder;
    this_trial_order = cfg.trialOrder;
    this_trial_order_split = split(this_trial_order,""); % "NLTT" => "" "N" "L" "T" "T" ""
    this_trial_order_split = this_trial_order_split(:,2:5);
    this_answer = (this_trial_order_split(:,4)=="T");
    answers(:,idx) = this_answer;

    % extract conditions 
    taskTypes(:,idx) = this_trial_order_split(:,1);
    tarDirs(:,idx) = this_trial_order_split(:,2);
    spaCues(:,idx) = this_trial_order_split(:,3);

    % extract response
    % KbName('KeyNamesWindows')>> 50 = "2@", 51 = 3#""
    this_resp = responses(:,1)==50; %
    resps(:,idx) = this_resp;

    % extract scores
    scores(:,idx) = (this_resp == this_answer);

    idx = idx+1;
end

% combine trial types and responses and answers (no need for separate runs)
result.nonspa_hrtf = mean(scores((taskTypes=="N")&(spaCues=="F")));
result.nonspa_ild = mean(scores((taskTypes=="N")&(spaCues=="L")));
result.nonspa_itd = mean(scores((taskTypes=="N")&(spaCues=="T")));
result.spa_hrtf = mean(scores((taskTypes=="S")&(spaCues=="F")));
result.spa_ild = mean(scores((taskTypes=="S")&(spaCues=="L")));
result.spa_itd = mean(scores((taskTypes=="S")&(spaCues=="T")));


%% eyetracker 


