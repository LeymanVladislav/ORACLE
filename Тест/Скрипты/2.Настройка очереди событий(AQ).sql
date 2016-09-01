---------------Создание обектного типа данных для событий---------------
CREATE TYPE evnt_type AS object(
     ID NUMBER, --уникальный номер события (сквозной для всех типов событий)
     TP VARCHAR2(32), --уведомление, подтверждение, предупреждение (Поддержать возможность расширения набора событий).
     DTIME date, --Время события
     DURATION NUMBER, --Длительность, в секундах
     TEXT VARCHAR2(255) --Описание события
     --Длительность
   );
/
---------------Создание таблицы для хранения событий---------------
BEGIN
  DBMS_AQADM.CREATE_QUEUE_TABLE(
     queue_table         => 'aq_tab', --имя таблицы
     queue_payload_type  => 'evnt_type', --объект тип данных события
     multiple_consumers  => TRUE, --у данной очереди может быть несколько получателей одного события.
     COMMENT             => 'Creat queue table' --комментарий
     );
END;
/
---------------Создание самой очереди---------------
BEGIN
   DBMS_AQADM.CREATE_QUEUE(
      queue_name         =>  'queue_1',
      queue_table        =>  'aq_tab');
END;
/
---------------Разрешение выполнения очереди---------------
BEGIN
   DBMS_AQADM.START_QUEUE(
      queue_name        => 'queue_1');
END;
/
---------------Создание подписчиков---------------
--без объявления подписчика нельзя поставить событие в очередь
DECLARE
   subs sys.aq$_agent;
BEGIN
   subs :=  sys.aq$_agent('SUBS_1', NULL, NULL);
   DBMS_AQADM.ADD_SUBSCRIBER(
      queue_name  =>  'queue_1',
      subscriber  =>  subs);
END;
/
