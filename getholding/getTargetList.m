function targetList = getTargetList(posHands)
%GETTARGETLIST 输入每日持仓方向和手数，输出每日持仓的主力合约名称及轧差交易单
% %% 得到每天每个品种的主力合约代码
mainContTable = getBasicData('future');

hands = posHands.fullHands;

%% 调整成targetList格式
% 第一步，先unstack maincontTable，把品种名称散到列名，和持仓手数表保持一致
mainContTrans = table(mainContTable.Date, mainContTable.ContName, mainContTable.MainCont, ...
    'VariableNames', {'Date', 'ContName', 'MainCont'}); 
mainContTrans.ContName = cellfun(@char, mainContTrans.ContName, 'UniformOutput', false);
mainContTrans = unstack(mainContTrans, 'MainCont', 'ContName');
mainContTrans = delStockBondIdx(mainContTrans);


% 第二步，hands就是最终手数不需要再点乘
res = table2array(hands(:, 2:end));
% 把res中手数NaN都换成0，便于下一步处理
res = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), res);

% 把mainContTrans选出posFullDirect对应日期部分

mainContTransSelec = hands(:, 1);
mainContTransSelec = outerjoin(mainContTransSelec, mainContTrans, 'type', 'left', 'MergeKeys', true);
mainContTrans = mainContTransSelec;
mainContTrans = stack(mainContTrans, 2:width(mainContTrans), ...
    'NewDataVariableName', 'MainCont', 'IndexVariableName', 'VarietyName');
% mainContTrans = [hands.Date, cell2mat(mainContTrans)];
% mainContTrans = table2array(mainContTrans(:, 2:end));
clear mainContTransSelec

% 第一步，后一天减前一天得到总轧差结果

shiftRes = [zeros(1, size(res, 2)); res(1:end-1, :)];
diffHands = res - shiftRes; % 总轧差结果

% 第二步，shift一个前一天矩阵，比较两天的手数属于哪种类型（先平后开，只开，只平），对应赋值

% 几个标签矩阵：
twoStepLabel = sign(shiftRes) .* sign(res) == -1; % 需要先平仓后开仓的部分
evenPartLabel1 = (shiftRes < 0) .* (res <= 0) .* (diffHands > 0); % 只平仓部分shift负 Res 非正  diff 正
evenPartLabel2 = (shiftRes > 0) .* (res >= 0) .* (diffHands < 0); % 只平仓部分 shift 正 Res 非负 diff 负
evenPartLabel = evenPartLabel1 + evenPartLabel2;
openPartLabel1 = (shiftRes == 0) .* (sign(res) == sign(diffHands)); % 只开仓部分 从0开仓
openPartLabel2 = (sign(shiftRes) == sign(res)) & (sign(res) == sign(diffHands)) & (shiftRes ~= 0); % 只开仓部分2  只加仓
openPartLabel = openPartLabel1 + openPartLabel2;


% 平仓的手数： (包括先平后开的平仓部分和只平仓部分）  Mark = '平'
evenHands1 = (0 - shiftRes) .* twoStepLabel;
evenHands2 = evenPartLabel .* diffHands;
evenHands = evenHands1 + evenHands2;
% 开仓的手数：（包括先平后开的开仓把邠和只开仓部分）  Mark = '开'
openHands1 = res .* twoStepLabel;
openHands2 = openPartLabel .* diffHands;
openHands = openHands1 + openHands2;


% 第三步，2个矩阵合并，得到总交易单 
% evenHands 和 openHands合并，就是总的交易单
% 到目前为止，汇总得到的信息包括：date, hands, Mark（还缺一个futCont之后再leftjoin）

evenHands = array2table([hands.Date, evenHands], 'VariableNames', hands.Properties.VariableNames);
evenHands = stack(evenHands, 2:width(evenHands), ...
    'NewDataVariableName', 'Hands', ...
    'IndexVariableName', 'VarietyName');
evenHands = outerjoin(evenHands, mainContTrans, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', {'Date', 'VarietyName'}, 'RightKeys', {'Date', 'VarietyName'});
evenHands = evenHands(evenHands.Hands ~= 0, :);
evenHands.Mark = repmat({'平'}, height(evenHands), 1);

openHands = array2table([hands.Date, openHands], 'VariableNames', hands.Properties.VariableNames);
openHands = stack(openHands, 2:width(openHands), ...
    'NewDataVariableName', 'Hands', ...
    'IndexVariableName', 'VarietyName');
openHands = outerjoin(openHands, mainContTrans, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', {'Date', 'VarietyName'}, 'RightKeys', {'Date', 'VarietyName'});
openHands = openHands(openHands.Hands ~= 0, :);
openHands.Mark = repmat({'开'}, height(openHands), 1);

targetList = vertcat(evenHands, openHands);

targetList.Time = ones(height(targetList), 1) * 999999999;
targetList.TargetP = nan(height(targetList), 1);
targetList.TargetC = nan(height(targetList), 1);

targetList = targetList(:, {'Date', 'Time' 'MainCont', 'Hands', 'TargetP', 'TargetC', 'Mark'});
targetList.Properties.VariableNames = {'date', 'time', 'futCont', 'hands', 'targetP', 'targetC', 'Mark'}; % 列名和漫雪回测平台保持一致
targetList = sortrows(targetList, {'date', 'futCont', 'Mark'});

% 
% tmp1 = reshape(mainContTrans', [size(mainContTrans, 2), size(mainContTrans, 1)]);
% tmp2 = reshape(res', [size(res, 2), size(res, 1)]);
% 
% tmp = num2cell(nan(numel(tmp1), 2));
% tmp(:, 1) = reshape(tmp1, numel(tmp1), 1);
% tmp(:, 2) = num2cell(reshape(tmp2, numel(tmp2), 1));
% tmp = reshape(tmp', 2, size(res, 2), size(res, 1));
% tmp = permute(tmp, [2 1 3]);
% 
% % 第三步，前两步内容结合，调整成targetPortfolio格式
% targetPortfolio = num2cell(NaN(size(hands, 1), 2));   %分配内存
% targetPortfolio(:, 2) = num2cell(hands.Date);
% 
% % 循环赋值，没有别的运算的话很快
% for iDate = 1 : size(res, 1)
%     % 先对tmp(:, :, iDate)进行去NaN和0操作
%     tmpI = tmp(:, :, iDate);
%     tmpITrans = cellfun(@(x, y, z) ifelse(isnan(x), 0, x), tmpI(:, 2));
%     validIdx = find(tmpITrans, size(tmpI, 1));
%     tmpI = tmpI(validIdx, :);
%     % 然后赋值
%     targetPortfolio{iDate, 1} = tmpI;
% end
% 
% clear tmp tmp1 tmp2



end

