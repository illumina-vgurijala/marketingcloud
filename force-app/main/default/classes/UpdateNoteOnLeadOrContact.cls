/***************************************************************************************************************************************
    * NAME   : UpdateNoteOnLeadOrContact
    * DESCRIPTION  : Logic for updating notes on Contact or Lead associated to Campaign Member when Campaign
    *                Member Notes Field on Campaign Member is updated.If note is not already
    *                present in lead or contact then create new note with updated (latest) campaign member note
    *                value.If Campaign Member Notes is updated as blank then corresponding Notes on Contact or Lead will be deleted.
    *                    
    * @AUTHOR : Nishan Shetty
    * @DATE   : 03-June-2021  
    * 
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Nishan Shetty           03-June-2021         Initial Version. 
*****************************************************************************************************************************************************************/


public with sharing class UpdateNoteOnLeadOrContact implements ilib_AdminOperationLogicInterface {
    private static final String LOG_TITLE = 'UpdateNoteOnLeadOrContact';

    /**
     *  @author                         : Nishan Shetty
     *  @description                    : Create,Update and Delete Content Notes based on values of Campaign Member Note using platform event.
     *  @Param lstCampaignMemberIds     : List of Campaign Members Ids.
     *  @return                         : void
     */
     public static void doBusinessLogic(List<Id> lstCampaignMemberIds) {
         
           ilib_LogEvent.rootTitle = LOG_TITLE;
           ilib_LogEvent.push(LOG_TITLE + '.doBusinessLogic()');

        
          
           Set<Id> setLeadOrContactIds=new Set<Id>();
           Map<String,String> mapTitleToNotesUpdate=new Map<String,String>();
           Set<String> setTitleNotesDelete=new Set<String>();
           Map<Id,Id> mapContentDocIdToLinkedEntityId=new Map<Id,Id>();
           Set<Id> setCampaignMembersIds=new Set<Id>(lstCampaignMemberIds);
           List<CampaignMember> lstCampaignMembers=new List<CampaignMember>(new CampaignMemberSelector().selectCampaignMembers(setCampaignMembersIds));

           
            
            for(CampaignMember objCampaignMember :lstCampaignMembers) {
            
                Id leadOrContactId=getLeadOrContactId(objCampaignMember);
                if(String.isBlank(objCampaignMember.Campaign_Member_Notes__c)) {
                    setTitleNotesDelete.add('Campaign Member Note: '+objCampaignMember.Campaign.Name+'~'+leadOrContactId);
                } else {
                    mapTitleToNotesUpdate.put('Campaign Member Note: '+objCampaignMember.Campaign.Name+'~'+leadOrContactId,objCampaignMember.Campaign_Member_Notes__c);
                }
                setLeadOrContactIds.add(leadOrContactId);

            }

            ilib_LogEvent.message('setLeadOrContactIds: '+setLeadOrContactIds);

            if(!setLeadOrContactIds.isEmpty()) {

                List<ContentDocumentLink> lstContentDocumentLink=new List<ContentDocumentLink>(new ContentDocumentLinksSelector().selectContentDocumentLinks(setLeadOrContactIds));
                for(ContentDocumentLink objContentDocLink:lstContentDocumentLink) {
                    mapContentDocIdToLinkedEntityId.put(objContentDocLink.ContentDocumentId,objContentDocLink.LinkedEntityId);
                }

                //Initiate updateDeleteNote Method.
                
                updateDeleteNote(mapContentDocIdToLinkedEntityId,mapTitleToNotesUpdate,setTitleNotesDelete);
            }

           

            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        
    
    }

    
    /**
     *  @author                               : Nishan Shetty
     *  @description                          : Update note on Lead or Contact record ,if campaign member notes is updated and delete note from lead or contact if
     *                                          campaign member notes is updated to blank.
     *  @Param mapContentDocIdToLinkedEntityId: map of note id to linkedEntityId(Lead or Contact)
     *  @Param mapTitleToNotesUpdate          : map with key as unique note title with lead or contact id and value as latest campaign member notes to update.
     *  @Param setTitleNotesDelete            : set of unique note title with lead or contact id used for deletion of existing notes.
     *  @return                               : void
     */
    public static void updateDeleteNote(Map<Id,Id> mapContentDocIdToLinkedEntityId,Map<String,String> mapTitleToNotesUpdate,Set<String> setTitleNotesDelete) {

      List<ContentNote> lstContentNoteToUpdate=new List<ContentNote>();
      List<ContentNote> lstContentNoteToDelete=new List<ContentNote>();
      List<ContentVersion> lstContentVersionToInsert = new List<ContentVersion>();
      Map<String,ContentNote> keyToContentNoteMap = new Map<String,ContentNote>();
      

    if(!mapContentDocIdToLinkedEntityId.isEmpty()) {
        List<ContentNote> lstContentNotes=new List<ContentNote>(new ContentNoteSelector().selectContentNotes(mapContentDocIdToLinkedEntityId.keySet()));
        for(ContentNote objContentNote:lstContentNotes) {
            keyToContentNoteMap.put(objContentNote.Title+'~'+mapContentDocIdToLinkedEntityId.get(objContentNote.Id),objContentNote);
        }
    }
    
    if(!mapTitleToNotesUpdate.isEmpty()) {
        for(String key : mapTitleToNotesUpdate.keyset()) {
              if(keyToContentNoteMap.containsKey(key)) {
                  ContentNote  objContentNote =  keyToContentNoteMap.get(key); 
                  objContentNote.Content=Blob.valueOf(mapTitleToNotesUpdate.get(key));
                  lstContentNoteToUpdate.add(objContentNote);
              } else {
                    ContentVersion  objContentVersion = new ContentVersion(Title=Key.substringBefore('~'),PathOnClient=Key.substringBefore('~')+'.snote',VersionData=Blob.valueOf(mapTitleToNotesUpdate.get(key)),FirstPublishLocationId=key.substringAfter('~'));
                    lstContentVersionToInsert.add(objContentVersion);
                }
            }
    }
    

    lstContentNoteToDelete.addAll(getNoteToDelete(keyToContentNoteMap,setTitleNotesDelete));
         
      
    try {
        if(!lstContentVersionToInsert.isEmpty()) {
            insert lstContentVersionToInsert;
        }
        if(!lstContentNoteToUpdate.isEmpty()) {
            update lstContentNoteToUpdate;
        }
        
        if(!lstContentNoteToDelete.isEmpty()) {
            delete lstContentNoteToDelete;
        }
        } catch(Exception e) {
          ApexExceptions.emit(LOG_TITLE+'noteOperation',e);
        }
      


    }

/*
     *  @author                     : Nishan Shetty
     *  @description                : Get Content Note to Delete.
     *  @Param setKeyString         : set of unique note title with lead or contact id.
     *  @Param mapKeyToContentNote  : map with key as unique note title with lead or contact id and value as latest campaign member notes to update.
     *  @return                     : list of Content Note to delete.
     * 
*/
public static List<ContentNote> getNoteToDelete(Map<String,ContentNote> mapKeyToContentNote,Set<String> setKeyString) {
    List<ContentNote> lstContentNote=new List<ContentNote>();
    if(!mapKeyToContentNote.isEmpty()) {
        for(String keyValue : mapKeyToContentNote.keyset()) {
            if(setKeyString.contains(keyValue)) {
                ContentNote objContentNotetoDelete =  mapKeyToContentNote.get(keyValue);
                lstContentNote.add(objContentNotetoDelete);
            }
        }
    }

    return lstContentNote;
}

/*
     *  @author                     : Nishan Shetty
     *  @description                : Get LeadId or ContactId for a Campaign Member.
     *  @Param objCampaignMember    : CampaignMember Object.
     *  @return                     : Id of Lead or Contact.
     * 
*/
public static Id getLeadOrContactId(CampaignMember objCampaignMember) {
    Id leadOrContactId= null;
    if(objCampaignMember.LeadId!=null) {
       leadOrContactId=objCampaignMember.LeadId;

    }
    if(objCampaignMember.ContactId!=null) {
        leadOrContactId=objCampaignMember.ContactId;
    }

    return leadOrContactId;
  

}


}