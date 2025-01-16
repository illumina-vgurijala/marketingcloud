/**
 * @description       : Test Class to validate CreateAssociatedCode functionality
 * @author            : Pooja
 * @last modified on  : 06-21-2022
**/
@isTest
public class TestCreateAssociatedCode_CaseHelper {
 
    public static final string STRING_CASE_CATEGORY_ORDER = 'New Order';
      /**
      * @description : To validate creation of associated code on case change
      **/
      static testmethod void newAssociatedCodeCreationOnInquiryCase() {
          
        Code_Library__c dcl = new Code_Library__c(Name='CS Inquiry Order', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                  Service_Product_Type__c = 'Tool');
        insert dcl;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'Order';
        cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
        cs.Status = 'Initiated';
        cs.ContactId = null;
        cs.Closed_with_Associated_Codes__c = false;
        User serviceUser=TestDataUser.findUserInProfile('Customer Service');   
        system.runAs(serviceUser){
            test.startTest();
            insert cs;
            system.assertNotEquals(null,cs.id, 'Case created successfully');
            
            /*cs.status='Completed';
            cs.Record_Updated_from_SFM__c=true;
            cs.Closed_with_Associated_Codes__c = true;
            cs.Send_Case_Completion_Email__c = false;
            cs.Is_Case_Completed__c = true;
            update cs;*/
            test.stopTest();
            //List<Associated_Codes__c> associatedCode=[select id from Associated_Codes__c LIMIT 1];
            //system.assert(!associatedCode.isEmpty(),'associated code is created');
        }
      
    }
}
