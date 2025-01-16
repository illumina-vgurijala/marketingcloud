/*@ author       : Shaik Moulali
* @ date         : 10-04-2018
* @ Description  : Test class for Instructor Led Training Controller class
* @ SeeAllData   : This is set to true to get Users Account Information
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          10-04-2018                 US-4252             Initial version
* 
*/
@IsTest(SeeAllData=true)
public class TestInstructorLedTrainingController {

	/*
	* test method for InstructorLedTrainingController
	*/
    @IsTest		
    public static void testInstructorLedTraining (){
        List<Partner_Request__c> lstInsLedPartnerRequest = TestDataPartnerPortal.getNewPartnerRequestForInstructorLedTraining(1);
        List<Instructor_Training_Catalog__c> lstTrainingCatalog= TestDataPartnerPortal.getTrainingCatalogList(2);
      /*  User Objuser=[SELECT Id, Username, Contact.AccountId, ContactId, LastName, Email, Profile.Name, 
                      Profile.UserLicense.Name, Contact.Name, Contact.Email, Contact.Phone FROM User where IsPortalEnabled=true AND 
                      Profile.Name='Channel Partner Sales and Service' LIMIT 1];
      */  
        Id profileId = [select id from profile where name=: Label.Channel_Partner_Profile_Name].id;
       
        Account ac =TestDataAccount.initAccount();
        ac.Territory_Region__c = 'AMR';
        
        insert ac;
        Contact con =TestDataContact.getNewContact(ac);
       // insert con;  
                  
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User user = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');
       
        insert user;
       
        //perform the test
        Test.startTest();      
        System.runAs (user){
            //InstructorLedTrainingController.getRegion();
            insert lstInsLedPartnerRequest.get(0);
            InstructorLedTrainingController.saveTrainingCourses(lstInsLedPartnerRequest.get(0).Requested_Courses__c,
                                                                lstInsLedPartnerRequest.get(0).Timeframe_for_Attendance__c,
                                                                lstInsLedPartnerRequest.get(0).Course_Justification__c,
                                                               'Partner_request__c',
                                                               'Instructor-Led Training Request');
            List<Partner_Request__c> lstTrainingCourses = [SELECT Id from Partner_Request__c where Id= :lstInsLedPartnerRequest.get(0).Id]; 
            InstructorLedTrainingController.getTrainingList();
            System.assertEquals(1,lstTrainingCourses.Size()); 
            System.assertEquals(2,lstTrainingCatalog.Size());
            InstructorLedTrainingController.getListViewId('Account','Recently Viewed Accounts');    
        } 
        Test.stopTest(); 
    }
}