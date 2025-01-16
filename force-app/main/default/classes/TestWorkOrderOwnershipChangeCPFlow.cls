/***************************************************************************************************************************************
* NAME   : TestWorkOrderOwnershipChangeCPFlow
* DESCRIPTION  : For Covering the "Work Order Ownership Change CP Flow"
*    
* @AUTHOR : Priya
* @DATE   : 30-Nov-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Priya             30-Nov-2023              Initial Version (CMCM-3824)
****************************************************************************************************************************************/ 

    
@isTest
public class TestWorkOrderOwnershipChangeCPFlow {
    public static final String STRING_WO_RECORDTYPE = 'Field Service';

    /**
     *  @author Priya
     *  @description - Positive Test case scenario 
     **/
    @isTest
    public static void testOwnershipChangeFlow() {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;

        
        Contact con = TestDataPerson.getNewContact(acc.Id);
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        workOrder.OwnerId = UserInfo.getUserId();
        insert workOrder;
        Test.startTest();
        workOrder.Request_Ownership_Status__c = 'Requested';
        workOrder.Ownership_Requested_By__c = UserInfo.getUserId();
        update workOrder;

        SVMXC__Service_Order__c updatedOrder = [SELECT Request_Ownership_Status__c, OwnerId, Ownership_Requested_By__c FROM SVMXC__Service_Order__c WHERE Id = :workOrder.Id];
        System.assertEquals('Requested', updatedOrder.Request_Ownership_Status__c);

        Test.stopTest();
    }
}