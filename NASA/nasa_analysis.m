close all
clear all
clc

dirname = 'data_csv';
addpath(dirname);
addpath('function');
subFol = dir(fullfile(dirname, '*.csv'));
userNames = {};
testTypes = {};
trialConditions = {};
filenames = {};

% Parse filenames to extract user, condition, and test type


for i = 1:length(subFol)
    [~, nameOnly, ~] = fileparts(subFol(i).name);
    parts = split(nameOnly, '_');
    if numel(parts) < 3, continue; end % skip malformed
    userNames{end+1} = parts{1};
    type = parts{end};
    if strcmp(type, 'PW')
        trialConditions{end+1} = 'PW';
        testTypes{end+1} = 'PW';
    else
        trialConditions{end+1} = parts{2};
        testTypes{end+1} = type;
    end
    filenames{end+1} = fullfile(subFol(i).folder, subFol(i).name);
end

dataTable = table(userNames', testTypes', trialConditions', filenames', ...
    'VariableNames', {'UserName','TestType','TrialCondition','Filename'});

% Detect all unique users and conditions
allUsers = unique(dataTable.UserName, 'stable');
allConditions = unique(dataTable.TrialCondition, 'stable');
nConditions = numel(allConditions);
nSubjects = numel(allUsers);

% Keep all users who did at least one task (no filtering)
allUsers = unique(dataTable.UserName, 'stable');
nSubjects = numel(allUsers);

Axes = categorical({'Effort' 'Frustration' 'Mental demand' 'Performance' 'Physical demand' 'Temporal demand'});
Weights = zeros((1+nConditions)*nSubjects, 6*(nConditions+1));

for k = 1:nSubjects
    rows = find(strcmp(dataTable.UserName, allUsers{k}));
    weightRow = (1 + (k-1)*(nConditions+1));
    for i = rows'
        if dataTable.TestType(i) == "PW"
            cat = categories(importfilePW(dataTable.Filename{i}));
            Weights(weightRow, ismember(Axes, cat)) = countcats(importfilePW(dataTable.Filename{i}));
        else
            condIdx = find(strcmp(dataTable.TrialCondition{i}, allConditions));
            ratingScales = importfileRS(dataTable.Filename{i});
            colStart = 6 * condIdx + 1;
            Weights(weightRow + 1, colStart:colStart + 5) = ratingScales.RatingScales';
        end
    end
end

% Sum for each subject
allScores = zeros(nSubjects, 6*(nConditions+1));
for i = 1:(nConditions+1):size(Weights,1)
    allScores(ceil(i/(nConditions+1)),:) = sum(Weights(i:i+nConditions,:), 1);
end

allUsersTable = table(allUsers, 'VariableNames', {'UserName'});
allWeights = [allUsersTable, array2table(allScores(:,1:6))];
allWeights.Properties.VariableNames = ['UserName'; categories(Axes)];

% ---- Individual Conditions
allRatingScales = struct();
for j = 1:nConditions
    colStart = 6*j + 1;
    colEnd = colStart + 5;
    tbl = [allUsersTable, array2table(allScores(:, colStart:colEnd))];
    tbl.Properties.VariableNames = ['UserName'; categories(Axes)];
    allRatingScales.(allConditions{j}) = tbl;
    adj = allScores(:, 1:6) .* allScores(:, colStart:colEnd);
    tblAdj = [allUsersTable, array2table(adj), array2table(sum(adj,2)/15, 'VariableNames', {'WeightedRating'})];
    tblAdj.Properties.VariableNames = ['UserName'; categories(Axes); 'WeightedRating'];
    allRatingScales.([allConditions{j} '_adj']) = tblAdj;
end

save NASA_TLX_weighted_scores.mat allWeights allRatingScales
% Detect all unique users and conditions
allUsers = unique(dataTable.UserName, 'stable');
allConditions = unique(dataTable.TrialCondition, 'stable');
nConditions = numel(allConditions);
nSubjects = numel(allUsers);

% Do NOT filter users by completed conditions; keep all users
allUsers = unique(dataTable.UserName, 'stable');
nSubjects = numel(allUsers);

Axes = categorical({'Effort' 'Frustration' 'Mental demand' 'Performance' 'Physical demand' 'Temporal demand'});
Weights = zeros((1+nConditions)*nSubjects, 6*(nConditions+1));

for k = 1:nSubjects
    rows = find(strcmp(dataTable.UserName, allUsers{k}));
    weightRow = (1 + (k-1)*(nConditions+1));
    for i = rows'
        if dataTable.TestType(i) == "PW"
            cat = categories(importfilePW(dataTable.Filename{i}));
            Weights(weightRow, ismember(Axes, cat)) = countcats(importfilePW(dataTable.Filename{i}));
        else
            condIdx = find(strcmp(dataTable.TrialCondition{i}, allConditions));
            ratingScales = importfileRS(dataTable.Filename{i});
            colStart = 6 * condIdx + 1;
            Weights(weightRow + 1, colStart:colStart + 5) = ratingScales.RatingScales';
        end
    end
