/**
* @author Prerna Agrawal
* @date 10 May 2022
*
* @description DCP-52354 Test class for RelatedContacts
*/ 
@isTest
public with sharing class RelatedContactsTest {
    @isTest
    static void testRelatedContactsMethod() {

        User u = TestDataFieldService.createUser('Field Service',false);
        Insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Product_Support'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        System.runAs(u)
        {  
            Test.startTest();
            Account objAcc = TestDataAccount.getUCAccount();
            objAcc.Market_Segment__c = null;
            insert objAcc;
            System.assertNotEquals(null, objAcc.Id, 'Account Not Inserted');
            // Account inserted	

            

            Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
            Case cs = TestDataCase.createCase('Business Issue','Initiated',objCon.Id);
            cs.Sub_Type__c = 'Complaint';
            update cs;
            System.assertNotEquals(null, cs.Id, 'Case Not Inserted');
            // Case inserted with Status as 'Initiated' Record type as 'Business Issue' sub type as 'Complaint'

            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
            SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
             SVMXC__Order_Status__c from 
             SVMXC__Service_Order__c where SVMXC__Case__c =: cs.Id Limit 1];
             //workOrder.SVMXC__Site__c=objLocation.Id;
             //update workOrder;
           
            Set<Id> woID = new Set<Id>();
            woId.add(workOrder.Id); 

            Id traineeRecordTypeId = Related_Contacts__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Trainee').getRecordTypeId();

            Related_Contacts__c rcdel = new Related_Contacts__c();
            rcdel.Work_Order__c = workOrder.id;            
            rcdel.RecordTypeId = traineeRecordTypeId;
            Insert rcdel;
            try{    
                delete rcdel;
            }
            catch(Exception ex){
                system.debug('Delete Related Contact');
            }
            
            Test.stopTest();
          }       
   }   
}
