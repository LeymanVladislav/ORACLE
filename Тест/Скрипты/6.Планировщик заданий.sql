---------------Планировщик задания---------------

---------------Создание программы---------------
BEGIN
DBMS_SCHEDULER.CREATE_PROGRAM
( 
    program_name         => 'AQ_PROGRAM_START'
    ,program_type        => 'STORED_PROCEDURE' , program_action => 'AQ_PRL_PRC'
    ,number_of_arguments => 4 
    ,enabled             => FALSE--TRUE
);
--Число событий для одного обработчика
DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT
( program_name      => 'AQ_PROGRAM_START'
, argument_position => 1
, argument_name     => 'N_TRSHLD'
, argument_type     => 'NUMBER'
, default_value     => 15
) ;
--Лимит для генерации нового события предупреждения
DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT 
( program_name      => 'AQ_PROGRAM_START'
, argument_position => 2
, argument_name     => 'N'
, argument_type     => 'NUMBER'
, default_value     => 10
) ;
--Электронная почта отрпавителя
DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT
( program_name      => 'AQ_PROGRAM_START'
, argument_position => 3
, argument_name     => 'v_sender'
, argument_type     => 'VARCHAR2'
, default_value     => NULL
) ;
--Электронная почта получателя
DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT
( program_name      => 'AQ_PROGRAM_START'
, argument_position => 4
, argument_name     => 'v_recipients'
, argument_type     => 'VARCHAR2'
, default_value     => NULL
) ;

DBMS_SCHEDULER.ENABLE ( 'AQ_PROGRAM_START' );
END;
/
---------------Создание расписания---------------
BEGIN
DBMS_SCHEDULER.CREATE_SCHEDULE
( schedule_name   => 'AQ_SCHEDULE'
,start_date      => SYSTIMESTAMP
,repeat_interval      => 'FREQ=MINUTELY; INTERVAL=1;'
) ;
END;
/
---------------Создание задания---------------
BEGIN
DBMS_SCHEDULER.CREATE_JOB
( job_name      => 'AQ_JOB'
, program_name  => 'AQ_PROGRAM_START'
, schedule_name => 'AQ_SCHEDULE'
, enabled       => TRUE
);
END;
/
/*
BEGIN
DBMS_SCHEDULER.ENABLE ( 'AQ_JOB' );
END;

BEGIN
DBMS_SCHEDULER.DISABLE ( 'AQ_JOB' );
END;
*/
