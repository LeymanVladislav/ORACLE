CREATE OR REPLACE PROCEDURE AQ_DIAG
                              ( 
                                INTRVL    NUMBER --�������� ������� JOB sec
                              ) 
AS                                                        
RES           VARCHAR2(30);
N_TST         NUMBER;
ID            NUMBER;   
N             NUMBER;         ----����� ��� ��������� ������ ������� ��������������
CNT           VARCHAR2(10);
AQ_JOB_ST     VARCHAR2(10);   --��������� AQ_JOB
FAIL_LST_HR   NUMBER;         --���������� ������ �� ��������� ���
N_TRSHLD      NUMBER;         --����� ������� ��� ������ �����������
N_NTF         NUMBER;         --����� ������� � �������
N_STEP        NUMBER;         --����� ������������ ������������
AQ_PRL_PRC_ST VARCHAR(30);    --��������� ���������� ��������  
PRG_CNT       NUMBER;         --���������� �������� ��������� AQ_PRL_PRC
BEGIN 
  --�������� ��������� jobe AQ_JOB
  SELECT 
        j.ENABLED INTO AQ_JOB_ST 
  FROM user_scheduler_jobs j
  WHERE j.job_name = 'AQ_JOB';
  DBMS_OUTPUT.PUT_LINE('�������� ��������� jobe AQ_JOB: '||AQ_JOB_ST||chr(13));
  --���������� ������ �� ��������� ���
  SELECT SUM(DECODE(l.STATUS,'FAILED',1,0)) INTO FAIL_LST_HR       
  FROM all_scheduler_job_log l,
       all_scheduler_job_run_details rd
  WHERE l.LOG_ID = rd.LOG_ID
        AND l.OWNER = 'AQ_USER'  
        AND l.LOG_DATE >= SYSDATE - 1/24;
  DBMS_OUTPUT.PUT_LINE('���������� ������ �� ��������� ���(all_scheduler_job_run_details): '||FAIL_LST_HR||chr(13));      
  SELECT pa.DEFAULT_VALUE INTO N
  FROM user_scheduler_program_args pa
  WHERE pa.PROGRAM_NAME = 'AQ_PROGRAM_START'
        AND pa.ARGUMENT_NAME = 'N';
  N_TST := round(dbms_random.VALUE(1000000,9999999));      
  --���� �������� �������
  DBMS_OUTPUT.PUT_LINE('���� �������� ������������ ���������� ��������� AQ_ENQUEUE'||chr(13));   
  FOR i IN(
           SELECT 1 id, 1 TP, N     DURATION, 'test_'||N_TST||1 TEXT FROM DUAL UNION ALL
           SELECT 2 id, 1 TP, N + 1 DURATION, 'test_'||N_TST||2 TEXT FROM DUAL UNION ALL
           SELECT 3 id, 2 TP, N     DURATION, 'test_'||N_TST||3 TEXT FROM DUAL UNION ALL
           SELECT 4 id, 2 TP, N + 1 DURATION, 'test_'||N_TST||4 TEXT FROM DUAL UNION ALL  
           SELECT 5 id, 3 TP, N     DURATION, 'test_'||N_TST||5 TEXT FROM DUAL
          )
  LOOP
      RES := AQ_ENQUEUE(
                        ATT => AQ_ENQUEUE_TYPE(
                                                   TP => i.TP, -- 1-�����������, 2-�������������, 3-��������������
                                                   DTIME => SYSDATE,
                                                   DURATION => i.DURATION,
                                                   TEXT => i.TEXT
                                                  )                             
                       );
      ID := REPLACE(REGEXP_SUBSTR(RES,'ID=.*'),'ID=','');
      DBMS_OUTPUT.PUT_LINE('i: '||i.ID||' ��������� ������� � �����������: ID='||ID||' TP='||i.TP||' DURATION='||i.DURATION||' TEXT='||i.TEXT);
     
      --�������� ������������ �������� ������� � AQ_TAB
      SELECT DECODE(COUNT(*),1,'�����','������') INTO CNT
      FROM AQ_TAB t
      WHERE t.user_data.id = ID
            AND t.user_data.text = i.TEXT;
      DBMS_OUTPUT.PUT_LINE('������ � ������� AQ_TAB: '||CNT); 
  END LOOP;  
  
  Dbms_Lock.sleep(INTRVL); --�������� ���������� jobe
  
