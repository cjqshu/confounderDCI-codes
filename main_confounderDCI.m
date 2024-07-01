clear
close all
warning("off")

% add specified folder
addpath(genpath('./data'));
addpath(genpath('./utils'));
addpath(genpath('./results'));
addpath(genpath('./models/confounderDCI'));

% hyperparameter setting
num_confounders = 3;
nIter = 20;
nAll = 10; % one third of total nodes
pAll = 0.5;
nTrialsAll = 500;
% nAll = [10, 20, 30, 50];  % one third of total nodes
% pAll = [0.3, 0.5, 0.7];
% nTrialsAll = [100, 300, 500, 700, 900];

% data directory
data_file_dir = strcat("./data/nc", num2str(num_confounders), "_", "nIter", num2str(nIter), "/");

% save data to this folder
folder_dir = strcat("./results/confouderDCI/nc", num2str(num_confounders), "_", "nIter", num2str(nIter), "/");
mkdir(folder_dir)

% use default random seed
rng('default');

t1 = clock;

for iN = 1:length(nAll)
    ResultsTable = table;

    for iP = 1:length(pAll)
        p = pAll(iP);

        for iNTrials = 1:length(nTrialsAll)
            nTrials = nTrialsAll(iNTrials);
            n = nAll(iN);

            % initialization
            accuracy = nan(1, nIter);
            precision = nan(1, nIter);
            recall = nan(1, nIter);

            tic

            for iIter = 1:nIter
                % load data, include "X", "T", "Y", "groundtruth_CMA", "groundtruth_C"
                try
                    data_file_name = strcat("nodes_", num2str(3*n), "_", num2str(p), "_", num2str(nTrials), "_", num2str(iIter), ".mat");
                    data_dir2name = strcat(data_file_dir, data_file_name);
                    load(data_dir2name);
                catch
                    continue;
                end

                % confounder Selection for Conditional Independence Test (confounderDCI)
                alpha_dep = 0.05; % minDependencyThreshold
                alpha_ci = 0.25; % thresholdCI
                [confounders_01, confounders_index] = confounderDCI(X, T, Y, C0, alpha_dep, alpha_ci);

                % evaluate
                num_confounders_index = size(confounders_index, 2);

                if num_confounders_index == 0 % exclude the case where confounders are not identified
                    continue;
                end

                [accuracy_i, precision_i, recall_i] = evaluation(groundtruth_C, confounders_01, num_confounders_index);

                accuracy(iIter) = accuracy_i;
                precision(iIter) = precision_i;
                recall(iIter) = recall_i;
            end

            % record results
            ResultsTableN = table;
            ResultsTableN.nNodes = 3 * n;
            ResultsTableN.sparseness = p;
            ResultsTableN.nSamples = nTrials;
            ResultsTableN.nIterations = nIter;

            ResultsTableN.accuracy_avg = nanmean(accuracy);
            ResultsTableN.precision_avg = nanmean(precision);
            ResultsTableN.recall_avg = nanmean(recall);

            %             ResultsTableN.accuracy_std = nanstd(accuracy);
            %             ResultsTableN.precision_std = nanstd(precision);
            %             ResultsTableN.recall_std = nanstd(recall);
            %             ResultsTableN.accuracy = accuracy;
            %             ResultsTableN.precision = precision;
            %             ResultsTableN.recall = recall;

            ResultsTableN.timeDuration = toc; % second

            ResultsTable = [ResultsTable; ResultsTableN];

            % print progress
            t2 = clock;
            t = etime(t2, t1) / 60; % minute
            disp(strcat("nNodes: ", num2str(3*n), ", sparsity: ", num2str(p), ", nSamples: ", ...
                num2str(nTrials), ", run_time_minute: ", num2str(t)));
        end
    end

    % save results
    save(strcat(folder_dir, "results_", num2str(3*n), ".mat"), "ResultsTable");
end
