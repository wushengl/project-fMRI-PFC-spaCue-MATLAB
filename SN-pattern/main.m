% Script for running the Spatial and Non-spatial pattern matching task.
%
% Task info:
% - each trial could be spatial/non-spatial task 
% - each trial could be presented from left/right hemisphere
% - each trial could be spatialized with HRTF/ILD/ITD
% - 12 conditions (2 task type * 2 hemisphere * 3 spatial cue)
%
% - each trial contains 2 sequences with 4 syllables in each sequence 
% - each syllable could be presented from 3 possible location in that hemi
% - each syllable could be either BA, DA, GA 
%
% The whole task has 8 runs, each run will contain 12 blocks, 
% each block is ~25sec, with only 1 condition, and 4 trials.
%
% run this script once for each run, fill in the run number in dialog. 
% There will be no break within each run (~6min), but some fixation
% time at beginning, middle, and end of the run.
% 

clear all
clc
addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/
% add BRIDGE_CENTER_PATH here


% folders
%cfg.sylbFoler = './stimuli/normalized-mono/syllables/';
cfg.sylbFoler = './stimuli/normalized-mono/broadband/';
cfg.hrirFolder = './hrir/';
cfg.saveDir = '../../data/'; 
% might do fMRI analysis with Python, so better keep data outside matlab folder

%% configuration

cfg.runNum = 8; 
cfg.blockPerRun = 12;
cfg.trialPerBlock = 4; 
trialPerRun = cfg.blockPerRun * cfg.trialPerBlock; 
runInfo = getRunInfo(cfg); 

% run setting
cfg.subID = runInfo{1};        % char array
cfg.device = runInfo{2};       % char array
cfg.runMode = runInfo{3};      % char array
cfg.trialNum = runInfo{4};     % integer number
cfg.trialOrder = runInfo{5};   % trialPerRun length string array
cfg.blockOrder = runInfo{6};   % blockPerRun length string array
cfg.eyetracker = runInfo{7};   % 0/1
cfg.runIdx = runInfo{8};       % integer number
if ~strcmp(cfg.runMode,'task')
    cfg.blockPerRun = length(cfg.blockOrder);
    cfg.trialPerBlock = 1;
end
cfg.saveFolder = [cfg.saveDir cfg.subID '/']; 
if ~exist(cfg.saveFolder, 'dir')
    mkdir(cfg.saveFolder) 
end

% audio setting
cfg.fs = 44100;
cfg.dirPool = ["15", "30", "90"];

% trial setting
cfg.sylbDur = 0.4;
cfg.cue2tarIntv = 0.5;
cfg.sylbIntv = 0;
cfg.pat2patIntv = 0.4;
cfg.respDur = 1.5;
cfg.sylbPerPat = 4;
cfg.patPerTrial = 2;
cfg.trialDur = cfg.sylbDur + cfg.cue2tarIntv + ...
    cfg.sylbDur*cfg.sylbPerPat*cfg.patPerTrial + cfg.pat2patIntv + cfg.respDur;
cfg.trialAudDur = cfg.trialDur - cfg.respDur;
% 0.4(cue) + 0.5 + 0.4*4*2 (pattern*2) + 0.4 + 1.5 = 6s per trial

% block setting 
cfg.taskScreenDur = 1.0;
cfg.blockIntv = 4.0;
cfg.blockDur = cfg.taskScreenDur + cfg.trialDur * cfg.trialPerBlock + cfg.blockIntv;

% scanner related 
TR = 2;
TRperTrial = cfg.trialDur/TR; % 3TR per trial
TRperBlock = cfg.blockDur/TR;
cfg.fixTime = 4*TR; 
TRperRun = TRperBlock*cfg.blockPerRun + cfg.fixTime*3; % this is not including fixation time


% keyboard setting
cfg.responseKeys = ["1","1!","2","2@","3","3#","4","4$","5","5%"];
cfg.triggerKeys = ["=","=+"];
cfg.escapeKey = ["q","ESCAPE"]; % KbName('ESCAPE')

% Preallocate memory and save workspace
responses = nan(cfg.trialNum,2);

subIDrunNum = [cfg.subID '_ses-0' int2str(cfg.runIdx)];
filename = [subIDrunNum datestr(now,'_yyyymmdd_HHMM') '.mat'];
cfg.edf_filename = [cfg.subID datestr(now, 'HHMM') '.edf'];
save([cfg.saveFolder filename]);

% display setting 
cfg.textSize = 36;

%% PsychToolbox initializations

% audio
InitializePsychSound;
cfg.pahandle = PsychPortAudio('Open', [], [], 0, cfg.fs, 2);

% visual
if cfg.device == "macbook"
    Screen('Preference','SkipSyncTests',1);
    screenNum=Screen('Screens');
    screenIdx = screenNum(end);
    cfg.kb = nan;
elseif cfg.device == "scanner"
    screenIdx = 1;
    % use specific keyboard
    devstring = 'Teensy Keyboard/Mouse';
    [id,name] = GetKeyboardIndices;
    cfg.kb = id(strcmp(name,devstring)); % strcmp returns logical array
    if isempty(cfg.kb)
        error('No device by that name was detected');
    end
end

AssertOpenGL; % break if installed PTB is not based on OpenGL
[cfg.win, rect] = Screen('OpenWindow',screenIdx,[0 0 0]); 
% rect is needed for eyetracker setup, PTB init has to be before eyetracker
cfg.rect = rect;

%% eyetracker setup

if cfg.eyetracker 
    el = setupEyelink(cfg,rect,cfg.edf_filename); % all initialization setup into another script
end

%% timing control 

