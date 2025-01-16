/**
* @author Pooja Shalwadi
* @date 21-Aug-2021
* @group ContentDocument
* @description: This Test class is used to validate the functionality of trigger handler.
* Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*        Avina             28-Mar-2022       QACM-36, Created checkBeforeNotesDeletion method to test the functionality of trigger handler
*        Abhishek Yadav    13-Dec-2024       CMCM-12619, Created validateForRecallFilesDeletionThrowsError method to test the functionality of deltion of file
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestContentDocuments { 
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String CASE_ORIGIN = 'Phone - CP';//QACM-36 
    public static final String CASE_RECORDTYPE_NAME = 'Business Issue';//QACM-36 
    public static final String  CASE_STATUS = 'In Progress';//QACM-36
    static Case cs;

    /*******************************************************************************************************
    * @description: This method is used for initial data creation
    */
    @testSetup
    public static void initializeTestData()
    {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        //insert case        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
	
/*******************************************************************************************************
    * @description: This method is used to validate the error message fired when deleting an attachment
    * @param void
    * @return void
	* User Story: DCP-49741
*/
	@isTest
    static void validateForManualSignLOAs(){
        Boolean expectedExceptionThrown =false;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'test@gmail.com',
            Username = 'test@gmail.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        System.runAs(u){
            try
            {
                List<ContentVersion> contversionLst= new List<ContentVersion>();
                ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
                objCV.Document_Type_fileupload__c='Manual Signed LOA';
                contversionLst.add(objCV);
                insert contversionLst;
               
                //Get Content Documents
                Test.startTest();
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objCV.Id].ContentDocumentId;
                List<ContentDocument> contentDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE ID =:conDocId];               
                delete contentDocuments;
                Test.stopTest();
            }
            catch(Exception e)
            {
                expectedExceptionThrown =  (e.getMessage().contains(Label.ManualLOAErrorMessage)) ? true : false;
                
            }
            System.AssertEquals(true, expectedExceptionThrown);
        }
    }
/*******************************************************************************************************
* @author Avina
* @description: QACM-36 This method is used to validate the error message fired when deleting an notes associate with case
* @return void
*/
    @isTest
    static void checkBeforeNotesDeletion(){
        Boolean expectedExceptionThrown =false;
        Case caseRecord = TestDataCase.initNewCase(CASE_RECORDTYPE_NAME,CASE_STATUS,CASE_ORIGIN);
        caseRecord.Sub_Type__c = 'Complaint';
        caseRecord.Category__c = 'LIMS';
        caseRecord.Date_of_Issue_Awareness__c = Date.Today() -3;
        caseRecord.Awareness_Date_Difference_Reason__c ='Logistical delay';
        insert caseRecord;

        ContentNote contNote = new ContentNote();
        contNote.Content = Blob.valueOf('Sample Note Body');
        contNote.Title = 'Sample Note';
        insert contNote;
            
        ContentDocumentLink contentDoclink = new ContentDocumentLink();
        contentDoclink.ShareType = 'V';
        contentDoclink.Visibility = 'AllUsers'; 
        contentDoclink.ContentDocumentId = contNote.Id;
        contentDoclink.LinkedEntityId = caseRecord.Id;
        insert contentDoclink;    
        try{
            test.startTest();
            List<ContentDocument> lstConDoc = [select Id from ContentDocument where Id=:contNote.Id];
            delete lstConDoc;
            test.stopTest();
        }
        catch(Exception e){
            expectedExceptionThrown =  e.getMessage().contains(Label.RestrictNotesDeletionError) ? true : false;
        }
        System.Assert(expectedExceptionThrown, 'User has deleted the record');
    }
    /*******************************************************************************************************
    * @description: This method is used to validate the error message fired when deleting an attachment
    * @param void
    * @return void
	* User Story: CMCM-12619
    */
	@isTest
    static void validateForRecallFilesDeletionThrowsError() {
        Boolean expectedExceptionThrown = false;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'wick@gmail.com',
            Username = 'wick@gmail.com' + System.currentTimeMillis(),
            CompanyName = 'Illumina',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        System.runAs(u) {
            try {
                List<ContentVersion> contversionLst= new List<ContentVersion>();
                ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Picture.txt', 'Test data', true);
                objCV.IsRecallRelated__c = true;
                contversionLst.add(objCV);
                insert contversionLst;
               
                //Get Content Documents
                Test.startTest();
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objCV.Id].ContentDocumentId;
                List<ContentDocument> contentDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE ID =:conDocId];               
                delete contentDocuments;
                Test.stopTest();
            } catch(Exception e) {
                expectedExceptionThrown =  e.getMessage().contains(Label.preventRecallFileDelete) ? true : false;   
            }
            Assert.isTrue(expectedExceptionThrown == true,'expectedExceptionThrown should be true');
        }
    }
}