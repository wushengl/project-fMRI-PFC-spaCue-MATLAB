% Script for running the Spatial and Non-spatial pattern matching task.
%
% Task info:
% - each trial could be spatial/non-spatial task 
% - each trial contains 2 sequences with 4 syllables in each sequence 
% - each syllable could be presented from 3 possible spatial location 
% - each syllable could be either BA, DA, GA 
%
% The whole task will be separate into several runs with scanner,
% run this script once for each run, fill in the run number in dialog. 
% There will be several trials per run, with no break, but some fixation
% time at beginning, middle, and end of the run. 

clear all
clc
addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/

%% configuration
runNum = 4;
trialPerRun = 30;
runInfo = getRunInfo(runNum,trialPerRun);

% run setting
cfg.subID = runInfo{1};        % char array
cfg.device = runInfo{2};       % char array
cfg.runMode = runInfo{3};      % char array
cfg.trialNum = runInfo{4};     % integer number
cfg.trialOrder = runInfo{5};   % trialPerRun length string array
cfg.eyetracker = runInfo{6};   % 0/1
cfg.runIdx = runInfo{7};       % integer number

% audio setting=1211
cfg.fs = 44100;
cfg.dirPool = ["15", "45", "90"];

% folders
cfg.sylbFoler = './stimuli/normalized-mono/syllables/';
cfg.hrirFolder = './hrir/';
cfg.saveFolder = ['../data/' cfg.subID '/'];
if ~exist(cfg.saveFolder, 'dir')
    mkdir(cfg.saveFolder) 
end

% trial setting
cfg.taskScreenDur = 1.0;
cfg.sylbDur = 0.4;
cfg.cue2tarIntv = 0.5;
cfg.sylbIntv = 0;
cfg.pat2patIntv = 0.4;
cfg.respDur = 1.5;
cfg.sylbPerPat = 4;
cfg.patPerTrial = 2;
cfg.trialDur = cfg.taskScreenDur + cfg.sylbDur + cfg.cue2tarIntv + ...
    cfg.sylbDur*cfg.sylbPerPat*cfg.patPerTrial + cfg.pat2patIntv + cfg.respDur;
% 1(task type) + 0.4(cue) + 0.5 + 0.4*4*2 (pattern*2) + 0.4 + 1.5 = 7s per trial

% scanner related 
TR = 2;
TRperTrial = cfg.trialDur/TR; % 3.5TR per trial
TRperRun = TRperTrial*trialPerRun; 

% fixation time setting
cfg.fixTime = 2*TR; % TODO: change back to 4 after finish piloting

% keyboard setting
cfg.responseKeys = ["1","1!","2","2@","3","3#","4","4$","5","5%"];
cfg.triggerKeys = ["=","=+"];
cfg.escapeKey = ["q","ESCAPE"]; % KbName('ESCAPE')

% Preallocate memory and save workspace
responses = nan(cfg.trialNum,2);

subIDrunNum = [cfg.subID '_ses-0' int2str(cfg.runIdx)];
filename = [subIDrunNum datestr(now,'_yyyymmdd_HHMM') '.mat'];
cfg.edf_filename = [cfg.saveFolder cfg.subID datestr(now, 'HHMM') '.edf'];
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
end
AssertOpenGL; % break if installed PTB is not based on OpenGL
screenNum=Screen('Screens');
screenIdx = screenNum(end);
[cfg.win, rect] = Screen('OpenWindow',screenIdx,[0 0 0]); 
% rect is needed for eyetracker setup, PTB init has to be before eyetracker


%% eyetracker setup

if cfg.eyetracker 
    cfg.vDistance = 107.5; % scanner viewing distance w/ eyetracker
    cfg.dWidth = 41.5; % scanner display width w/ eyetracker
    ppd = pi*rect(3) / atan(cfg.dWidth/cfg.vDistance/2) / 360; % pixels per degree
    cfg.ppd = ppd; 

    el = setupEyelink(cfg,rect,cfg.edf_filename); % all initialization setup into another script
end

%% timing control -- remove this later

% There're 2 options for timing control, one is to run each, record time,
% check if time is correct (what I normally do); another is to generate
% start times ahead of time and execute event at desired time (Abby's code)
% 
% Here I'm switching to create start times ahead of time and execute events
% at desired time. As those time will be used for fMRI analysis anyhow.

trialStartTimes = (0:trialPerRun-1)*TR*TRperTrial + cfg.fixTime;
trialStartTimes(trialPerRun/2+1:end) = trialStartTimes(trialPerRun/2+1:end) + cfg.fixTime;


%% Prepare spatialized stimuli 
% spaSylbs stores all spatialized syllables, so that when generating the
% trial, don't need to do convolution within trial.
% All of the signals are spatialized to fixed duratoin of cfg.sylbDur. 
% Due to MATLAB naming restriction, fieldnames for spaSylbs are "L30" etc
% (start with letter instead of number).

spaSylbs = generateSpaSylbs(cfg); 

%% Start run 

if cfg.eyetracker
    % Must be offline to draw to EyeLink screen
    Eyelink('Command', 'set_idle_mode');
    
    % clear tracker display and draw box at fix point
    box = round(2.5*ppd);
    width = rect(3);
    height = rect(4);
    Eyelink('Command', 'clear_screen 0')
    Eyelink('command', 'draw_box %d %d %d %d 15', (width/2)-box, (height/2)-box, (width/2)+box, (height/2)+box);
    
    Eyelink('Command', 'set_idle_mode');
end

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
    Eyelink('command', 'record_status_message "Trial %d"', i);
    Eyelink('StartRecording');
end

for i = 1:cfg.trialNum

    % trial prep
    thisTrial = char(cfg.trialOrder(i));
    thisTaskType = thisTrial(1);

    fprintf("Current trial: %d\n",i)
    fprintf("Trial type: %s\n",thisTrial)

    thisTrialSig = generateTrialSig(cfg,thisTrial,spaSylbs); 
    drawTasktypeScreen(cfg,thisTaskType);

    % wait to show task type screen
    while GetSecs - runStartTime < trialStartTimes(i)
        % wait until trial onset time
    end
    Screen('Flip', cfg.win); % show task type screen
    trialStartTime = GetSecs;

    % show task type screen for certain duration
    WaitSecs(cfg.taskScreenDur);
    if cfg.eyetracker
        Eyelink('Message','SYNCTIME');
    end

    % onset of audio signal
    DrawFormattedText(cfg.win, '+', 'center','center',[255 255 255]);
    Screen('Flip', cfg.win);
    audioOnsetTime = GetSecs;
    disp("audio start relative to trial onset:")
    disp(audioOnsetTime-trialStartTime)

    % play audio 
    PsychPortAudio('FillBuffer', cfg.pahandle, thisTrialSig');
    PsychPortAudio('Start', cfg.pahandle, 1, 0, 0); % TODO: waitForStart = 0 or 1

    % response time 
    cfg.respStartTime = audioOnsetTime; % excution moves on before audio finished
    [responses(i,1),responses(i,2)] = getResponse(cfg); 
    trialEndTime = GetSecs;
    disp("trial finish relative to trial onset:")
    disp(trialEndTime-trialStartTime) 

    % ending info
    save([cfg.saveFolder filename]);

    % fixation in the middle
    if i == cfg.trialNum/2
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