end

% Sum for each subject
allScores = zeros(nSubjects, 6*(nConditions+1));
for i = 1:(nConditions+1):size(Weights,1)
    allScores(ceil(i/(nConditions+1)),:) = sum(Weights(i:i+nConditions,:), 1);
end

allUsersTable = table(allUsers, 'VariableNames', {'UserName'});
allWeights = [allUsersTable, array2table(allScores(:,1:6))];
allWeights.Properties.VariableNames = ['UserName'; categories(Axes)];

% ---- Individual Conditions
allRatingScales = struct();
for j = 1:nConditions
    colStart = 6*j + 1;
    colEnd = colStart + 5;
    tbl = [allUsersTable, array2table(allScores(:, colStart:colEnd))];
    tbl.Properties.VariableNames = ['UserName'; categories(Axes)];
    allRatingScales.(allConditions{j}) = tbl;
    adj = allScores(:, 1:6) .* allScores(:, colStart:colEnd);
    tblAdj = [allUsersTable, array2table(adj), array2table(sum(adj,2)/15, 'VariableNames', {'WeightedRating'})];
    tblAdj.Properties.VariableNames = ['UserName'; categories(Axes); 'WeightedRating'];
    allRatingScales.([allConditions{j} '_adj']) = tblAdj;
end

save NASA_TLX_weighted_scores.mat allWeights allRatingScales


%% Save to a csv file for SPSS
T = table(allUsers, 'VariableNames', {'UserName'});
axesLabels = categories(Axes);

for i = 1:nConditions
    cond = allConditions{i};
    for j = 1:length(axesLabels)
        axisName = axesLabels{j};
        colName = sprintf('%s_%s', cond, strrep(axisName, ' ', ''));
        T.(colName) = allRatingScales.([cond '_adj']).(axisName);
    end
    T.([cond '_WeightedRating']) = allRatingScales.([cond '_adj']).WeightedRating;
end

writetable(T, 'NASA_TLX_weighted_scores.csv');


%% Plot

close all
clearvars -except allWeights allRatingScales allUsers allConditions Axes subFol
clc

% Load if needed
if ~exist('allWeights', 'var') || ~exist('allRatingScales', 'var')
    load NASA_TLX_weighted_scores.mat
end

labels = cellstr(Axes);
mainConditions = setdiff(allConditions, {'PW'}, 'stable');
conditions = cellstr(mainConditions);

% ---- Plot 1 - Overall Workload (bar of weighted averages)
for s = 1:length(allUsers)
    user = allUsers{s};
    % Count non-PW conditions for this user using filenames
    condsForUser = {};
    for i = 1:length(subFol)
        [~, nameOnly, ~] = fileparts(subFol(i).name);
        parts = split(nameOnly, '_');
        if numel(parts) < 3, continue; end
        if ~strcmp(parts{1}, user), continue; end
        if strcmp(parts{end}, 'PW'), continue; end
        cond = parts{2};
        if ~ismember(cond, condsForUser)
            condsForUser{end+1} = cond; 
        end
    end
    userWR = [];
    for c = 1:numel(condsForUser)
        cond = condsForUser{c};
        tbl = allRatingScales.([cond '_adj']);
        userIdx = find(strcmp(tbl.UserName, user), 1);
        if isempty(userIdx)
            continue;
        end
        userWR(end+1) = tbl.WeightedRating(userIdx); 
    end
    if isempty(userWR)
        continue;
    end
    figure;
    bar(categorical(condsForUser), userWR)
    title(sprintf('Overall Workload - %s', user), 'FontName', 'Times New Roman')
    ylabel('Weighted Rating', 'FontName', 'Times New Roman')
    xlabel('Condition', 'FontName', 'Times New Roman')
    set(gca, 'FontName', 'Times New Roman');
    grid on
end

% ---- Plot 2 - Category-wise Ratings (mean per axis)
numLabels = length(labels);
cmap = lines(numLabels); % or parula, jet, hsv, etc.
userCondsList = cell(length(allUsers), 1);
maxCondsPerUser = 0;
for s = 1:length(allUsers)
    user = allUsers{s};
    condsForUser = {};
    for i = 1:length(conditions)
        cond = conditions{i};
        tbl = allRatingScales.(cond);
        if any(strcmp(tbl.UserName, user))
            condsForUser{end+1} = cond;
        end
    end
    userCondsList{s} = condsForUser;
    maxCondsPerUser = max(maxCondsPerUser, numel(condsForUser));
end
if maxCondsPerUser == 0
    maxCondsPerUser = 1;
end

