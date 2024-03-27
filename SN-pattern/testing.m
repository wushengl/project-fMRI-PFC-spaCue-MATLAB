% psychtoolbox testing and MATLAB recap 
% Hello MATLAB I'm back :\

%% initialization

% clean workspace and command window
clear all
clc

% add path 
addpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab_codes')


%% configuration

do_run_screen = true;
do_run_sound = false;
do_run_keyboard = false;

%% psychtoolbox 

%{ 
Here I'm testing psychtoolbox functions for 
- screen display
- audio presentation 
- keyboard listening 
- timestamp recording 
%}

% -----------------------------------------------
% screen display
% -----------------------------------------------

% Here I'm skipping syncronization test as psychtoolbox syncing is not 
% working well for M2 Chip Macbook. Only SkipSyncTests for testing on my 
% own computer, should do SyncTests on task presentation pc. 

Screen('Preference','SkipSyncTests',1);

% Some initial Screen information 
screenNumbers=Screen('Screens');
screenIdx = screenNumbers(end);
screenFR = Screen('FrameRate',screenIdx);
fprintf("Display on Screen: %d\n",screenIdx)
fprintf("Screen refresh rate: %d\n",screenFR)

% [windowPtr,rect]=Screen(‘OpenWindow‘,windowPtrOrScreenNumber [,color] [,rect] 
% [,pixelSize] [,numberOfBuffers] [,stereomode] [,multisample][,imagingmode]
% [,specialFlags][,clientRect][,fbOverrideRect][,vrrParams=[]]);

[win, rect] = Screen('OpenWindow',screenIdx,[0,0,0]);
Screen('TextSize', win, 120);
DrawFormattedText(win, '+', 'center','center',[255 255 255]);
% The Screen is draw in the buffer and won't show until "flip" the screen

% [VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] = 
% Screen(‘Flip’, windowPtr [, when] [, dontclear] [, dontsync] [, multiflip]);
% 
% “when” specifies when to flip: If set to zero (default), it will flip
% on the next possible video retrace
[~, onsettime, ~, ~, ~] = Screen('Flip', win);
Screen('CloseAll');


% -----------------------------------------------
% audio presentation
% -----------------------------------------------

InitializePsychSound;

% pahandle = PsychPortAudio(‘Open’ [, deviceid][, mode][, reqlatencyclass][, freq]
% [, channels][, buffersize][, suggestedLatency][, selectchannels][, specialFlags=0]);
freq = 44100;
pahandle = PsychPortAudio('Open', [], [], 0, freq,2);
[stim,~] = audioread("AV-2back/animal-sounds/cat_sounds/1.wav");
stim_dur = length(stim)/fs;

% Each row of the matrix specifies one sound channel, each column one sample for each channel.
PsychPortAudio('FillBuffer', pahandle, [stim';stim']); 
PsychPortAudio('Start', pahandle, 1, 0, 1); % repetitions, when, waitForStart
PsychPortAudio('Close', pahandle);


% -----------------------------------------------
% keyboard input
% -----------------------------------------------

% 0 will turn off character listening and reset the buffer which holds the captured characters
% 1 or not passing any value will enable listening
% 2 will enable listening, additionally any output of keypresses to Matlabs is suppressed. (CTRL+C)

% ListenChar(1);
% ListenChar(0);


%% keyboard testing 

Screen('Preference','SkipSyncTests',1);

% Some initial Screen information 
screenNumbers=Screen('Screens');
screenIdx = screenNumbers(end);

[win, rect] = Screen('OpenWindow',screenIdx,[0,0,0]);
Screen('TextSize', win, 120);

KbQueueCreate;
KbQueueStart;

DrawFormattedText(win, 'Hi!', 'center','center',[255 255 255]);
[~, onsettime, ~, ~, ~] = Screen('Flip', win);
WaitSecs(1)

for i = 1:5
    DrawFormattedText(win, char(i), 'center','center',[255 255 255]);
    [~, onsettime, ~, ~, ~] = Screen('Flip', win);
    startTime = GetSecs;
    while GetSecs - startTime < 1
        [pressed, firstPress] = KbQueueCheck;
        if pressed
            disp(find(firstPress))
            for pk = find(firstPress)
                disp(KbName(pk))
            end
        end
    end
end

KbQueueRelease;
Screen('CloseAll');


%% 


KbQueueCreate;
KbQueueStart;
[pressed, firstPress]=KbQueueCheck;

function responses = getResponse(cfg)

% This subfunction uses KbQueue to wait for participants to press a key; it
% checks whether it's a legal key and records the key and the time it was
% pressed.

responses = nan(1,1,2);

KbQueueCreate;
KbQueueStart;

% As long as it's before the timeout
while (GetSecs - cfg.stimEndTime < cfg.timeoutTime)
    % Look for keypresses
    [pressed, firstPress]=KbQueueCheck;
    % If a key is pressed
    if numel(find(firstPress)) == 1
        k = find(firstPress); % Keycode of pressed key
        if pressed && ismember(k, [KbName(cfg.repeatKey1) KbName(cfg.newKey1) KbName(cfg.repeatKey2) KbName(cfg.newKey2)])
            try
                switch k
                    case {KbName(cfg.repeatKey1), KbName(cfg.repeatKey2)}
                        r = 1;
                    case {KbName(cfg.newKey1), KbName(cfg.newKey2)}
                        r = 2;
                end
                responses(1,1,1) = r;
                responses(1,1,2) = firstPress(k) - cfg.stimEndTime;
                break
            catch
                'KbQueue failure'
                break
            end
        end
    else
        % Multiple keys pressed
        responses(1,1,1) = -999;
        responses(1,1,2) = -999;
    end
end

KbQueueRelease;

% Timeout.
if GetSecs - cfg.stimEndTime > cfg.timeoutTime
    responses(1,1,1) = 999;
    responses(1,1,2) = 999;
end

end


