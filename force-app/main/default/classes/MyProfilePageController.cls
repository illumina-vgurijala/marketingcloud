/**
 * An apex class that updates portal user details.
   Guest users are never able to access this page.
 */
public with sharing class MyProfilePageController {

    private User user;
    private boolean isEdit = false;

		/*
         * description - getUser method
		 * return - user
         */
    public User getUser() {
        return user;
    }

		/*
         * Constructor
         */
    public MyProfilePageController() {
        user = [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId()];
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }
	
		/*
         * description - getIsEdit method
		 * return - Boolean
         */
    public Boolean getIsEdit() {
        return isEdit;
    }

		/*
         * description - edit method
		 * return - void
         */
    public void edit() {
        isEdit=true;
    }

		/*
         * description - save method
		 * return - void
         */
    public void save() {
        try {
            update user;
            isEdit=false;
        } catch(DmlException e) {
            ApexPages.addMessages(e);
        }
    }

		/*
         * description - changePassword method
         */
    public PageReference changePassword() {
        return Page.ChangePassword;
    }

		/*
         * description - cancel method
		 * return - void
         */
    public void cancel() {
        isEdit=false;
        user = [SELECT id, email, username, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId()];
    }    
}