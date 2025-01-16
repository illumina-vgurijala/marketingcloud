/*
*    @author Nishan Shetty
*    @date   2021-06-18
*    @description  Controller class for moveCampaignMembersLwc component.
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                18 Jun 2021          Move Campaign Members to New Campaign [SPQ 45].        		
*    --------------------------------------------------------------------------------------------------------
*                    
*/
public with sharing class MoveCampaignMembersController {
    private static final String LOG_TITLE = 'MoveCampaignMembersController';
    /*
     *  @AUTHOR:  Nishan Shetty
     *  @DESCRIPTION: CampaignMember wrapper
     */
    public class CampaignMemberWrapper {
        String id;
        String strType;
        String strStatus;
        String strFirstName;
        String strLastName;
        String strCompanyOrAccount;
        String strCampaignMemberNotes;
        Boolean checked;

       /*
        *  @AUTHOR:  Nishan Shetty
        *  @DESCRIPTION: CampaignMember Wrapper constructor
        */
        public CampaignMemberWrapper(CampaignMember objCampaignMember) {
            this.id = objCampaignMember.id;
            this.strType = objCampaignMember.Type;
            this.strStatus = objCampaignMember.Status;
            this.strFirstName = objCampaignMember.FirstName;
            this.strLastName= objCampaignMember.LastName;
            this.strCompanyOrAccount= objCampaignMember.CompanyOrAccount;
            this.strCampaignMemberNotes=objCampaignMember.Campaign_Member_Notes__c;
            this.checked=false;
        }
    }

    /*
     *  @author Nishan Shetty
     *  @description Get related Campaign Member Records for Campaign.
     *  @param campaignId Id of Campaign.
     *  @return List of CampaignMemberWrapper
    */
    @AuraEnabled
    public static String getCampaignMembers(String campaignId) {
        ilib_LogEvent.push(LOG_TITLE + '.getCampaignMembers()');
        List<CampaignMemberWrapper> lstCampaignMemberWrapper=new List<CampaignMemberWrapper>();
        try {
                List<CampaignMember> lstCampaignMembers=new List<CampaignMember>(new CampaignMemberSelector().selectCampaignMembersListCampaign(new Set<Id>{Id.valueOf(campaignId)}));
                String strCampaignName=new CampaignSelector().selectCampaigns(new Set<Id>{Id.valueOf(campaignId)})[0].Name;
                for(CampaignMember objCampaignMember:lstCampaignMembers) {
                    lstCampaignMemberWrapper.add(new CampaignMemberWrapper(objCampaignMember));
                }
                ilib_LogEvent.message('strCampaignName: ' + strCampaignName);
                ilib_LogEvent.message('lstCampaignMembers: ' + lstCampaignMembers);
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
               

                return '{"lstCampaignMembers": '+JSON.serialize(lstCampaignMemberWrapper)+','
                        +' "strOffsetSize": "'+getOffsetSize()+'",'
                        +' "mapLabels": '+JSON.serialize(getMapLabels())+','
                        +' "strCampaignName": "'+strCampaignName+'"}';

            } catch (Exception e) {
                 ApexExceptions.emit(LOG_TITLE,campaignId,e);
                 throw  new AuraHandledException('GetCampaignMembers'+ e.getMessage()) ;
            }
       
    }

    /*
     *  @author Nishan Shetty
     *  @description Move New Campaign Members to New Campaign and Delete Campaign Members from Old Campaign.
     *  @param strNewCampaignId - Id of New Campaign.
     *  @param strCampaignMemberIds - String of Campaign Member Ids.
     *  @return String - SUCCESS
    */
    @AuraEnabled
    public static String moveCampaignMembers(String strCampaignMemberIds,String strNewCampaignId) {
    ilib_LogEvent.push(LOG_TITLE + '.moveCampaignMembers()'); 
    List<CampaignMember> lstCampaignMemberToInsert=new List<CampaignMember>();
    List<CampaignMember> lstCampaignMemberToDelete=new List<CampaignMember>();
    List<CampaignMember> lstCampaignMemberToUpdate=new List<CampaignMember>();

    try {
            Id idOldCampaignId=null;
            Set<Id> setCampaignMembersIds=new Set<Id>((List<Id>) JSON.deserialize(strCampaignMemberIds,List<Id>.class));
            List<CampaignMember> lstCampaignMembersToMove=new List<CampaignMember>(new CampaignMemberSelector().selectCampaignMembers(setCampaignMembersIds));
            List<CampaignMember> lstCampaignMembersExisting= new List<CampaignMember>(new CampaignMemberSelector().selectCampaignMembersListCampaign(new Set<Id>{Id.valueOf(strNewCampaignId)}));
            Set<Id> setLeadorContactIds=new Set<Id>();

            for(CampaignMember objCampaignMemb:lstCampaignMembersExisting) {
                Id leadOrContactId=CampaignMemberService.getLeadOrContactId(objCampaignMemb);
                setLeadorContactIds.add(leadOrContactId);      
            }
            for(CampaignMember objCampaignMember:lstCampaignMembersToMove) {
                Id leadOrContactId=CampaignMemberService.getLeadOrContactId(objCampaignMember);
                idOldCampaignId=objCampaignMember.CampaignId;
                if(!setLeadorContactIds.contains(leadOrContactId)) {
                    CampaignMember objNewCampaignMember=objCampaignMember.clone(false,false,false,false);
                    objNewCampaignMember.CampaignId=Id.valueOf(strNewCampaignId);
                    objNewCampaignMember.Campaign_Member_Notes__c=null;
                    objNewCampaignMember.Campaign_Member_Owner__c=null;
                    objNewCampaignMember.Status=null;
                    lstCampaignMemberToInsert.add(objNewCampaignMember);
                    objCampaignMember.Legacy_SFDC_Record_ID__c=null;
                    lstCampaignMemberToUpdate.add(objCampaignMember);
                    lstCampaignMemberToDelete.add(objCampaignMember);
                }
                
            }
            List<CampaignMember> lstCampaignMembersStillExisting=new List<CampaignMember>(new CampaignMemberSelector().selectCampaignMembersListCampaign(new Set<Id>{idOldCampaignId}));
            Set<Id> setCampaignMembersStillExistingIds=new Set<Id>();
            setCampaignMembersStillExistingIds.addAll(getStillExistingCampaignMemberIds(lstCampaignMembersStillExisting,setCampaignMembersIds));
            if(!setCampaignMembersStillExistingIds.containsAll(setCampaignMembersIds)) {
                return 'NOTEXIST';   
            }

            if(!lstCampaignMemberToUpdate.isEmpty()) {
                update lstCampaignMemberToUpdate;
            }

            if(!lstCampaignMemberToInsert.isEmpty()) {
                insert lstCampaignMemberToInsert;
            }

            if(!lstCampaignMemberToDelete.isEmpty()) {
                delete lstCampaignMemberToDelete;
            }
            ilib_LogEvent.message('lstCampaignMemberToUpdate: ' + lstCampaignMemberToUpdate);
            ilib_LogEvent.message('lstCampaignMemberToInsert: ' + lstCampaignMemberToInsert);
            ilib_LogEvent.message('lstCampaignMemberToDelete: ' + lstCampaignMemberToDelete);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();

            return 'SUCCESS';         
        
    } catch (Exception e) {
        ApexExceptions.emit(LOG_TITLE,strNewCampaignId,e);
        throw new AuraHandledException('MoveCampaignMembers'+ e.getMessage());
    }
  }

    /*
     *  @author Nishan Shetty
     *  @description Check if Campaign Members still exists in old Campaign.
     *  @return - Set of Campaign Member Ids.
     */
    public static Set<Id> getStillExistingCampaignMemberIds(List<CampaignMember> lstCampaignMembersExisting,Set<Id> setCampaignMemberIds) {
        Set<Id> setExistingCampaignMemberIds=new Set<Id>();
        for(CampaignMember objCampMember:lstCampaignMembersExisting) {
            if(setCampaignMemberIds.contains(objCampMember.id)) {
                setExistingCampaignMemberIds.add(objCampMember.id);
            }
        }

        return setExistingCampaignMemberIds;

    }


    /*
     *  @author Nishan Shetty
     *  @description Get offsetSize from Code Parameter metadata which is used in datatable.
     *  @return String - OffsetSize.
     */
    public static String getOffsetSize() {
     Set<String> setMetaDataDeveloperName=new Set<String>{'Move_Campaign_Members_Cmp_OffsetSize'};
     List<Code_Parameter__mdt> lstCodeParameters=new List<Code_Parameter__mdt>(new CodeParametersSelector().selectCodeParameterByDeveloperName(setMetaDataDeveloperName));
     if(!lstCodeParameters.isEmpty()) {
       return lstCodeParameters.get(0).Value__c;
     }
     return '1';
     }


    /*
     *  @author Nishan Shetty
     *  @description Get MapLabels.
     *  @return Map<String,String> - Map of Labels.
    */
    public static Map<String,String> getMapLabels() {

        return new Map<String,String>{
            'Move_Campaign_Members_Cmp_Title' => Label.Move_Campaign_Members_Cmp_Title,
            'Move_Campaign_Members_Cmp_HelpText' => Label.Move_Campaign_Members_Cmp_HelpText,
            'Move_Campaign_Members_Cmp_Search_Field_Label' => Label.Move_Campaign_Members_Cmp_Search_Field_Label,
            'Move_Campaign_Members_Cmp_From_Field_Label' => Label.Move_Campaign_Members_Cmp_From_Field_Label,
            'Move_Campaign_Members_Cmp_To_Field_Label' => Label.Move_Campaign_Members_Cmp_To_Field_Label,
            'Move_Campaign_Members_Cmp_To_Field_API_Name' => Label.Move_Campaign_Members_Cmp_To_Field_API_Name,
            'Move_Campaign_Members_Cmp_Search_Field_Placeholder' =>Label.Move_Campaign_Members_Cmp_Search_Field_Placeholder,
            'Button_Submit_Label' => Label.Button_Submit_Label,
            'Button_Submit_Title' => Label.Button_Submit_Title,
            'Button_Cancel_Label' => Label.Button_Cancel_Label,
            'Button_Cancel_Title' => Label.Button_Cancel_Title,
            'Move_Campaign_Members_Cmp_SuccessMsg' => Label.Move_Campaign_Members_Cmp_SuccessMsg,
            'Move_Campaign_Members_Cmp_ErrorMsg_Unselected' => Label.Move_Campaign_Members_Cmp_ErrorMsg_Unselected,
            'Move_Campaign_Members_Cmp_ErrorMsg_Existing' => Label.Move_Campaign_Members_Cmp_ErrorMsg_Existing,
            'Move_Campaign_Members_Cmp_ErrorMsg_Member_Already_Moved' => Label.Move_Campaign_Members_Cmp_ErrorMsg_Member_Already_Moved
         };
        
    }
}