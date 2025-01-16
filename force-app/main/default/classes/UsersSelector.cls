/**
 * @author Vignesh S 
 * @description  Query Selector for User Object.
 * @TestClasses:  TestUsersSelector
 * Modification Log:
*  ------------------------------------------------------------------------------------
*   Developer                Date                Description
*   Vignesh S                12-Feb-2019         DCP-31443 : Adding method to query User with permission set.
*   B Kamini                 21-Feb-2020         DCP-34092: Added Profile name select field in selectByUserId
*   KD                       11-Nov-2020         DCP-42122 : Sharing of CP Quota
*   Deep Diwakar             16-April-2021       DCP-45348: Added customer community user selector method
*   Satya Swain              27-April-2021       INC0317595 : changed getManagerId() to get records based on federation Identifier.
*   Adyasha Satapathy        07-May-2021         DCP-38809, DCP-39763: Added method selectUsersByNames
*   Sagar Madkaikar          13-Sep-2021         CMCP-22:Added field in SOQL of selectByUserId() method. Added Query Instrumentation
*   Satya Swain              26-09-2021          TASK0644781: Added selectUsersByActiveStatus
*   Gladis                   20-Sep-2022         Added Query Instrumentation
*  -----------------------------------------------------------------------------------
*/
public with sharing class UsersSelector extends ilib_SObjectSelector {

    private static final string  LOG_TITLE = 'UsersSelector';//CMCP-22
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';//CMCP-22
      /**
     *  @author 
     *  @description : Initialization of the User object
     *  @return SObjectType The Schema.SObjectType of the proposal
     */
    public Schema.SObjectType getSObjectType()
    {
        return User.sObjectType;
    }
     /**

     *  @author  Ritika Maheshwari
     *  @description Retrieve list of fields for User sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           User.Id,
           User.Name,
           User.Email,
           User.Title,
           User.EmployeeNumber,
           User.Username,
           User.Contact.AccountId,
           User.LastName,
           User.Profile.Name,
           User.Profile.UserLicense.Name,
           User.Contact.Name,
           User.Contact.Phone,
           User.Contact.Email,
           User.ProfileId,
           User.Manager_Email__c,
           //DCP-27444: Add AD field
           User.AD_userName__c,
           User.AccountId
       };
    }

    /**
     * Queries for all users in "profileName".
     * Can exclude users from results and filter on active/not
     *
     * USAGE
     * List<User> usersInProfile = new UsersSelector().usersInProfile(Profiles.SYSTEM_ADMINISTRATOR, new Set<Id> { UserInfo.getUserId() }, true);
     *
     * @author Todd Newman
     * @param profileName  Profile name to look for users (hint: use constants in Profiles.cls)
     * @param otherThanIds Users to exclude from the results (often used to exclude the running user)
     * @param isActive     Whether to search for inactive or active users
     * @return List<User>  Query results
     **/
    public List<User> usersInProfile(String profileName, Set<Id> otherThanIds, Boolean isActive)
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.usersInProfile', UtilsCollection.serializeIds(otherThanIds));
        }
            List<User> res = (List<User>) Database.query(
            newQueryFactory(true)
            .setCondition('Profile.Name = :profileName AND IsActive = :isActive AND Id NOT IN :otherThanIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /**
     * Returns a user who is not in "profileName"
     * Can exclude users from results
     *
     * USAGE
     * List<User> userNotInProfile = new UsersSelector().activeUserNotInProfile(Profiles.SYSTEM_ADMINISTRATOR, new Set<Id>());
     *
     * @author Todd Newman
     * @param profileName  Profile name to look for users (hint: use constants in Profiles.cls)
     * @param otherThanIds Users to exclude from the results (often used to exclude the running user)
     * @return List<User>  A user who is not in the profile name passed
     **/
    public List<User> activeUserNotInProfile(String profileName, Set<Id> otherThanIds)
    {
        String standardUserType = 'Standard';
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.activeUserNotInProfile', UtilsCollection.serializeIds(otherThanIds));
        }    
        List<User> res = (List<User>) Database.query(
            newQueryFactory(true)
            .setCondition('Id NOT IN :otherThanIds')
            .setCondition('UserType = :standardUserType')
            .setCondition('Profile.Name != :profileName')
            .setLimit(1)
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /* @author Govind Dubey
     * @param set of User Ids
     * @return List of User
     **/
   public List<User> selectByUserId(Set<Id> setUserIds)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByUserId', UtilsCollection.serializeIds(setUserIds));
        }    
            List<User> res = (List<User>) Database.query(
            newQueryFactory()
            //Refactor PB :: Parts_Order_Populate_User_Related_Fields
            .selectField('ManagerId')
            .selectField('Manager.ProfileId')
            .selectField('Manager.IsActive')
            .selectField('Manager.ManagerId')
            .selectField('Manager.DelegatedApproverId')//Added for DCP-37395
            .selectField('Manager.Out_of_Office__c')//Added for DCP-37395
            .selectField('contact.AccountId')
            .selectField('Profile.Name')//Added DCP-34092
            .selectField('UserType')
            .selectField('Signature')//Added for DCP-33497
            .selectField('DelegatedApproverId')//Added for DCP-37395
            .selectField('Out_of_Office__c')//Added for DCP-37395
            .selectField('IsPortalEnabled')
            .selectField('EmployeeNumber')
            .selectField('AccountId')
            .selectField('User_Profile_Name__c') //CMCP-13
            .selectField('IsActive')
            .selectField('Contact.Account.Territory_Region__c')//POL-190
            .selectField('Contact.Account.SVMX_PS_Location__r.ERP_Customer_ID__c')//CMCP-22
            .setCondition('Id IN :setUserIds').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - Fetch users with employee numbers by passing in the set of user ids.
     *  @PARAM : Set of user IDs.
     *  @RETURN : List of users
     **/
    public List<User> selectUserEmployeeNoById(Set<Id> setUserIds)
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUserEmployeeNoById', UtilsCollection.serializeIds(setUserIds));
        }    
            List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .selectField('IsPortalEnabled')
            .selectField('id')
            .selectField('EmployeeNumber')
            .selectField('Contact.AccountId')
            .setCondition('Id IN :setUserIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /*
     * @Author : Sravan Panchangam
     * @Description:Fetch the list of Users who by employee id
    */
    public List<User> getUsersByEmpId(set<String> employeeNumber){
        Boolean isActive=true;
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getUsersByEmpId', UtilsCollection.serializeIds(employeeNumber));
        }    
            List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('EmployeeNumber IN :employeeNumber')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }


    /*
    * @Author : Vignesh Sethuramalingam
    * @Description: Method to fetch User's AccountId for partner users.
    */
    public List<User> getPartnerUserAccId(set<Id> setPartnerOwnerId) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getPartnerUserAccId', UtilsCollection.serializeIds(setPartnerOwnerId));
        }    
        List<User> res = (List<User>) Database.query(
        newQueryFactory().selectField('id').selectField('AccountId')
        .setCondition('ID IN : setPartnerOwnerId')
        .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

   /* @author Prakhar Kumar
     * @return List of Portal Users
     **/
    public List<User> getLoggedInPortalUser(String strID)
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getLoggedInPortalUser', strID);
        }
        ilib_QueryFactory query = newQueryFactory();
            query.setCondition('Id = :strID');
            String strQuery = query.selectField('id')
                                   .selectField('FirstName')
                                   .selectField('City')
                                   .selectField('Phone')
                                   .selectField('Username')
                                   .selectField('Contact.AccountId')
                                   .selectField('Contact.Account.Territory_Code__c')
                                   .selectField('LastName')
                                   .selectField('Email')
                                   .selectField('IsPortalEnabled')
                                   .toSOQL();
                                   system.debug('UsersSelector==='+strQuery);
        List<User> res = (List<User>) Database.query( strQuery);
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
     /* @author Soumya Sahu
     * @param set of User Ids
     * @return List of User
     * DCP-30843
     **/
    public List<User> selectUserIdFromProfiles(Set<Id> setUserIds,set<string> setProfileNames)
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUserIdFromProfiles', UtilsCollection.serializeIds(setUserIds));
        }    
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('Id IN :setUserIds AND Profile.Name IN :setProfileNames AND IsActive = true')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /* @author     : Vignesh S
     * @param      : User Ids
     * @return     : User Record
     * @Description: Method that returns user details with Permission set assigned to the user.
     **/
    public User returnUserProfileDetails(Id userId, string permissionSetName){
        ilib_QueryFactory userQuery = newQueryFactory();
        userQuery.selectField('Profile.Name');

        ilib_QueryFactory permissionSetAssignmentSubQuery = new PermissionSetAssignmentsSelector()
        .addQueryFactorySubselect(userQuery,'PermissionSetAssignments');

        permissionSetAssignmentSubQuery.setCondition('Permissionset.Name = :permissionSetName');

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.returnUserProfileDetails', permissionSetName);
        }    
        User res = (user)Database.query(userQuery.setCondition('Id = :UserId').toSOQL());
        
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(1);
        }

        return res;

    }
    /* @author     : Satya Swain
     * @param      : String federationId, String managerEmail
     * @return     : List Of User Records
     * @Description: Method that returns manager records based on federation records and manager email
     **/
    public List<User> getManagerId(String federationId, String managerEmail) 
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getManagerId', federationId);
        }    
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .selectField('Id')
            //changed to FederationIdentifier from EmployeeNumber as part of INC0317595
            .setCondition('FederationIdentifier =: federationId and Email =: managerEmail')
            .setLimit(100).toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /**
    * @description To check if User is Licensed For Package
    * @author 
    * @param packageNamespace 
    * @param userId 
    * @return Boolean 
    **/
    public Boolean isUserLicensedForPackage(String packageNamespace, String userId)
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.isUserLicensedForPackage',userId);
        }    
        Boolean res= [
            SELECT count()
            FROM UserPackageLicense
            WHERE PackageLicense.NamespacePrefix = :packageNamespace
            AND UserId = :userId
            LIMIT 1
        ] == 1;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(1);
        }

        return res;
    }
    /* @author     : KD
     * @param      : Set of Account Id
     * @return     : User Record
     * @Description: Method that returns active user details for account
     **/
    public List<User> getAssociatedPartnerUser(Set<Id> setAccountId) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getAssociatedPartnerUser', UtilsCollection.serializeIds(setAccountId));
        }    
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .selectField('contact.AccountId')
            .setCondition('contact.AccountId IN :setAccountId AND IsActive = true').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /* @author     : KD
     * @param      : Set of Contact Id
     * @return     : User Record
     * @Description: Method that returns active user details for contact
     **/
    public List<User> getActivePartnerUserByContact(Set<Id> setContactId) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getActivePartnerUserByContact', UtilsCollection.serializeIds(setContactId));
        }    
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('contactId IN :setContactId AND IsActive = true').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
     /* @author     : KD
     * @param      : Set of Contact Id
     * @return     : User Record
     * @Description: Method that returns active user details
     **/
    public List<User> getActiveUsers(Set<Id> setUserId) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getActiveUsers', UtilsCollection.serializeIds(setUserId));
        }    
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('Id IN :setUserId AND IsActive = true').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

