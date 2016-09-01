---------------Создание обектного типа данных для функции---------------
CREATE TYPE AQ_ENQUEUE_F_TYPE AS object(
     TP NUMBER, --уведомление, подтверждение, предупреждение (Поддержать возможность расширения набора событий).
     DTIME date, --Время события
     DURATION NUMBER, --Длительность, в секундах
     TEXT VARCHAR2(255) --Описание события
     --Длительность
   );
/
---------------Создание функции добавления события для запуска другим пользователем---------------
CREATE OR REPLACE FUNCTION AQ_ENQUEUE_F(ATT IN AQ_ENQUEUE_F_TYPE) RETURN VARCHAR2
IS
enqueue_options DBMS_AQ.enqueue_options_t;
msg_properties  DBMS_AQ.message_properties_t;
msg_handle      RAW(16);
evnt            evnt_type;
ID              NUMBER;
TP_IN           VARCHAR2(30);
BEGIN
   SELECT NVL(MAX(t.User_Data.id)+1,1) INTO ID
   FROM AQ_TAB t;
   IF ATT.TP = 1 THEN 
     TP_IN := 'Уведомление';
   ELSIF ATT.TP = 2 THEN
     TP_IN := 'Подтверждение'; 
   ELSIF ATT.TP = 3 THEN
     TP_IN := 'Предупреждение';
   ELSE TP_IN := NULL;
   END IF;      
   IF TP_IN IS NOT NULL THEN
     evnt := evnt_type(ID, TP_IN, ATT.DTIME, ATT.DURATION, ATT.TEXT);
     DBMS_AQ.ENQUEUE(
                      queue_name         => 'aq_user.queue_1',
                      enqueue_options    => enqueue_options,
                      message_properties => msg_properties,
                      payload            => evnt,
                      msgid              => msg_handle
                     );
     COMMIT;
     RETURN('Событие принято: ID='||ID);     
   ELSE
     RETURN('Некорректный тип события: '||ATT.TP);
   END IF;  
END;
/
--Созданине публичного синонима
CREATE PUBLIC SYNONYM AQ_ENQUEUE
FOR AQ_USER.AQ_ENQUEUE_F;
/
CREATE PUBLIC SYNONYM AQ_ENQUEUE_TYPE
FOR AQ_USER.AQ_ENQUEUE_F_TYPE;
/
--Добавление привилегий для пользователя на синоним
GRANT execute ON AQ_ENQUEUE to USER;
GRANT execute ON AQ_ENQUEUE_TYPE to USER;
/
---------------Запуск функции другим пользователем для добавления события---------------
/*
DECLARE
RES VARCHAR2(30);
BEGIN 
  RES := AQ_ENQUEUE(
                    ATT => AQ_ENQUEUE_TYPE(
                                               TP => 2, -- 1-Уведомление, 2-Подтверждение, 3-Предупреждение
                                               DTIME => SYSDATE,
                                               DURATION => 10,
                                               TEXT => 'test_005'
                                              )                             
                   );
  DBMS_OUTPUT.PUT_LINE(RES);                  
END;
*/
