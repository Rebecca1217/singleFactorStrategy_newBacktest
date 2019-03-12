function [newList,err] = getNewTargetList(listI)
% ���׵�ֻ������һ�����������
% 1.�����һ�����׵������ô���
% 2.������������׵���ֻ�����������
% 2.1.������ƽ�ֵ������������ֵ�
% 2.2.������ƽ�ֵ���������ƽ�ֵ�

err = 0;



if height(listI)==1
    newList = listI(:,{'date';'time';'futCode';'hands';'targetP';'targetC'});
elseif height(listI)==2 %�����ж�����׵�
    listO = listI(ismember(listI.Mark,'��'),:);
    listC = listI(ismember(listI.Mark,'ƽ'),:);
    if ~isempty(listO)
        % ����
        newList = [listI(1,{'date';'time';'futCode'}),array2table([sum(listI.hands),nan,nan],'VariableNames',{'hands';'targetP';'targetC'})];
    else %����ƽ�ֵ�
        newList = listI(:,{'date';'time';'futCode';'hands';'targetP';'targetC'});
    end
else
    disp([nu2mstr(listI.date(1)),' ',num2str(listI.time(1)),'����Ľ��׵����󣡣�'])
    err = 1;
    return;
end