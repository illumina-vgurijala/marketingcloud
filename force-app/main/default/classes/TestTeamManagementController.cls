/*@ author       : Shaik Moulali
* @ date         : 10-04-2018
* @ Description  : Test class for Team Management controller class
* @ SeeAllData   : given values as true to fetch Account Information
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          10-04-2018                 US-4252             Initial version
* 
*/
@IsTest(SeeAllData=true)
public class TestTeamManagementController {
    @IsTest
	
		/*Test Data*/
    public static void testTeamManagement(){
        Id idExpectedRecordTypeId;
                
        List<Contact> lstContacts = TestDataPartnerPortal.getContactList(3);
        
        Id idRecordType = [SELECT Id, Name FROM RecordType 
                           WHERE sobjecttype = 'Partner_Request__c' 
                           AND Name = 'Portal Request - Add Team Member' LIMIT 1].Id;
         Id profileId = [select id from profile where name=: Label.Channel_Partner_Profile_Name].id;
       
        Account ac =TestDataAccount.initAccount();
         insert ac;
        Contact con =TestDataContact.getNewContact(ac);
       // insert con;  
                  
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        String uniqueName = orgId + dateString;

        User user = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');
       
        insert user;
        
        //perform the test
        Test.startTest();
        System.runAs (user){
            TeamManagementController.getUser();
            TeamManagementController.getContacts('Active');
            idExpectedRecordTypeId = TeamManagementController.getRecordTypeId('Partner_Request__c','Portal Request - Add Team Member');
        } 
        Test.stopTest(); 
        System.assertEquals(idExpectedRecordTypeId, idRecordType);
        System.assertEquals(3,lstContacts.Size());
    }
}