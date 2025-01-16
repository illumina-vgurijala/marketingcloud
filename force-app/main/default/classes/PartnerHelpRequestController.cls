/*@ author       : Shaik Moulali
* @ date         : 17-09-2018
* @ Description  : Class created for managing Instructor Led Training Course Registrations.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          17-09-2018                 US-4252             Initial version
* Gerardo Garcia         18-12-2024                                     CMCM-13201 OpportunityClosedStageModal component CommetD implementation.
*/
public with sharing class PartnerHelpRequestController {
    private static final String LOG_TITLE = 'PartnerHelpRequestController';
    /*
     * Method created for fetching logged in user information
     */
    @AuraEnabled
    public static User fetchUserDetails(){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        try {
            UsersSelector usr = new UsersSelector();
            String strId=UserInfo.getUserId();
            ilib_LogEvent.message('LoggedIn ID=='+strId);
            List<User> objUser=usr.getLoggedInPortalUser(strId);
            ilib_LogEvent.emit();
            return objUser[0];
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE + '.fetchSessionId',e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*
     * Method created for saving newly created Help Request.
     * 
     */
    @AuraEnabled
    public static String saveHelpRequest(Partner_Request__c partnerRequest,String objectApiName, String recordTypeName){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        String errorMsg = '';
        try{
            Id recordType = [Select Id,Name From RecordType where sobjecttype = :objectApiName and Name= :recordTypeName LIMIT 1].Id;
            partnerRequest.RecordTypeId = recordType;
            insert partnerRequest;
            ilib_LogEvent.info('Partner Request inserted succesfully:'+partnerRequest.Id);
            ilib_LogEvent.emit();
        }catch(Exception e){
            errorMsg = 'Error occured during Insertion in Help Request Object';
            ApexExceptions.emit(LOG_TITLE + '.saveHelpRequest ' + errorMsg,e);
        }
        return errorMsg;
    }

    /**
     * @description: Test for slOpportunityClosedStagePlatformEventCatch component. User for CommetD
     */
    @AuraEnabled( cacheable=true )
    public static String fetchSessionId() {
        try {
            return UserInfo.getSessionId();
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE + '.fetchSessionId',e, ilib_LogEvent.SALES);
            throw new AuraHandledException(e.getMessage());
        }
    }
}