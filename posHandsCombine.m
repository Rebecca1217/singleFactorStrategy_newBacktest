
fullHands1 = posHandsSP60W1.fullHands;
fullHands2 = posHandsSP60W2.fullHands;
fullHands3 = posHandsSP90W1.fullHands;
fullHands4 = posHandsSP90W2.fullHands;
fullHands5 = posHandsWarrantW1.fullHands;
fullHands6 = posHandsWarrantW2.fullHands;
% 补全通道的时间
% fullHands2
[~, addIdx, ~] = intersect(fullHands1.Date, fullHands2.Date);
fullHands2Add = array2table(...
    [fullHands1.Date(1:addIdx(1)-1), zeros(addIdx(1)-1, width(fullHands1)-1)], ...
    'VariableNames', fullHands1.Properties.VariableNames);
fullHands2 = vertcat(fullHands2Add, fullHands2);
% fullHands4
[~, addIdx, ~] = intersect(fullHands1.Date, fullHands4.Date);
fullHands4Add = array2table(...
    [fullHands1.Date(1:addIdx(1)-1), zeros(addIdx(1)-1, width(fullHands1)-1)], ...
    'VariableNames', fullHands1.Properties.VariableNames);
fullHands4 = vertcat(fullHands4Add, fullHands4);

% fullHands6
[~, addIdx, ~] = intersect(fullHands1.Date, fullHands6.Date);
fullHands6Add = array2table(...
    [fullHands1.Date(1:addIdx(1)-1), zeros(addIdx(1)-1, width(fullHands1)-1)], ...
    'VariableNames', fullHands1.Properties.VariableNames);
fullHands6 = vertcat(fullHands6Add, fullHands6);

% 排序保证不要加错
disp({height(fullHands1); height(fullHands2); height(fullHands3); height(fullHands4); height(fullHands5); height(fullHands6)})
fullHands1 = sortrows(fullHands1, 'Date');
fullHands2 = sortrows(fullHands2, 'Date');
fullHands3 = sortrows(fullHands3, 'Date');
fullHands4 = sortrows(fullHands4, 'Date');
fullHands5 = sortrows(fullHands5, 'Date');
fullHands6 = sortrows(fullHands6, 'Date');


% 把所有NaN都换成0
fullHands1 = array2table(...
    [fullHands1.Date, arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), table2array(fullHands1(:, 2:end)))], ...
    'VariableNames', fullHands1.Properties.VariableNames);
fullHands2 = array2table(...
    [fullHands2.Date, arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), table2array(fullHands2(:, 2:end)))], ...
    'VariableNames', fullHands2.Properties.VariableNames);
fullHands3 = array2table(...
    [fullHands3.Date, arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), table2array(fullHands3(:, 2:end)))], ...
    'VariableNames', fullHands3.Properties.VariableNames);
fullHands4 = array2table(...
    [fullHands4.Date, arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), table2array(fullHands4(:, 2:end)))], ...
    'VariableNames', fullHands4.Properties.VariableNames);
fullHands5 = array2table(...
    [fullHands5.Date, arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), table2array(fullHands5(:, 2:end)))], ...
    'VariableNames', fullHands5.Properties.VariableNames);
fullHands6 = array2table(...
    [fullHands6.Date, arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), table2array(fullHands6(:, 2:end)))], ...
    'VariableNames', fullHands6.Properties.VariableNames);



fullHands = table2array(fullHands1(:, 2:end)) + table2array(fullHands2(:, 2:end)) + ...
    table2array(fullHands3(:, 2:end)) + table2array(fullHands4(:, 2:end)) + ...
    table2array(fullHands5(:, 2:end)) + table2array(fullHands6(:, 2:end));
    
fullHands = array2table([fullHands1.Date, fullHands], 'VariableNames', fullHands1.Properties.VariableNames);

compPosHands.fullHands = fullHands;

compTargetList = getTargetList(compPosHands);

[BacktestResult, BacktestAnalysis] = ...
    CTABacktest_GeneralPlatform_v2_1(compTargetList, strategyPara, tradingPara);

