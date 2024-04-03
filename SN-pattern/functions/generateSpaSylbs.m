function spaSylbs = generateSpaSylbs(cfg)
% This function generates a struct of spatialized syllables,
% from normalized mono syllables and mono hrir signals 
% I've been using char arrays and string arrays alternatively...which is
% not good, also I'm using a_b and aB naming for variables...

sigLen = double(cfg.sylbDur * cfg.fs);

% load mono syllables 
% sigPool = ["ba","da","ga"]; 
sigPool = ["int1","int3","int28","ba_30_30000_10db","da_30_30000_10db","ga_30_30000_10db"]; 
for sylb = sigPool
    sig_file = [cfg.sylbFoler char(sylb) '_F_rms0d05_350ms.wav']; % TODO: back to M
    [sig,~] = audioread(sig_file);
    sigs.(sylb) = sig;
end


% convolve to obtain spatialized syllables
spaCuePool = ["HRTF","ILD","ITD"];
for dir = cfg.dirPool

    hrir_file = [cfg.hrirFolder 'H0e0' char(dir) 'a.wav'];
    [hrir,~] = audioread(hrir_file); % (128,2)

    % obtain frequency specific ILD and ITDs and save all to struct
    spaCues.("HRTF") = hrir;
    spaCues.("ILD") = getFreqSpecILD(hrir);
    spaCues.("ITD") = getFreqSpecITD(hrir);

    for hemi = ["L","R"]
        tarDir = dir+hemi; 
        for spaCue = spaCuePool
            thisSpaCue = spaCues.(spaCue); % e.g. 30 degrees frequency-specific ild 
            for sylb = sigPool
                if hemi == "R"
                    spaSig_ch1 = conv(sigs.(sylb), thisSpaCue(:,1));
                    spaSig_ch2 = conv(sigs.(sylb), thisSpaCue(:,2));
                elseif hemi == "L"
                    spaSig_ch1 = conv(sigs.(sylb), thisSpaCue(:,2));
                    spaSig_ch2 = conv(sigs.(sylb), thisSpaCue(:,1));
                end

                % pad to fixed length
                if length(spaSig_ch1) > sigLen
                    error("Spatialized signal longer than desired length!")
                else
                    spaSylbs.(sylb+"_"+tarDir+"_"+spaCue) = padarray([spaSig_ch1, spaSig_ch2],sigLen-length(spaSig_ch1),0,'post');
                end
            end
        end
    end
end

%% adjust ITD level to be the same as better ear in ILD
% ITD has magnitude response of 1 across all frequencies, while ILD has
% same magnitude response ans HRTF, where some of the frequencies are
% attenuated (and maybe some are amplified). This results in difference in
% level in the spatialized stimuli with diffrent spatial cues, and it's
% dependent on the frequency content of the stimuli. 
% So here I'm adding some code to compensate for that. I'm making ITD both
% channel having the same level as the louder ear in HRTF/ILD condition.
% And I'm separating it so that if we decided we don't want to compensate
% for that anymore, it'd be easy to not run this component at all. 

doAttITD = true;

if doAttITD
    for dir = cfg.dirPool
        for hemi = ["L","R"]
            for sylb = sigPool
                hrtf_key = sylb + "_" + dir + hemi + "_HRTF";
                itd_key = sylb + "_" + dir + hemi + "_ITD";

                hrtf_sig = spaSylbs.(hrtf_key);
                itd_sig = spaSylbs.(itd_key);

                better_ear_rms = max(rms(hrtf_sig));

                itd_sig_ch1 = itd_sig(:,1)./rms(itd_sig(:,1)).*better_ear_rms;
                itd_sig_ch2 = itd_sig(:,2)./rms(itd_sig(:,2)).*better_ear_rms;
                spaSylbs.(itd_key) = [itd_sig_ch1,itd_sig_ch2];
            end
        end
    end
end

end



%% functions to obtain frequency-specific ILD and ITD

function ild = getFreqSpecILD(hrir)

% ym is minimum phase cepstrum reconstruction of signal
[~,ild1] = rceps(hrir(:,1));
[~,ild2] = rceps(hrir(:,2));

ild = [ild1,ild2];

% testing - plots
% plot(hrir(:,1)); hold on; plot(ild1)
% plot(abs(fft(hrir(:,1)))); hold on; stem(abs(fft(ild1)))
% plot(unwrap(angle(fft(hrir(:,1))))); hold on; stem(unwrap(angle(fft(ild1))))

% testing - sounds
% test_ild = [conv(sig,ild(:,1)),conv(sig,ild(:,1))];
% test_hrir = [conv(sig,hrir(:,1)),conv(sig,hrir(:,1))];
% sound(test_ild,44100)
end


function itd = getFreqSpecITD(hrir)

epsilon = 10^-8; % avoid dividing by 0
P = nextpow2(length(hrir));
N = 2^P; % in case having extra long hrir, this makes FFT faster

[~,ild1] = rceps(hrir(:,1));
[~,ild2] = rceps(hrir(:,2));

itd1 = ifft(fft(hrir(:,1),N)./(fft(ild1,N)+epsilon),N);
itd2 = ifft(fft(hrir(:,2),N)./(fft(ild2,N)+epsilon),N);

itd = [itd1,itd2];

% testing - plots
% plot(hrir(:,1)); hold on; plot(itd1)
% plot(abs(fft(hrir(:,1)))); hold on; stem(abs(fft(itd1)))
% plot(unwrap(angle(fft(hrir(:,1))))); hold on; stem(unwrap(angle(fft(itd1))))

% testing - sounds
% test_itd = [conv(sig,itd(:,1)),conv(sig,itd(:,1))];
% test_hrir = [conv(sig,hrir(:,1)),conv(sig,hrir(:,1))];
% sound(test_itd,44100)

end
