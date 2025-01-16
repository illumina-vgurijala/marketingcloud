/*@ author       : Prakhar Kumar
* @ date         : 26-09-2018
* @ Description  : Fetches respective carousel on the basis of Logged in user's region information
*
* Modification Log:
* ---------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------
* Prakhar Kumar          25-09-2018                                    Initial version
* Prakhar Kumar          19-09-2019               DCP-28546            Added ImageCSS__c in SOQL Query
*
*/

public with sharing class PartnerPortalContentFetchSlides {

    /*
    *  @author       : Prakhar Kumar
    *  @description  : Fetch the corresponding Slides based on the region
    *  @param        : NA
    *  @return       : void
    */

    public Static Final String OBJECTNAME='Partner_Portal_Content__c';
    public Static Final String RECORDTYPENAME='Slides';
    @AuraEnabled
	
		/*
         * description - PartnerPortalContentWrapper method
         */	
    public static PartnerPortalContentWrapper loadCarousel(){
    String strErrorMsg='';
    List<Account> lstAccounts;
    String strAccountId;
        List <Partner_Portal_Content__c> lstSlides;

        try{
        // Fetch details of logged in user
        List<User> objUser = new UsersSelector().getLoggedInPortalUser(UserInfo.getUserId());
        strAccountId = objUser[0].Contact.AccountId;
        if(String.isEmpty(strAccountId))
        {
            strErrorMsg='Please ensure there is account associated with the Logged in User to view additional content on this page';
        }

        // Get account information to fetch linked region
        lstAccounts = new AccountsSelector().selectLoggedInAccountForUser(strAccountId);
        String strAccountRegion = lstAccounts[0].Territory_Region__c;



        // Get record type from Partner_Portal_Content object
        RecordType objRecordType= [SELECT Id from RecordType
                                   WHERE sObjectType = :OBJECTNAME  and Name = :'Slides'];
        String strRecordTypeId=objRecordType.Id;

        lstSlides = [SELECT Id,name,Button_Visible__c,Button_Text__c,Slide_Name__c,Button_URL__c,Slide_Title__c,Slide_Subtitle__c,Image_URL__c,Active__c,ImageCSS__c
                                                       FROM Partner_Portal_Content__c
                                                       WHERE recordtypeID = :strRecordTypeId
                                                       AND RecordType.Name = :RECORDTYPENAME
                                                       AND Region__c = :strAccountRegion
                                                       AND Active__c = true];

        if((lstAccounts[0].Territory_Region__c=='')||(lstAccounts[0].Territory_Region__c==NULL)){
           strErrorMsg='Please ensure your account is associated with a valid region to view additional content on this page';
        }


        }catch(Exception e){
            System.debug('strErrorMsg=>'+strErrorMsg);
        }
        PartnerPortalContentWrapper objSlidesWrapper=new PartnerPortalContentWrapper(lstSlides,strErrorMsg);
        return objSlidesWrapper;
    }
}