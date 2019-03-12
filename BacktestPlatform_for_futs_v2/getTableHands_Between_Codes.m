function TableHands = getTableHands_Between_Codes(TableData,type,Reb,wkDay)
% TableData��ʽ��date,time,code
% �����һ������������
% -------------------------
% 20181224��
% ԭ�汾��Ȩ����������ƽ�⣬���ڸĳ�ÿ����ƽ��һ�Σ�Ĭ��������ƽ��

if nargin==2
    Reb = 0;
elseif nargin==3
    Reb = 1;
    wkDay = 'Fri';
end

ttSize = 50000000; %��������ֵ
ttATR = 1000000; %��ATR

% ����������ɸѡ
TableOri = TableData;
TableData(TableData.status==0,:) = [];

TableData = sortrows(TableData,{'date';'time';'code'});
sumFuts = varfun(@nansum,TableData(:,{'date';'time'}),'GroupingVariables',{'date';'time'}); %���������յ�Ʒ������
TableData = outerjoin(TableData,sumFuts,'Mergekeys',1,'type','left');
TableData = sortrows(TableData,{'date';'time';'code'});
if strcmpi(type,'eqSize')
    % ����Ʒ��Ȩ��
    TableData.weight = 1./TableData.GroupCount;
    TableData.Size = ttSize.*TableData.weight;
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(TableData.Size./(TableData.multifactor.*TableData.close));
elseif strcmpi(type,'eqATR')
    % �ܲ���ˮƽ���䣬�ܲ���Ϊ100w
    TableData.SizeATR = ttATR./TableData.GroupCount; %ÿ��Ʒ��������䵽��ATR����
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(TableData.SizeATR./(TableData.multifactor.*TableData.atrABS));
elseif strcmpi(type,'eqATR2')
    % ����Ʒ���в������ޣ�20w
    TableData.SizeATR = min([ttATR./TableData.GroupCount,200000*ones(height(TableData),1)],[],2);
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(TableData.SizeATR./(TableData.multifactor.*TableData.atrABS));
elseif strcmpi(type,'eqATR3')
    % �̶�����Ʒ�ֵ�ATR=100000
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(100000./(TableData.multifactor.*TableData.atrABS));
end

    
TableHands = outerjoin(TableOri(:,{'date';'time';'code'}),TableHands,'MergeKeys',true,'Type','left');
TableHands = TableHands(:,{'date','time','code','hand'});
TableHands.hand(isnan(TableHands.hand)) = 0;    
TableHands = sortrows(TableHands,{'date';'time';'code'});

% ÿ�ܽ���Ȩ�ص���ƽ��
if Reb==1 %��Ҫ������ƽ��
    wkDay = lower(wkDay);
    wkNum = find(ismember({'mon';'tue';'wes';'thu';'fri'},wkDay))+1; %monday:2,...,friday:6
    stDate = TableHands.date(find(TableHands.hand~=0,1,'first')); %��ʼ����
    dateUni = unique(TableHands.date(TableHands.date>=stDate)); %ȫ���Ľ�������
    dateUni(:,2) = weekday(datenum(num2str(dateUni),'yyyymmdd'));
    % ��ȡ��Ҫ��ƽ�������
    dateReb = dateUni(dateUni(:,2)==wkNum,1);
    dateReb(1) = [];
    dateReb = [stDate;dateReb];
    % ��ƽ�����ڶ�Ӧ�ĳֲ����
    TableHandsReb = TableHands(ismember(TableHands.date,dateReb),:);
    % ���ڲ�ȫ
    TableHandsReb = outerjoin(TableOri(:,{'date';'time';'code'}),TableHandsReb,'MergeKeys',true,'Type','left');
    TableHandsReb = sortrows(TableHandsReb,{'code';'date';'time'});
    codeUni = unique(TableHandsReb.code);
    for c = 1:length(codeUni)
        tmp = TableHandsReb(TableHandsReb.code==codeUni(c),:);
        tmp.hand = fillmissing(tmp.hand,'previous');
        TableHandsReb.hand(TableHandsReb.code==codeUni(c)) = tmp.hand;
    end
    TableHands = TableHandsReb;  
    TableHands.hand(isnan(TableHands.hand)) = 0;
    TableHands = sortrows(TableHands,{'date';'time';'code'});
end

