function [TableHands,error] = ptfWeight4(TableData,type,volWin)
% TableData��ʽ��date,time,code
% type=0:��Ȩ��type=1:�����ʵ�����һ��type=2��ATR������һ��type=3����ATR��type=4���Ȳ����ʣ�type=5���ȷ��չ��ף�type=6��������
% volWin:�����ʵĴ����ڲ���,Ĭ��ֵ��20
% ------------------------------------
% ע�⣺
% 1.��ATR��ATR������Ȩ��һ��ֻ����ڻ�����
% 2.������ڻ��Ļ���Ҫ���������Ե����⣬�����Բ��õ�Ʒ�ֲ�����Ȩ��
% ����ʽ�����޳������Բ��õ�Ʒ�֣�Ȼ��������λ֮���ٰ������Բ��õ�Ʒ������ϣ�TableWeight�ĳ��Ⱥ�TableData��ͬ
% 3.�ȷ��չ��ײ�����ʱ�޷�ʵ�֣���Ϊ�޷�����Э�������
% --------------------------------------
% 20180513���������޳������Բ��õ�Ʒ�֣�Ҫ�ڼ����겨����֮�����޳�����Ȼ���㲨�����õ������ǲ�������
% 20180514���޸�����ʷ�����ʼ���Ĵ��룬�ڻ������ʱ�����޳�amtΪ0�����ݣ���Ϊ����һ�ξ��ǽ��ײ���Ծ���޳�֮�����Ĳ����ʲ��ܷ�ӳ��ʱ����ʵ�������
% 20180813�������typeҲ������str��ʽ��
% 20181129�����ڻ��������Խ��������жϣ���ȥ20���վ��ɽ�������1w��
% 20181203:�����Ϊ����

% �ж��Ƿ����ڻ���������ڻ��Ļ������޳������Բ��õ�Ʒ��
if TableData.code(1)<700000 %����ǹ�Ʊ�����Ӻ�Լ�����У�ֵ��Ϊ1
    TableData.multifactor = ones(height(TableData),1);
end
%
if isa(type,'char')
    typeList = {'eqSize';'normVol';'normATR';'eqATR';'eqVol';'eqRisk';'eqHands'};
    type = find(ismember(typeList,type))-1;
end
% ������ʷ������
if ismember(type,[1,4,5]) %type1,4,5��Ҫ�õ�����������
    %������ʷ�����ʣ��޳�ͣ��(amt=0)�������������
    TableData.adjclose = TableData.close .* TableData.adjfactor;
    TableData = sortrows(TableData,{'code';'date';'time'},'ascend');
    TableData.preadjclose = shiftN(TableData.adjclose,TableData.code,1);
    TableData.pctchange = TableData.adjclose./TableData.preadjclose -1;
    if nargin==2
        win = 20;
    else
        win = volWin;
    end
    if TableData.code(1)>700000 %�ڻ�
        iTableData = TableData;
    else
        iTableData = TableData(TableData.amt>0,:); %��ƱҪ�޳�amt=0�Ĳ���
    end
    iTableData.hisVolatility =  movstd(iTableData.pctchange,[win-1,0],0,1,'Endpoints','fill'); %
    nanL = NanL_from_chgCode(iTableData.code,win);
    iTableData.hisVolatility(nanL) = nan;
    TableData = outerjoin(TableData,iTableData(:,{'code','date','time','hisVolatility'}),'MergeKeys',true,'Type','left');
    TableData = sortrows(TableData,{'code';'date';'time'},'ascend');% �ٴ�����
    if TableData.code(1)<700000 %��Ʊ
        TableData.hisVolatility(TableData.amt==0) = nan;
        %�޳��쳣ֵ��������̫С������Ȩ�ع���
        TableData.hisVolatility(TableData.hisVolatility<0.001) = nan;
    end
    TableData.hisVolatility1 = fillmissing(TableData.hisVolatility,'previous');
    TableData.hisVolatility1(nanL) = nan;
end  
  
% �ж��Ƿ����ڻ���������ڻ��Ļ������޳������Բ��õ�Ʒ��
if TableData.code(1)>700000
    % ����������ɸѡ
    TableOri = TableData;
    TableData(TableData.status==0,:) = [];
end
    
error = 0;
% �ж�һ��Ʒ�ֺͲ��õĴ���ʽ�Ƿ�ƥ��
if ismember(type,[2,3])
    if TableData.code(1)<700000 %��Ʊ
        disp('��Ʊ���ܲ���ATR�ķ�ʽ����Ȩ�ط��䣬���޸�Ȩ�ط��䷽ʽ��')
        error = 1;
        TableHands = [];
        return;
    end
end

