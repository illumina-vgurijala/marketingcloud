/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for WOResource_WOHelper
*/
@IsTest
private class TestWOResource_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST = 'Primary Field Application Scientists';
    
    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /**
      * DCP-25271
      *  @author Digvijay
      *  @description - Work Order Resource Creation  
      **/
      
      static testMethod void testWorkOrderResourceCreation1(){
      
          List<User> lstUsers = [SELECT Id 
                                  FROM User 
                                  WHERE Profile.Name =: System.label.Field_Service
                                  LIMIT 1];
           
          SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
          insert serviceTeam;
              
          SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
          technician.SVMXC__Email__c='a@b.com';
          insert technician;
          SVMXC__Service_Group_Members__c technician1 =TestDataFieldService.createTechnician(lstUsers[0].id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
          technician.SVMXC__Email__c='b@b.com';
          insert technician1;
          
          
          Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
          acc.Account_Group__c='Distributor';
          insert acc;
   
          
          Account_to_Field_Support__c accTechRole = new Account_to_Field_Support__c(
              Account__c = acc.Id,
              User__c = technician.Id,
              User_Role__c = 'Primary Field Service Engineer'
          );
          insert accTechRole;
          
          Contact con = TestDataPerson.getNewContact(acc.Id);
          Case objcs = TestDataCase.initServiceRequestCase(con);
          insert objcs;
          
          Case cs = TestDataCase.initServiceRequestCase(con);
          insert cs;
          
           
          List<SVMXC__Service_Order__c> lstWorkOrderInserted = new List<SVMXC__Service_Order__c>();
          SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
          workOrder.Record_Created_from_SFM__c=true;
          workOrder.SVMXC__Group_Member__c=technician.id;
          lstWorkOrderInserted.add(workOrder);
          
          SVMXC__Service_Order__c instworkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objcs.Id, 'Initiated');
          instworkOrder.SVMXC__Order_Type__c='Installation';
          instworkOrder.SVMXC__Company__c=acc.id;
          instworkOrder.Is_Auto_Created__c = true;
          lstWorkOrderInserted.add(instworkOrder);
          insert lstWorkOrderInserted;
          
          WorkOrders.hasupdaterun = false;
          Test.startTest();
          lstWorkOrderInserted[0].SVMXC__Group_Member__c = technician1.Id;
          update lstWorkOrderInserted[0];
           
          WorkOrders.hasupdaterun = false;
          lstWorkOrderInserted[0].SVMXC__Scheduled_Date_Time__c = System.now().addDays(1); 
          update lstWorkOrderInserted[0];
          
          WorkOrderResourceSelector wORSelectorObj=new WorkOrderResourceSelector();
          List<SVMXC__Work_Order_Resource__c> lstWORforWO=WORSelectorObj.selectWorkOrderResources(new set<Id>{workOrder.id});
          System.assertEquals(1,lstWORforWO.size(), 'size different');
          
          
          Test.stopTest();
}
}