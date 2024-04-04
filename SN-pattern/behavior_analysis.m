% this script is for behavior and eyetracker data analysis 

clear all
clc
addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/

%% behavior 

% This script will form the data into a format easy to analysis in R, as
% it'd be easiest to make plots and do stats and all different types of
% comparisons in R. 
%
% This session will run through all subjects and 

% TODO
% there will be at least 8 mat files for each subject
% load cfg and response to run_01 ... run_08

subID = 'test';

% load all cfg (for trialOrder) and responses
for run = 1:8
    data_path = ['../../data/' subID '/' subID '_run-0' char(run) '_20240329_1725.mat'];
    cfgs.("run_0"+string(run)) = load(data_path,"cfg");
    resps.("run_0"+string(run)) = load(data_path,"responses");
end

% combine trial types and responses and answers (no need for separate runs)



% extract response and answers 
trial_order = cfg.trialOrder;
trial_order_split = split(trial_order,""); % "NLTT" => "" "N" "L" "T" "T" ""
trial_order_split = trial_order_split(:,2:5);
answer = (trial_order_split(:,4)=="T");
resp = (1-isnan(responses(:,1))); % first column for keypress, second for time

% compute score
score_total = sum(resp == answer);


%% eyetracker 


