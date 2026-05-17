close all
clear all
clc

% Folder containing the CSV files
data_folder = 'data_csv';

% Get list of all CSV files in the folder
csv_files = dir(fullfile(data_folder, '*.csv'));

% Prepare storage variables
usernames = {};
conditions = {};
sus_scores = [];

for i = 1:length(csv_files)
    % Get full path of the file
    filepath = fullfile(data_folder, csv_files(i).name);
    
    % Extract filename, e.g., 'albertino_sus_responses_HC.csv'
    filename = csv_files(i).name;
    
    % Extract user and condition using split
    parts = split(filename, '_');
    user = parts{1};               % 'albertino'
    condition = parts{2};
    
    % Read responses
    sus_table = readtable(filepath);
    responses = table2array(sus_table);
    
    
    % Compute SUS score
    odd_items  = responses(1:2:end);     % Q1, Q3, ...
    even_items = responses(2:2:end);     % Q2, Q4, ...
    adjusted = [odd_items - 1, 5 - even_items];
    sus_score = sum(adjusted) * 2.5;
    
    % Store results
    usernames{end+1} = user;
    conditions{end+1} = condition;
    sus_scores(end+1) = sus_score;
end


sus_results = table(usernames', conditions', sus_scores', ...
    'VariableNames', {'User', 'Condition', 'SUS_Score'});
disp(sus_results);


% Create initial long-format table
long_table = table(usernames', conditions', sus_scores', ...
    'VariableNames', {'User', 'Condition', 'SUS_Score'});


% Modular: detect all unique conditions and sort columns accordingly
unique_conditions = unique(long_table.Condition, 'stable');
num_conditions = numel(unique_conditions);
[G, user_groups] = findgroups(long_table.User);
user_counts = splitapply(@numel, long_table.Condition, G);
user_has_all = user_counts == num_conditions;
users_with_all = user_groups(user_has_all);
filtered_table = long_table(ismember(long_table.User, users_with_all), :);

% Pivot to wide-format table, only for users with all conditions
wide_table = unstack(filtered_table, 'SUS_Score', 'Condition');

% Sort columns: User, then all detected conditions in order
expected_order = ["User", unique_conditions'];
actual_vars = string(wide_table.Properties.VariableNames);
ordered_vars = intersect(expected_order, actual_vars, 'stable');
wide_table = wide_table(:, ordered_vars);

% Prepare data for boxplot/barplot
all_completion_times = [];
group_labels = {};
short_names = cellstr(unique_conditions');
for i = 1:num_conditions
    cond = unique_conditions(i);
    cond_name = char(cond); % Ensure variable name is char for table indexing
    if ismember(cond_name, wide_table.Properties.VariableNames)
        vals = wide_table.(cond_name);
        all_completion_times = [all_completion_times, vals];
        group_labels = [group_labels, repmat(short_names(i), 1, length(vals))];
    end
end



% Plot: use bar if only one subject, boxplot otherwise
if height(wide_table) == 1
    % Only one subject: bar plot
    figure;
    bar(categorical(short_names), all_completion_times(1,:));
    ylabel('SUS Score');
    title('SUS Score by Condition');
else
    % Multiple subjects: boxplot
    figure;
    boxplot(all_completion_times(:), group_labels(:));
    ylabel('SUS Score');
    title('SUS Score by Condition');
end


% Modular stats calculation
groups = short_names;
num_groups = numel(groups);
data_vectors = cell(1, num_groups);
for i = 1:num_groups
    cond_name = char(groups{i});
    if ismember(cond_name, wide_table.Properties.VariableNames)
        data_vectors{i} = wide_table.(cond_name);
    else
        data_vectors{i} = NaN(height(wide_table),1);
    end
end
stats = table('Size', [num_groups 5], ...
    'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'LowerWhisker', 'Q1', 'Median', 'Q3', 'UpperWhisker'}, ...
    'RowNames', groups);
for i = 1:num_groups
    x = data_vectors{i};
    q = quantile(x, [0.25, 0.5, 0.75]);
    iqr_val = iqr(x);
    lw = min(x(x >= (q(1) - 1.5 * iqr_val)));
    uw = max(x(x <= (q(3) + 1.5 * iqr_val)));
    stats{i, :} = [lw, q(1), q(2), q(3), uw];
end
disp(stats);



