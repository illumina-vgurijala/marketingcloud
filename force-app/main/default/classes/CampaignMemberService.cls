/*
*    @author Nishan Shetty
*    @date   2021-06-23
*    @description  Controller class for moveCampaignMembersLwc component.
*
*    @Test Class: TestCampaignMemberService, TestMoveCampaignMembersController, TestCampaignMembers
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                23 Jun 2021          Service Class For Campaign Member.   
*            Deep Diwakar   		      Oct 16 2023          CMCM-1188: Added method to find Campaign attribution and media code for Cvent user
*                                                              Also, added inherited sharing (earlier there was no sharing keyword) as 
*                                                              this class is used by other work-stream classes
*    --------------------------------------------------------------------------------------------------------
*                    
*/
public inherited sharing class CampaignMemberService {


    private static final String LOG_TITLE = 'CampaignMemberService';
    private static final Integer ONE = 1;

    /*
        *  @author                     : Nishan Shetty
        *  @description                : Get LeadId or ContactId for a Campaign Member.
        *  @Param objCampaignMember    : CampaignMember Object.
        *  @return                     : Id of Lead or Contact.
        * 
    */ 
    public static Id getLeadOrContactId(CampaignMember objCampaignMember) {
    
        if(objCampaignMember.LeadId!=null) {
            return objCampaignMember.LeadId;
        }

        return objCampaignMember.ContactId;
    }

    /**
     * @author: Deep Diwakar
     * @date: Oct-16-2023
     * @description: this method finds Campaign attribution and media code values for Cvent user
     * @param: list of campaign members
     * @return: void
     */
    public static void runCattMediaLogicForCvent(List<CampaignMember> lstCampaignMembers) {

        ilib_LogEvent.push(LOG_TITLE + '.runCattMediaLogicForCvent');

        for (CampaignMember cmpMember : lstCampaignMembers) {
            String refIdValue = '';
            String catt = '';
            String mediaCode = '';

            // get Reference Id value passed from Cvent
            refIdValue = cmpMember.Campaign_Attribution__c;

            ilib_LogEvent.message('Cvent refIdValue: ' + refIdValue);

            if (String.isBlank(refIdValue)) {
                continue;
            }

            // remove any whitespace
            refIdValue = refIdValue.trim();

            // find campaign attribution and media code from coming reference id field 
            // Example of Inputs:
            // Campaign attribution only: catt=Medium_Source,
            // Media code only: media=1234567, 
            // both campaign attribution and media code combined: catt=example_example+media=1234567
            if (refIdValue.contains('+')) {
                if (refIdValue.countMatches('+') > ONE) {
                    continue;
                }
                catt = refIdValue.substringBefore('+');
                mediaCode = refIdValue.substringAfter('+');

                if (!String.isBlank(catt) && catt.startsWith('catt=')) {
                    cmpMember.Campaign_Attribution__c = catt.substringAfter('=').trim();
                }
                if (!String.isBlank(mediaCode) && mediaCode.startsWith('media=')) {
                    cmpMember.Media_Code__c = mediaCode.substringAfter('=').trim();
                }  

            } else if (refIdValue.startsWith('catt=')) {
                cmpMember.Campaign_Attribution__c = refIdValue.substringAfter('=').trim();

            } else if (refIdValue.startsWith('media=')) {
                cmpMember.Media_Code__c = refIdValue.substringAfter('=').trim();
                cmpMember.Campaign_Attribution__c = '';
            }

            ilib_LogEvent.message('cmpMember.Media_Code__c: ' + cmpMember.Media_Code__c);
            ilib_LogEvent.message('cmpMember.Campaign_Attribution__c: ' + cmpMember.Campaign_Attribution__c);

        }

        ilib_LogEvent.pop();

    }

 
}