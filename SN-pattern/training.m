% This script is used for training
% This script is not saving data, default to macbook file path 
% =

clear all
clc

addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/

% BRIDGE_CENTER Windows 
%addpath(genpath('C:\Users\Brown-lab\project-fMRI-PFC-spaCue-MATLAB'))
%cd C:\Users\Brown-lab\project-fMRI-PFC-spaCue-MATLAB\SN-pattern

% booth3 windows-pc hereq
%addpath(genpath('E:\Experiments\Wusheng\project-fMRI-PFC-spaCue-MATLAB'))
%cd E:\Experiments\Wusheng\project-fMRI-PFC-spaCue-MATLAB\SN-pattern

% folders
%cfg.sylbFoler = './stimuli/normalized-mono/syllables/';
cfg.sylbFoler = './stimuli/normalized-mono/broadband/';
cfg.hrirFolder = './hrir/';
cfg.saveDir = '../data/'; 
% might do fMRI analysis with Python, so better keep data outside matlab folder

%% configuration

cfg.runNum = 8; 
cfg.blockPerRun = 18;
cfg.trialPerBlock = 4; 
trialPerRun = cfg.blockPerRun * cfg.trialPerBlock; 
%runInfo = getRunInfo(cfg); 

% run setting
cfg.subID = 'train';            % char array
cfg.device = 'macbook';         % char array
cfg.runMode = 'train';          % char array
cfg.trialNum = 6;               % integer number
cfg.trialOrder = ["SLFF";"NLFT";"SRFT";"PRFF";"SLFT";"NLFF";"PRFF";"NRFT"];   
cfg.blockOrder = cfg.trialOrder;   % blockPerRun length string array
cfg.eyetracker = 0;             % 0/1
cfg.runIdx = 0;                 % integer number
if ~strcmp(cfg.runMode,'task')
    cfg.blockPerRun = length(cfg.blockOrder);
    cfg.trialPerBlock = 1;
end
if strcmp(cfg.runMode,'train') 
    % not saving for training because we need to push after any changes
    % made on local pc to avoid version conflicts, which is not optimal 
    cfg.doSave = false;
else
    cfg.doSave = true;
end

cfg.saveFolder = [cfg.saveDir cfg.subID '/']; 
if cfg.doSave
    if ~exist(cfg.saveFolder, 'dir')
        mkdir(cfg.saveFolder) 
    end
end

% audio setting
cfg.fs = 44100;
cfg.dirPool = ["30","90"];
%cfg.dirPool = ["15", "30", "90"];

% trial setting
cfg.sylbDur = 0.4; % 0.4====
cfg.cue2tarIntv = 0.5;
cfg.sylbIntv = 0;
cfg.pat2patIntv = 0.4;
cfg.sylbPerPat = 4;
cfg.patPerTrial = 2;

doAudCue = false;
if doAudCue
    cfg.respDur = 1.5;
    cfg.trialDur = cfg.sylbDur + cfg.cue2tarIntv + ...
        cfg.sylbDur*cfg.sylbPerPat*cfg.patPerTrial + cfg.pat2patIntv + cfg.respDur;
    % 0.4(cue) + 0.5 + 0.4*4*2 (pattern*2) + 0.4 + 1.5 = 6s per trial
else
    cfg.respDur = 1.4;
    cfg.trialDur = cfg.sylbDur*cfg.sylbPerPat*cfg.patPerTrial + cfg.pat2patIntv + cfg.respDur;
    % 0.4*4*2 (pattern*2) + 0.4 + 1.4 = 5s per trial
end

cfg.trialAudDur = cfg.trialDur - cfg.respDur;


% block setting 
cfg.taskScreenDur = 1.0;
cfg.blockIntv = 2.0; % changed to 2 from 4
if ~strcmp(cfg.runMode,'task')
    cfg.blockIntv = 1.0;
end
cfg.blockDur = cfg.taskScreenDur + cfg.trialDur * cfg.trialPerBlock + cfg.blockIntv;

% scanner related 
TR = 2;
TRperTrial = cfg.trialDur/TR; % 3TR per trial
TRperBlock = cfg.blockDur/TR;
cfg.fixTime = 4*TR; 
if ~strcmp(cfg.runMode,'task')
    cfg.fixTime = 1*TR; 
