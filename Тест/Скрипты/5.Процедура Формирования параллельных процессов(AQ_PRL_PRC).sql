---------------��������� ������������ ������������ ���������---------------
CREATE OR REPLACE PROCEDURE AQ_PRL_PRC
                            (
                             N_TRSHLD     NUMBER,                --����� ������� ��� ������ �����������
                             N            NUMBER,                 --����� ��� ��������� ������ ������� ��������������
                             v_sender     VARCHAR2 DEFAULT NULL, --����������� ����� �����������
                             v_recipients VARCHAR2 DEFAULT NULL, --����������� ����� ����������
                             TEXT         VARCHAR2 DEFAULT NULL  --�����������                                 
                            )
AS
N_NTF        NUMBER;         --����� ������� � �������
N_STEP       NUMBER;         --����� ������������ ������������
RL_ACTION    VARCHAR2(20000);
RL_CONDITION VARCHAR2(20000);
RN_START     NUMBER;
RN_END       NUMBER;
BEGIN
     --�������� ����� �������� ������� AQ_CHAIN
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
     --�������� ����� ��������� ��������
     FOR p IN (
               SELECT program_name
               FROM user_scheduler_programs p
               WHERE p.PROGRAM_NAME LIKE 'AQ_PROGRAM_%'
                     AND p.PROGRAM_NAME <> 'AQ_PROGRAM_START'
               ) 
     LOOP
       sys.dbms_scheduler.drop_program(program_name => p.program_name);
     END LOOP;   
     --����������� ���������� �������
     SELECT GREATEST(COUNT(*),MAX(t.user_data.id)) INTO N_NTF
     FROM AQ_TAB t;
     IF N_NTF>0 THEN    
         --������ ������������ ���������� ������������ N_STEP
         N_STEP := CEIL(N_NTF/N_TRSHLD);                         
         --�������� ������� AQ_CHAIN
         sys.dbms_scheduler.create_chain
                (
                 chain_name => 'AQ_CHAIN'
                );
         --�������� �������� � ����� ������� ��� scheduler
         FOR i IN 1..N_STEP
           LOOP
             RN_START := (i-1)*N_TRSHLD + 1;
             RN_END := i*N_TRSHLD;       
             --�������� ����� ��������� �����������
             sys.dbms_scheduler.create_program
                    (
                     program_name => 'AQ_PROGRAM_'||i,
                     program_type => 'PLSQL_BLOCK',
                     program_action => 'AQ_DEQUEUE(''SUBS_1'','||RN_START||','||RN_END||','||N||',''AQ_PROGRAM_'||i||''','''||v_sender||''','''||v_recipients||''');',
                     enabled => TRUE  
                    );                
             --�������� ����� ������� AQ_CHAIN
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
          --�������� ������ ��� �������, ��� ������������� ������� �����
          sys.dbms_scheduler.define_chain_rule
                  (
                   chain_name => 'AQ_CHAIN',
                   condition => '1=1',
                   action => RL_ACTION,
                   rule_name => 'AQ_R_START'
                  );
          --�������� ������������ �������
          sys.dbms_scheduler.define_chain_rule
                  (
                   chain_name => 'AQ_CHAIN',
                   condition => RL_CONDITION,
                   action => 'END',
                   rule_name => 'AQ_R_FINAL'
                  );
          --��������� ������� AQ_CHAIN
          sys.dbms_scheduler.enable('AQ_CHAIN'); 
          --������ �������
          sys.dbms_scheduler.run_chain('AQ_CHAIN', '','AQ_CHAIN_JOB');            
     END IF;
END;
