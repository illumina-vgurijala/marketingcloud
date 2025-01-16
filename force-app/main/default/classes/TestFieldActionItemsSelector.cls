/***************************************************************************************************************************************
 * NAME   : TestFieldActionItemsSelector
 * DESCRIPTION  : TestClass for FieldActionItemsSelector
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 24-June-2019 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             24-June-2019             Initial Version
  ****************************************************************************************************************************************/ 
@isTest
private class TestFieldActionItemsSelector {
    static Case cs;
    static Field_Action_Notification__c fAN;
    /**
    * method : createdata
    * Description: method is to create test data.
    * params: NA
    * return: void
    * author: prashanth
    **/
    @testSetup
    static void createData(){
        //create Case record
        cs = TestDataCase.initNewCase('Business Issue', 'Initiated', 'Phone - Field');
        cs.Date_of_Issue_Awareness__c = Date.Today();
        insert cs;
        // To create a fAN record of record type "Notification"
        fAN =TestDataFieldService.createFAN('Notification');
        insert fAN;
    }
     /**
    * method : testFieldActionItemsSelector
    * Description: method is to test selectFieldActionItemsByFANRecType,selectFieldActionItemsByCaseId methods.
    * params: NA
    * return: void
    * author: prashanth
    **/
    static testMethod void fieldActionItemsSelectorTest(){ 
        createData();
        // To create a new fAI record With fAN record type "Notification"
        Field_Action_Item__c fAI =TestDataFieldService.createFAI(CS.Id,fAN.Id);
        SVMXC__Service_Order__c woObj=[Select Id from SVMXC__Service_Order__c where SVMXC__Case__c=:CS.Id];
        insert fAI;
        Test.StartTest();
            //test selectFieldActionItemsByFANRecType method 
            FieldActionItemsSelector selector = new FieldActionItemsSelector();
            List<Field_Action_Item__c> lstFieldActionItemsList = selector.selectFieldActionItemsByCaseORWOId(new set<Id>{woObj.Id},new set<Id>{CS.Id});
            System.assertEquals(lstFieldActionItemsList[0].Id , fAI.Id);
            List<Field_Action_Item__c> lstFieldActionItems = selector.selectFieldActionItemsByFANRecType(new Set<Id> {CS.Id}, 'Notification');
            System.assertEquals('Notification',lstFieldActionItems[0].Field_Action_Notification_Record_Type__c);
            //test selectFieldActionItemsByCaseId method
            List<Field_Action_Item__c> lstFieldActionItems1 = selector.selectFieldActionItemsByCaseId(new Set<Id> {cs.Id});
            System.assertEquals(lstFieldActionItems1[0].Case__c ,cs.Id);
        Test.StopTest();
    }
}