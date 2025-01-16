/*
*    @author: Pankaj Singla
*    @date:   14-May-2020
*    @description:  Utils class for Prospect Scoring
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla             14-May-2020             DCP-35843 Initial Build
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ProspectScoringUtils{
    public static Boolean boolPreventDuplicateRun=true;
    public static final String STRING_OBJECT_LEAD='Lead';
    
    /*
    *  @author Pankaj Singla
    *  @description To create a new scoring Log Record
    *  @param strActionName - Action Name
    *  @param strCampaignName - The Campaign Name
    *  @param idProspect  - Lead/Contact Id
    *  @param idUser - UserId
    *  @param strRegion - Region
    *  @param intPreviousScore - Previous Score Value
    *  @param intNewScore - New Score Value
    *  @return Prospect_Scoring_Log__c- record
    */
    public static Prospect_Scoring_Log__c createProspectScoringLogRecords(String strActionName,String strCampaignName,Id idProspect, Id idUser,String strRegion,Integer intPreviousScore, Integer intNewScore){
        //boolPreventDuplicateRun=false;
        Prospect_Scoring_Log__c objProspectLog=new Prospect_Scoring_Log__c();
        String sObjName = idProspect.getSObjectType().getDescribe().getName();
        if(sObjName.equals(STRING_OBJECT_LEAD)){
            objProspectLog.Lead__c=idProspect;
        }
        else {
            objProspectLog.Contact__c=idProspect;
        }
        objProspectLog.Action_Name__c=strActionName;
        objProspectLog.Campaign_Name__c=(String.isBlank(strCampaignName)==false?strCampaignName:'');
        objProspectLog.New_Score_Value__c=intNewScore;
        objProspectLog.Previous_Score_Value__c=(intPreviousScore==NULL?0:intPreviousScore);
        objProspectLog.Region__c=strRegion;
        objProspectLog.User__c=idUser;
        return objProspectLog;
        
    }

}