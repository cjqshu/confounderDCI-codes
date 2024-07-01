clear
close all
warning("off")

% add specified folder
addpath(genpath('./data'));
addpath(genpath('./utils'));

% hyperparameter setting
num_confounders = 3;
nIter = 20;
nAll = 10; % one third of total nodes
pAll = 0.5;
nTrialsAll = 500;
% nAll = [10, 20, 30, 50];  % one third of total nodes
% pAll = [0.3, 0.5, 0.7];
% nTrialsAll = [100, 300, 500, 700, 900];

% save data to this folder
folder_dir = strcat("./data/nc", num2str(num_confounders), "_", "nIter", num2str(nIter), "/");
mkdir(folder_dir)

% use default random seed
rng('default');

for iN = 1:length(nAll)
    for iP = 1:length(pAll)
        p = pAll(iP);
        for iNTrials = 1:length(nTrialsAll)
            nTrials = nTrialsAll(iNTrials);
            n = nAll(iN);
            for iIter = 1:nIter
                % generate data
                [X, T, Y, C0, groundtruth_C, groundtruth_CMA] = data_generator(n, p, num_confounders, nTrials);

                % save data and groundtruth
                file_name = strcat("nodes_", num2str(3*n), "_", num2str(p), "_", num2str(nTrials), "_", num2str(iIter), ".mat");
                file_dir = strcat(folder_dir, file_name);
                save(file_dir, "X", "T", "Y", "C0", "groundtruth_CMA", "groundtruth_C");
            end
        end
    end
end
