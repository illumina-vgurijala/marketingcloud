/*
 * @author:         Sarath Pullanikkatt
 * @date:           12-10-2019
 * @description     Server controller for Community Self-Registration
 */
public without sharing class CommunitySelfRegistrationFormController {

    private static final String SELF_REG_ERROR_ILLUMINA_EMPLOYEE = Label.Comm_Self_Reg_Error_Illumina_Employee;
    private static final String SELF_REG_ERROR_INACTIVE_USER = Label.Comm_Self_Reg_Error_Inactive_User;
    private static final String SELF_REG_ERROR_ACTIVE_USER = Label.Comm_Self_Reg_Error_Active_User;
    private static final String SELF_REG_ERROR_MULTIPLE_CONTACTS = Label.Comm_Self_Reg_Error_Multiple_Contacts;
    private static final String SELF_REG_ERROR_EXTERNAL_USER_EXCEPTION = Label.Comm_Self_Reg_Error_External_User_Exception;
    private static final String SELF_REG_ERROR_GENERIC_EXCEPTION = Label.Comm_Self_Reg_Error_Generic_Exception;

    private static final String COMMUNITY_USER_TYPE = 'PowerCustomerSuccess';
    private static final String ILLUMINA_DOMAIN = '@illumina.com';
    private static final String SELF_REG_SUCCESS = 'Success';

    private static Id defaultCommunityAccountId = Label.Comm_Self_Reg_Default_Account_ID;

    /*
     * @author:         Sarath Pullanikkatt
     * @description:    Return the list of Countries configured in Salesforce State & Country Picklist Mappings.
     * @param:          None
     * @return:         Map of Country names
     */
    @AuraEnabled
    public static Map<String, String> getCountries() {

        Map<String, String> mapCountries = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Account.BillingCountrycode.getDescribe();
        List<Schema.PicklistEntry> lstPickListEntries = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry ple : lstPickListEntries)
            mapCountries.put(ple.getLabel(), ple.getValue());
        
        return mapCountries;
    }

    /*
     * @author:         Sarath Pullanikkatt
     * @description:    Perform Self-Registration. Used in LWC - communitySelfRegistrationForm
     * @param:          email address, first name, last name, title, location, preferred language and password.
     * @return:         A message 'Success' if the Self-Registration was successful. AuraHandledException in case of failures.
     */
    @AuraEnabled
    public static String registerCommunityUser(String strEmail, String strFirstName, String strLastName, String strTitle,
                                               String strLocation, String strPreferredLanguage, String strPassword) {
        strEmail = String.escapeSingleQuotes(strEmail);
        strFirstName = String.escapeSingleQuotes(strFirstName);
        strLastName = String.escapeSingleQuotes(strLastName);

        if(strEmail.containsIgnoreCase(ILLUMINA_DOMAIN))
            throw new AuraHandledException(SELF_REG_ERROR_ILLUMINA_EMPLOYEE);

        List<User> lstExistingUsers = [SELECT Id, Email, ContactId, UserType, IsActive, Contact.Email
                                       FROM User
                                       WHERE UserType = :COMMUNITY_USER_TYPE
                                             AND ContactId <> NULL
                                             AND (
                                                 Email = :strEmail
                                                 OR Contact.Email = :strEmail
                                             )
                                       LIMIT 1
                                      ];

        if(!lstExistingUsers.isEmpty()) {
            
            if(!lstExistingUsers[0].IsActive)
                throw new AuraHandledException(SELF_REG_ERROR_INACTIVE_USER);
            else
                throw new AuraHandledException(SELF_REG_ERROR_ACTIVE_USER);
        }
        else {
            
            List<Contact> lstExistingContacts = [SELECT Id, FirstName, LastName, Email, AccountId
                                                 FROM Contact
                                                 WHERE Email = :strEmail
                                                 LIMIT 1000];
            if(!lstExistingContacts.isEmpty()) {
                
                //Only 1 matching Contact for the provided email
                if(lstExistingContacts.size() == 1) {
                    defaultCommunityAccountId = lstExistingContacts[0].AccountId;
                }
                //Multiple contacts matching the provided the email
                else {
                    
                    Boolean blnMatchFound = false;
                    for(Contact c: lstExistingContacts) {
                        //See if the first name and last name for existing contact records match the information provided by user during sign-up process.
                        if(c.FirstName == strFirstName && c.LastName == strLastName && !blnMatchFound) {
                            blnMatchFound = true;
                            defaultCommunityAccountId = c.AccountId; //This would be the account we use for community self registration.
                            break;
                        }
                    }
                    //If we are unable to determine a unique contact to tie the customer's community login, redirect to community administrators.
                    if(!blnMatchFound)
                        throw new AuraHandledException(SELF_REG_ERROR_MULTIPLE_CONTACTS);
                }
            }
            
            //By now the appropriate account ID to initiate self registration process would be determined.
            //Initiate community user self registration
            String userId = initiateSelfRegistration(strEmail, strFirstName, strLastName, strTitle, strLocation, strPreferredLanguage, strPassword);

            return SELF_REG_SUCCESS;
        }
    }

    /*
     * @author:         Sarath Pullanikkatt
     * @description:    Invokes Salesforce Site.createExternalUser() method to perform Self-Registration.
     * @param:          email address, first name, last name, title, location, preferred language and password.
     * @return:         User ID if self-registration was successful. AuraHandledException in case of failures.
     */
    private static String initiateSelfRegistration(String strEmail, String strFirstName, String strLastName, String strTitle,
                                                   String strLocation, String strPreferredLanguage, String strPassword) {
        try {
            User newUser = new User();
            newUser.Username = strEmail;
            newUser.Email = strEmail;
            newUser.FirstName = strFirstName;
            newUser.LastName = strLastName;
            newUser.Title = strTitle;
            newUser.CountryCode = strLocation;
            newUser.LanguageLocaleKey = strPreferredLanguage;
            newUser.UserPreferencesHideS1BrowserUI = true;
            newUser.CommunityNickname = strFirstName.substring(0, 1) + strLastName.substring(0,strLastName.length() > 6 ? 6 : strLastName.length()) + String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            
            System.debug('Final DEFAULT_COMMUNITY_ACCOUNT_ID: ' + defaultCommunityAccountId);
            System.debug('User Information leading into Site.createExternalUser(): ' + newUser);

            return Site.createExternalUser(newUser, defaultCommunityAccountId, strPassword);
        }
        catch(Site.ExternalUserCreateException e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(SELF_REG_ERROR_EXTERNAL_USER_EXCEPTION);
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(SELF_REG_ERROR_GENERIC_EXCEPTION);
        }
    }
}