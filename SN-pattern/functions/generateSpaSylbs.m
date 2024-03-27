function spaSylbs = generateSpaSylbs(cfg)
% This function generates a struct of spatialized syllables,
% from normalized mono syllables and mono hrir signals 
% I've been using char arrays and string arrays alternatively...which is
% not good, also I'm using a_b and aB naming for variables...

sigLen = double(cfg.sylbDur * cfg.fs);

% load mono syllables 
sigPool = ["ba","da","ga"];
for sylb = sigPool
    sig_file = [cfg.sylbFoler char(sylb) '_M_rms0d05_350ms.wav'];
    [sig,~] = audioread(sig_file);
    sigs.(sylb) = sig;
end


% convolve to obtain spatialized syllables
for dir = cfg.dirPool

    % obtain frequency specific ILD and ITDs
    hrir_file = [cfg.hrirFolder 'H0e0' char(dir) 'a.wav'];
    [hrir,~] = audioread(hrir_file); % (128,2)
    ild = getFreqSpecILD(hrir);
    itd = getFreqSpecITD(hrir);

    for hemi = ["L","R"]
        tarDir = dir+hemi; 
        
        for sylb = sigPool
            if hemi == "R"
                spaSig_ch1 = conv(sigs.(sylb), hrir(:,1));
                spaSig_ch2 = conv(sigs.(sylb), hrir(:,2));
            elseif hemi == "L"
                spaSig_ch1 = conv(sigs.(sylb), hrir(:,2));
                spaSig_ch2 = conv(sigs.(sylb), hrir(:,1));
            end

            % pad to fixed length
            if length(spaSig_ch1) > sigLen
                error("Spatialized signal longer than desired length!")
            else
                spaSylbs.(sylb+"_"+tarDir) = padarray([spaSig_ch1, spaSig_ch2],sigLen-length(spaSig_ch1),0,'post');
            end
        end
    end
end

end

%% functions to obtain frequency-specific ILD and ITD

function ild = getFreqSpecILD(hrir)

% TODO: update this 
ild = hrir;

end



function itd = getFreqSpecITD(hrir)

% TODO: update this 
itd = hrir;

end
