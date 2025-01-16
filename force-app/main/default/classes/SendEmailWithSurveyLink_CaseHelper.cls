/**
* @author Shivani Jain
* @date 18 May 2022
*
* @description DCP-49913 Enhance sending the same survey link via both Email and WeChat
*/ 
public class SendEmailWithSurveyLink_CaseHelper {

    private static final String QUALTRICS_EMAIL_METADATA = 'Qualtrics_Survey_Link_To_WeChat_Follower';

    /*******************************************************************************************************
    * @description Send Email to WeChat Follower with Survey Link
    * @param caseList - List<Case>
    * @return
    */
    public static void sendEmailWithSurveyLink(List<Case> caseList) {
        SendEmailNotification.getSendEmailParamaters(QUALTRICS_EMAIL_METADATA, caseList, 
                           null, null);
    }

}