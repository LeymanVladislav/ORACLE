---------------�������� ��������� ���� ������ ��� �������---------------
CREATE TYPE evnt_type AS object(
     ID NUMBER, --���������� ����� ������� (�������� ��� ���� ����� �������)
     TP VARCHAR2(32), --�����������, �������������, �������������� (���������� ����������� ���������� ������ �������).
     DTIME date, --����� �������
     DURATION NUMBER, --������������, � ��������
     TEXT VARCHAR2(255) --�������� �������
     --������������
   );
/
---------------�������� ������� ��� �������� �������---------------
BEGIN
  DBMS_AQADM.CREATE_QUEUE_TABLE(
     queue_table         => 'aq_tab', --��� �������
     queue_payload_type  => 'evnt_type', --������ ��� ������ �������
     multiple_consumers  => TRUE, --� ������ ������� ����� ���� ��������� ����������� ������ �������.
     COMMENT             => 'Creat queue table' --�����������
     );
END;
/
---------------�������� ����� �������---------------
BEGIN
   DBMS_AQADM.CREATE_QUEUE(
      queue_name         =>  'queue_1',
      queue_table        =>  'aq_tab');
END;
/
---------------���������� ���������� �������---------------
BEGIN
   DBMS_AQADM.START_QUEUE(
      queue_name        => 'queue_1');
END;
/
---------------�������� �����������---------------
--��� ���������� ���������� ������ ��������� ������� � �������
DECLARE
   subs sys.aq$_agent;
BEGIN
   subs :=  sys.aq$_agent('SUBS_1', NULL, NULL);
   DBMS_AQADM.ADD_SUBSCRIBER(
      queue_name  =>  'queue_1',
      subscriber  =>  subs);
END;
/
