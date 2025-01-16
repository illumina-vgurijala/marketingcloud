/*@ author       : Shaik Moulali
* @ date         : 10-06-2018
* @ Description  : class created for managing Team Management list view.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          10-06-2018                 US-4252             Initial version
* 
*/
public class TeamManagementController {
    /*
     * Fetching logged In portal User details
     */ 
    @AuraEnabled
    public static User getUser(){
        UsersSelector user = new UsersSelector();
        List<User> lstUsers = user.getLoggedInPortalUser(UserInfo.getUserId());
        return lstUsers.get(0);
    }
    
    /*
     * Fetch List of Contacts for based on logged in account
     * and partner portal status
     * 
     */ 
    
    @AuraEnabled
    public static List<Contact> getContacts(String partnerPortalStatus){
        User objUser;
        objUser=getUser();
        
        AccountsSelector account = new AccountsSelector();
        ContactsSelector contact = new ContactsSelector();
        
        //Fetching account details for logged in user
        List<Account> lstAccounts = account.selectLoggedInAccountForUser(objUser.Contact.AccountId);
        Id idAccount = lstAccounts.get(0).Id;
		
        return contact.selectLoggedInAccountContacts(idAccount,partnerPortalStatus);
    } 
    
    /*
     * Fetch Record Type Id for the Add Team Member and Remove Team Member record types
     * 
     */ 
       
    @AuraEnabled
    public static Id getRecordTypeId(String objectApiName, String recordTypeName){
        Id idRecordType;
        try{
            //Fetching record type id for record type
            idRecordType = [SELECT Id, Name FROM RecordType 
                		WHERE sobjecttype = :objectApiName AND Name = :recordTypeName LIMIT 1].Id;
        }catch(Exception e){
            idRecordType = null;
        }
        return idRecordType;
    }
}