/***
 * @actor illumina
 * @decription:
 */
@isTest
public with sharing class TestDataUser {

    public final static String PROFILE_SALES_REP = 'Sales User';
    public final static String PROFILE_FIELD_SERVICE = 'Field Service';
    public final static String PROFILE_ADMIN = 'System Administrator';
    public final static String PROFILE_CHANNEL = 'Channel Partner Service';
    public final static String PROFILE_CUSTOMER_SERVICE = 'Customer Service';
    public final static String PROFILE_COMMERCIAL_OPS_QUOTING_USER = 'Commercial Ops Quoting User';
    public final static String PROFILE_COMMERCIAL_REVENUE_OPERATIONS = 'Commercial and Revenue Operations';
    public final static String PROFILE_FAST_TRACK_SERVICES = 'Fast Track Services';
    public final static String PROFILE_INTEGRATION_SNAP_SALES ='Integration Sales SnapLogic';

    public final static String ROLE_AMR_SALES = 'AMR Sales';

    public final static String PERMISSIONSET_MANAGE_PARTNER_PORTAL_USERS = 'Manage_Partner_Portal_Users';
    
    /**
    * @actor illumina
    * @decription:
    */
    public static void allowUserCreation()
    {
        insert new cs_Apex_Settings__c(Modify_Users__c = true);
    }
    /**
     *  @author   
     *  @description static method to allow user creation
     *  @param Id userId
     *  @return NA 
     **/
    public static void allowUserCreation(Id userId)
    { 
        cs_Apex_Settings__c c = cs_Apex_Settings__c.getInstance(userId);
        c.SetupOwnerId = userId;
        c.Modify_Users__c = true;
        upsert c;
    }
    /**
     *  @author   
     *  @description static method to find the user in profilename
     *  @param String profileName
     *  @return NA 
     **/
    public static User findUserInProfile(String profileName)
    {
        return findUserInProfile(profileName, new Set<Id>(), true);
    }
    /**
     *  @author   
     *  @description static method to find the user in profilename
     *  @param String profileName, Set<Id> otherThanIds
     *  @return User
     **/
    public static User findUserInProfile(String profileName, Set<Id> otherThanIds)
    {
        return findUserInProfile(profileName, otherThanIds, true);
    }
    /**
     *  @author   
     *  @description static method to find the user in profilename
     *  @param String profileName, Set<Id> otherThanIds , Boolean isActive
     *  @return User 
     **/
    public static User findUserInProfile(String profileName, Set<Id> otherThanIds, Boolean isActive)
    {
        List<User> usersInProfile = new UsersSelector().usersInProfile(profileName, otherThanIds, isActive);
        
        if (usersInProfile.isEmpty()) return null;
        return usersInProfile.get(0);
    }
    /**
     *  @author   
     *  @description static method
     *  @param String profileName , Set<Id> otherThanIds
     *  @return User
     **/
    public static User findUserNotInProfile(String profileName, Set<Id> otherThanIds)
    {
        List<User> usersNotInProfile = new UsersSelector().activeUserNotInProfile(profileName, otherThanIds);
        
        if (usersNotInProfile.isEmpty()) return null;
        return usersNotInProfile.get(0);
    }
    /**
     *  @author   
     *  @description static method initPartnerUser
     *  @param Id profileId, Id contactId
     *  @return User 
     **/
    public static User initPartnerUser(Id profileId, Id contactId)
    {
        String firstName = TestData.getRandom(4);
        String lastName = TestData.getRandom();

        User u = new User(
            Alias = firstName,
            Email = firstName + '@test.org',
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            Country = 'USA',
            IsActive = true,
            PortalRole = 'Manager',
            ContactId = contactId,
            TimezoneSidKey = 'America/Los_Angeles',
            Username = firstName + '@test.' + lastName
        );
        return u;
    }
    /**
     *  @author   
     *  @description static method initStandardUser
     *  @param Id profileId
     *  @return User 
     **/
    public static User initStandardUser(Id profileId)
    {
        String firstName = TestData.getRandom(4);
        String lastName = TestData.getRandom();

        User u = new User(
            Alias = firstName,
            Email = firstName + '@test.org',
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            IsActive = true,
            UserRoleId = '00E1N000001ehJt',
            FederationIdentifier = '0000000',
            TimezoneSidKey = 'America/Los_Angeles',
            Username = firstName + '@test.' + lastName
        );
        return u;
    }

    /**
     *  @author ereyes
     *  @description static method initStandardInternalUser
     *  @param Id profileId
     *  @return User 
     **/
    public static User initStandardInternalUser(Id profileId, Id roleId)
    {
        String firstName = TestData.getRandom(4);
        String lastName = TestData.getRandom();
        String federationId = TestData.getRandom(4);

        User u = new User(
            Alias = firstName,
            Email = firstName + '@illumina.com',
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            IsActive = true,
            UserRoleId = roleId,
            FederationIdentifier = federationId,
            TimezoneSidKey = 'America/Los_Angeles',
            Username = firstName + '@test.' + lastName
        );
        return u;
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method updates user in future
    *  @PARAM :  String COntact is
    *  @RETURN:  
    */
    @future
    public static void updateUserDetailsFuture(String strContactId,String strFirstName){
        //String PROFILE_CHANNEL = 'Channel Partner Sales';
        Id profileId = [SELECT Id FROM Profile WHERE Name = :TestDataUser.PROFILE_CHANNEL].Id;
        User channelUser1 = TestDataUser.initPartnerUser(profileId, strContactId);
        channelUser1.FirstName = strFirstName;
        insert channelUser1;
    }

    /**
     * @author Gerardo Garcia
     * @description Gets Automated User
     * @return User
     */
    public static User getAutomatedUser() {
        return [SELECT Id FROM User WHERE alias = 'autoproc'];
    }

    /**
     * @author Gerardo Garcia
     * @description init admin user
     * @return User
     */
    public static User initAdminUser() {
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = :TestDataUser.PROFILE_ADMIN].Id;
        return initStandardUser(adminProfileId);
    }

    /**
     * @author Gerardo Garcia
     * @description getsUser
     * @return Map of profiles name->id
     */
    public static Map<String, String> getProfilesIds(Set<String> profileNames) {
        List<Profile> profiles = new ProfilesSelector().getProfileByName(profileNames);
        Map<String, String> mapProfiles = UtilsObject.getMapOfStringToString(profiles, 'Name', 'id');
        return mapProfiles;
    }
}