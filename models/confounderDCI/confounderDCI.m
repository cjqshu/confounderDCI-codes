function [confounders_01, confounders_index] = confounderDCI(X, T, Y, C0, alpha_dep, alpha_ci)
% Description:
% discover confounders using confounderDCI
%
% Inputs:
% X: Covariate matrix
% n: the size of covariates
% T: treatment
% Y: outcome
% C0: seed variable
%
% Outputs:
% confounders_01: the logical array of confounders

% add specified folder
addpath(genpath('./KCI'));

% hyperparameter setting
info.minDependencyThreshold = alpha_dep; % default: alpha_dep=0.05
info.thresholdCI = alpha_ci; % the thereshold of conditional independence tests--default: alpha_ci=0.25
info.methods = "Hsic";

pars.pairwise = true; % if true, the test is performed pairwise if d1>1 (standard: false)
pars.bonferroni = false; % if true, bonferroni correction is performed (standard: false)
pars.width = 2; % kernel width (standard: 0, which results in an automatic -heuristic- choice)

X_CO = C0;

% 1. run level1 dependency tests (find correlation)
[~, ~, pHSIC_XT] = calcCandidatesLevel1(info, X, T);
[~, ~, pHSIC_XY] = calcCandidatesLevel1(info, X, Y);
pHSIC_XTY = 0.5 * pHSIC_XT + 0.5 * pHSIC_XY; % 0.8, 0.2
pHSIC_XTY_01 = pHSIC_XTY <= info.minDependencyThreshold; % logical array

% 2. run level2 independence tests (find independence)
[~, ~, pHSIC_XC0] = calcCandidatesLevel1(info, X, X_CO);
pHSIC_XC0_01 = pHSIC_XC0 > info.thresholdCI;

% 3. run level3 conditional dependency tests X_CO_|/|_X_nonCO|T (find correlation)
n = size(X, 2);
pHsic_givenT = zeros(1, n);

for iCand = 1:n
    [pHsic_givenT(iCand), ~] = indtest_hsic(X_CO, X(:, iCand), T, pars); % check C0 _|\|_ nonC0 | T
end

pHSIC_givenT_01 = pHsic_givenT <= info.minDependencyThreshold;
% pHSIC_givenT_01 = pHsic_givenT <= info.thresholdCI;

% summary
% level_1 = pHSIC_XTY_01;
% level_12 = pHSIC_XTY_01 & pHSIC_XC0_01;
level_123 = pHSIC_XTY_01 & pHSIC_XC0_01 & pHSIC_givenT_01;
confounders_01 = level_123;
confounders_index = find(confounders_01 == 1);

end


% subfunction
function [DependencyXy_Index, DependencyXy_01, pHSIC_Xy] = calcCandidatesLevel1(info, X, y)
% Description:
% select the index of X that are dependent with y
%
% Inputs:
% info                  significance level information, such as info.minDependencyThreshold (0.5)
% X                     matrix of covariates
% y                     vector of a covariate
%
% Outputs:
% DependencyXy_Index    Indexes in X that are related to y
% DependencyXy_01       logical array in X that are related to y
% pHSIC_Xy              p value of the test
%
% Examples:
% a = rand(100,1);
% b = rand(100,1);
% c = a + b;
% info.minDependencyThreshold = 0.05;
% [DependencyXy_Index, DependencyXy_01, pHSIC_Xy] = calcCandidatesLevel1(info, [a, b, c], b)
%
% results
% DependencyXy_Index =
%      2     3
% DependencyXy_01 =
%   1×3 logical array
%    0   1   1
% pHSIC_Xy =
%     0.4953    0.0000    0.0000

% significance level alpha(0.05), p-value <= alpha(0.05) signifies significant dependency
dependencyThresholdHsic = info.minDependencyThreshold;

% find significant dependency candidates X _|/|_ y
[pHSIC_Xy, ~] = calcDependencyXy(X, y);
DependencyXy_01 = pHSIC_Xy <= dependencyThresholdHsic; % the boolean True is significant dependency, vice versa
DependencyXy_Index = find(DependencyXy_01);
end


% subfunction
function [pHSIC, statHSIC] = calcDependencyXy(X, y)
% Description:
% calculate dependency between X_i and y
%
% Inputs:
% X         matrix of covariates
% y         vector of a covariate
%
% Outputs:
% pHSIC     p value of the test
% statHSIC  test statistic

% hyperparameter setting
pars.pairwise = true;
pars.bonferroni = false;
pars.perm = 1000;

nComponents = size(X, 2);
pHSIC = nan(1, nComponents);
statHSIC = nan(1, nComponents);

for iComp = 1:nComponents
    [pHSIC(iComp), statHSIC(iComp)] = indtest_hsic(X(:, iComp), y, [], pars);
end
end
