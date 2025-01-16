/**
 *    @author Unknown
 *    @date   Not available
 *    @description  An apex controller class for interface log object in order to retrieve interface logs.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Jitesh Lakhwani                6-July-2022         Code Scan fixes of Comments
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

public with sharing class InterfaceLog {

    public final static String RESULT_SUCCESS = 'Success';
    public final static String RESULT_FAIL = 'Fail';

    /**
    * @description: This method will retreive Interface Logs based on the record id (of the related record) for which log is created.
    * @param : String recordId
    * @return: list<WrapperForInterfaceLogRecord> - list of interface logs for the related record.
    */
    @AuraEnabled(Cacheable = true)
    public static list<WrapperForInterfaceLogRecord> retreiveInterfaceLogs(String recordId)
    {
        String strQuery = 'SELECT Id, Name, Result__c, LastModifiedDate FROM Interface_Log__c WHERE Related_Record__c =: recordId';
        List<SObject> lstInterfaceLogs = Database.query(strQuery);
        if (lstInterfaceLogs.isEmpty()) {
            throw new AuraHandledException('No Interface Log Record Found.');
        }

        List<WrapperForInterfaceLogRecord> lstWrapperForInterfaceLogRecord = new List<WrapperForInterfaceLogRecord>();
        for (sObject li : lstInterfaceLogs)
        {
            WrapperForInterfaceLogRecord wrapper = new WrapperForInterfaceLogRecord(
                '/'+li.get('Id'),
                (String)li.get('Name'),
                (String)li.get('Result__c'),
                (DateTime)li.get('LastModifiedDate')
            );
            lstWrapperForInterfaceLogRecord.add(wrapper);
        }
        return lstWrapperForInterfaceLogRecord;
    }

    /**
    * @description: WrapperForInterfaceLogRecord wrapper class. This is the format in which data will returned. It is used in above method named 'retreiveInterfaceLogs'
    * @param : None
    * @return: None
    */
    public class WrapperForInterfaceLogRecord {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String result;
        @AuraEnabled
        public Datetime lastModifiedDate;

        /**
        * @description: WrapperForInterfaceLogRecord constructor This is the format in which data will returned. It is used in above method named 'retreiveInterfaceLogs'
        * @param : String id, String name, String result, Datetime lastModifiedDate
        * @return: None
        */
        public WrapperForInterfaceLogRecord(String id, String name, String result, Datetime lastModifiedDate)
        {
            this.id = id;
            this.name = name;
            this.result = result;
            this.lastModifiedDate = lastModifiedDate;
        }
    }

}