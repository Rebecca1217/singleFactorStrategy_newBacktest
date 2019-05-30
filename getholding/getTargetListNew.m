function targetList = getTargetListNew(fullHands)
%GETTARGETLIST ����ÿ�ճֲַ�������������ÿ�ճֲֵ�������Լ���Ƽ�����׵�
% %% �õ�ÿ��ÿ��Ʒ�ֵ�������Լ����
% �޸��߼��ܼ򵥣�֮ǰ�ǰ�ƽeven�Ϳ�open�ֿ������������������ƥ���ϲ�����Լ����
% ���ھ��������ֿ������ʱ������Ƿ�����һ�������Ȼ��ƥ���Լ�����ʱ��ƽ��ƥ����������������ƥ�������������

% Ҫ��fullHands���������밴��ĸ˳������

mainContTable = getBasicData('future');
% mainContTable = mainContTable(mainContTable.ContCode <= 700057, :);

hands = fullHands;
dateFrom = min(hands.Date);
dateTo = max(hands.Date);

%% ������targetList��ʽ
% ��һ������unstack maincontTable����Ʒ������ɢ���������ͳֲ���������һ��
mainContTrans = table(mainContTable.Date, mainContTable.ContName, mainContTable.MainCont, ...
    'VariableNames', {'Date', 'ContName', 'MainCont'}); 
mainContTrans.ContName = cellfun(@char, mainContTrans.ContName, 'UniformOutput', false);
mainContTrans = unstack(mainContTrans, 'MainCont', 'ContName');
mainContTrans = delStockBondIdx(mainContTrans);

% @2019.05.07 �޸ģ�ɸѡ��fullHands������Ʒ�֣���ȻchgLabel��nonChgLabel�ᱣ������Ʒ��
mainContTrans = mainContTrans(:, hands.Properties.VariableNames);

% shiftMainContTrans����ƽ����ĺ�Լ
shiftMainContTrans = horzcat(mainContTrans(2:end, 1), mainContTrans(1:end-1, 2:end)); % ��mainContTrans��һ�У�[]���ܴ���cell��double�ϲ�

% ��¼���±�����ڽ��׵�չ��
chgLabel = array2table(... % ����1�� ������0
    [mainContTrans.Date, [nan(1, width(mainContTrans) - 1); ...
    table2array(varfun(@(x) ~strcmp(x(2:end), x(1:end-1)), mainContTrans(:, 2:end)))]], ...
    'VariableNames', mainContTrans.Properties.VariableNames);
chgLabel = chgLabel(chgLabel.Date >= dateFrom & chgLabel.Date <= dateTo, :);
nonChgLabel = table2array(chgLabel(:, 2:end)) + 1;
nonChgLabel = array2table(... % ������1�� ����0
    [chgLabel.Date, arrayfun(@(x, y, z) ifelse(x == 2, 0, x), nonChgLabel)], ...
    'VariableNames', chgLabel.Properties.VariableNames);

% �ڶ�����hands����������������Ҫ�ٵ��
res = table2array(hands(:, 2:end));
% ��res������NaN������0��������һ������
res = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), res);

% ��mainContTransѡ��posFullDirect��Ӧ���ڲ���
% 2019.04.30 �Ȳ�ɸѡ����Ϊ���õ�ǰһ���������Լ����

% mainContTransSelec = hands(:, 1);
% mainContTransSelec = outerjoin(mainContTransSelec, mainContTrans, 'type', 'left', 'MergeKeys', true);
% mainContTrans = mainContTransSelec;
% mainContTrans = stack(mainContTrans, 2:width(mainContTrans), ...
%     'NewDataVariableName', 'MainCont', 'IndexVariableName', 'VarietyName');
% % mainContTrans = [hands.Date, cell2mat(mainContTrans)];
% % mainContTrans = table2array(mainContTrans(:, 2:end));
% clear mainContTransSelec

% ��һ������һ���ǰһ��õ���������

shiftRes = [zeros(1, size(res, 2)); res(1:end-1, :)];
diffHands = res - shiftRes; % ��������

% �ڶ�����shiftһ��ǰһ����󣬱Ƚ���������������������ͣ���ƽ�󿪣�ֻ����ֻƽ������Ӧ��ֵ

% @2019.04.29 �������еı�ǩ�ָ���������һ�㣬�Ƿ��£���Ϊ2���ֱַ��������ϵ�һ��

