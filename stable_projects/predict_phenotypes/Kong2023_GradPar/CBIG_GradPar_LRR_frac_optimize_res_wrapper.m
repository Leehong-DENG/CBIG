function CBIG_GradPar_LRR_frac_optimize_res_wrapper(params)

% CBIG_GradPar_LRR_frac_optimize_res_wrapper(params)
%
% This script optimizes the resolution for LRR fracridge prediction using multiple resolutions for
% generating FC matrices. This script can also be used to optimize other parameter for LRR fracridge
% prediction. Specifically, given a set of LRR fracridge predictions of different approaches using the
% same set of lambda values, this script can be used to find the optimal result for each behavior
% across all approaches. In Kong2023, we generated a set of prediction results using different
% resolutions of FC matrices. This script is used to find the optimal resolution for each behavior.
%
% Input:
%   - params: a structure with the following fields
%     - params.project_set: 
%       a cell array of strings. Each string is the path to the project which contains the esults of
%       LRR fracridge prediction. For example, if you want to optimize the resolution for Kong2021,
%       then params.project_set = {'<path>/Kong2021/100', '<path>/Kong2021/200','<path>/Kong2021/300'},
%       where there are 3 resolutions for Kong2021: 100, 200, and 300. The LRR fracridge prediction
%       results for each resolution are stored in subfolders under folder Kong2021. If the LRR fracridge
%       prediction results were stored in the following folders: Kong2021_100, Kong2021_200, and
%       Kong2021_300, then the input can be params.project_set = {'<path>/Kong2021_100',
%       '<path>/Kong2021_200','Kong2021_300'}.
%
%     - params.num_splits:
%       a string. The number of random splits of the cross-validation. For example, if you perform 100
%       repeats of cross-validation, then params.num_splits = '100'. If there is no different split,
%       (i.e. 1 split), then params.num_splits = ''.
%
%     - params.num_folds:
%       a string. The number of folds of the outer-loop cross-validation. For example, if you perform
%       20-fold cross-validation, then params.num_folds = '20'.
%
%     - params.num_behaviors:
%       a string. The number of behaviors. For example, if you have 61 behaviors to be predicted, then
%       params.num_behaviors = '61'.
%
%     - params.outstem:
%       a string. The name of the output file name. To keep the structure to be the same as the LRR fracridge
%       prediction results of the project_set, the output file name should be consistent with project_set.
%       For example, if the outstem of Kong2021/100 is '58_behaviors_3_components', then you should also use
%       this string as the params.outstem.
%
%     - params.out_dir:
%       a string. The path to the output folder. For example, if you want to optimize the resolution
%       for Kong2021, then you can give params.outname = '<path>/Kong2021_opt_res'.
%
% Output:
%   The output results will be stored in the folder params.out_dir. The output results will be saved in the same
%   structure as the LRR fracridge prediction results of the project_set.
%   - acc_metric_train: training accuracy
%   - acc_corr_test: test accuracies (given in correlation)
%   - y_predict: predicted target values
%   - optimal_statistics: a cell array of size equal to the number of folds. Each element in the cell array
%     is a structure storing the accuracies of each possible accuracy metric (eg. corr, MAE, etc).
%   - optimal_project: a cell array of size equal to the number of folds. Each element in the cell array is the
%     optimal project in the project_set for the corresponding fold of all target values.
%
% Written by Ruby Kong and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

% Set up parameters
if(~isempty(params.num_splits))
    num_splits = str2num(params.num_splits);
else
    num_splits = 1;
end
num_folds = str2num(params.num_folds);
num_behaviors = str2num(params.num_behaviors);

for s = 1:num_splits
    for i = 1:num_folds
        for r = 1:length(params.project_set)
            curr_project = params.project_set{r};
            if(num_splits == 1)
                data_file = fullfile(curr_project, 'params', ['fold_' num2str(i)],...
                    ['selected_parameters_' params.outstem '.mat']);
            else
                data_file = fullfile(curr_project, num2str(s), 'params', ['fold_' num2str(i)],...
                    ['selected_parameters_' params.outstem '.mat']);
            end
            data = load(data_file);
            curr_loss = data.min_loss;
            if(r==1)
                loss_all = curr_loss;
            else
                loss_all = [loss_all; curr_loss];
            end
        end
        [~,min_res_idx] = min(loss_all);
        opt_project = params.project_set(min_res_idx);
        optimal_project{i} = opt_project;
        for b = 1:num_behaviors
            if(num_splits == 1)
                acc_file = fullfile(opt_project{b}, 'results', 'optimal_acc', [params.outstem '.mat']);
            else
                acc_file = fullfile(opt_project{b}, num2str(s), 'results', 'optimal_acc', [params.outstem '.mat']);
            end
            acc_data = load(acc_file);
            acc_corr_test(i,b) = acc_data.acc_corr_test(i,b);
            y_predict{i}(:,b) = acc_data.y_predict{i}(:,b);
            acc_metric_train(i,b) = acc_data.acc_metric_train(i,b);

            % obtain all the fields of acc_data.optimal_statistics{i}
            fields = fieldnames(acc_data.optimal_statistics{i});
            for f = 1:length(fields)
                optimal_statistics{i}.(fields{f})(b) = acc_data.optimal_statistics{i}.(fields{f})(b);
            end

        end
    end
    if(num_splits == 1)
        out_dir = fullfile(params.out_dir, 'results','optimal_acc');
    else
        out_dir = fullfile(params.out_dir, num2str(s), 'results','optimal_acc');
    end
    out_file = fullfile(out_dir, [params.outstem '.mat']);
    mkdir(out_dir)
    save(out_file,'acc_corr_test','acc_metric_train','y_predict','optimal_statistics','optimal_project');

end

end