function targetList = getTargetListNew(fullHands)
%GETTARGETLIST 输入每日持仓方向和手数，输出每日持仓的主力合约名称及轧差交易单
% %% 得到每天每个品种的主力合约代码
% 修改逻辑很简单，之前是把平even和开open分开，先算各自手数，再匹配上操作合约代码
% 现在就是手数分开计算的时候根据是否换月做一点调整，然后匹配合约代码的时候平仓匹配昨天主力，开仓匹配今天主力即可

% 要求：fullHands的列名必须按字母顺序排列

mainContTable = getBasicData('future');
% mainContTable = mainContTable(mainContTable.ContCode <= 700057, :);

hands = fullHands;
dateFrom = min(hands.Date);
dateTo = max(hands.Date);

%% 调整成targetList格式
% 第一步，先unstack maincontTable，把品种名称散到列名，和持仓手数表保持一致
mainContTrans = table(mainContTable.Date, mainContTable.ContName, mainContTable.MainCont, ...
    'VariableNames', {'Date', 'ContName', 'MainCont'}); 
mainContTrans.ContName = cellfun(@char, mainContTrans.ContName, 'UniformOutput', false);
mainContTrans = unstack(mainContTrans, 'MainCont', 'ContName');
mainContTrans = delStockBondIdx(mainContTrans);

% @2019.05.07 修改：筛选出fullHands包含的品种，不然chgLabel和nonChgLabel会保留所有品种
mainContTrans = mainContTrans(:, hands.Properties.VariableNames);

% shiftMainContTrans用于平昨天的合约
shiftMainContTrans = horzcat(mainContTrans(2:end, 1), mainContTrans(1:end-1, 2:end)); % 比mainContTrans少一行，[]不能处理cell和double合并

% 记录换月标记用于交易单展期
chgLabel = array2table(... % 换月1， 不换月0
    [mainContTrans.Date, [nan(1, width(mainContTrans) - 1); ...
    table2array(varfun(@(x) ~strcmp(x(2:end), x(1:end-1)), mainContTrans(:, 2:end)))]], ...
    'VariableNames', mainContTrans.Properties.VariableNames);
chgLabel = chgLabel(chgLabel.Date >= dateFrom & chgLabel.Date <= dateTo, :);
nonChgLabel = table2array(chgLabel(:, 2:end)) + 1;
nonChgLabel = array2table(... % 不换月1， 换月0
    [chgLabel.Date, arrayfun(@(x, y, z) ifelse(x == 2, 0, x), nonChgLabel)], ...
    'VariableNames', chgLabel.Properties.VariableNames);

% 第二步，hands就是最终手数不需要再点乘
res = table2array(hands(:, 2:end));
% 把res中手数NaN都换成0，便于下一步处理
res = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), res);

% 把mainContTrans选出posFullDirect对应日期部分
% 2019.04.30 先不筛选，因为会用到前一天的主力合约代码

% mainContTransSelec = hands(:, 1);
% mainContTransSelec = outerjoin(mainContTransSelec, mainContTrans, 'type', 'left', 'MergeKeys', true);
% mainContTrans = mainContTransSelec;
% mainContTrans = stack(mainContTrans, 2:width(mainContTrans), ...
%     'NewDataVariableName', 'MainCont', 'IndexVariableName', 'VarietyName');
% % mainContTrans = [hands.Date, cell2mat(mainContTrans)];
% % mainContTrans = table2array(mainContTrans(:, 2:end));
% clear mainContTransSelec

% 第一步，后一天减前一天得到总轧差结果

shiftRes = [zeros(1, size(res, 2)); res(1:end-1, :)];
diffHands = res - shiftRes; % 总轧差结果

% 第二步，shift一个前一天矩阵，比较两天的手数属于哪种类型（先平后开，只开，只平），对应赋值

% @2019.04.29 以下所有的标签分割都在下面添加一层，是否换月，分为2部分分别计算后整合到一起

% 几个标签矩阵：
% twoStepLabel 先平后开 分为不换月和换月两部分
twoStepLabel1 = (sign(shiftRes) .* sign(res) == -1) & table2array(nonChgLabel(:, 2:end)); % 前后符号不等且不换月，平旧开新，旧和新一样
twoStepLabel2 = table2array(chgLabel(:, 2:end)) & (shiftRes ~= 0 & res ~= 0); % 换月，且有手数的情况下一定先平旧后开新，旧和新不一样
twoStepLabel = twoStepLabel1 + twoStepLabel2;

