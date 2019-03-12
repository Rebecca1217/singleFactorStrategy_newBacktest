function [newList,err] = getNewTargetList_2(listI,hisHands,chgIF,hisMainCont,info)
% ���׵����������������
% 1.�����һ�����׵������ô���
% 2.������������׵���ֻ�����������
% 2.1.��������+ƽ��������ƽ����������ƽ���п��ܣ�
% 2.2.����ƽ��������ͬ��ƽ�ֵ�
% 3.�������׵���
% ��+������ƽ+������ƽ������������ƽ�Ϳ��Ƕ�Ӧ�ģ�����������ƽҪ����ʷ��λ��ȫƽ����
% ����ʽ��
% ��ƽ���ϲ�
% ���ӵĽ���˳��
% ������ƽ������������ƽ

err = 0;
date = info.date(1);
time = info.time(1);
% �ȼ��һ�½��׵��Ƿ�����
if ~isempty(listI)
    if height(listI)==1 %ֻ��һ�ʽ��׵�
        if ismember('��',listI.Mark)
            if hisHands~=0 && sign(hisHands)~=sign(listI.hands) %δƽ�ֵ�����·��򿪲�
                disp([num2str(date),' ',num2str(time),'���׵�����,δƽ�ֵ�����·����˷��򿪲�ָ���'])
                err = 1;
            end
        elseif ismember('ƽ',listI.Mark)
            if hisHands==0 || sign(hisHands)==sign(listI.hands) %ƽ�ֵ�����
                disp([num2str(date),' ',num2str(time),'���׵�����,��λ�����޷�ִ��ƽ��ָ���'])
                err = 1;
            end
        end
    elseif height(listI)==2
        if sum(ismember(listI.Mark,'ƽ'))==2 %ȫ��ƽ�ֵ�
            if abs(hisHands)<abs(sum(listI.hands)) || sign(hisHands)==sign(listI.hands(1)) || sign(hisHands)==sign(listI.hands(2))
                disp([num2str(date),' ',num2str(time),'���׵�����,��λ�����޷�ִ��ƽ��ָ���'])
                err = 1;
            end
            if height(unique(listI(:,{'targetP';'targetC'})))==1 %˵������ƽ�ֵ���ƽ��������һ�µģ�Ӧ�úϲ��Ŷ�
                disp([num2str(date),' ',num2str(time),'���׵�����,����ƽ�ֵ���ƽ������һ�£�����Ƿ���Ҫ�ϲ�����'])
                err = 1;
            end
        elseif sum(ismember(listI.Mark,'��'))==2 %ȫ�ǿ��ֵ�
            disp([num2str(date),' ',num2str(time),'���׵�����,��Ӧ�����������ֵ�������Ƿ���Ҫ�ϲ�����'])
            err = 1;
        else %һ�����ֵ�һ��ƽ�ֵ�
            % �ж�ƽ�ֵ�����
            tmpO = listI(ismember(listI.Mark,'��'),:);
            tmpC = listI(ismember(listI.Mark,'ƽ'),:);
            if isnan(tmpC.targetP) && isnan(tmpC.targetC) %������ƽ
                if hisHands==0 || sign(hisHands)==sign(tmpC.hands) || abs(hisHands)<abs(tmpC.hands)
                    disp([num2str(date),' ',num2str(time),'���׵�����,��λ�����޷�ִ��ƽ��ָ���'])
                    err = 1;
                else
                    if sign(tmpO.hands)==sign(hisHands) %��ƽ��Ҫ����
                        netHands = tmpO.hands+tmpC.hands;
                        if netHands==0
                            listI = [];
                        elseif sign(netHands)==sign(hisHands) %������
                            listI = tmpO;
                            listI.hands = netHands;
                        else %��ƽ��
                            listI = tmpC;
                            listI.hands = netHands;
                        end
                    else %���ֵķ����Ƿ����
                        if tmpC.hands~=-hisHands
                            disp([num2str(date),' ',num2str(time),'���׵�����,δƽ�ֵ�����·����˷��򿪲�ָ���'])
                            err = 1;
                        end
                    end
                end
            else %��������ƽ��,���ֵķ���������ʷ��λ��ͬ
                if sign(tmpO.hands)~=sign(hisHands)
                    disp([num2str(date),' ',num2str(time),'���׵�����,δƽ�ֵ�����·����˷��򿪲�ָ���'])
                    err = 1;
                end
            end
        end
    elseif height(listI)==3 %����������ƽ��������ƽ
        if hisHands==0
            disp([num2str(date),' ',num2str(time),'���׵�����,û����ʷ�ֲֵ�����µ��������յĽ��׵���Ӧ����2������'])
            err = 1;
        else
            tmpCN = listI(ismember(listI.Mark,'ƽ') & isnan(listI.targetP) & isnan(listI.targetC),:);
            tmpC2 = listI(ismember(listI.Mark,'ƽ') & (~isnan(listI.targetP) | ~isnan(listI.targetC)),:);
            tmpO = listI(ismember(listI.Mark,'��'),:);
            if isempty(tmpCN) || isempty(tmpC2) || isempty(tmpO)
                disp([num2str(date),' ',num2str(time),'���׵�����,�������׵��������󣡣�'])
                err = 1;
            else %һ��Ҫ�Ȱ�ԭ�еĲ�λ��ƽ�ꣻ������ƽ��һ�����뿪�ֶ�Ӧ��
                % �����������
                % ������ƽ�ֵ���ԭ��λȫƽ������ͬ�򿪲ֻ��߷��򿪲֣�������ƽ�ֵ�Ҫ���µĿ��ֵ���Ӧ
                % ������ƽ�ֵ�û�н�ԭ��λȫƽ��ֻ��ͬ�򿪲֣����ͷ��Ҫ��ԭͷ�緽����ͬ
                if tmpCN.hands==-hisHands %ȫƽ
                    if abs(tmpO.hands)<abs(tmpC2.hands) || sign(tmpO.hands)==sign(tmpC2.hands)
                        disp([num2str(date),' ',num2str(time),'���׵�����,�µĿ��ֵ���ƽ�ֵ�����Ӧ����'])
                        err = 1;
                    end
                elseif abs(tmpCN.hands)<abs(hisHands) && sign(tmpCN.hands)==-sign(hisHands) % û��ȫƽ
                    if sign(hisHands+tmpCN.hands+tmpC2.hands+tmpO.hands)~=sign(hisHands) || sign(hisHands+tmpCN.hands+tmpC2.hands+tmpO.hands)~=0
                        disp([num2str(date),' ',num2str(time),'���׵�����,��λ�����޷�ִ��ƽ��ָ���'])
                        err = 1;
                    else
                        if sign(tmpO.hands)~=sign(hisHands)
                            disp([num2str(date),' ',num2str(time),'���׵�����,δƽ�ֵ�����·����˷��򿪲�ָ���'])
                            err = 1;
                        end
                    end
                else
                    disp([num2str(date),' ',num2str(time),'���׵�����,��λ�����޷�ִ��ƽ��ָ���'])
                    err = 1;
                end
            end
        end
    elseif height(listI)>3
        disp([num2str(date),' ',num2str(time),'���׵�����,���������յĽ��׵���Ӧ����3������'])
        err = 1;
    end
