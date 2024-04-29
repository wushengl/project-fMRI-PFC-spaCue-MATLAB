
clear all
clc
addpath(genpath('/Users/wusheng/Research/Project-fMRI-PFC-spaCue'))
cd /Users/wusheng/Research/Project-fMRI-PFC-spaCue/matlab/SN-pattern/

% folders
%cfg.sylbFoler = './stimuli/normalized-mono/syllables/';
cfg.sylbFoler = './stimuli/normalized-mono/broadband/';
cfg.hrirFolder = './hrir/';
cfg.saveDir = '../../data/'; 

%% sound setting 

fs = 44100;
sylb = "int28";
tarDir = "L";
dirPool = ["15","90"]; % ["15", "45", "90"];
cuePool = ["HRTF", "ILD", "ITD"]; % "HRTF", "ILD", "ITD"
sylbIntv = 0.1;
repeatPerSylb = 5;
doRandom = false;

cfg.sylbDur = 0.5;
cfg.fs = fs;
cfg.dirPool = dirPool;
spaSylbs = generateSpaSylbs(cfg); 

%% makeup the sound sequence

for cue = cuePool

    % generate sequence
    sigPool = sylb + "_" + dirPool + tarDir + "_";
    sigPool = reshape(sigPool + cue,[],1); % all combination of angle and cue
    sigSeq = repmat(sigPool,repeatPerSylb);
    
    if doRandom
        sigSeq = sigSeq(randperm(length(sigSeq)));
    end
    
    sigConcat = [];
    sigIntv = zeros([ceil(sylbIntv*fs),2]);
    for i = 1:length(sigSeq)
        thisSigName = sigSeq(i);
        thisSig = spaSylbs.(thisSigName);
        sigConcat = [sigConcat;thisSig];
        sigConcat = [sigConcat;sigIntv];
    end
    
    %sound(sigConcat,fs)
    
    save_path = ['./examples/' char(sylb) '_F_' char(cue) '_' char(strjoin(dirPool,'-')) '.wav'];
    audiowrite(save_path,sigConcat,fs)

end

%% plot spectrum 
% dirPool

% figure
% sub = 1;
% for dir = dirPool
% 
%     hrir_file = [cfg.hrirFolder 'H0e0' char(dir) 'a.wav'];
%     [hrir,~] = audioread(hrir_file); %128-pt
%     
%     hrtf = fft(hrir);
%     siglen = length(hrir);
%     f = (0:siglen-1)./siglen.*fs;
% 
%     subplot(3,1,sub)
%     plot(f(1:siglen/2),20*log10(hrtf(1:siglen/2,:)))
%     sub = sub + 1;
% end


%% concat all spatial cues and all directions for each stimuli

% intsPool = ["int1", "int3", "int28"];
% sigConcat = [];
% sigIntv = zeros([ceil(sylbIntv*fs),2]);
% 
% for cue = cuePool
%     for dir = dirPool
%         for i = intsPool
%             this_key = i + "_" + dir + tarDir + "_" + cue;
%             this_sig = spaSylbs.(this_key);
% 
%             sigConcat = [sigConcat;this_sig];
%             sigConcat = [sigConcat;sigIntv];
%         end
%     end
% end
% 
% %sound(sigConcat,fs)
% save_path = ['./examples/' 'sweep_all_' char(strjoin(dirPool,'-')) '.wav'];
% audiowrite(save_path,sigConcat,fs)

%% broadband ILD

% sigConcat = [];
% for dir = dirPool
%     hrir_file = [cfg.hrirFolder 'H0e0' char(dir) 'a.wav'];
%     [hrir,~] = audioread(hrir_file); %128-pt
%     level_ch1 = 20*log10(rms(hrir(:,1)));
%     level_ch2 = 20*log10(rms(hrir(:,2)));
%     this_ILD = abs(level_ch1 - level_ch2);
%     ILD_bb.("ILD"+dir) = this_ILD;
%     for sylb = intsPool
%         sig_file = [cfg.sylbFoler char(sylb) '_F_rms0d05_350ms.wav']; % TODO: back to M
%         [sig,~] = audioread(sig_file);
%         sigs.(sylb) = sig;
% 
%         % ILD_bb is positive number 
%         spaSig = [sig, sig.*10^(-this_ILD/20)];
%         sigConcat = [sigConcat;spaSig];
%         sigConcat = [sigConcat;sigIntv];
%     end
% end
%
% sound(sigConcat,fs)
% save_path = ['./examples/' 'broadband_ILD_' char(strjoin(dirPool,'-')) '.wav'];
% audiowrite(save_path,sigConcat,fs)