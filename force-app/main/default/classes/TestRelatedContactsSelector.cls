/*
* @ author       : Pooja Shalwadi
* @ date         : 30-March-2022
* @ Description  : Test class for RelatedContactSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Pooja Shalwadi         25-Feb-2022                        Initial version
* Rohan Rathod           30-05-2022                         Added logic to test new method
*/
@IsTest
public class TestRelatedContactsSelector {
     /**
     * @method:TestRelatedContactsSelectorMethod
     * @description: testing RelatedContactSelector class.
     */
    static testMethod void testRelatedContactsSelectorMethod() {

      User u = TestDataFieldService.createUser('System Administrator',false);
      Insert u;
      PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Product_Support'];
      insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
      System.runAs(u)
      {  
          
          Account objAcc = TestDataAccount.getUCAccount();
          insert objAcc;
          System.assertNotEquals(null, objAcc.Id, 'Account Object should not be empty');
          // Account inserted	

          

          Contact objCon = TestDataPerson.getNewContact(objAcc.Id);

          Case cs = TestDataCase.createCase('Business Issue','Initiated',objCon.Id);
          cs.Sub_Type__c = 'Complaint';
          update cs;
          System.assertNotEquals(null, cs.Id,'Case object should not be empty');
          // Case inserted with Status as 'Initiated' Record type as 'Business Issue' sub type as 'Complaint'
          
          SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test','Test','Test','USD');
              insert objLocation;
              System.assertNotEquals(null, objLocation.Id,'Site object should not be empty');
            //Location inserted

          SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
          SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
           SVMXC__Order_Status__c from 
           SVMXC__Service_Order__c where SVMXC__Case__c =: cs.Id Limit 1];
           workOrder.SVMXC__Site__c=objLocation.Id;
           workOrder.Business_Impact_to_Customer__c = 'System Down';
           workOrder.Business_impact_to_Illumina__c = 'Instrument replacement';              
           update workOrder;
           System.assertNotEquals(null, workOrder.Id,'WO object should not be empty');

          Related_Contacts__c rc = new Related_Contacts__c();
          rc.Elevated_Work_Order__c = workOrder.id;            
          rc.User__c=u.id;
          rc.Type__c = 'Watcher (Account)';
          rc.recordtypeid = Schema.SObjectType.Related_Contacts__c.getRecordTypeInfosByName().get('Elevation Member').getRecordTypeId();
          rc.Source__c = 'Flow';
          Insert rc;
          System.assertNotEquals(null, rc.Id, 'RC Object should not be empty');
          //Related Contact inserted
          Test.startTest();
          List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
         Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
         Id accountElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();  
          Elevations__c techElev = new Elevations__c();
          techElev.RecordTypeId = technicalElevationRecordType;
          techElev.Elevation_Category__c = 'Standard Technical';
          techElev.Elevation_Status__c = 'Open';
          techElev.Work_Order__c = workOrder.Id;
          insert techElev;
          System.assertNotEquals(null, techElev.Id, 'Elevation Object should not be empty');
          // Elevation inserted
          Elevations__c accElev = new Elevations__c();
         accElev.RecordTypeId = accountElevationRecordType;
         accElev.Elevation_Category__c = 'Account Maintenance';
         accElev.Elevation_Status__c = 'Open';   
         accElev.Executive_Action_Required__c = 'Yes';
         accElev.Summary_of_Executive_Action__c = 'TEST';
         accElev.Elevation_Owner__c = lstUsers[0].Id;
         accElev.Plan_of_Action__c = 'test';
         accElev.Work_Order__c = workOrder.id;
         insert accElev;
         System.assertNotEquals(null, accElev.Id, 'Elevation Object should not be empty');
         
         workOrder.Technical_Elevation__c = techElev.Id;
         workOrder.Account_Elevation__c = accElev.Id;
         update workOrder;
         System.assertNotEquals(null, workOrder.Id, 'WO Object should not be empty');
         Test.stopTest();
          Set<Id> woID = new Set<Id>();
          woId.add(workOrder.Id); 

          string a='Watcher (Account)';
          String typeRC= '('+'\''+a+'\''+')';    

          RelatedContactsSelector selector = new RelatedContactsSelector();
          List<Related_Contacts__c> lstPOL1 = selector.selectRelatedContact(woID);
          System.assert(lstPOL1.size() != null, 'Related contact list should not be empty');
          
          List<Related_Contacts__c> lstPOL2 = selector.selectAddElevationMembersByWOId(woID,typeRC);
          System.assert(!lstPOL2.isEmpty(), 'Related contact list should not be empty');
             
          List<Related_Contacts__c> lstPOL3 = selector.selectRelatedContactByWOId(woID);
          System.assert(!lstPOL3.isEmpty(), 'Related contact list should not be empty');

          List<Related_Contacts__c> lstPOL4 = selector.selectElevationMembersByCategory(woID);
          System.assert(!lstPOL4.isEmpty(), 'Related contact list should not be empty');
        }       
 }  

}        