for s = 1:length(allUsers)
    user = allUsers{s};
    % Count non-PW conditions for this user using filenames
    condsForUser = {};
    for i = 1:length(subFol)
        [~, nameOnly, ~] = fileparts(subFol(i).name);
        parts = split(nameOnly, '_');
        if numel(parts) < 3, continue; end
        if ~strcmp(parts{1}, user), continue; end
        if strcmp(parts{end}, 'PW'), continue; end
        cond = parts{2};
        if ~ismember(cond, condsForUser)
            condsForUser{end+1} = cond;
        end
    end
    nConds = numel(condsForUser);
    figure;
    for c = 1:nConds
        subplot(1, nConds, c);
        cond = condsForUser{c};
        tbl = allRatingScales.(cond);
        userIdx = find(strcmp(tbl.UserName, user), 1);
        if isempty(userIdx)
            axis off
            continue;
        end
        subj_ratings = table2array(tbl(userIdx, 2:end));
        subj_weights = table2array(allWeights(userIdx, 2:end));
        nonzero_idx = find(subj_weights > 0);
        ratings_nz = subj_ratings(nonzero_idx);
        weights_nz = subj_weights(nonzero_idx);
        labels_nz = labels(nonzero_idx);
        cmap_nz = cmap(nonzero_idx, :);
        numLabels_nz = length(labels_nz);
        if isempty(weights_nz) || sum(weights_nz) == 0
            axis off
            title(sprintf('%s - %s', cond, user), 'FontName', 'Times New Roman')
            continue;
        end
        norm_weights = weights_nz / sum(weights_nz) * numLabels_nz;
        lefts = [0, cumsum(norm_weights(1:end-1))];
        for j = 1:numLabels_nz
            rectangle('Position', [lefts(j), 0, norm_weights(j), ratings_nz(j)], 'FaceColor', cmap_nz(j,:), 'EdgeColor', 'none');
        end
        xlim([0, sum(norm_weights)]);
        ylim([0, 100]);
        title(sprintf('%s', cond), 'FontName', 'Times New Roman')
        ylabel('Rating', 'FontName', 'Times New Roman')
        set(gca, 'XTick', []);
        set(gca, 'FontName', 'Times New Roman');
    end
    sgtitle(sprintf('Subject: %s', user), 'FontName', 'Times New Roman');
    % Add legend outside the subplots, only for nonzero-weight axes for this subject
    subject_weights = zeros(1, numLabels);
    for c = 1:nConds
        cond = condsForUser{c};
        tbl = allRatingScales.(cond);
        userIdx = find(strcmp(tbl.UserName, user), 1);
        if isempty(userIdx), continue; end
        subj_weights = table2array(allWeights(userIdx, 2:end));
        subject_weights = subject_weights | (subj_weights > 0);
    end
    legend_labels = labels(subject_weights == 1);
    legend_colors = cmap(subject_weights == 1, :);
    hold on;
    for k = 1:numel(legend_labels)
        plot(nan, nan, 's', 'MarkerFaceColor', legend_colors(k,:), 'MarkerEdgeColor', 'none', 'DisplayName', legend_labels{k});
    end
    hold off;
    if ~isempty(legend_labels)
        legend('show', 'Location', 'eastoutside', 'FontName', 'Times New Roman');
    end
end

%% --- PAIRWISE (PW) ANALYSIS SECTION ---
% Find and process only PW files
pwUserNames = {};
pwConditions = {};
pwFilenames = {};

for i = 1:length(subFol)
    [~, nameOnly, ~] = fileparts(subFol(i).name);
    parts = split(nameOnly, '_');
    if numel(parts) < 3, continue; end
    type = parts{end};
    if strcmp(type, 'PW')
        pwUserNames{end+1} = parts{1};
        pwConditions{end+1} = parts{2};
        pwFilenames{end+1} = fullfile(subFol(i).folder, subFol(i).name);
    end
end

if ~isempty(pwFilenames)
    Axes = categorical({'Effort' 'Frustration' 'Mental demand' 'Performance' 'Physical demand' 'Temporal demand'});
    pwResults = zeros(length(pwFilenames), numel(Axes));
    for i = 1:length(pwFilenames)
        cat = categories(importfilePW(pwFilenames{i}));
        pwResults(i, ismember(Axes, cat)) = countcats(importfilePW(pwFilenames{i}));
    end
    pwTable = array2table(pwResults, 'VariableNames', cellstr(Axes));
    pwTable.UserName = pwUserNames';
    pwTable.Condition = pwConditions';
    pwTable = movevars(pwTable, {'UserName','Condition'}, 'Before', 1);
    disp('Pairwise (PW) results:');
    disp(pwTable);
    % Example: bar plot for each user-condition
    figure;
    for i = 1:height(pwTable)
        subplot(1, height(pwTable), i);
        bar(categorical(Axes), table2array(pwTable(i,3:end)));
        title(sprintf('%s', pwTable.UserName{i}));
        ylabel('Pairwise Count');
        ylim([0, max(pwResults(:))+1]);
    end
    sgtitle('Pairwise Comparison Results per User/Condition');
end

