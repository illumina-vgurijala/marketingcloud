/*@ author       : Digvijay
* @ date         : 08-04-2019
* @ Description  : Test class for UserSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          10-04-2018                 US-4252             Initial version
* Deep Diwakar           16-04-2021                DCP- 45348   Added test for customer community user selector method. Also added test stop and start method.
* Gladis                 22-09-2022                Added test selector methods
*****************************************************************************************************************************************************
*/
@IsTest(SeeAllData=false)
global with sharing class TestUsersSelector{
public static final String PROFILE_ADMIN = 'System Administrator';
    @IsTest
		/*Test Data*/
    public static void testUserSelection(){

     Id profileId = [select id from profile where name=:PROFILE_ADMIN].id;
     String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User user = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,EmployeeNumber='65734678',

                timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');

        insert user;

        Set<Id> setUserId=new Set<Id>();
        setUserId.add(user.id);
        Set<String> setUser=new Set<String>();
        setUser.add(user.EmployeeNumber);

        UsersSelector  userSelectorObj=new UsersSelector();
        Schema.SObjectType sobj= userSelectorObj.getSObjectType();
        System.assertNotEquals(null,sobj);
        List<Schema.SObjectField> lstsobjectField=userSelectorObj.getSObjectFieldList();
        System.assert(lstsobjectField.size()>0);
        List<User>   lstuser=userSelectorObj.getLoggedInPortalUser(user.id);
        System.assert(lstuser.size()>0);
        lstuser=userSelectorObj.selectUserEmployeeNoById(setUserId);
        System.assert(lstuser.size()>0);
        lstuser=userSelectorObj.getUsersByEmpId(setUser);
        System.assert(lstuser.size()>0);
        lstuser=userSelectorObj.selectByUserId(setUserId);
        System.assert(lstuser.size()>0);
        userSelectorObj.activeUserNotInProfile(PROFILE_ADMIN,setUserId);
         userSelectorObj.selectUserIdFromProfiles(setUserId,new set<String>{PROFILE_ADMIN});
        userSelectorObj.getManagerId(user.EmployeeNumber,'test@gmail.com');
        userSelectorObj.returnUserProfileDetails(user.id,PROFILE_ADMIN);
        userSelectorObj.usersInProfile(PROFILE_ADMIN,setUserId,true);
        System.assertEquals(null,userSelectorObj.getPartnerUserAccId(setUserId)[0].AccountId);

        //Customer community user selector test
        List<User> userList = userSelectorObj.selectCustomerCommunityUsersByEmail('PowerCustomerSuccess', new Set<String>{User.email});
        // since test user is not of type 'PowerCustomerSuccess' then this query should return no records
        System.assertEquals(0, userList.size());
		string userId = user.id;
        userSelectorObj.getUniqueUsers(userId);
        userSelectorObj.selectUsersByActiveStatus(true);
    }

    /**
     *  @author Gladis
     *  @description - Test method to check getActivePartnerUserByContact
    **/
    static testMethod void testgetActivePartnerUserByContact(){
      
      Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
      acc.Account_Group__c= 'Distributor';
      insert acc;
      Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname' , AccountId = acc.Id);
      Test.startTest();
      List<User> lstUserAPUC = new UsersSelector().getActivePartnerUserByContact(new Set<Id>{con.Id});
      system.assert(!lstUserAPUC.isEmpty(), 'User APUC List Empty');
      Test.stopTest();
    }

    /**
     *  @author Gladis
     *  @description - Test method to check getActiveUsers
    **/
    static testMethod void testgetActiveUsers(){
      Test.startTest();
      List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service and IsActive = true LIMIT 1]; 
      List<User> lstActiveUsr = new UsersSelector().getActiveUsers(new Set<Id>{lstUsers[0].Id});
      system.assert(!lstActiveUsr.isEmpty(), 'Active User List Empty');
      Test.stopTest();
    } 
    
    /**
     *  @author Gladis
     *  @description - Test method to check selectUsersByNames
    **/
    static testMethod void testselectUsersByNames(){
      Test.startTest();
      List<User> lstUsrnames = new UsersSelector().selectUsersByNames(new Set<String>{'GIS Illumina'});
      system.assert(!lstUsrnames.isEmpty(), 'List Empty');
      Test.stopTest();
    }
}