--�������� ������������ ���������� ��������� AQ_PRL_PRC 

  SELECT pa.DEFAULT_VALUE INTO N_TRSHLD
  FROM user_scheduler_program_args pa
  WHERE pa.PROGRAM_NAME = 'AQ_PROGRAM_START'
        AND pa.ARGUMENT_NAME = 'N_TRSHLD';
  --����������� ���������� �������
  SELECT GREATEST(COUNT(*),MAX(t.user_data.id)) INTO N_NTF
  FROM AQ_TAB t;  

  Dbms_Lock.sleep(INTRVL); --�������� 2-�� ������ ���������� jobe, �.�. ��������� ������� ������������� �������������� ��� ��������� ������� job  

  IF N_NTF>0 THEN    
    --������ ������������ ���������� ������������ N_STEP
    N_STEP := CEIL(N_NTF/N_TRSHLD);
    --���������� �������� ��������� AQ_PRL_PRC
    SELECT COUNT(*) INTO PRG_CNT
    FROM user_scheduler_programs p
    WHERE p.PROGRAM_NAME LIKE 'AQ_PROGRAM_%'
          AND p.PROGRAM_NAME <> 'AQ_PROGRAM_START'; 
    IF PRG_CNT > 0 THEN     
       IF PRG_CNT = N_STEP THEN
          AQ_PRL_PRC_ST := '�����';   
       ELSE 
          AQ_PRL_PRC_ST := '������';  
       END IF; 
    ELSE
       AQ_PRL_PRC_ST := '���������� �������� ��������� AQ_PRL_PRC = 0';     
    END IF;
  ELSE 
    AQ_PRL_PRC_ST := '��� ������� � �������';               
  END IF;
  DBMS_OUTPUT.PUT_LINE(chr(13)||'�������� ������������ ���������� ��������� AQ_PRL_PRC: '||AQ_PRL_PRC_ST); 
        
--���� �������� ������������ ���������� ��������� AQ_DEQUEUE
  DBMS_OUTPUT.PUT_LINE(chr(13)||'���� �������� ������������ ���������� ��������� AQ_DEQUEUE'||chr(13));       
  FOR i IN(
           SELECT 1 id, 1 TP, N     DURATION, 'test_'||N_TST||1 TEXT FROM DUAL UNION ALL
           SELECT 2 id, 1 TP, N + 1 DURATION, 'test_'||N_TST||2 TEXT FROM DUAL UNION ALL
           SELECT 3 id, 2 TP, N     DURATION, 'test_'||N_TST||3 TEXT FROM DUAL UNION ALL
           SELECT 4 id, 2 TP, N + 1 DURATION, 'test_'||N_TST||4 TEXT FROM DUAL UNION ALL  
           SELECT 5 id, 3 TP, N     DURATION, 'test_'||N_TST||5 TEXT FROM DUAL
          )
  LOOP
      DBMS_OUTPUT.PUT_LINE('i: '||i.ID);
 --�������� ������������ ���������� ������ � ������� AQ_CONFIRM
      IF i.TP = 2 THEN
          SELECT DECODE(COUNT(*),1,'�����','������') INTO CNT
          FROM AQ_CONFIRM t
          WHERE t.text = i.TEXT;
          DBMS_OUTPUT.PUT_LINE('������ � ������� AQ_CONFIRM: '||CNT);     
      END IF;    
  --�������� ������������ ���������� ������ � ������� AQ_WARN
      IF i.TP = 3 OR i.DURATION > N THEN
          SELECT DECODE(COUNT(*),1,'�����','������') INTO CNT
          FROM AQ_WARN t
          WHERE t.text = i.TEXT;
          DBMS_OUTPUT.PUT_LINE('������ � ������� AQ_WARN: '||CNT);     
      END IF;       
  END LOOP;
END;
