---------------Процедура Формирования параллельных процессов---------------
CREATE OR REPLACE PROCEDURE AQ_PRL_PRC
                            (
                             N_TRSHLD     NUMBER,                --Число событий для одного обработчика
                             N            NUMBER,                 --Лимит для генерации нового события предупреждения
                             v_sender     VARCHAR2 DEFAULT NULL, --Электронная почта отрпавителя
                             v_recipients VARCHAR2 DEFAULT NULL, --Электронная почта получателя
                             TEXT         VARCHAR2 DEFAULT NULL  --Комментарий                                 
                            )
AS
N_NTF        NUMBER;         --Число событий в очереди
N_STEP       NUMBER;         --Число параллельных обработчиков
RL_ACTION    VARCHAR2(20000);
RL_CONDITION VARCHAR2(20000);
RN_START     NUMBER;
RN_END       NUMBER;
BEGIN
     --Удаление ранее созданой цепочки AQ_CHAIN
     FOR c IN (
               SELECT t.CHAIN_NAME
               FROM user_scheduler_chains t
               WHERE t.CHAIN_NAME = 'AQ_CHAIN'
               )
     LOOP          
       sys.dbms_scheduler.drop_chain
                (
                 chain_name => C.CHAIN_NAME
                );
     END LOOP;          
     --Удаление ранее созданных программ
     FOR p IN (
               SELECT program_name
               FROM user_scheduler_programs p
               WHERE p.PROGRAM_NAME LIKE 'AQ_PROGRAM_%'
                     AND p.PROGRAM_NAME <> 'AQ_PROGRAM_START'
               ) 
     LOOP
       sys.dbms_scheduler.drop_program(program_name => p.program_name);
     END LOOP;   
     --Определение количества событий
     SELECT GREATEST(COUNT(*),MAX(t.user_data.id)) INTO N_NTF
     FROM AQ_TAB t;
     IF N_NTF>0 THEN    
         --Расчет необходимого количества обработчиков N_STEP
         N_STEP := CEIL(N_NTF/N_TRSHLD);                         
         --Создание цепочки AQ_CHAIN
         sys.dbms_scheduler.create_chain
                (
                 chain_name => 'AQ_CHAIN'
                );
         --Создание программ и шагов цепочки для scheduler
         FOR i IN 1..N_STEP
           LOOP
             RN_START := (i-1)*N_TRSHLD + 1;
             RN_END := i*N_TRSHLD;       
             --Создание новой программы обработчика
             sys.dbms_scheduler.create_program
                    (
                     program_name => 'AQ_PROGRAM_'||i,
                     program_type => 'PLSQL_BLOCK',
                     program_action => 'AQ_DEQUEUE(''SUBS_1'','||RN_START||','||RN_END||','||N||',''AQ_PROGRAM_'||i||''','''||v_sender||''','''||v_recipients||''');',
                     enabled => TRUE  
                    );                
             --Создание шагов цепочки AQ_CHAIN
             sys.dbms_scheduler.define_chain_step
                    (
                     chain_name => 'AQ_CHAIN',
                     step_name => 'AQ_PROGRAM_STEP_'||i,
                     program_name => 'AQ_PROGRAM_'||i
                    ); 
             IF i = 1 THEN 
               RL_ACTION := 'START AQ_PROGRAM_STEP_'||i;
               RL_CONDITION := 'AQ_PROGRAM_STEP_'||i||' COMPLETED';
             ELSE  
               RL_ACTION := RL_ACTION||', AQ_PROGRAM_STEP_'||i; 
               RL_CONDITION := RL_CONDITION||' AND AQ_PROGRAM_STEP_'||i||' COMPLETED'; 
             END IF;            
           END LOOP;
          --Создание правил для цепочки, для параллельного запуска шагов
          sys.dbms_scheduler.define_chain_rule
                  (
                   chain_name => 'AQ_CHAIN',
                   condition => '1=1',
                   action => RL_ACTION,
                   rule_name => 'AQ_R_START'
                  );
          --Создание завершающего правила
          sys.dbms_scheduler.define_chain_rule
                  (
                   chain_name => 'AQ_CHAIN',
                   condition => RL_CONDITION,
                   action => 'END',
                   rule_name => 'AQ_R_FINAL'
                  );
          --Активация цепочки AQ_CHAIN
          sys.dbms_scheduler.enable('AQ_CHAIN'); 
          --Запуск цепочки
          sys.dbms_scheduler.run_chain('AQ_CHAIN', '','AQ_CHAIN_JOB');            
     END IF;
END;
