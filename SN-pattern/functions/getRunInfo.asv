
function info = getRunInfo(cfg)

    prompt = {'Subject ID:','Device (macbook / windows / scanner):','Task mode (test / train / task):'};
    dlgtitle = 'Run setting';
    fieldsize = [1 60; 1 60; 1 60];
    definput = {'test','macbook','test'}; 
    answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
    info = answer;

    if strcmp(answer{3},'test')
        trial_number = 4;
        eyetracker = 0;
        runIdx = 0;
        trialOrder = ["SLLF";"SLTF";"SRLF";"SRTF"];
        blockOrder = trialOrder;
    elseif strcmp(answer{3},'train')
        trial_number = 8;
        eyetracker = 0;
        runIdx = 0;
        trialOrder = ["SLFF";"NLFT";"SRFT";"PRFF";"SLFT";"NLFF";"PRFF";"NRFT"];
        blockOrder = trialOrder;
    else 
        runStr = inputdlg("Run number:","Run setting",[1 60],{'1'});
        runIdx = str2double(runStr);

        trialPerRun = cfg.blockPerRun * cfg.trialPerBlock; 
        saveFolder = [cfg.saveDir answer{1} '/'];

        % check if trialOrder already exist
        trialOrderPath = [saveFolder 'trialOrder.mat'];
        if ~exist(trialOrderPath,"file")
            [trialOrder_full, blockOrder] = getTrialOrder(cfg.runNum,cfg.blockPerRun,trialPerRun);
            if ~exist(saveFolder, 'dir')
                mkdir(saveFolder) 
            end
            save(trialOrderPath,"trialOrder_full","blockOrder");
            disp("Trial order file generated.")
        else
            load(trialOrderPath,"trialOrder_full","blockOrder");
            disp("Trial order file loaded.")
        end
        trial_number = trialPerRun;
        blockOrder = blockOrder(:,runIdx);
        trialOrder = trialOrder_full(:,runIdx);
        eyetracker = 1; 
        
    end

    info = [info;{trial_number};{trialOrder};{blockOrder};{eyetracker};{runIdx}]; 
end
