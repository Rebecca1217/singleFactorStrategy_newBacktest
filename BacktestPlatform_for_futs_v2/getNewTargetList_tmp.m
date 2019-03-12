function [newList,err] = getNewTargetList_tmp(listI,hisHands) 
% �Ե����δ�������Ŀ�꽻�׵�����Ԥ����


if height(listI)==1
    newList = listI;
else %�����ж�����׵�
    %���ֿ��ֵ���ƽ�ֵ�
    listO = listI(ismember(listI.Mark,'��'),:);
    listC = listI(ismember(listI.Mark,'ƽ'),:);
    newList = [];
    % ���ֵ��ϲ�
    if ~isempty(listO) %�п��ֵ�
         if height(listO)==1
             newList = [newList;listO];
         else %�ж�����ֵ������кϲ�
             % ���ж��Ƿ���Ժϲ�
             uni = unique(listO(:,{'date';'time';'futCode';'targetP';'targetC'}),'rows');
             if height(uni)==1
                 tthands = sum(listO.hands);
                 newList = [newList;[uni(:,{'date';'time';'futCode'}),array2table(tthands,'VariableNames',{'hands'}),uni(:,{'targetP';'targetC';'Mark'})]];
             else
                 disp([num2str(uni.date(1)),' ',num2str(uni.time(1)),'����Ŀ��ֽ��׵����󣡣�'])
                 err = 1;
                 return;
             end
         end
    end
    % ƽ�ֵ��ϲ�
    if ~isempty(listC) %��ƽ�ֵ�
        if height(listC)==1
            newList = [newList;listC];
        else %�ж��ƽ�ֵ������кϲ�
            % ���ж��Ƿ���Ժϲ�
            uni = unique(listC(:,{'date';'time';'futCode';'targetP';'targetC'}),'rows');
            if height(uni)==1
                tthands = sum(listC.hands);
                newList = [newList;[uni(:,{'date';'time';'futCode'}),array2table(tthands,'VariableNames',{'hands'}),uni(:,{'targetP';'targetC';'Mark'})]];
            else
                %������ӵ�ƽ���������ܲ�ͬ
                newList = [newList;listC];
            end
        end
    end
    % ���ֵ���ƽ�ֵ����кϲ�
    % ����ĺϲ�������֮��������ֵ���ƽ�ֵ������ڣ��򿪲ֵ�һ����ƽ�ֵ���1�����߶��
    aimHands = hisHands+sum(newList.hands); %Ŀ������   
    if ~isempty(listO) && ~isempty(listC) %�п��ֵ���ƽ�ֵ�
        if aimHands==0 || sign(aimHands)==sign(hisHands) %Ŀ�������ķ����ԭ������ͬ����Ŀ������Ϊ0
            nlistO = newList(ismember(newList.Mark,'��'),:);
            nlistC = newList(ismember(newList.Mark,'ƽ'),:);
            nlistO.Mark = {'ƽ'};  %���ֵ�ֱ�ӱ�Ϊƽ�ֵ�
            % ���һ����û�п��Ժ͸�ƽ�ֵ��ϲ���ƽ�ֵ�
            locs = find(isnan(nlistC.targetP) & isnan(nlistC.targetC));
            if ~isempty(locs)
                nlistO.hands = nlistC.hands(locs)+nlistO.hands;
                nlistC(locs,:) = [];
                if nlistO.hands>hisHands
                    tmp = nlistO;
                    tmp.hands = nlistO.hands-hisHands;
                    tmp.Mark = {'��'};
                    nlistO = [nlistO;tmp];
                end
            end
            newHisHands = hisHands+sum(nlistO.hands); %��������ƽ�ֲ����Ѿ�����֮���ͷ��
            newAimHands = aimHands-newHisHands; %����Ŀ����������Ҫ����Ĳ��֣�����Ǹ��ģ�����Ҫ���յĲ��֣���������ģ�����Ҫ����Ĳ���
            if newAimHands~=0 %������Ҫ�����ͷ��
                if height(nlistC)==1 %ֻ��һ��ƽ�ֵ���
                    nlistC.hands = newAimHands;
                    nlistC.Mark = {'������'};
                else %���ж��ƽ�ֵ�����Ҫ����tick���ݲ����ж��ĸ�ƽ�ֵ��ĳ�������
                    % ����tick����
                    load([tickDataPath,'\',freqK,'\',num2str(nlistC.date(1)),'_',num2str(nlistC.time(1)),'.mat'])
                    % �жϸ��������´�������������ʱ�䣬�ȴ����ĵ��ӱ��������
                    locs = zeros(height(nlistC),1);
                    for i = 1:height(nlistC)
                        [locs(i),err] = findOutTime(tickData,sign(nlistC.hands(i)),nlistC.targetP(i),nlistC.targetC(i),crossType);
                        if err==1
                            disp([num2str(nlistC.date(1)),' ',num2str(nlistC.time(1)),'�����ֹӯֹ������󣡣�'])
                            return;
                        end
                    end
                    if locs(1)<locs(2) %�������ı�Ϊ������
                        nlistC.Mark(1) = {'������'};
                    else
                        nlistC.Mark(2) = {'������'};
                    end                                            
                end
            end
            newList = [nlistO;nlistC];
        else %Ŀ�������ķ����ԭ�����෴
            % ����һ���µ�ƽ�ֵ���������ԭ�ֲ�������ͬ
            nlistO = newList(1,:);
            nlistO.hands = -hisHands;
            nlistO.targetP = nan;
            nlistO.targetC = nan;
            nlistO.Mark = {'ƽ'};
            % ʣ�������
            newHisHands = hisHands+nlistO.hands; %��������ƽ�ֲ����Ѿ�����֮���ͷ��
            newAimHands = aimHands-newHisHands; %����Ŀ����������Ҫ����Ĳ��֣�����Ǹ��ģ�����Ҫ���յĲ��֣���������ģ�����Ҫ����Ĳ���
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
        end
    end
                
end
             
             
        
