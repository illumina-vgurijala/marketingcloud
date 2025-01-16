/***************************************************************************************************************************************
 * NAME   : TestAddArticletoCaseController
 * DESCRIPTION  : Test Class for AddArticletoCaseControlle
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 25-09-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Digvijay                 25-09-2019          Created
 * Adyasha                  26-11-2020          Added method for random string generation to be used as urlname.
 * Pooja                    23-09-2022          CodeScan Fixes
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestAddArticletoCaseController {


 static testmethod void testfindRecords() {
     String searchKey='Test';
     String objectName='Case';
     String searchField='CaseNumber,Subject';
     String queryFields='CaseNumber,Subject';
     AddArticletoCaseController.findRecords(searchKey,objectName,searchField,queryFields);
 }

 static testmethod void testattachCase() {
     knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle('test','Instrumentation','Software');
      insert newArticle;
      Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
       
      Contact con = TestDataPerson.getNewContact(objAccount.Id);
       Case objCase = TestDataCase.initNewCase('Service Request', 'Initiated', 'Phone - CS');

       objCase.ContactId = con.id;
     insert objCase;
     AddArticletoCaseController.attachCase(String.valueof(newArticle.id),String.valueof(objCase.id));
 }

}