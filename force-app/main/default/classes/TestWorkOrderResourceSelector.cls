/*@ author       : Tapas
* @ date         : 22-05-2019
* @ Description  : Test class for WorkOrderResourceSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Tapas                   22-05-2019               US-25271          Initial version
* 
*/
@IsTest(SeeAllData=false)
global with sharing class TestWorkOrderResourceSelector {
    Static testMethod void testmethodWorkOrderResourceSelector(){
        Account ac =TestDataAccount.initAccount();
        ac.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert ac;
        Contact con =TestDataContact.getNewContact(ac); 
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        
         List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];
         
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c technicianFSE =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Service Engineer',serviceTeam.id);
        technicianFSE.SVMXC__Email__c='ax@b.com';
        insert technicianFSE;
        
        Case objCase  = new Case(
            Status = 'Initiated',
            Subject = dateString ,
            Description= dateString,
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Automatic case creation during off hours',
            ContactId = con.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        insert objCase  ;
        // Insert Work Order
        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder  = [Select id,OwnerID from SVMXC__Service_Order__c where SVMXC__Case__c=: objCase.Id];
        objWorkOrder.SVMXC__Group_Member__c=technicianFSE.id;
        update objWorkOrder;
        
        Set<Id> setWOId=new Set<Id>();
        setWOId.add(objWorkOrder.id);
        WorkOrderResourceSelector worSelectorObj=new WorkOrderResourceSelector();
        List<SVMXC__Work_Order_Resource__c> lstWORforWO=worSelectorObj.selectWorkOrderResources(setWOId);
        System.assertEquals(1,lstWORforWO.size());
        Test.stopTest();
    }
}