end
if err==1
    newList = [];
    return;
end

fut = regexp(hisMainCont,'\D*','match');
fut = fut{1};

if hisHands==0 || (hisHands~=0 && chgIF==0)
    newList = listI;
else %����ʷ�ֲ���Ҫ����   
    % ƽ�ɺ�Լ�Ľ��׵�
    listC = info(:,{'date';'time'});
    listC.futCont = {hisMainCont};
    listC.hands = -hisHands;
    listC.targetP = nan;
    listC.targetC = nan;
    listC.Mark = {'ƽ'};
    listC.fut = {fut};
    newList = listC;
    %
    if isempty(listI) %����û�ж���Ľ���
        listO = info;
        listO.hands = hisHands;
        listO.targetP = nan;
        listO.targetC = nan;
        listO.Mark = {'��'};
        listO.fut = {fut};
        newList = [newList;listO];
    else
        if height(listI)==1
            if strcmp(listI.Mark,'��')
                listO = listI;
                listO.hands = listO.hands+hisHands;
            else
                netHands = hisHands+listI.hands;
                % ���º�Լ�Ͽ���
                listO = info;
                listO.hands = netHands;
                listO.targetP = nan;
                listO.targetC = nan;
                listO.Mark = {'��'};
                listO.fut = {fut};
            end
            newList = [newList;listO];
        elseif height(listI)==2 %����
            if ismember('��',listI.Mark) %һ��һƽ
                % ���������ƽ����ǰ�Ŀ���һ������ʷ�ֲַ�����ͬ�����԰ѿ��ֽ��׵��ϲ�һ��
                % �����������ƽ����ƽ������һ������ʷ�ֲ�����ͬ�ģ�Ȼ����з��򿪲�
                tmpO = listI(ismember(listI.Mark,'��'),:);
                tmpC = listI(ismember(listI.Mark,'ƽ'),:);
                if ~isnan(tmpC.targetP) || ~isnan(tmpC.targetC) %��������ƽ
                    listO = info;
                    listO.hands = hisHands+tmpO.hands;
                    listO.targetP = nan;
                    listO.targetC = nan;
                    listO.Mark = {'��'};
                    listO.fut = {fut};
                    newList = [newList;listO;tmpC];
                else % ��������ƽ
                    newList = [newList;tmpO];
                end
            else %����ƽ�ֵ�
                tmpCN = listI(isnan(listI.targetP) & isnan(listI.targetC),:);
                if ~isempty(tmpCN) %������ƽ�ֵ�
                    netHands = hisHands+tmp.hands;
                else
                    netHands = hisHands;
                end
                listO = info;
                listO.hands = netHands;
                listO.targetP = nan;
                listO.targetC = nan;
                listO.Mark = {'��'};
                listO.fut = {fut};
                % ������ƽ�ֵ�
                tmpC2 = listI(~isnan(listI.targetP) | ~isnan(listI.targetC),:);
                newList = [newList;listO;tmpC2];
            end
        else %����:ƽ+��+������ƽ
            % ƽ�ֵ����º�Լ�ϵĿ��ֵ�����
            tmpCN = listI(ismember(listI.Mark,'ƽ') & isnan(listI.targetP) & isnan(listI.targetC),:);
            tmpC2 = listI(ismember(listI.Mark,'ƽ') & (~isnan(listI.targetP) | ~isnan(listI.targetC)),:);
            tmpO = listI(ismember(listI.Mark,'��'),:);
            netHands = hisHands+tmpCN.hands+tmpO.hands; %�������������º�Լ�ϵĿ��ֵ���������ƽ�ֵ��Ϳ��ֵ��ϲ�
            listO = info;
            listO.hands = netHands;
            listO.targetP = nan;
            listO.targetC = nan;
            listO.Mark = {'��'};
            listO.fut = {fut};
            newList = [newList;listO;tmpC2];
        end
    end
end

      
% ����������ƽ+��+������ƽ
if height(newList)>1
    tmpCN = newList(ismember(newList.Mark,'ƽ') & isnan(newList.targetP) & isnan(newList.targetC),:);
    tmpO = newList(ismember(newList.Mark,'��'),:);
    tmpC = newList(ismember(newList.Mark,'ƽ') & (~isnan(newList.targetP) | ~isnan(newList.targetC)),:);
    newList = [tmpCN;tmpO;tmpC];
end
newList(newList.hands==0,:) = [];
