function [X, T, Y, C0, groundtruth_C, groundtruth_CMA] = data_generator(n, p, num_confounders, nTrials)
% Description:
% generate data based on structural causal model
%
% Inputs:
% n                   one third of total nodes
% p                   density
% num_confounders     number of true confounders
% nTrials             sample size
%
% Outputs:
% X                   number of covariates
% T                   treatment
% Y                   outcome
% C0                  a priori confounder
% groundtruth_C       ground truth of confounding variables
% groundtruth_CMA     ground truth of confounding, mediating, and adjustment variables
%
% Example:
% [X, T, Y, C0, groundtruth_C, groundtruth_CMA] = data_generator(5, 0.2, 1, 100);

mu = 0;
sigma = random('uniform', 0, 1, 1);
gm = gmdistribution(mu, sigma);
parameters = random(gm, 10);

% create noise terms for all nodes of graph
noiseTerms = createNodesWithNoiseTerms(n * 3 + 3, nTrials);
noiseTerms_C = noiseTerms(:, 1:n);
noiseTerms_M = noiseTerms(:, n+1:2*n);
noiseTerms_A = noiseTerms(:, 2*n+1:3*n);
noiseTerms_T = noiseTerms(:, 3*n+1);
noiseTerms_Y = noiseTerms(:, 3*n+2);
C0 = noiseTerms(:, 3*n+3);

edgeBetweenC_TY = zeros(1, n);
edgeBetweenM_TY = zeros(1, n);
edgeBetweenA_Y = zeros(1, n);

while sum(edgeBetweenM_TY) == 0 || sum(edgeBetweenA_Y) == 0
    edgeBetweenM_TY = logical(binornd(1, p*ones(1, n))); % generate mediating nodes (T-> M ->Y)
    edgeBetweenA_Y = logical(binornd(1, p*ones(1, n))); % generate adjustment nodes (A->Y)
end

edgeBetweenC_TY(1:num_confounders) = 1;
edgeBetweenC_TY = logical(edgeBetweenC_TY); % choose the first num_confounder variables as confounders

% data generation mechanism
C = noiseTerms_C;
M = noiseTerms_M;
A = noiseTerms_A;
T = noiseTerms_T + sum(parameters(1).*[C(:, edgeBetweenC_TY), C0]+parameters(2), 2);
M(:, edgeBetweenM_TY) = M(:, edgeBetweenM_TY) + sum(parameters(3).*T+parameters(4), 2);
Y = noiseTerms_Y + T ...
    +sum(parameters(5).*[C(:, edgeBetweenC_TY), C0]+parameters(6), 2) ...
    +sum(parameters(7).*M(:, edgeBetweenM_TY)+parameters(8), 2) ...
    +sum(parameters(9).*A(:, edgeBetweenA_Y)+parameters(10), 2);
X = [C, M, A];

groundtruth_C = logical([edgeBetweenC_TY, zeros(1, size(edgeBetweenM_TY, 2)), zeros(1, size(edgeBetweenA_Y, 2))]);
groundtruth_CMA = logical([edgeBetweenC_TY, edgeBetweenM_TY, edgeBetweenA_Y]);
end


% subfunction
function [noiseTerms] = createNodesWithNoiseTerms(n, nTrials)
% Description:
% create nodes with noiseterms
%
% Input:
% n                   number of columns
% nTrials             number of rows
%
% Output:
% noiseTerms          nTrials × n matrix (nTrials points with dimensionality n)
%
% Example:
% noiseTerms = createNodesWithNoiseTerms(3, 100);

mu = 0;
noiseTerms = nan(nTrials, n);
for inode = 1:n
    sigma = random('uniform', 0, 1, 1);
    gm = gmdistribution(mu, sigma);
    noiseTerms(:, inode) = random(gm, nTrials);
end
end