% There're 2 options for timing control, one is to run each, record time,
% check if time is correct (what I normally do); another is to generate
% start times ahead of time and execute event at desired time (Abby's code)
% 
% Here I'm switching to create start times ahead of time and execute events
% at desired time. As those time will be used for fMRI analysis anyhow.

blockStartTimes = (0:cfg.blockPerRun-1)*TRperBlock*TR + cfg.fixTime;
blockStartTimes(cfg.blockPerRun/2+1:end) = blockStartTimes(cfg.blockPerRun/2+1:end) + cfg.fixTime;

%trialStartTimes = (0:trialPerRun-1)*TR*TRperTrial + cfg.fixTime;
%trialStartTimes(trialPerRun/2+1:end) = trialStartTimes(trialPerRun/2+1:end) + cfg.fixTime;

%% Prepare spatialized stimuli 
% spaSylbs stores all spatialized syllables, so that when generating the
% trial, don't need to do convolution within trial.
% All of the signals are spatialized to fixed duratoin of cfg.sylbDur. 
% Due to MATLAB naming restriction, fieldnames for spaSylbs are "L30" etc
% (start with letter instead of number).

spaSylbs = generateSpaSylbs(cfg); 

%% Start run 

Screen('TextSize', cfg.win, cfg.textSize);
DrawFormattedText(cfg.win, 'Waiting for scanner..', 'center','center',[255 255 255]);
Screen('Flip', cfg.win);

% get trigger time
runStartTime = getTrigger(cfg);

%----------------------
% Start running trials
%----------------------

% insert fixation time
showFixationScreen(cfg);

if cfg.eyetracker
    Eyelink('Command', 'set_idle_mode');
    Eyelink('command', 'record_status_message "Run %d"', cfg.runIdx);
    Eyelink('StartRecording');
end

for i = 1:cfg.blockPerRun
    % would be easier to collect response per trial, so I'm still playing
    % sounds on trial basis 

    thisBlockType = char(cfg.blockOrder(i));
    fprintf("Current block: %d\n",i)
    fprintf("Block type: %s\n",thisBlockType)
    drawTasktypeScreen(cfg,thisBlockType(1),i);

    % prep audio for the entire block
    blockSig_dur = cfg.trialDur*cfg.trialPerBlock;
    trialSig_len = int32((cfg.trialDur-cfg.respDur)*cfg.fs);
    blockSig = zeros(cfg.trialPerBlock,trialSig_len,2);

    for j = 1:cfg.trialPerBlock
        trial_idx = (i-1)*cfg.trialPerBlock + j;
        thisTrial = char(cfg.trialOrder(trial_idx));
        thisTrialSig = generateTrialSig(cfg,thisTrial,spaSylbs); 
        blockSig(j,:,:) = thisTrialSig;
    end

    % wait for block onset to show block screen
    while GetSecs - runStartTime < blockStartTimes(i)
        % wait until trial onset time
    end
    Screen('Flip', cfg.win); % show task type screen

    if cfg.eyetracker
        Eyelink('command', 'record_status_message "Block %d"', i);
    end
    blockStartTime = GetSecs;
    WaitSecs(cfg.taskScreenDur);

    for j = 1:cfg.trialPerBlock

        trial_idx = (i-1)*cfg.trialPerBlock + j;
        thisTrial = cfg.trialOrder(trial_idx);

        if cfg.eyetracker
            Eyelink('Message', 'TRIALID "%d"', trial_idx);
            Eyelink('Message','SYNCTIME');
        end

        % show fixation
        DrawFormattedText(cfg.win, '+', 'center','center',[255 255 255]);
        Screen('Flip', cfg.win);
        fprintf("Current trial: %d (%s)\n",j,thisTrial)

        audioOnsetTime = GetSecs;
        disp("audio start relative to block onset:")
        disp(audioOnsetTime-blockStartTime)

        % play audio 
        PsychPortAudio('FillBuffer', cfg.pahandle, squeeze(blockSig(j,:,:))');
        PsychPortAudio('Start', cfg.pahandle, 1, 0, 0); 

        % response time 
        WaitSecs(cfg.trialAudDur); % now it's only taking response at response screen
        DrawFormattedText(cfg.win, 'RESPONSE', 'center','center',[255 255 255]); % to help them separate trials
        Screen('Flip', cfg.win);
        cfg.respStartTime = GetSecs; % excution moves on before audio finished
        [responses(trial_idx,1),responses(trial_idx,2)] = getResponse(cfg); 

        while GetSecs - cfg.respStartTime < cfg.respDur
            % still show RESPONSE screen if pressed button and breaked early
        end

        trialEndTime = GetSecs;
        disp("trial finish relative to trial onset:")
        disp(trialEndTime-audioOnsetTime) 
    end

    disp("block finish relative to block onset:")
    disp(GetSecs-blockStartTime)
    
    DrawFormattedText(cfg.win, 'WAITING FOR NEXT BLOCK...', 'center','center',[255 255 255]);
    Screen('Flip', cfg.win);

    % ending info
    save([cfg.saveFolder filename]);
    
    % fixation in the middle
    if i == cfg.blockPerRun/2
        showFixationScreen(cfg);
    end
end

% fixation at the end
showFixationScreen(cfg);
while GetSecs - trialEndTime < cfg.fixTime
    % Wait
end

if cfg.eyetracker
    Eyelink('StopRecording');
    Eyelink('Message','TRIAL_RESULT 0');
end

runFinishTime = GetSecs;
runDuration = runFinishTime - runStartTime;
fprintf("Run finished! Duration: %.3f\n",runDuration)
save([cfg.saveFolder filename]);


%% cleanup 

closeNcleanup(cfg)

