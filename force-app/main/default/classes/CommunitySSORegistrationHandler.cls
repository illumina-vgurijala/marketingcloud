/*
 * @author:         Deep Diwakar
 * @date:           03-31-2021
 * @description     Customer Community Registation Handler to enable SSO login using Platform as identity provider
 * Test Class for 75% Coverage : TestCommunitySSORegistrationHandler
 * Test Class for 90% Coverage : TestCommunitySSORegistrationHandler
 * @modification    Anshaj Sinha            05-09-2022           CMSI-214 - Instrumented Class for ilib_LogEvent Framework
 */
global class CommunitySSORegistrationHandler implements Auth.RegistrationHandler {

    // pulling up labels
    private static final String CUSTOMER_COMMUNITY_SUFFIX = Label.Comm_SSO_Username_Suffix;
    private static final String DEFAULT_ACCOUNTNAME = Label.Comm_SSO_Default_Account_Name;
    private static final String EXTERNAL_USER_PROFILE = Label.Comm_SSO_External_User_Profile;
    private static final String EXTERNAL_USER_DEFAULT_LOCALE = Label.Comm_SSO_Locale;
    private static final String EXTERNAL_USER_DEFAULT_TIMEZONE = Label.Comm_SSO_Timezone;
    private static final String EXTERNAL_USER_DEFAULT_LANGUAGE = Label.Comm_SSO_Default_Language;
    private static final String EXTERNAL_USER_DEFAULT_EMAIL_ENCODING = Label.Comm_SSO_EmailEncoding;


    // Following labels are passed as string and its actual value is pulled in LWC component to show different info/error messages.
    // If we directly pass label values in the URL then spaces, special characters etc. get encoded.
    private static final String COMM_SSO_ERROR_ILLUMINA_EMPLOYEE = 'Comm_SSO_Error_Illumina_Employee';
    private static final String COMM_SSO_ERROR_GENERIC_EXCEPTION = 'Comm_SSO_Error_Generic_Exception';
    private static final String COMM_SSO_ERROR_INACTIVE_USER = 'Comm_SSO_Error_Inactive_User';
    private static final String COMM_SSO_ERROR_MULTIPLE_USER_OR_CONTACT = 'Comm_SSO_Error_Multiple_User_Or_Contact';

    private static final String ILLUMINA_DOMAIN = '@illumina.com';
    private static final String CUSTOMER_COMMUNITY_USER_TYPE = 'PowerCustomerSuccess';
    private static final Integer ONE = 1;
    private static final Integer EIGHT = 8;
    private static final String LOG_TITLE = 'CommunitySSORegistrationHandler';



    /**
    * @author     : Deep Diwakar
    * @param      : Auth provider user data coming from platform
    * @return     : True/false
    * @Description: This method checks if we have all the necessary info to proceed further with user creation/login
    */
    private boolean canCreateUser(Auth.UserData data) {
        ilib_LogEvent.info('canCreateUser was called for ' + (data != null ? data.email : 'null'));


        Boolean result = false;

        if (data != null && !String.isBlank(data.email)
            && !String.isBlank(data.lastname) && !String.isBlank(data.firstname)
                && !String.isBlank(data.attributeMap.get('addr_country'))) {

                    result = true;
        }
        ilib_LogEvent.info('Returning value of result : '+result);
        return result;
    }

    /**
    *
    * @author: Deep Diwakar
    * @param portalId  - Id of the Community
    * @param data - Auth Provider user data describing the User to create
    * @return User that has been initialized
    * @description: Create the User - A required method to implement the Handler Interface
    **/

    global User createUser(Id portalId, Auth.UserData data) {

        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.createUser()');
        User communityUser;

        try {

            // spitting out input received from platform
            ilib_LogEvent.info('portalId : '+portalId);
            ilib_LogEvent.info('data : '+data);

            // spitting out attribute map received from platform
            for(String str:data.attributeMap.keyset()) {
                ilib_LogEvent.message('Key: ' + str + 'Value: ' + data.attributeMap.get(str));
            }

            // if required fields are null or empty then throw exception
            if(!canCreateUser(data)) {
                ilib_LogEvent.error('User info coming form platform has null or empty values!');
                throw new CommSSORegHandlerException(COMM_SSO_ERROR_GENERIC_EXCEPTION);
            }


            // sanitize input data
            String plfPguid=String.escapeSingleQuotes(data.identifier);
            String plfFirstName = String.escapeSingleQuotes(data.firstName);
            String plfLastName = String.escapeSingleQuotes(data.lastName);
            String plfEmail = String.escapeSingleQuotes(data.email);
            String plfCountry = String.escapeSingleQuotes(data.attributeMap.get('addr_country'));

            PlatformUserDataWrapper plfDataWrapper = new PlatformUserDataWrapper(plfFirstName, plfLastName, plfEmail, plfPguid, plfCountry);

            List<User> extUserList = new List<User>();

            Contact communityContact = null;

            // if internal user, then inform to follow different process
            if(plfEmail.containsIgnoreCase(ILLUMINA_DOMAIN)) {
                throw new CommSSORegHandlerException(COMM_SSO_ERROR_ILLUMINA_EMPLOYEE);
            }

            Set<String> emailSet = new Set<String>();
            emailSet.add(plfEmail);

            // get users based on email
            extUserList = new UsersSelector().selectCustomerCommunityUsersByEmail(CUSTOMER_COMMUNITY_USER_TYPE, emailSet);

            ilib_LogEvent.info('extUserList: ' + extUserList);
            ilib_LogEvent.info('extUserList.size(): ' + extUserList.size());

            if (extUserList.size() > 0) {
                communityUser = findExistingCommunityUser(extUserList, plfFirstName, plfLastName, plfPguid);
                ilib_LogEvent.info('Inside if block -> update username to add customer community suffix');
                // update username to add customer community suffix
                updateUserSuffix(communityUser);
                ilib_LogEvent.info('Returning Community User : '+communityUser);
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return communityUser;

            } else {
                // query contact object with email
                List<Contact> extContactList = new ContactsSelector().selectCustomerCommunityContactsByEmail(emailSet);

                if (extContactList.size() > 0) {
                    communityContact = findCommunityContact(extContactList, plffirstName, plflastName, plfPguid);
                }

            }

            ilib_LogEvent.info('existing contact : ' + communityContact);

            // if no contact found, then create new contact
            if (communityContact == null) {
                ilib_LogEvent.info('creating new contact');
                communityContact = createCommunityContact(plfFirstName, plfLastName, plfEmail);
            }


            ilib_LogEvent.info('creating new user');

            communityUser = createCommunityUser(plfDataWrapper, communityContact);

            ilib_LogEvent.info('user id of new community user : ' + communityUser.Id);


        } catch(CommSSORegHandlerException ex) {
            ilib_LogEvent.error('Exception encountered: ' + ex);
            ilib_LogEvent.error('Exception message: ' + ex.getMessage());
            ApexExceptions.emit('CommunitySSORegistrationHandler', ex, ilib_LogEvent.MARKETING);
            throw ex;

        } catch(Exception ex) {
            ilib_LogEvent.error('Exception encountered: ' + ex);
            ilib_LogEvent.error('Exception message: ' + ex.getMessage());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            ApexExceptions.emit('CommunitySSORegistrationHandler', ex, ilib_LogEvent.MARKETING);
            throw new CommSSORegHandlerException(COMM_SSO_ERROR_GENERIC_EXCEPTION);

        }
        ilib_LogEvent.info('Returning Community User : '+communityUser);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return communityUser;

    }

    /**
     * @author: Deep Diwakar
     * @param: user object to be updated
     * @return:  none
     * @description: This method udpates user object record with community suffix
     */
    private void updateUserSuffix(User commUser) {
        ilib_LogEvent.push(LOG_TITLE + '.updateUserSuffix()');
        String currentUserName = commUser.username;

        if (!String.isBlank(currentUserName) && !currentUserName.endsWithIgnoreCase(CUSTOMER_COMMUNITY_SUFFIX)) {
            // add customer community suffix
            commUser.username = commUser.username + CUSTOMER_COMMUNITY_SUFFIX;
            update commUser;
            ilib_LogEvent.info('commUser : '+commUser);
        }

        ilib_LogEvent.pop();
    }

    /**
     * @author: Deep Diwakar
     * @param extContactList: contact list with matching email
     * @param plfFirstName: platform sent user first name
     * @param plfLastName: platform sent user last name
     * @param plfPguid: platform sent user pguid
     * @return:  unique contact or exception
     * @description: This method tries to find unique contact based on info sent by platform
     */
    private Contact findCommunityContact(List<Contact> extContactList, String plfFirstName, String plfLastName, String plfPguid) {
        ilib_LogEvent.push(LOG_TITLE + '.findCommunityContact()');
        Contact communityContact = null;

        if (extContactList.size() == ONE && String.isBlank(extContactList.get(0).Partner_Portal_Status__c)) {
            communityContact = extContactList.get(0);

        } else {
            for (Contact cont : extContactList) {
                // check for PGUID match first
                if (String.isBlank(cont.Partner_Portal_Status__c) && !String.isBlank(cont.PGUID__c) && cont.PGUID__c.equalsIgnoreCase(plfPguid)) {
                    communityContact = cont;
                    break;
                }

                // check if FN and LN match
                if (String.isBlank(cont.Partner_Portal_Status__c) && !String.isBlank(cont.FirstName) && cont.FirstName.equalsIgnoreCase(plfFirstName) &&
                        !String.isBlank(cont.LastName) && cont.LastName.equalsIgnoreCase(plfLastName)) {
                            communityContact = cont;
                            break;
                }


            }

            if (communityContact == null && extContactList.size() > ONE) {
                throw new CommSSORegHandlerException(COMM_SSO_ERROR_MULTIPLE_USER_OR_CONTACT);

            }

        }
        ilib_LogEvent.info('Returning Community User : '+communityContact);
        ilib_LogEvent.pop();
        return communityContact;

    }

    /**
     * @author: Deep Diwakar
     * @param extUserList: user list with matching email
     * @param plfFirstName: platform sent user first name
     * @param plfLastName: platform sent user last name
     * @param plfPguid: platform sent user pguid
     * @return:  unique user or exception
     * @description: This method tries to find unique user based on info sent by platform
     */
    private User findExistingCommunityUser(List<User> extUserList, String plfFirstName, String plfLastName, String plfPguid) {
        ilib_LogEvent.push(LOG_TITLE + '.findExistingCommunityUser()');
        ilib_LogEvent.info('First Name : '+plfFirstName + 'Last Name : '+plfLastName);
        User extUser = null;

        if (extUserList.size() == ONE) {
            if (extUserList.get(0).isActive) {
                extUser = extUserList.get(0);
            } else {
                throw new CommSSORegHandlerException(COMM_SSO_ERROR_INACTIVE_USER);
            }


        } else {
            // filter based on PGUID, FN and LN
            for (User usr : extUserList) {
                ilib_LogEvent.message('usr : '+usr);
                // check if PGUID match
                if (!String.isBlank(usr.Contact.PGUID__c) && usr.Contact.PGUID__c.equalsIgnoreCase(plfPguid)) {
                    if (usr.isActive) {
                        extUser = usr;
                        break;
                    } else {
                        throw new CommSSORegHandlerException(COMM_SSO_ERROR_INACTIVE_USER);

                    }

                }

                // check if FN and LN match
                if (!String.isBlank(usr.FirstName) && usr.FirstName.equalsIgnoreCase(plfFirstName) &&
                        !String.isBlank(usr.LastName) && usr.LastName.equalsIgnoreCase(plfLastName)) {
                            if (usr.isActive) {
                                extUser = usr;
                                break;
                            } else {
                                throw new CommSSORegHandlerException(COMM_SSO_ERROR_INACTIVE_USER);

                            }
                }

            }

            // if we have reached here, it means there are multiple users with this email and we are not able to determin correct user
            if (extUser == null && extUserList.size() > ONE) {
                throw new CommSSORegHandlerException(COMM_SSO_ERROR_MULTIPLE_USER_OR_CONTACT);

            }
        }
        ilib_LogEvent.info('Returning extUser : '+extUser);
        ilib_LogEvent.pop();
        return extUser;


    }


    /**
     * @author: Deep Diwakar
     * @param userId: id of the user who is logging in
     * @param portalId  - Id of the Community
     * @param data - Auth Provider user data describing the User to create
     * @return:  none
     * @description: Update the User - A required method to implement the Handler Interface. This method logs in user who had logged in prior with this process
     */

    global void  updateUser(Id userId, Id portalId, Auth.UserData data) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.updateUser()');
        ilib_LogEvent.info('Update User method called - Already logged in user login again');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }


    /**
     * @author: Deep Diwakar
     * @param firstName: first name of the contact to be created
     * @param lastName: last name of the contact to be created
     * @param email: email of the contact to be created
     * @return:  contact record that is created
     * @description: This method creates community contact when not found by earlier method
     */
    private Contact createCommunityContact(String firstName, String lastName, String email) {
        ilib_LogEvent.push(LOG_TITLE + '.createCommunityContact()');
        Contact contact = new Contact();

        // set values
        contact.LastName = lastname;
        contact.FirstName = firstName;
        contact.Email = email;

        // set Account Id
        List<Account> accountList = [SELECT Id FROM Account WHERE Name =: DEFAULT_ACCOUNTNAME LIMIT 1];
        ilib_LogEvent.info('Found account: ' + accountList);

        contact.accountId = accountList[0].Id;

        insert contact;
        ilib_LogEvent.info('Returning Contact : '+contact);
        ilib_LogEvent.pop();
        return contact;
    }


   /**
     * @author: Deep Diwakar
     * @param firstName: first name of the user to be created
     * @param lastName: last name of the user to be created
     * @param email: email of the user to be created
     * @param commContact: community contact for the user creation
     * @return:  user record that is created
     * @description: This method creates community user when not found by earlier method
     */
    private User createCommunityUser(PlatformUserDataWrapper wrapper, Contact commContact) {
        ilib_LogEvent.push(LOG_TITLE + '.createCommunityUser()');
        //String firstName, String lastName, String email, String country, Contact commContact

        User newUser = new User();

        newUser.username = wrapper.plfEmail + CUSTOMER_COMMUNITY_SUFFIX;
        newUser.email = wrapper.plfEmail;
        newUser.lastName = wrapper.plfLastName;
        newUser.firstName = wrapper.plfFirstName;
        newUser.contactId = commContact.Id;
        newUser.CountryCode = wrapper.plfCountry;

        newUser.LanguageLocaleKey = EXTERNAL_USER_DEFAULT_LANGUAGE;


        String alias = wrapper.plfFirstName + wrapper.plfLastName;

        //Alias must be 8 characters or less
        if(alias.length() > EIGHT) {
            alias = alias.substring(0, 8);
        }
        newUser.alias = alias;
        newUser.localesidkey = EXTERNAL_USER_DEFAULT_LOCALE;
        newUser.emailEncodingKey = EXTERNAL_USER_DEFAULT_EMAIL_ENCODING;
        newUser.timeZoneSidKey = EXTERNAL_USER_DEFAULT_TIMEZONE;




        newUser.CommunityNickname = wrapper.plfFirstName.substring(0, 1) + wrapper.plfLastName.substring(0,wrapper.plfLastName.length() > 6 ? 6 : wrapper.plfLastName.length()) + String.valueOf(Crypto.getRandomInteger()).substring(1,7);

        Profile commExtProfile = [SELECT Id FROM Profile WHERE Name =:EXTERNAL_USER_PROFILE];

        newUser.profileId = commExtProfile.Id;
        ilib_LogEvent.info('Returning newUser : '+newUser);
        ilib_LogEvent.pop();
        return newUser;
    }

    /**
    * @description: inner class to create custom SSO exception
    */
    class CommSSORegHandlerException extends Exception {}

    /**
    * @description: data wrapper class for sanitized platform data
    */
    class PlatformUserDataWrapper {
        public String plfFirstName;
        public String plfLastName;
        public String plfEmail;
        public String plfPguid;
        public String plfCountry;

        /**
         * constructor
         */
        public PlatformUserDataWrapper(String firstName, String lastName, String email, String pguid, String country) {
            plfFirstName = firstName;
            plfLastName = lastName;
            plfEmail = email;
            plfPguid = pguid;
            plfCountry = country;

        }


    }

}
