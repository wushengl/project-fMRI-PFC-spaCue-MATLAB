function trialSig = generateTrialSig(cfg,thisTrial,spaSylbs,doAudCue)
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
        %spaCue = "ILD";
        %spaCue = "bbILD";
        spaCue = "fixedILD";
    case 'T'
        %spaCue = "ITD";
        %spaCue = "bbITD";
        spaCue = "fixedITD";
    otherwise
        error("Undefined spaCue_char in thisTrial.")
end


%% generate random sequence
% 1. generate pattern 1 purely randomly
% 2. we don't want them to recognize the patterns are different too fast, 
% so we'll have first 2 syllables in pattern 2 the same as pattern 1, and
% randomly change one of syllable in syllable 3 and 4 
% 3. if task is spatial task, the location pattern will be determined
% follow 2, the syllable pattern will be randomly true or false  

% each syllable appear twice maximum
% sylbPool = ["int1", "int1", "int1", "int1", "int1", "int1"]; % this is for testing only
sylbPool = ["int1", "int4", "int5", "int1", "int4", "int5"]; % 1, 3, 28 for p001
repeatDirPool = [cfg.dirPool cfg.dirPool];

% random sample sylb_per_pattern (4) from the pool
ptn1_sylbs = randsample(sylbPool,cfg.sylbPerPat); 
ptn1_dirs = randsample(repeatDirPool,cfg.sylbPerPat,false);

if taskType == 'S'
    % spatial task, choose a random sound and fix for this trial
    ptn1_sylbs = repmat(randsample(sylbPool,1),1,4); % choose 1 random repeat 4 times, result in 1x4 array
    ptn2_sylbs = ptn1_sylbs; 
    % random direction sequence
    ptn1_dirs = randsample(repeatDirPool,cfg.sylbPerPat,false);
    if isTar == 'T'
        ptn2_dirs = ptn1_dirs;
    else
        %ptn2_dirs = replaceLaterItem(ptn1_dirs,cfg.dirPool,cfg);
        ptn2_dirs = switchTwoItem(ptn1_dirs);
    end
elseif taskType == 'N'
    % non-spatial task, choose a random location and fix for this trial
    ptn1_dirs = repmat(randsample(repeatDirPool,1),1,4);
    ptn2_dirs = ptn1_dirs;
    % random syllable sequence
    ptn1_sylbs = randsample(sylbPool,cfg.sylbPerPat);
    if isTar == 'T'
        ptn2_sylbs = ptn1_sylbs;
    else
        ptn2_sylbs = replaceLaterItem(ptn1_sylbs,sylbPool,cfg);
    end
else 
    % passive task, half fixing location random syllable, half fixing
    % syllalbe, random location. Compare both, should be the same, if so, 
    % average to be baseline.

    % Here I'm not adding a new indicator for whether this passive trial is
    % fixing location or syllable, simply using T/F indicator, which is
    % already balanced and not useful for behavior.
    if isTar == 'T'
        % fixing location, random syllable 
        ptn1_dirs = repmat(randsample(repeatDirPool,1),1,4);
        ptn2_dirs = ptn1_dirs;
        ptn1_sylbs = randsample(sylbPool,cfg.sylbPerPat);
        ptn2_sylbs = ptn1_sylbs;
    else
        % fixing syllable, random location 
        ptn1_sylbs = repmat(randsample(sylbPool,1),1,4); % choose 1 random repeat 4 times, result in 1x4 array
        ptn2_sylbs = ptn1_sylbs; 
        ptn1_dirs = randsample(repeatDirPool,cfg.sylbPerPat,false);
        ptn2_dirs = ptn1_dirs;
    end
    %ptn2_dirs = replaceLaterItem(ptn1_dirs,cfg.dirPool,cfg);
    %ptn2_sylbs = replaceLaterItem(ptn1_sylbs,sylbPool,cfg);
end


%% concate signals 
% audio sigal does not include task type instruction screen, it starts from
% playing cue sound. 

% compute corresponding onset times
if doAudCue
    cue_offset = cfg.sylbDur + cfg.cue2tarIntv;
else
    cue_offset = 0;
end
ptn1_onsets = cue_offset + (0:cfg.sylbPerPat-1)*(cfg.sylbDur + cfg.sylbIntv);
ptn2_onsets = ptn1_onsets(end) + cfg.sylbDur + cfg.pat2patIntv + ...
    (0:cfg.sylbPerPat-1)*(cfg.sylbDur + cfg.sylbIntv);
audio_dur = ptn2_onsets(end) + cfg.sylbDur;

% create baseline trial with cue 
audio_samps = ceil(audio_dur*cfg.fs);
trialSig = zeros(audio_samps,2);

cue_sylb = "int4";
% cue_sylb = "ba_30_30000_10db"; 
cue_dir = cfg.dirPool(2);
cue_sig = spaSylbs.(cue_sylb+"_"+cue_dir+string(tarHemi)+"_"+spaCue);
sylb_len = length(cue_sig);


if doAudCue
    trialSig(1:sylb_len,:) = cue_sig; 
end

% we don't have any overlap of signals in this task, so simply place those
% syllables at their locations without adding all signals (need to pad all)
% is fine. 

% TODO: remove this
%disp(ptn1_dirs)
%disp(ptn2_dirs)

for s = 1:cfg.sylbPerPat
    this_ptn1_sylb = ptn1_sylbs(s); % e.g. "ba"
    this_ptn2_sylb = ptn2_sylbs(s); 
    this_ptn1_dir = ptn1_dirs(s); % e.g. "30"
    this_ptn2_dir = ptn2_dirs(s);

    this_ptn1_sig = spaSylbs.(this_ptn1_sylb+"_"+this_ptn1_dir+string(tarHemi)+"_"+spaCue);
    this_ptn2_sig = spaSylbs.(this_ptn2_sylb+"_"+this_ptn2_dir+string(tarHemi)+"_"+spaCue);

    this_ptn1_onset = ceil(ptn1_onsets(s)*cfg.fs);
    this_ptn2_onset = ceil(ptn2_onsets(s)*cfg.fs);

    trialSig(this_ptn1_onset+1:this_ptn1_onset+sylb_len,:) = this_ptn1_sig;
    trialSig(this_ptn2_onset+1:this_ptn2_onset+sylb_len,:) = this_ptn2_sig;
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

function new_seq = switchTwoItem(seq)
    % seq is 4 item sequence with 2 dir1 and 2 dir 2
    % here I'm finding a non-repeating pair and switching their positions
    seq_next = seq(2:end);
    is_repeat = seq(1:end-1) == seq_next;
    switch_idx = randsample(find(is_repeat==0),1);

    switch_item1 = seq(switch_idx);
    switch_item2 = seq(switch_idx+1);

    new_seq = seq;
    new_seq(switch_idx) = switch_item2;
    new_seq(switch_idx+1) = switch_item1;
end