end
TRperRun = TRperBlock*cfg.blockPerRun - cfg.blockIntv/TR + (cfg.fixTime/TR)*3; % this is not including fixation time

% keyboard setting
cfg.responseKeys = ["1","1!","2","2@","3","3#","4","4$","5","5%"];
cfg.triggerKeys = ["=","=+"];
cfg.escapeKey = ["q","ESCAPE"]; % KbName('ESCAPE')

% Preallocate memory and save workspace
responses = nan(cfg.trialNum,2);

% TODO: add ses to input 
subIDrunNum = [cfg.subID '_ses-01_task-SNpattern_run-0' int2str(cfg.runIdx)]; % need update ses if split later
filename = [subIDrunNum datestr(now,'_yyyymmdd_HHMM') '.mat']; % it's okay to have the timestr, can use *str* to 
cfg.edf_filename = [cfg.subID datestr(now, 'HHMM') '.edf']; % edf file can only be saved like this due to eyelink limitation
if cfg.doSave
    save([cfg.saveFolder filename]);
end

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
    cfg.eyetracker = 0;
elseif cfg.device == "scanner"
    Screen('Preference','SkipSyncTests',1);
    screenIdx = 1;
    % use specific keyboard
    devstring = 'Keyboard'; %  for BRIDGE Windows 'USB Device'
    [id,name] = GetKeyboardIndices;
    cfg.kb = id(strcmp(name,devstring)); % strcmp returns logical array
    if isempty(cfg.kb)
        error('No device by that name was detected');
    end
end

AssertOpenGL; % break if installed PTB is not based on OpenGL
[cfg.win, rect] = Screen('OpenWindow',screenIdx,[0 0 0]); % testing: [0,0,300,400]
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

cfg.blockStartTimes = blockStartTimes;

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
    drawTasktypeScreen(cfg,thisBlockType,i);
    thisTaskType = thisBlockType(1);
    thisTarDir = thisBlockType(2);

    % prep audio for the entire block
    blockSig_dur = cfg.trialDur*cfg.trialPerBlock;
    trialSig_len = int32((cfg.trialDur-cfg.respDur)*cfg.fs);
    blockSig = zeros(cfg.trialPerBlock,trialSig_len,2);

    for j = 1:cfg.trialPerBlock
        trial_idx = (i-1)*cfg.trialPerBlock + j;
        thisTrial = char(cfg.trialOrder(trial_idx));
        thisTrialSig = generateTrialSig(cfg,thisTrial,spaSylbs,doAudCue); 
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
        
        switch thisTarDir
            case 'L'
                text2 = sprintf('<');
            case 'R'
                text2 = sprintf('>');
        end

        switch thisTaskType
            case 'S'
                text1 = sprintf('LOCATION');
            case 'N'
                text1 = sprintf('CONTENT');
            case 'P'
                text1 = sprintf('RELAX');
                text2 = sprintf('<>');
        end

        DrawFormattedText(cfg.win, text1, 'center',(cfg.rect(4)/2 - 20),[255 255 255]);
        DrawFormattedText(cfg.win, text2, 'center',(cfg.rect(4)/2 + 30),[255 255 255]);
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
    disp("block finish relative to run onset:")
    disp(GetSecs-runStartTime)
    
    DrawFormattedText(cfg.win, 'WAITING FOR NEXT BLOCK...', 'center','center',[255 255 255]);
    Screen('Flip', cfg.win);

    tic
    % ending info
    if cfg.doSave
        save([cfg.saveFolder filename]);
    end
    toc
    
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

DrawFormattedText(cfg.win, 'SAVING DATA...', 'center', 'center',[255 255 255]);
Screen('Flip', cfg.win);

if cfg.eyetracker
    Eyelink('StopRecording');
    Eyelink('Message','TRIAL_RESULT 0');
end

runFinishTime = GetSecs;
runDuration = runFinishTime - runStartTime;
fprintf("Run finished! Duration: %.3f\n",runDuration)
if cfg.doSave
    save([cfg.saveFolder filename]);
end


%% cleanup 

closeNcleanup(cfg)

