function BacktestAnalysis = getCTAAnalysis(tdList)
% ���㼨Ч


nv = tdList{:,{'date';'time';'profit'}}; %���
nv = [nv(:,1:2),cumsum(nv(:,3)),nv(:,3)];
if nv(1,2)==999999999
    dayNum = 244;
else % ��Ƶ������ÿ��ƽ����K�߸���
    % ����ÿ���K�߸�����Ȼ������������ƽ����Ȼ�����244
    tmp = array2table(nv(:,1:2),'VariableNames',{'date';'time'});
    tmp = varfun(@nansum,tmp,'GroupingVariables','date');
    meanBarNum = floor(mean(tmp.GroupCount));
    dayNum = 244*meanBarNum;
end
nv = nv(:,[1,3,4]);
tt = {'�ۼ�����';'�껯����';'�껯����';'��ʤ��';'ӯ����';'���س�';'�س������ʱ��';'���ձ�';'����س���';'�ز⿪ʼ����';'�ز��������'};

analysis = zeros(length(tt),1);
analysis(1) = nv(end,2); %�ۼ�����
analysis(2) = mean(nv(:,3))*dayNum; %�껯����
analysis(3) = std(nv(:,3))*sqrt(dayNum); %�껯����
analysis(4) = sum(nv(:,3)>0)/sum(nv(:,3)~=0); %�в�λ������µ���ʤ��
analysis(5) = mean(nv(nv(:,3)>0,3))/-mean(nv(nv(:,3)<0,3)); %ӯ����
dd = nv(:,2)-cummax(nv(:,2)); 
% dd��0�为����ʼ�س���dd�ɸ���0�������س�
sgn = sign(dd);
noDDLocs = find(sgn==0); %û�лس���ʱ���������
if noDDLocs(end)~=length(sgn)
    noDDLocs(end+1) = length(sgn);
end
analysis(6) = -min(dd); %���س�
try
    analysis(7) = max(diff(noDDLocs)); %�س������ʱ��
catch
    analysis(7) = length(dd);
end
analysis(8) = analysis(2)/analysis(3); %sr
analysis(9) = analysis(2)/-min(dd); %calmar
analysis(10) = nv(1,1);
analysis(11) = nv(end,1);


BacktestAnalysis = [tt,num2cell(analysis)];


end