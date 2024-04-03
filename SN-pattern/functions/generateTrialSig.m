function trialSig = generateTrialSig(cfg,thisTrial,spaSylbs)
% This function use spatialized syllables, create audio signal for a trial,
% where each trial contains 2 patterns (each contains 4 syllables).
% The taskType, tarDir, isTar should be read from thisTrial

taskType = thisTrial(1);
tarHemi = thisTrial(2);
spaCue_char = thisTrial(3);
isTar = thisTrial(4);

switch spaCue_char
    case 'F'
        spaCue = "HRTF";
    case 'L'
        spaCue = "ILD";
    case 'T'
        spaCue = "ITD";
    otherwise
        error("Undefined spaCue_car in thisTrial.")
end


%% generate random sequence
% 1. generate pattern 1 purely randomly
% 2. we don't want them to recognize the patterns are different too fast, 
% so we'll have first 2 syllables in pattern 2 the same as pattern 1, and
% randomly change one of syllable in syllable 3 and 4 
% 3. if task is spatial task, the location pattern will be determined
% follow 2, the syllable pattern will be randomly true or false  

% each syllable appear twice maximum
%sylbPool = ["ba","da","ga","ba","da","ga"]; % TODO
%sylbPool = ["int1", "int3", "int28", "int1", "int3", "int28"];
sylbPool = ["ba_30_30000_10db","da_30_30000_10db","ga_30_30000_10db",...
    "ba_30_30000_10db","da_30_30000_10db","ga_30_30000_10db"];
ptn1_sylbs = randsample(sylbPool,cfg.sylbPerPat);
ptn1_dirs = randsample(cfg.dirPool,cfg.sylbPerPat,true);

if taskType == 'S'
    ptn2_sylbs = ptn1_sylbs; % definately not correlated with ptn2_dirs
    if isTar == 'T'
        ptn2_dirs = ptn1_dirs;
    else
        ptn2_dirs = replaceLaterItem(ptn1_dirs,cfg.dirPool,cfg);
    end
elseif taskType == 'N'
    ptn2_dirs = ptn1_dirs;
    if isTar == 'T'
        ptn2_sylbs = ptn1_sylbs;
    else
        ptn2_sylbs = replaceLaterItem(ptn1_sylbs,sylbPool,cfg);
    end
end


%% concate signals 
% audio sigal does not include task type instruction screen, it starts from
% playing cue sound. 

% compute corresponding onset times
cue_offset = cfg.sylbDur + cfg.cue2tarIntv;
ptn1_onsets = cue_offset + (0:cfg.sylbPerPat-1)*(cfg.sylbDur + cfg.sylbIntv);
ptn2_onsets = ptn1_onsets(end) + cfg.sylbDur + cfg.pat2patIntv + ...
    (0:cfg.sylbPerPat-1)*(cfg.sylbDur + cfg.sylbIntv);
audio_dur = ptn2_onsets(end) + cfg.sylbDur;

% create baseline trial with cue 
audio_samps = ceil(audio_dur*cfg.fs);
trialSig = zeros(audio_samps,2);

% cue_sylb = "int3";
cue_sylb = "ba_30_30000_10db"; % TODO
cue_dir = cfg.dirPool(2);
cue_sig = spaSylbs.(cue_sylb+"_"+cue_dir+string(tarHemi)+"_"+spaCue);
sylb_len = length(cue_sig);
trialSig(1:sylb_len,:) = cue_sig; 

% we don't have any overlap of signals in this task, so simply place those
% syllables at their locations without adding all signals (need to pad all)
% is fine. 

for s = 1:cfg.sylbPerPat
    this_ptn1_sylb = ptn1_sylbs(s); % e.g. "ba"
    this_ptn2_sylb = ptn2_sylbs(s); 
    this_ptn1_dir = ptn1_dirs(s); % e.g. "30"
    this_ptn2_dir = ptn2_dirs(s);

    this_ptn1_sig = spaSylbs.(this_ptn1_sylb+"_"+this_ptn1_dir+string(tarHemi)+"_"+spaCue);
    this_ptn2_sig = spaSylbs.(this_ptn2_sylb+"_"+this_ptn2_dir+string(tarHemi)+"_"+spaCue);

    this_ptn1_onset = ceil(ptn1_onsets(s)*cfg.fs);
    this_ptn2_onset = ceil(ptn2_onsets(s)*cfg.fs);

    trialSig(this_ptn1_onset:this_ptn1_onset+sylb_len-1,:) = this_ptn1_sig;
    trialSig(this_ptn2_onset:this_ptn2_onset+sylb_len-1,:) = this_ptn2_sig;
end

end

%% helper function 

function new_seq = replaceLaterItem(seq,pool,cfg)
    % choose 1 to replace, create new pool without that item
    replace_idx = randsample([cfg.sylbPerPat-1,cfg.sylbPerPat],1);
    old_item = seq(replace_idx);
    new_pool = pool(~ismember(pool,old_item));
    
    % create new sequence, with 1 later item not the same as original
    new_seq = seq;
    new_seq(replace_idx) = randsample(new_pool,1);
end