/* @author     : Vaibhav
 * @param      : User Unique Id
 * @return     : User Record
 * @Description: DCP-42718 - Method that returns unique user details
 **/
public List<User> getUniqueUsers(string uniqueId) {

    ilib_LogQuery logger = null;
    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
        logger = new ilib_LogQuery(LOG_TITLE + '.getUniqueUsers', uniqueId);
    }    
    List<User> res = (List<User>) Database.query(
        newQueryFactory()
        .selectField('Unique_Id__c')
        .setCondition('Unique_Id__c = :uniqueId AND IsActive = true').toSOQL()
    );

    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
        logger.stop(res.size());
    }    
    return res;
}

/* @author     : Vaibhav
 * @param      : CP User Federation Id
 * @return     : User Record
 * @Description: DCP-43152 - Method that returns unique cp user details by federation id
 **/
public List<User> getCPUniqueUsersByFederationId(string uniqueId) {

    ilib_LogQuery logger = null;
    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
        logger = new ilib_LogQuery(LOG_TITLE + '.getCPUniqueUsersByFederationId', uniqueId);
    }    
    List<User> res = (List<User>) Database.query(
        newQueryFactory()
        .selectField('FederationIdentifier')
        .setCondition('FederationIdentifier = :uniqueId AND IsActive = true').toSOQL()
    );

    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
        logger.stop(res.size());
    }    

    return res;
}

  /**
  * @author     : Deep Diwakar
  * @param userType : userType
  * @param email : email
  * @return : List of user records
  * @Description: Method that returns list of users for customer community specific fields using
                  email id as filter criteria.
  **/
  public List<User> selectCustomerCommunityUsersByEmail(String userType, Set<String> emailSet) {
    
    ilib_LogQuery logger = null;
    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
        logger = new ilib_LogQuery(LOG_TITLE + '.selectCustomerCommunityUsersByEmail', userType);
    }    
    List<User> res = (List<User>) Database.query(newQueryFactory(false)
                  .selectField('Id')
                  .selectField('FirstName')
                  .selectField('LastName')
                  .selectField('Email')
                  .selectField('ContactId')
                  .selectField('UserType')
                  .selectField('UserName')
                  .selectField('IsActive')
                  .selectField('Contact.Email')
                  .selectField('Contact.PGUID__c')
                  .setCondition('UserType =: userType AND (Email IN :emailSet OR Contact.Email IN :emailSet)').toSOQL());

    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
        logger.stop(res.size());
    }

    return res;              

}


    /**
     *  @AUTHOR Adyasha Satapathy
     *  @DESCRIPTION - Fetch users based on set of User Names
     *  @PARAM : Set of user names.
     *  @RETURN : List of users
     **/
    public List<User> selectUsersByNames(Set<String> setUserNames)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUsersByNames', UtilsCollection.serializeIds(setUserNames));
        }
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('Name IN :setUserNames')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }    

        return res;
    }

    /** @author Satya Swain
    *   @param isActive     Whether to search for inactive or active users
    *   @return List<User>  Query results
    **/
    public List<User> selectUsersByActiveStatus(Boolean isActive)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUsersByActiveStatus');
        }
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('IsActive = :isActive')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
        /** @author Kumar Gaurav
    *   @param Set<Id>   
    *   @return List<User>  Query results
    **/
    public List<User> selectUserByIds(Set<Id> userIds)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.SelectUserByIds');
        }
        List<User> res = (List<User>) Database.query(
            newQueryFactory()
            .setCondition('IsActive = :isActive')
            .selectField('Id')
            .selectField('Profile.Name')
            .selectField('User_Profile_Name__c')
            .selectField('IsActive')
            .setCondition('Id IN :userIds')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
}