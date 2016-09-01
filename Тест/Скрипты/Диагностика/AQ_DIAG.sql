CREATE OR REPLACE PROCEDURE AQ_DIAG
                              ( 
                                INTRVL    NUMBER --Интервал запуска JOB sec
                              ) 
AS                                                        
RES           VARCHAR2(30);
N_TST         NUMBER;
ID            NUMBER;   
N             NUMBER;         ----Лимит для генерации нового события предупреждения
CNT           VARCHAR2(10);
AQ_JOB_ST     VARCHAR2(10);   --Состояние AQ_JOB
FAIL_LST_HR   NUMBER;         --Количество ошибок за последний час
N_TRSHLD      NUMBER;         --Число событий для одного обработчика
N_NTF         NUMBER;         --Число событий в очереди
N_STEP        NUMBER;         --Число параллельных обработчиков
AQ_PRL_PRC_ST VARCHAR(30);    --Результат выполнения процдуры  
PRG_CNT       NUMBER;         --Количество программ созданных AQ_PRL_PRC
BEGIN 
  --Проверка состояния jobe AQ_JOB
  SELECT 
        j.ENABLED INTO AQ_JOB_ST 
  FROM user_scheduler_jobs j
  WHERE j.job_name = 'AQ_JOB';
  DBMS_OUTPUT.PUT_LINE('Проверка состояния jobe AQ_JOB: '||AQ_JOB_ST||chr(13));
  --Количество ошибок за последний час
  SELECT SUM(DECODE(l.STATUS,'FAILED',1,0)) INTO FAIL_LST_HR       
  FROM all_scheduler_job_log l,
       all_scheduler_job_run_details rd
  WHERE l.LOG_ID = rd.LOG_ID
        AND l.OWNER = 'AQ_USER'  
        AND l.LOG_DATE >= SYSDATE - 1/24;
  DBMS_OUTPUT.PUT_LINE('Количество ошибок за последний час(all_scheduler_job_run_details): '||FAIL_LST_HR||chr(13));      
  SELECT pa.DEFAULT_VALUE INTO N
  FROM user_scheduler_program_args pa
  WHERE pa.PROGRAM_NAME = 'AQ_PROGRAM_START'
        AND pa.ARGUMENT_NAME = 'N';
  N_TST := round(dbms_random.VALUE(1000000,9999999));      
  --Цикл создания событий
  DBMS_OUTPUT.PUT_LINE('Цикл проверки корректности выполнения процеруды AQ_ENQUEUE'||chr(13));   
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
                                                   TP => i.TP, -- 1-Уведомление, 2-Подтверждение, 3-Предупреждение
                                                   DTIME => SYSDATE,
                                                   DURATION => i.DURATION,
                                                   TEXT => i.TEXT
                                                  )                             
                       );
      ID := REPLACE(REGEXP_SUBSTR(RES,'ID=.*'),'ID=','');
      DBMS_OUTPUT.PUT_LINE('i: '||i.ID||' Генерация события с параметрами: ID='||ID||' TP='||i.TP||' DURATION='||i.DURATION||' TEXT='||i.TEXT);
     
      --Проверка корректности создания события в AQ_TAB
      SELECT DECODE(COUNT(*),1,'Успех','Ошибка') INTO CNT
      FROM AQ_TAB t
      WHERE t.user_data.id = ID
            AND t.user_data.text = i.TEXT;
      DBMS_OUTPUT.PUT_LINE('Запись в таблицу AQ_TAB: '||CNT); 
  END LOOP;  
  
  Dbms_Lock.sleep(INTRVL); --Ожидание выполнения jobe
  
--Проверка корректности выполнения процеруды AQ_PRL_PRC 

  SELECT pa.DEFAULT_VALUE INTO N_TRSHLD
  FROM user_scheduler_program_args pa
  WHERE pa.PROGRAM_NAME = 'AQ_PROGRAM_START'
        AND pa.ARGUMENT_NAME = 'N_TRSHLD';
  --Определение количества событий
  SELECT GREATEST(COUNT(*),MAX(t.user_data.id)) INTO N_NTF
  FROM AQ_TAB t;  

  Dbms_Lock.sleep(INTRVL); --Ожидание 2-го циклоа выполнения jobe, т.к. созданные события предупрежденя обрабатываются при следующем запуске job  

  IF N_NTF>0 THEN    
    --Расчет необходимого количества обработчиков N_STEP
    N_STEP := CEIL(N_NTF/N_TRSHLD);
    --Количество программ созданных AQ_PRL_PRC
    SELECT COUNT(*) INTO PRG_CNT
    FROM user_scheduler_programs p
    WHERE p.PROGRAM_NAME LIKE 'AQ_PROGRAM_%'
          AND p.PROGRAM_NAME <> 'AQ_PROGRAM_START'; 
    IF PRG_CNT > 0 THEN     
       IF PRG_CNT = N_STEP THEN
          AQ_PRL_PRC_ST := 'Успех';   
       ELSE 
          AQ_PRL_PRC_ST := 'Ошибка';  
       END IF; 
    ELSE
       AQ_PRL_PRC_ST := 'Количество программ созданных AQ_PRL_PRC = 0';     
    END IF;
  ELSE 
    AQ_PRL_PRC_ST := 'Нет событий в очереди';               
  END IF;
  DBMS_OUTPUT.PUT_LINE(chr(13)||'Проверка корректности выполнения процеруды AQ_PRL_PRC: '||AQ_PRL_PRC_ST); 
        
--Цикл проверки корректности выполнения процеруды AQ_DEQUEUE
  DBMS_OUTPUT.PUT_LINE(chr(13)||'Цикл проверки корректности выполнения процеруды AQ_DEQUEUE'||chr(13));       
  FOR i IN(
           SELECT 1 id, 1 TP, N     DURATION, 'test_'||N_TST||1 TEXT FROM DUAL UNION ALL
           SELECT 2 id, 1 TP, N + 1 DURATION, 'test_'||N_TST||2 TEXT FROM DUAL UNION ALL
           SELECT 3 id, 2 TP, N     DURATION, 'test_'||N_TST||3 TEXT FROM DUAL UNION ALL
           SELECT 4 id, 2 TP, N + 1 DURATION, 'test_'||N_TST||4 TEXT FROM DUAL UNION ALL  
           SELECT 5 id, 3 TP, N     DURATION, 'test_'||N_TST||5 TEXT FROM DUAL
          )
  LOOP
      DBMS_OUTPUT.PUT_LINE('i: '||i.ID);
 --Проверка корректности добавления записи в таблицу AQ_CONFIRM
      IF i.TP = 2 THEN
          SELECT DECODE(COUNT(*),1,'Успех','Ошибка') INTO CNT
          FROM AQ_CONFIRM t
          WHERE t.text = i.TEXT;
          DBMS_OUTPUT.PUT_LINE('Запись в таблицу AQ_CONFIRM: '||CNT);     
      END IF;    
  --Проверка корректности добавления записи в таблицу AQ_WARN
      IF i.TP = 3 OR i.DURATION > N THEN
          SELECT DECODE(COUNT(*),1,'Успех','Ошибка') INTO CNT
          FROM AQ_WARN t
          WHERE t.text = i.TEXT;
          DBMS_OUTPUT.PUT_LINE('Запись в таблицу AQ_WARN: '||CNT);     
      END IF;       
  END LOOP;
END;
