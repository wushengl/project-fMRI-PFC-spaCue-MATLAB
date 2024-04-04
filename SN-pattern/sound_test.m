 % All stimuli for AV-2back and SN-pattern are normalized in RMS. Here just
% playing sounds in random order to help them adjust the volume with
% scanner noise and make sure left and right insert phone seals are roughly
% equally tight. 
%
% blockLen is number of sounds to play, there're 68 in total, 1.3s per sound

function sound_test(blockLen)
% This function plays stimuli for AV-2back and SN-pattern in random order

%addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue'))
%cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/
addpath(genpath('C:\Users\Brown-lab\project-fMRI-PFC-spaCue-MATLAB'))
cd C:\Users\Brown-lab\project-fMRI-PFC-spaCue-MATLAB\SN-pattern

AV_cat_folder = '../AV-2back/animal-sounds/cat_sounds/';
AV_dog_folder = '../AV-2back/animal-sounds/dog_sounds/';
SN_sylb_folder = './stimuli/normalized-mono/broadband/';

folders = [string(AV_cat_folder) string(AV_dog_folder) string(SN_sylb_folder)];
files_all = [];

for folder = folders
    folder = char(folder);
    files = dir([folder '*.wav']);
    for i = 1:numel(files)
        files(i).name = [folder files(i).name]; 
    end
    files_all = [files_all;files];
end


files_all = files_all(randperm(length(files_all))); % shuffle files
cfg.ITI = .3; % syllable length .35
cfg.timeoutTime = 1; % 1 second


%% test start

Screen('Preference','SkipSyncTests',1);
screenNum=Screen('Screens');
screenIdx = screenNum(end);
[cfg.win, rect] = Screen('OpenWindow',screenIdx,[0 0 0]);
cfg.freq = 44100; % Audio device frequency
InitializePsychSound;
cfg.pahandle = PsychPortAudio('Open', [], [], 0, cfg.freq,2);

Screen('TextSize', cfg.win, 36);
DrawFormattedText(cfg.win, '+', 'center','center',[255 255 255]);
[~, cfg.lastEventEnd, ~, ~, ~] = Screen('Flip', cfg.win);

% present stimuli
for i = 1:blockLen

    fname = files_all(i).name;
    
    while GetSecs-cfg.lastEventEnd < cfg.ITI
        % wait
    end
    
    [stim,~] = audioread(fname);
    stim = stim';
    if size(stim,1) == 1
        stim = [stim;stim]; % make it stereo if it isn't already
    end
    % Playback
    PsychPortAudio('FillBuffer', cfg.pahandle, stim);
    PsychPortAudio('Start', cfg.pahandle, 1, 0, 0);

    cfg.stimEndTime = GetSecs;
    
    while GetSecs - cfg.stimEndTime < cfg.timeoutTime
        % wait
    end

    cfg.lastEventEnd = GetSecs;
end

PsychPortAudio('Close', cfg.pahandle);
Screen('CloseAll');

end