% evenPartLabel 只平仓 不论换月与否，只要前一天~=0 今天=0 ，则只平仓
evenPartLabel1 = (shiftRes < 0) .* (res <= 0) .* (diffHands > 0) .* table2array(nonChgLabel(:, 2:end)); % 只平仓部分 不换月 shift负 Res 非正  diff 正
evenPartLabel2 = (shiftRes > 0) .* (res >= 0) .* (diffHands < 0) .* table2array(nonChgLabel(:, 2:end)); % 只平仓部分 不换月 shift 正 Res 非负 diff 负
evenPartLabel3 = (shiftRes ~= 0) .* (res == 0) .* table2array(chgLabel(:, 2:end)); % 只平仓，换月，不开新手数（不换月的包含在上面2中情景）
evenPartLabel = evenPartLabel1 + evenPartLabel2 + evenPartLabel3;

% openPartLabel 只开仓 不论换月与否，只要前一天==0，今天~=0，则只开仓
openPartLabel1 = (shiftRes == 0) .* (res ~= 0); % 只开仓部分 从0开仓
openPartLabel2 = (sign(shiftRes) == sign(res)) .* (sign(res) == sign(diffHands)) .* (shiftRes ~= 0) .*...
    table2array(nonChgLabel(:, 2:end)); % 只开仓部分2  只加仓 不换月
openPartLabel = openPartLabel1 + openPartLabel2;

% @2019.04.30 下面计算手数的同时需要匹配上futCont，不能等到最后一期匹配，因为有的换月有的不换月

% 操作永远都是平昨天的合约，开今天的合约，换不换月都是这样
% 平仓的手数： (包括先平后开的平仓部分和只平仓部分）  Mark = '平'
% 换月不换月都可以选择平昨天的合约，全平掉
evenHands1 = (0 - shiftRes) .* twoStepLabel; % 平掉2step中昨天的持仓
evenHands2 = evenPartLabel .* diffHands; % 只平仓部分的全部diff手数
evenHands = evenHands1 + evenHands2;
% 开仓的手数：（包括先平后开的开仓部分和只开仓部分）  Mark = '开'
openHands1 = res .* twoStepLabel; % 开 2step中今天应开的手数
openHands2 = openPartLabel .* diffHands; % 开 只开仓部分的全部diff手数
openHands = openHands1 + openHands2;

% 第三步，2个矩阵合并，得到总交易单 
% evenHands 和 openHands合并，就是总的交易单
% 到目前为止，汇总得到的信息包括：date, hands, Mark（还缺一个futCont之后再leftjoin）
% @2019.04.30 这个leftjoin时候 even部分join昨天的fut, open部分join今天的fut

mainContTrans = stack(mainContTrans, 2:width(mainContTrans), ...
    'NewDataVariableName', 'MainCont', 'IndexVariableName', 'VarietyName');
shiftMainContTrans = stack(shiftMainContTrans, 2:width(shiftMainContTrans), ...
    'NewDataVariableName', 'ShiftMainCont', 'IndexVariableName', 'VarietyName');


evenHands = array2table([hands.Date, evenHands], 'VariableNames', hands.Properties.VariableNames);
evenHands = stack(evenHands, 2:width(evenHands), ...
    'NewDataVariableName', 'Hands', ...
    'IndexVariableName', 'VarietyName');
evenHands = outerjoin(evenHands, shiftMainContTrans, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', {'Date', 'VarietyName'}, 'RightKeys', {'Date', 'VarietyName'});
evenHands = evenHands(evenHands.Hands ~= 0, :);
evenHands.Mark = repmat({'平'}, height(evenHands), 1);
[~, idx] = ismember('ShiftMainCont', evenHands.Properties.VariableNames);
evenHands.Properties.VariableNames(idx) = {'TradingContName'};
clear idx

openHands = array2table([hands.Date, openHands], 'VariableNames', hands.Properties.VariableNames);
openHands = stack(openHands, 2:width(openHands), ...
    'NewDataVariableName', 'Hands', ...
    'IndexVariableName', 'VarietyName');
openHands = outerjoin(openHands, mainContTrans, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', {'Date', 'VarietyName'}, 'RightKeys', {'Date', 'VarietyName'});
openHands = openHands(openHands.Hands ~= 0, :);
openHands.Mark = repmat({'开'}, height(openHands), 1);
[~, idx] = ismember('MainCont', openHands.Properties.VariableNames);
openHands.Properties.VariableNames(idx) = {'TradingContName'};
clear idx

targetList = vertcat(evenHands, openHands);

targetList.Time = ones(height(targetList), 1) * 999999999;
targetList.TargetP = nan(height(targetList), 1);
targetList.TargetC = nan(height(targetList), 1);

targetList = targetList(:, {'Date', 'Time' 'TradingContName', 'Hands', 'TargetP', 'TargetC', 'Mark'});
targetList.Properties.VariableNames = {'date', 'time', 'futCont', 'hands', 'targetP', 'targetC', 'Mark'}; % 列名和漫雪回测平台保持一致
targetList = sortrows(targetList, {'date', 'futCont', 'Mark'});



end

