һ�������ݴ洢·����\\10.201.227.227\�ڻ�����\Data_Cleaning\WWB
�����ز⣺
����demo���޸�����·����
�����ز�ƽ̨CTABacktest_GeneralPlatform_v2_1˵����
1.���ڸ���Ƶ�ʵ��ڻ����Իز⣬�������ڵ����ԵĻز⣬֧��Bar��ֹӯֹ��Ļز�
2.���������TargetTradeList,StrategyPara,TradePara
3.����˵����
3.1. TargetTradeList˵����
��1��Ŀ�꽻�׵���������һ��bar��Ҫ���еĽ��ף�����Ҫ���ǻ��µ����⣨�����ڲ����д���
��2��table��ʽ����7�У�date,time,futCont,hands,targetP,targetC,Mark
date,time:ָ�����Ӧ��ʱ�䣨����20181119��Ӧ�Ŀ���ָ���20181120���̼��볡��
futCont:���׵ĺ�Լ���룬��A1901��ע�⣺�·ݺ�Լ������4λ���֣�����A809����д��A0809��
hands:���׵���������������1������-1��
targetP:ֹӯĿ��ۣ����û�У�Ϊnan��
targetC:ֹ��Ŀ��ۣ����û�У�Ϊnan��
Mark:��ƽ��ǣ�����ƽ��
����ʾ����TargetTradeList�е��ļ�
3.2. StrategyPara˵����
��1��������صĲ���
��2��struct��ʽ������crossType,freqK,edDate��������
crossType:ֹӯʱ�����۸�ķ�ʽ��dn��Ĭ�ϣ��´�������up
freqK:K��Ƶ�ʣ�Dly��Ĭ�ϣ�����NMIN(5MIN,10MIN,...)
edDate:�ز��ֹ���ڣ�nan��Ĭ�ϣ�Ĭ�ϻز⵽�������ڣ�
��3������ʱ������ֻ��ĳ��������ֵ����������Ĭ�ϲ���
3.3. TradePara˵����
��1��������صĲ���
��2��struct��ʽ������fixC,slip,PType,tickNum,futDataPath,tickDataPath��������
fixC:�̶��ɱ���0.0002��Ĭ�ϣ�
slip:���������2��Ĭ�ϣ�
PType:���׼۸�open��Ĭ�Ͽ��̼۽��ף�
tickNum:�õ�tick����ʱʱ���ͺ�����10��Ĭ�ϣ������ж�100000000������������Ϊ100005000ʱ�̵ļ۸�
futDataPath:K�����ݴ洢·����\\10.201.227.227\�ڻ�����\Data_Cleaning\WWB��Ĭ�ϣ�
tickDataPath:tick���ݴ洢·����\\10.201.227.227\�ڻ�����\Data_Cleaning\WWB��Ĭ�ϣ�
��3������ʱ������ֻ��ĳ��������ֵ����������Ĭ�ϲ���