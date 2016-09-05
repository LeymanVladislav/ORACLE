---------------Создание таблицы для событий с типом - Подтверждение---------------
CREATE SEQUENCE AQ_CONFIRM_SEQ
START WITH     1
INCREMENT BY   1
/ 
CREATE TABLE AQ_CONFIRM
(
       ID INTEGER PRIMARY KEY,
       TP VARCHAR2(32), --Тип события
       DTIME date, --Время события
       DURATION NUMBER, --Длительность, в секундах
       TEXT VARCHAR2(255) --Описание события 
)
/
---------------Создание таблицы для событий с типом - Предупреждение---------------
CREATE SEQUENCE AQ_WARN_SEQ
START WITH     1
INCREMENT BY   1
/
CREATE TABLE AQ_WARN
(
       ID INTEGER PRIMARY KEY,
       TP VARCHAR2(32), --Тип события
       DTIME date, --Время события
       DURATION NUMBER, --Длительность, в секундах
       TEXT VARCHAR2(255) --Описание события 
)
/
---------------Создание процедуры для обработки событий---------------
CREATE OR REPLACE PROCEDURE AQ_DEQUEUE (
                                        SUBS         VARCHAR2,             --Имя подписчика
                                        RN_START     NUMBER,               --ID первой строки
                                        RN_END       NUMBER,               --ID последней строки
                                        N            NUMBER,               --Лимит для генерации нового события предупреждения
                                        v_sender     VARCHAR2 DEFAULT NULL, --Электронная почта отрпавителя
                                        v_recipients VARCHAR2 DEFAULT NULL, --Электронная почта получателя
                                        TEXT         VARCHAR2 DEFAULT NULL --Комментарий                                       
                                        )
AS
deq_options     DBMS_AQ.dequeue_options_t;
msg_properties  DBMS_AQ.message_properties_t;
msg_handle      RAW(16);
evnt            evnt_type;
RES             VARCHAR2(30);
BEGIN
   FOR i IN(
            SELECT *
            FROM AQ_TAB t
            WHERE t.user_data.id >= RN_START
                  AND t.user_data.id <= RN_END
            ORDER BY t.user_data.id ASC       
           )
   LOOP        
       --deq_options.dequeue_mode :=  DBMS_AQ.BROWSE -- не удалять сообщения из очереди (по умолчанию DBMS_AQ.REMOVE)
       --deq_options.navigation := DBMS_AQ.FIRST_MESSAGE;
       deq_options.msgid := i.msgid;
       deq_options.consumer_name := SUBS;
       deq_options.wait := DBMS_AQ.NO_WAIT; --параметр ожидания события, можно указать в секундах
       DBMS_AQ.DEQUEUE(
          queue_name          =>     'queue_1',
          dequeue_options     =>     deq_options,
          message_properties  =>     msg_properties,
          payload             =>     evnt,
          msgid               =>     msg_handle);          
       DBMS_OUTPUT.PUT_LINE('ID: '|| evnt.id);
       DBMS_OUTPUT.PUT_LINE('tp: '|| evnt.tp);
       DBMS_OUTPUT.PUT_LINE('dtime: '|| evnt.dtime);
       DBMS_OUTPUT.PUT_LINE('DURATION: '|| evnt.DURATION);   
       DBMS_OUTPUT.PUT_LINE('TEXT: '|| evnt.TEXT);
       IF evnt.tp = 'Уведомление' AND evnt.DURATION > N THEN --Уведомление – если длительность больше N cекунд, то генерировать событие предупреждения для дальнейшей обработки. 
          RES := AQ_ENQUEUE(
                            ATT => AQ_ENQUEUE_F_TYPE(
                                                      TP => 3,
                                                      DTIME => evnt.dtime,
                                                      DURATION => evnt.DURATION,
                                                      TEXT => evnt.TEXT
                                                     )
                           );                           
          DBMS_OUTPUT.PUT_LINE('Создание сообщения с типом - Предупреждение'); 
       ELSIF evnt.tp = 'Подтверждение' THEN  --Подтверждение – складывать в отдельную таблицу.  
          INSERT INTO AQ_CONFIRM VALUES (
                                         AQ_CONFIRM_SEQ.NEXTVAL,
                                         evnt.tp,       --Тип события
                                         evnt.dtime,    --Время события
                                         evnt.DURATION, --Длительность, в секундах
                                         evnt.TEXT      --Описание события 
                                         );
          IF evnt.DURATION > N THEN --если длительность больше N cекунд, то генерировать событие предупреждения для дальнейшей обработки.
             RES := AQ_ENQUEUE(
                               ATT => AQ_ENQUEUE_F_TYPE(
                                                         TP => 3,
                                                         DTIME => evnt.dtime,
                                                         DURATION => evnt.DURATION,
                                                         TEXT => evnt.TEXT
                                                        )
                               );                           
             DBMS_OUTPUT.PUT_LINE('Создание сообщения с типом - Предупреждение'); 
          END IF; 
       ELSIF evnt.tp = 'Предупреждение' THEN  --Предупреждение  - складывать в отдельную таблицу (бонус – отправлять email, заголовок и тело письма должно содержать информацию о событии)                                     
          INSERT INTO AQ_WARN VALUES (
                                       AQ_WARN_SEQ.NEXTVAL,
                                       evnt.tp,       --Тип события
                                       evnt.dtime,    --Время события
                                       evnt.DURATION, --Длительность, в секундах
                                       evnt.TEXT      --Описание события 
                                      );  
        --Отправка E-Mail 
        IF v_sender IS NOT NULL AND v_recipients IS NOT NULL THEN
            NULL;
            /*UTL_MAIL.send(
                          sender     => v_sender,
                          recipients => v_recipients,
                          subject    => '[AQ] Событие с типом - Предупреждение',
                          message    => '<p>Уведомление о событии с типом - Предупреждение/</p><p>Время события: '||evnt.dtime||'</p><p>Длительность: '||evnt.DURATION||'сек.</p><p>Описание события: '||evnt.TEXT||'</p>',
                          mime_type  => 'text/html; charset=«UTF-8»'--'text; charset=us-ascii'
                         );  */
        END IF;                          
       END IF;
       COMMIT;
   --SYS.DBMS_LOCK.Sleep(20); Для тестирования с нагрузкой   
   END LOOP;
EXCEPTION 
   WHEN OTHERS
     THEN 
       DBMS_OUTPUT.PUT_LINE('ERROR: '|| sqlerrm);
       ROLLBACK;     
END;
/