% ������ǩ����
% twoStepLabel ��ƽ�� ��Ϊ�����ºͻ���������
twoStepLabel1 = (sign(shiftRes) .* sign(res) == -1) & table2array(nonChgLabel(:, 2:end)); % ǰ����Ų����Ҳ����£�ƽ�ɿ��£��ɺ���һ��
twoStepLabel2 = table2array(chgLabel(:, 2:end)) & (shiftRes ~= 0 & res ~= 0); % ���£����������������һ����ƽ�ɺ��£��ɺ��²�һ��
twoStepLabel = twoStepLabel1 + twoStepLabel2;

% evenPartLabel ֻƽ�� ���ۻ������ֻҪǰһ��~=0 ����=0 ����ֻƽ��
evenPartLabel1 = (shiftRes < 0) .* (res <= 0) .* (diffHands > 0) .* table2array(nonChgLabel(:, 2:end)); % ֻƽ�ֲ��� ������ shift�� Res ����  diff ��
evenPartLabel2 = (shiftRes > 0) .* (res >= 0) .* (diffHands < 0) .* table2array(nonChgLabel(:, 2:end)); % ֻƽ�ֲ��� ������ shift �� Res �Ǹ� diff ��
evenPartLabel3 = (shiftRes ~= 0) .* (res == 0) .* table2array(chgLabel(:, 2:end)); % ֻƽ�֣����£������������������µİ���������2���龰��
evenPartLabel = evenPartLabel1 + evenPartLabel2 + evenPartLabel3;

% openPartLabel ֻ���� ���ۻ������ֻҪǰһ��==0������~=0����ֻ����
openPartLabel1 = (shiftRes == 0) .* (res ~= 0); % ֻ���ֲ��� ��0����
openPartLabel2 = (sign(shiftRes) == sign(res)) .* (sign(res) == sign(diffHands)) .* (shiftRes ~= 0) .*...
    table2array(nonChgLabel(:, 2:end)); % ֻ���ֲ���2  ֻ�Ӳ� ������
openPartLabel = openPartLabel1 + openPartLabel2;

% @2019.04.30 �������������ͬʱ��Ҫƥ����futCont�����ܵȵ����һ��ƥ�䣬��Ϊ�еĻ����еĲ�����

% ������Զ����ƽ����ĺ�Լ��������ĺ�Լ���������¶�������
% ƽ�ֵ������� (������ƽ�󿪵�ƽ�ֲ��ֺ�ֻƽ�ֲ��֣�  Mark = 'ƽ'
% ���²����¶�����ѡ��ƽ����ĺ�Լ��ȫƽ��
evenHands1 = (0 - shiftRes) .* twoStepLabel; % ƽ��2step������ĳֲ�
evenHands2 = evenPartLabel .* diffHands; % ֻƽ�ֲ��ֵ�ȫ��diff����
evenHands = evenHands1 + evenHands2;
% ���ֵ���������������ƽ�󿪵Ŀ��ֲ��ֺ�ֻ���ֲ��֣�  Mark = '��'
openHands1 = res .* twoStepLabel; % �� 2step�н���Ӧ��������
openHands2 = openPartLabel .* diffHands; % �� ֻ���ֲ��ֵ�ȫ��diff����
openHands = openHands1 + openHands2;

% ��������2������ϲ����õ��ܽ��׵� 
% evenHands �� openHands�ϲ��������ܵĽ��׵�
% ��ĿǰΪֹ�����ܵõ�����Ϣ������date, hands, Mark����ȱһ��futCont֮����leftjoin��
% @2019.04.30 ���leftjoinʱ�� even����join�����fut, open����join�����fut

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
evenHands.Mark = repmat({'ƽ'}, height(evenHands), 1);
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
openHands.Mark = repmat({'��'}, height(openHands), 1);
[~, idx] = ismember('MainCont', openHands.Properties.VariableNames);
openHands.Properties.VariableNames(idx) = {'TradingContName'};
clear idx

targetList = vertcat(evenHands, openHands);

targetList.Time = ones(height(targetList), 1) * 999999999;
targetList.TargetP = nan(height(targetList), 1);
targetList.TargetC = nan(height(targetList), 1);

targetList = targetList(:, {'Date', 'Time' 'TradingContName', 'Hands', 'TargetP', 'TargetC', 'Mark'});
targetList.Properties.VariableNames = {'date', 'time', 'futCont', 'hands', 'targetP', 'targetC', 'Mark'}; % ��������ѩ�ز�ƽ̨����һ��
targetList = sortrows(targetList, {'date', 'futCont', 'Mark'});



end

