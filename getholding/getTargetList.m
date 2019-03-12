function targetList = getTargetList(posHands)
%GETTARGETLIST ����ÿ�ճֲַ�������������ÿ�ճֲֵ�������Լ���Ƽ�����׵�
% %% �õ�ÿ��ÿ��Ʒ�ֵ�������Լ����
mainContTable = getBasicData('future');

hands = posHands.fullHands;

%% ������targetList��ʽ
% ��һ������unstack maincontTable����Ʒ������ɢ���������ͳֲ���������һ��
mainContTrans = table(mainContTable.Date, mainContTable.ContName, mainContTable.MainCont, ...
    'VariableNames', {'Date', 'ContName', 'MainCont'}); 
mainContTrans.ContName = cellfun(@char, mainContTrans.ContName, 'UniformOutput', false);
mainContTrans = unstack(mainContTrans, 'MainCont', 'ContName');
mainContTrans = delStockBondIdx(mainContTrans);


% �ڶ�����hands����������������Ҫ�ٵ��
res = table2array(hands(:, 2:end));
% ��res������NaN������0��������һ������
res = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), res);

% ��mainContTransѡ��posFullDirect��Ӧ���ڲ���

mainContTransSelec = hands(:, 1);
mainContTransSelec = outerjoin(mainContTransSelec, mainContTrans, 'type', 'left', 'MergeKeys', true);
mainContTrans = mainContTransSelec;
mainContTrans = stack(mainContTrans, 2:width(mainContTrans), ...
    'NewDataVariableName', 'MainCont', 'IndexVariableName', 'VarietyName');
% mainContTrans = [hands.Date, cell2mat(mainContTrans)];
% mainContTrans = table2array(mainContTrans(:, 2:end));
clear mainContTransSelec

% ��һ������һ���ǰһ��õ���������

shiftRes = [zeros(1, size(res, 2)); res(1:end-1, :)];
diffHands = res - shiftRes; % ��������

% �ڶ�����shiftһ��ǰһ����󣬱Ƚ���������������������ͣ���ƽ�󿪣�ֻ����ֻƽ������Ӧ��ֵ

% ������ǩ����
twoStepLabel = sign(shiftRes) .* sign(res) == -1; % ��Ҫ��ƽ�ֺ󿪲ֵĲ���
evenPartLabel1 = (shiftRes < 0) .* (res <= 0) .* (diffHands > 0); % ֻƽ�ֲ���shift�� Res ����  diff ��
evenPartLabel2 = (shiftRes > 0) .* (res >= 0) .* (diffHands < 0); % ֻƽ�ֲ��� shift �� Res �Ǹ� diff ��
evenPartLabel = evenPartLabel1 + evenPartLabel2;
openPartLabel1 = (shiftRes == 0) .* (sign(res) == sign(diffHands)); % ֻ���ֲ��� ��0����
openPartLabel2 = (sign(shiftRes) == sign(res)) & (sign(res) == sign(diffHands)) & (shiftRes ~= 0); % ֻ���ֲ���2  ֻ�Ӳ�
openPartLabel = openPartLabel1 + openPartLabel2;


% ƽ�ֵ������� (������ƽ�󿪵�ƽ�ֲ��ֺ�ֻƽ�ֲ��֣�  Mark = 'ƽ'
evenHands1 = (0 - shiftRes) .* twoStepLabel;
evenHands2 = evenPartLabel .* diffHands;
evenHands = evenHands1 + evenHands2;
% ���ֵ���������������ƽ�󿪵Ŀ��ְ�ߓ��ֻ���ֲ��֣�  Mark = '��'
openHands1 = res .* twoStepLabel;
openHands2 = openPartLabel .* diffHands;
openHands = openHands1 + openHands2;


% ��������2������ϲ����õ��ܽ��׵� 
% evenHands �� openHands�ϲ��������ܵĽ��׵�
% ��ĿǰΪֹ�����ܵõ�����Ϣ������date, hands, Mark����ȱһ��futCont֮����leftjoin��

evenHands = array2table([hands.Date, evenHands], 'VariableNames', hands.Properties.VariableNames);
evenHands = stack(evenHands, 2:width(evenHands), ...
    'NewDataVariableName', 'Hands', ...
    'IndexVariableName', 'VarietyName');
evenHands = outerjoin(evenHands, mainContTrans, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', {'Date', 'VarietyName'}, 'RightKeys', {'Date', 'VarietyName'});
evenHands = evenHands(evenHands.Hands ~= 0, :);
evenHands.Mark = repmat({'ƽ'}, height(evenHands), 1);

openHands = array2table([hands.Date, openHands], 'VariableNames', hands.Properties.VariableNames);
openHands = stack(openHands, 2:width(openHands), ...
    'NewDataVariableName', 'Hands', ...
    'IndexVariableName', 'VarietyName');
openHands = outerjoin(openHands, mainContTrans, 'type', 'left', 'MergeKeys', true, ...
    'LeftKeys', {'Date', 'VarietyName'}, 'RightKeys', {'Date', 'VarietyName'});
openHands = openHands(openHands.Hands ~= 0, :);
openHands.Mark = repmat({'��'}, height(openHands), 1);

targetList = vertcat(evenHands, openHands);

targetList.Time = ones(height(targetList), 1) * 999999999;
targetList.TargetP = nan(height(targetList), 1);
targetList.TargetC = nan(height(targetList), 1);

targetList = targetList(:, {'Date', 'Time' 'MainCont', 'Hands', 'TargetP', 'TargetC', 'Mark'});
targetList.Properties.VariableNames = {'date', 'time', 'futCont', 'hands', 'targetP', 'targetC', 'Mark'}; % ��������ѩ�ز�ƽ̨����һ��
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
% % ��������ǰ�������ݽ�ϣ�������targetPortfolio��ʽ
% targetPortfolio = num2cell(NaN(size(hands, 1), 2));   %�����ڴ�
% targetPortfolio(:, 2) = num2cell(hands.Date);
% 
% % ѭ����ֵ��û�б������Ļ��ܿ�
% for iDate = 1 : size(res, 1)
%     % �ȶ�tmp(:, :, iDate)����ȥNaN��0����
%     tmpI = tmp(:, :, iDate);
%     tmpITrans = cellfun(@(x, y, z) ifelse(isnan(x), 0, x), tmpI(:, 2));
%     validIdx = find(tmpITrans, size(tmpI, 1));
%     tmpI = tmpI(validIdx, :);
%     % Ȼ��ֵ
%     targetPortfolio{iDate, 1} = tmpI;
% end
% 
% clear tmp tmp1 tmp2



end

