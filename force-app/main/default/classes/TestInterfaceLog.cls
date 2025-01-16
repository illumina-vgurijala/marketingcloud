/**  
*    @description  Test class for Interface Log
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Nishan                         10-Oct-2022         CodeScanFix [Method name should not start with Capital].
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestInterfaceLog {
    @isTest
    static void testInterfaceLog() {//CodeScanIssue Fix
        Account acc = TestDataAccount.getNewAccount();
        Interface_Log__c interfaceAccLog = new Interface_Log__c(Result__c = 'Success', Related_Record__c = acc.id);
        insert interfaceAccLog;
        Test.startTest();
            list<interfaceLog.WrapperForInterfaceLogRecord> interfaceLogs = interfaceLog.retreiveInterfaceLogs(interfaceAccLog.Related_Record__c);
        Test.stopTest(); 
        system.assertEquals('Success', interfaceLogs[0].Result);
    }
}