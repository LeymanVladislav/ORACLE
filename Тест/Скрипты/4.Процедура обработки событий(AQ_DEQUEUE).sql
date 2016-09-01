---------------�������� ������� ��� ������� � ����� - �������������---------------
CREATE SEQUENCE AQ_CONFIRM_SEQ
START WITH     1
INCREMENT BY   1
/ 
CREATE TABLE AQ_CONFIRM
(
       ID INTEGER PRIMARY KEY,
       TP VARCHAR2(32), --��� �������
       DTIME date, --����� �������
       DURATION NUMBER, --������������, � ��������
       TEXT VARCHAR2(255) --�������� ������� 
)
/
---------------�������� ������� ��� ������� � ����� - ��������������---------------
CREATE SEQUENCE AQ_WARN_SEQ
START WITH     1
INCREMENT BY   1
/
CREATE TABLE AQ_WARN
(
       ID INTEGER PRIMARY KEY,
       TP VARCHAR2(32), --��� �������
       DTIME date, --����� �������
       DURATION NUMBER, --������������, � ��������
       TEXT VARCHAR2(255) --�������� ������� 
)
/
---------------�������� ��������� ��� ��������� �������---------------
CREATE OR REPLACE PROCEDURE AQ_DEQUEUE (
                                        SUBS         VARCHAR2,             --��� ����������
                                        RN_START     NUMBER,               --ID ������ ������
                                        RN_END       NUMBER,               --ID ��������� ������
                                        N            NUMBER,               --����� ��� ��������� ������ ������� ��������������
                                        v_sender     VARCHAR2 DEFAULT NULL, --����������� ����� �����������
                                        v_recipients VARCHAR2 DEFAULT NULL, --����������� ����� ����������
                                        TEXT         VARCHAR2 DEFAULT NULL --�����������                                       
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
       --deq_options.dequeue_mode :=  DBMS_AQ.BROWSE -- �� ������� ��������� �� ������� (�� ��������� DBMS_AQ.REMOVE)
       --deq_options.navigation := DBMS_AQ.FIRST_MESSAGE;
       deq_options.msgid := i.msgid;
       deq_options.consumer_name := SUBS;
       deq_options.wait := DBMS_AQ.NO_WAIT; --�������� �������� �������, ����� ������� � ��������
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
       IF evnt.tp = '�����������' AND evnt.DURATION > N THEN --����������� � ���� ������������ ������ N c�����, �� ������������ ������� �������������� ��� ���������� ���������. 
          RES := AQ_ENQUEUE(
                            ATT => AQ_ENQUEUE_F_TYPE(
                                                      TP => 3,
                                                      DTIME => evnt.dtime,
                                                      DURATION => evnt.DURATION,
                                                      TEXT => evnt.TEXT
                                                     )
                           );                           
          DBMS_OUTPUT.PUT_LINE('�������� ��������� � ����� - ��������������'); 
       ELSIF evnt.tp = '�������������' THEN  --������������� � ���������� � ��������� �������.  
          INSERT INTO AQ_CONFIRM VALUES (
                                         AQ_CONFIRM_SEQ.NEXTVAL,
                                         evnt.tp,       --��� �������
                                         evnt.dtime,    --����� �������
                                         evnt.DURATION, --������������, � ��������
                                         evnt.TEXT      --�������� ������� 
                                         );
          IF evnt.DURATION > N THEN --���� ������������ ������ N c�����, �� ������������ ������� �������������� ��� ���������� ���������.
             RES := AQ_ENQUEUE(
                               ATT => AQ_ENQUEUE_F_TYPE(
                                                         TP => 3,
                                                         DTIME => evnt.dtime,
                                                         DURATION => evnt.DURATION,
                                                         TEXT => evnt.TEXT
                                                        )
                               );                           
             DBMS_OUTPUT.PUT_LINE('�������� ��������� � ����� - ��������������'); 
          END IF; 
       ELSIF evnt.tp = '��������������' THEN  --��������������  - ���������� � ��������� ������� (����� � ���������� email, ��������� � ���� ������ ������ ��������� ���������� � �������)                                     
          INSERT INTO AQ_WARN VALUES (
                                       AQ_WARN_SEQ.NEXTVAL,
                                       evnt.tp,       --��� �������
                                       evnt.dtime,    --����� �������
                                       evnt.DURATION, --������������, � ��������
                                       evnt.TEXT      --�������� ������� 
                                      );  
        --�������� E-Mail 
        IF v_sender IS NOT NULL AND v_recipients IS NOT NULL THEN
            NULL;
            /*UTL_MAIL.send(
                          sender     => v_sender,
                          recipients => v_recipients,
                          subject    => '[AQ] ������� � ����� - ��������������',
                          message    => '<p>����������� � ������� � ����� - ��������������/</p><p>����� �������: '||evnt.dtime||'</p><p>������������: '||evnt.DURATION||'���.</p><p>�������� �������: '||evnt.TEXT||'</p>',
                          mime_type  => 'text/html; charset=�UTF-8�'--'text; charset=us-ascii'
                         );  */
        END IF;                          
       END IF;
       COMMIT;
   --SYS.DBMS_LOCK.Sleep(20); ��� ������������ � ���������   
   END LOOP;
EXCEPTION 
   WHEN OTHERS
     THEN 
       DBMS_OUTPUT.PUT_LINE('ERROR: '|| sqlerrm);
       ROLLBACK;     
END;
/
