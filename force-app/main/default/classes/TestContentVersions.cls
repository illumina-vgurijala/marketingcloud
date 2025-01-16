/***************************************************************************************************************************************
 * NAME         : TestContentVersions 
 * DESCRIPTION  : Test class for ContentVersions.
 * @AUTHOR      : Vignesh Sethuramalingam
 * @DATE        : 14-Mar-2022  
 *  
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                   DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vignesh Sethuramalingam   14-Mar-2022         Initial Version. 
 ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public class TestContentVersions {
  
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String STRING_ACCOUNT = 'Test Acc';
    static Case cs;

    /*******************************************************************************************************
    * @description: This method is used for initial data creation
    */
    @testSetup
    public static void initializeTestData(){
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
    
    /*
        * @description: This method is used to validate the error message fired when deleting an attachment
        * @param void
        * @return void
        * User Story: DCP-49741
    */
    @isTest
    static void checkFIleExtension(){
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
            List<ContentVersion> contversionLst= new List<ContentVersion>();
            ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txtxtxtxtxtxtxtxtEND', 'Test Content', true);
            objCV.Document_Type_fileupload__c='Manual Signed LOA';
            contversionLst.add(objCV);
            insert contversionLst;
           
            //Get Content Documents
            Test.startTest();
            String strPathOnClient = [SELECT ContentDocumentId,PathOnClient FROM ContentVersion WHERE Id =:objCV.Id].PathOnClient;
           
            Test.stopTest();
            System.assert(strPathOnClient != '', 'Path should not be blank');
        }
    }
    /*******************************************************************************************************
    * @description: This method is used to validate the error message fired when uploading new version an attachment
    * @param void
    * @return void
	* User Story: DCP-49741
    */
	@isTest
    static void validateForRecallFilesDeletionThrowsError() {
        Boolean expectedExceptionThrown = false;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'wickj@gmail.com',
            Username = 'wickj@gmail.com' + System.currentTimeMillis(),
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
                ContentVersion objContentVersion = TestDataFieldService.createDocVersion('test Data', 'Picture.txt', 'Test doc', false);
                objContentVersion.ContentDocumentId = conDocId;
                insert objContentVersion;
                Test.stopTest();
            } catch(Exception e) {
                expectedExceptionThrown =  e.getMessage().contains(Label.preventRecallFileDelete) ? true : false;   
            }
            Assert.isTrue(expectedExceptionThrown == true,'expectedExceptionThrown should be true');
        }
    }
}