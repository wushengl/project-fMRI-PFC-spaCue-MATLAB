
function info = getRunInfo(runNum,trialPerRun)

    prompt = {'Subject ID:','Device (macbook / windows / scanner):','Task mode (test / train / task):'};
    dlgtitle = 'Run setting';
    fieldsize = [1 60; 1 60; 1 60];
    definput = {'test','macbook','test'}; 
    answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
    info = answer;

    % 6s per trial (with 1.5s response)
    % 3min per block would be 30 trials per block
    % each block contains 1 task type and 1 direction for now 
    % update in getTrialOrder

    if strcmp(answer{3},'test')
        trial_number = 4;
        eyetracker = 0;
        runIdx = 0;
        trialOrder = ["SLF";"NLT";"SRT";"NRF"];
    elseif strcmp(answer{3},'train')
        trial_number = 6;
        eyetracker = 0;
        runIdx = 0;
        trialOrder = ["SLF";"NLT";"SRT";"NRF";"SLT";"NLF";"SRF";"NRT"];
    else 
        runStr = inputdlg("Run number:","Run setting",[1 60],{'1'});
        runIdx = str2double(runStr);
        trialOrder_full = getTrialOrder(runNum,trialPerRun);
        trial_number = trialPerRun;
        trialOrder = trialOrder_full(:,runIdx);
        eyetracker = 0; % TODO
        
    end

    info = [info;{trial_number};{trialOrder};{eyetracker};{runIdx}]; 
end