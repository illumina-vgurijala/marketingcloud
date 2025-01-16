/*@ author       : Gladis
* @ date         : 21-09-2021
* @ Description  : Test class for TimeInStateSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gladis                 21-09-2021               Initial version
****************************************************************************************************************************************/ 
@isTest
public with sharing class TestTimeInStateSelector { 
    
    static SVMXC__Service_Order__c objWorkOrder;
    static Time_In_State__c objTimeInState;
    static Case objCase;
    static Account objAccount;
    static Contact objContact;

    /*
    *@author: Gladis
    *@Desc: Test data method
    */
    @testSetup
    public static void initializeTestData() {
        
        objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        
        objContact = TestDataPerson.getNewContact(objAccount.Id);
    
        objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;    

        objWorkOrder = TestDataFieldService.createWorkOrder('Remote Support', objCase.Id, 'Initiated');
        objWorkOrder.SVMXC__Order_Status__c='Assigned';
        objWorkOrder.Is_Auto_Created__c = true;
        insert objWorkOrder;

    }
    /**
     *  @author Gladis
     *  @description - CMCP-16 Test method to check the queries
    **/
    static testMethod void checkTimeInStateQueries(){

        SVMXC__Service_Order__c objWorkOrderLocal = [SELECT Id from SVMXC__Service_Order__c Limit 1];

        Test.startTest();
        objTimeInState = new Time_In_State__c(
            			Start_Date_Time__c = System.Now(),
                        Work_Order__c = objWorkOrderLocal.Id,
                        Value__c = 'Test' );                 
        insert objTimeInState;
        list<Time_In_State__c> lstTis = new TimeInStateSelector().getRecordbyWorkOrder(new Set<Id>{objWorkOrderLocal.Id});
        Test.stopTest();
        system.assert(lstTis.size() > 0);
    }
}