TableData = sortrows(TableData,{'date','time','code'});
if type == 0 %eqSize
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(5000000./(TableData.close.*TableData.multifactor));
elseif type ==1 %�����ʵ�����һ
    %����Ȩ��
    TableData.volweight = 1./TableData.hisVolatility1;
    tbl_dt=varfun(@nansum,TableData(:,{'date','time','volweight'}),'GroupingVariables',{'date','time'});
    TableHands = outerjoin(TableData(:,{'date','time','code','volweight'}),tbl_dt,'MergeKeys',true,'Type','left');
    TableHands.weight = TableHands.volweight./TableHands.nansum_volweight;
elseif type ==2  %������ڻ�,atr�������� 
    TableData.atrweight = 1./(TableData.atrABS./TableData.close);
    tbl_dt=varfun(@nansum,TableData(:,{'date','time','atrweight'}),'GroupingVariables',{'date','time'});
    TableHands = outerjoin(TableData(:,{'date','time','code','atrweight'}),tbl_dt,'MergeKeys',true,'Type','left');
    TableHands.weight = TableHands.atrweight./TableHands.nansum_atrweight;
elseif type==3 %��ATR��������ڻ�
    TableHands = TableData(:,{'date','time','code'});
    % ��������=atrԤ��/(atr�ľ�����ֵ*��Լ����)
    TableHands.hand = round(100000./(TableData.atrABS.*TableData.multifactor)); 
%     % ���㵽��ֵ�����չ̶�������ֵ���з���
%     TableData = sortrows(TableData,{'date','time','code'});
%     % ������ֵ=atrԤ��/(atr�ľ�����ֵ*��Լ����)*δ��Ȩ���̼�
%     TableData.openSize = 100000./TableData.atrABS.*TableData.close; %������ֵ
%     tmp = TableData(:,{'date','time','code','openSize'});
%     TotalSize_dly = varfun(@nansum,tmp,'GroupingVariables',{'date','time'});
%     TotalSize_dly = TotalSize_dly(:,{'date';'time';'nansum_openSize'});
%     tmp = outerjoin(tmp,TotalSize_dly,'MergeKeys',true,'Type','left');
%     tmp.weight = tmp.openSize./tmp.nansum_openSize; %�ֲ�Ȩ��
%     TableWeight = tmp(:,{'date';'time';'code';'weight'});
%     TableHands.hand = round(10000000*TableWeight.weight./(TableData.multifactor.*TableData.close));
elseif type==4 % �Ȳ����ʣ���Ʊ�ڻ�����
    TableData = sortrows(TableData,{'date','time','code'});
    TableData.calP = TableData.close; %�Է���Ʊ������δ��Ȩ���̼�
    % ������ֵ=������Ԥ��/������*δ��Ȩ���̼�*��Լ����
    TableData.openSize = 1./TableData.hisVolatility1.*TableData.multifactor.*TableData.calP; %������ֵ
    tmp = TableData(:,{'date','time','openSize'});
    TotalSize_dly = varfun(@nansum,tmp,'GroupingVariables',{'date','time'});
    tmp = outerjoin(tmp,TotalSize_dly,'MergeKeys',true,'Type','left');
    weight = tmp.openSize./tmp.nansum_openSize; %�ֲ�Ȩ��
    TableHands = table;
    TableHands.date = TableData.date;
    TableHands.time = TableData.time;
    TableHands.code = TableData.code;
    TableHands.weight = weight;
% elseif type==5 %�ȷ��չ��ף���Ʊ�ڻ�����
elseif type==6 % ����������Ʊ�ڻ�����
    TableData = sortrows(TableData,{'date';'time';'code'});
    TableData.calP = TableData.close; %��δ��Ȩ���̼ۼ���
    % ������ֵ=����*δ��Ȩ���̼�*��Լ����
    TableData.openSize = 1*TableData.calP.*TableData.multifactor; %������ֵ
    tmp = TableData(:,{'date','time','openSize'});
    TotalSize_dly = varfun(@nansum,tmp,'GroupingVariables',{'date','time'});
    tmp = outerjoin(tmp,TotalSize_dly,'MergeKeys',true,'Type','left');
    weight = tmp.openSize./tmp.nansum_openSize; %�ֲ�Ȩ��
    TableHands = table;
    TableHands.date = TableData.date;
    TableHands.time = TableData.time;
    TableHands.code = TableData.code;
    TableHands.weight = weight;
end
    
if TableData.code(1)>700000
    TableHands = outerjoin(TableOri,TableHands,'MergeKeys',true,'Type','left');
end
TableHands = TableHands(:,{'date','time','code','hand'});
TableHands.hand(isnan(TableHands.hand)) = 0;    
end

