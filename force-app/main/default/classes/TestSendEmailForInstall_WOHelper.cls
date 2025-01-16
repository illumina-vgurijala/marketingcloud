/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for SendEmailForInstall_WOHelper
*/
@IsTest
private class TestSendEmailForInstall_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_TIMEZONE = 'America/Los_Angeles';


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
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
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
       
    }

    /**
    * Method: checkInstallationWOEmailNotification
    * Developer : Vignesh S
    * Description: Testmethod to check Installation Work Order Email Notification on assignment.
    * CreatedDate: 24-09-2019
    * DCP-28403
    * */
    static testMethod void checkInstallationWOEmailNotification(){
        Id profileId = [select id from profile where name='Channel Partner Sales and Service'].id;
          
        Account objAccount = TestDataAccount.initAccount();//TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;
        Contact cont = TestDataContact.getNewContact(objAccount);//TestDataPerson.getNewContact(null);
       
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;          
        User cSuser = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                               emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                               localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                               ContactId = cont.Id,
                               timezonesidkey=STRING_TIMEZONE, username=uniqueName + '@test' + orgId + '.org');
        insert cSuser;
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail1@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = cSuser.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Company__c=objAccount.id;
        insert objInstalledProduct;
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
        insert objLocation;
        
        List<SVMXC__Service_Order__c> lstWo= new List<SVMXC__Service_Order__c>();
        
        SVMXC__Service_Order__c objWorkOrderTwo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Assignment Accepted');
        objWorkOrderTwo.SVMXC__Product__c=objProduct.id;
        objWorkOrderTwo.SVMXC__Company__c = objAccount.Id;
        objWorkOrderTwo.Partner_Installation_WO__c = true;
        objWorkOrderTwo.SVMXC__Order_Type__c='Installation';
        objWorkOrderTwo.SVMXC__Component__c = objInstalledProduct.Id;
        objWorkOrderTwo.ERP_Order_Number__c='1234567';
        objWorkOrderTwo.ERP_Order_Line_Number__c='1234567_001';
        objWorkOrderTwo.ERP_Order_Line_Quantity__c=1;
        objWorkOrderTwo.Is_Auto_Created__c = true;
        objWorkOrderTwo.Partner_Installation_WO__c = true;
    
        SVMXC__Service_Order__c objInternalUserWO = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Assigned');
        objInternalUserWO.SVMXC__Product__c=objProduct.id;
        objInternalUserWO.SVMXC__Company__c = objAccount.Id;
        objInternalUserWO.SVMXC__Order_Type__c='Installation';
        objInternalUserWO.SVMXC__Component__c = objInstalledProduct.Id;
        objInternalUserWO.ERP_Order_Number__c='2345678';
        objInternalUserWO.ERP_Order_Line_Number__c='2345678_001';
        objInternalUserWO.ERP_Order_Line_Quantity__c=1;
        objInternalUserWO.Is_Auto_Created__c = true;
        objInternalUserWO.Partner_Installation_WO__c = false;
        
        objWorkOrderTwo.ownerId = cSuser.Id;
        objWorkOrderTwo.SVMXC__Group_Member__c = grpMembers.id;
        objWorkOrderTwo.SVMXC__Service_Group__c = serviceTeam.id;
        
        objInternalUserWO.ownerId = cSuser.Id;
        objInternalUserWO.SVMXC__Group_Member__c = grpMembers.id;
        objWorkOrderTwo.SVMXC__Service_Group__c = serviceTeam.id;
        
        lstWo.add(objWorkOrderTwo);
        lstWo.add(objInternalUserWO);
        
        Test.startTest(); 
        insert lstWo;
        System.debug('no.of queries executed 1:'+Limits.getQueries());
        
        Test.stopTest();
              
    }
}