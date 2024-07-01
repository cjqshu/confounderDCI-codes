function [accuracy, precision, recall] = evaluation(y, scores, k)
% Description:
% This function evaluates the performance of a binary classification model.
% It calculates the accuracy, precision, and recall based on the top k predicted scores.
% 
% Inputs:
% y         A vector of true binary labels (ground truth).
% scores    A vector of scores from the model.
% k         The number of top elements to consider for the evaluation.
%
% Outputs:
% accuracy  Scalar in [0,1]
% precision Scalar in [0,1]
% recall    Scalar in [0,1]
%
% Example:
% [accuracy, precision, recall] = evaluation([1,0,1], [0.2, 0.3, 0.1], 2)

% Sort the scores in descending order and get the sorted indices
[~, sorted_idx] = sort(scores, 'descend');
% idx = sorted_idx(1:k); % Return the indices of the top k elements if needed

% Calculate the number of true positives (tp) and false positives (fp) in the top k elements
tp = sum(y(sorted_idx(1:k)) == 1);
fp = sum(y(sorted_idx(1:k)) == 0);

% Calculate the number of true negatives (tn) and false negatives (fn) in the remaining elements
tn = sum(y(sorted_idx(k+1:end)) == 0);
fn = sum(y(sorted_idx(k+1:end)) == 1);

% Calculate accuracy as the ratio of correctly predicted instances to the total number of instances
accuracy = (tp + tn) / (tp + fp + tn + fn);

% Calculate precision as the ratio of true positives to the sum of true positives and false positives
precision = tp / (tp + fp);

% Calculate recall as the ratio of true positives to the sum of true positives and false negatives
recall = tp / (tp + fn);  % Recall is also known as the true positive rate (tpr)

% Additional metrics can be calculated if needed:
% tpr = tp / (tp + fn);
% fpr = fp / (fp + tn);
% f1_score = 2 * precision * recall / (precision + recall);
end