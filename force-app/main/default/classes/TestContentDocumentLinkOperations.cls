/***************************************************************************************************************************************
* NAME   : ContentDocumentLinks
* DESCRIPTION  : Domain class for ContentDocumentLink.
*                Added logic for DCP-804  
* @AUTHOR : Debalina
* @DATE   : 08-Jun-2018  
*  
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
*   Debalina            14-Jun-2018            Initial Version. 
*   Akshay              19-June-2018           Changed Account creation method
****************************************************************************************************************************************/ 

@isTest(SeeAllData = false)
public with sharing class TestContentDocumentLinkOperations {

    /*
    * Method to Setup data for test class
    */
    @testSetup
    public static void setUpData() {
      TestDataFieldService.createSettings();
    }
    
    testMethod static void testContentLinkInsertPositiveUseCase(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Order__c'
        );
        insert apexSettings;
        Id recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        List<User> lstUsers = [SELECT Id FROM User 
                WHERE Profile.Name =: System.label.ProfileSystemAdmin
                AND IsActive = true
                LIMIT 1];
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){

                //TestDataFieldService.createSettings(); 
                 
                
                Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
                objAcc.RecordTypeId = recordtypeid;
                insert objAcc;
                Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
                Case objCase = TestDataCase.getNewComplaintCase(objCon);
                objCase.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Service Request');
                objCase.ContactId = null;
                update objCase;
                SVMXC__Service_Order__c objWO = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
                objWO.Record_Created_from_SFM__c=true;
                objWO.Is_Auto_Created__c = true;
                objWO.SVMXC__Order_Type__c='Presales';
                insert objWO;
                                
                SVMXC__Installed_Product__c objIP = TestDataFieldService.createInstalledProduct('TestClassProd','USD','Installed');  
                insert objIP; 
                objWO.SVMXC__Company__c = objAcc.Id;
                objWO.SVMXC__Component__c = objIP.Id;
                Test.startTest(); 
                update objWO;
                
                ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
                insert objCV;
                objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
                
                ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, objWO.Id,'V','AllUsers');
                insert objCDL;
                
                delete objCDL;
                Test.stopTest();
                
                if(objCV != NULL){
                  List<ContentDocumentLink> lstCDL = [SELECT Id, ContentDocumentId 
                                    FROM ContentDocumentLink 
                                    WHERE ContentDocumentId = :objCV.ContentDocumentId];
                
                System.assertEquals(true,lstCDL.size()>0);}
            }
        }
    }
}