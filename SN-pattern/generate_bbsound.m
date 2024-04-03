% this script is used for generating braodband sounds 

fs = 44100;
desired_rms = 0.05;

%% syllable in broadband noise 

% config
sylb_folder = './stimuli/normalized-mono/syllables/';
bb_folder = './stimuli/normalized-mono/broadband/';
sylb_pool = ["ba","da","ga"];
gender_pool = ["F","M"];

% prep noise with specific frequency range
dur = 0.4;
f1 = 30;
f2 = 30000;

t = 0:1/fs:dur;
chirp_sig = chirp(t,f1,dur,f2);
chirp_noise = chirp_sig(randperm(length(chirp_sig)));

% add noise to sylb and save
att_noise_db = 10;
for sylb = sylb_pool
    for gen = gender_pool
        % read sig
        this_path = [sylb_folder char(sylb) '_' char(gen) '_rms0d05_350ms.wav'];
        [this_sig, ~] = audioread(this_path);
        % compute corresponding rms
        sig_rms = rms(this_sig);
        noise_rms = sig_rms*10^(-att_noise_db/20); % noise will be 10 dB lower than sig
        % adding noise
        chirp_noise = chirp_noise./rms(chirp_noise).*noise_rms;
        sig_noised = this_sig + chirp_noise(1:length(this_sig))';
        % normalizing to desired rms 
        sig_normalized = sig_noised./rms(sig_noised).*desired_rms;
        % save signal
        sig_id = [char(sylb) '_' int2str(f1) '_' int2str(f2) '_' int2str(att_noise_db) 'db'];
        save_path = [bb_folder sig_id '_' char(gen) '_rms0d05_350ms.wav'];
        audiowrite(save_path,sig_normalized,fs);
    end
end



%% chirp signal

% % config
% dur = 0.3;
% f_start = 30;
% f_end = 30000;
% desired_rms = 0.05;
% 
% % normal chirp
% t = 0:1/fs:dur;
% chirp_sig = chirp(t,f_start,dur,f_end);
% chirp_sig = chirp_sig./rms(chirp_sig).*desired_rms;
% 
% % reversed chirp
% chirp_sig_inv = chirp(t,f_end,dur,f_start);
% chirp_sig_inv = chirp_sig_inv./rms(chirp_sig_inv).*desired_rms;
% 
% % blocked and half-reversed chirp
% mid_pt = ceil(length(chirp_sig_inv)/2);
% chirp_sig_blocked = [chirp_sig_inv(1:mid_pt), flip(chirp_sig_inv(mid_pt+1:end))];
% 
% % sound(chirp_sig,fs)
% % audiowrite("./examples/chirp.wav",chirp_sig,fs)


