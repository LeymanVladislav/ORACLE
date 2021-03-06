--Создание пользователя
CREATE USER aq_user IDENTIFIED BY 12345; 
---------------Предоставление необходимых прав:-------------------
GRANT DBA, CREATE ANY TYPE TO aq_user;
GRANT EXECUTE ON DBMS_AQ TO aq_user;
GRANT EXECUTE ON DBMS_AQADM TO aq_user;
GRANT EXECUTE ON DBMS_SCHEDULER TO aq_user;
GRANT EXECUTE ON Dbms_Lock TO AQ_USER
GRANT AQ_ADMINISTRATOR_ROLE TO aq_user; 
--Привилегии для chain
GRANT SCHEDULER_ADMIN TO AQ_USER;
GRANT CREATE JOB TO AQ_USER;
GRANT MANAGE SCHEDULER TO AQ_USER;

BEGIN
  dbms_rule_adm.grant_system_privilege(
  dbms_rule_adm.create_rule_obj, 'AQ_USER');
  dbms_rule_adm.grant_system_privilege(
  dbms_rule_adm.create_rule_set_obj, 'AQ_USER');
  dbms_rule_adm.grant_system_privilege(
  dbms_rule_adm.create_evaluation_context_obj, 'AQ_USER');
END;
/

BEGIN
DBMS_RULE_ADM.GRANT_SYSTEM_PRIVILEGE(DBMS_RULE_ADM.CREATE_ANY_RULE, 'AQ_USER');
DBMS_RULE_ADM.GRANT_SYSTEM_PRIVILEGE (
   DBMS_RULE_ADM.CREATE_ANY_RULE_SET, 'AQ_USER');
DBMS_RULE_ADM.GRANT_SYSTEM_PRIVILEGE (
   DBMS_RULE_ADM.CREATE_ANY_EVALUATION_CONTEXT, 'AQ_USER');
END;
/
