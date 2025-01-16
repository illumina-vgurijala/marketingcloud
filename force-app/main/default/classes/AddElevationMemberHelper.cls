/***************************************************************************************************************************************
    * NAME   : AddElevationMemberHelper
    * DESCRIPTION  : Controller Class for lwcLookup to fetch contact details on Create technical Elevation screen.
    *                    
    * @AUTHOR : Rohan Rathod
    * @DATE   : 13-Dec-2021  
    * 
    * MODIFICATION LOG: 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Rohan                  13-Dec-2021         Initial Version.
    *****************************************************************************************************************************************/

    public with sharing class AddElevationMemberHelper {
        public static final Id ELEVATION_MEMBER_ID = Schema.SObjectType.Related_Contacts__c.getRecordTypeInfosByName().get('Elevation Member').getRecordTypeId();
        public static final string STR_USER_IDENTIFICATION = '005';
        /*
        *  @AUTHOR: Rohan Rathod
        *  @DESCRIPTION: To create the related contact records using input string from screen flow
        *  @PARAM : List of String
        *  @RETURN:  void
        */
        @InvocableMethod(label='Deserialize Elevation Members'DESCRIPTION='Deserialize input string and creates Related Contacts records' category='Elevation')
        public static void deserializeElevationMembers(List<String> lstInputRecords) {        
            String strJson=lstInputRecords.get(0);
            if(!String.isBlank(strJson) && strJson != null){
                List<RelatedConWrapper> wrapLst = (List<RelatedConWrapper> ) System.JSON.deserialize(strJson, List<RelatedConWrapper>.class);
                List<Related_Contacts__c> lstRelCon= new List<Related_Contacts__c>();           
                    for(RelatedConWrapper wrapObj:wrapLst){
                        if(wrapObj.memberId==null)
                        {
                            Related_Contacts__c obj= new Related_Contacts__c();
                            obj.Type__c=wrapObj.typePiclst;
                            obj.Elevated_Work_Order__c=wrapObj.woRecId;
                            obj.RecordTypeId=ELEVATION_MEMBER_ID;
                            obj.Source__c='Flow';
                            obj.User__c=wrapObj.tempAllIds.startsWith(STR_USER_IDENTIFICATION)? wrapObj.tempAllIds: null; 
                            obj.Contact__c= !wrapObj.tempAllIds.startsWith(STR_USER_IDENTIFICATION)? wrapObj.tempAllIds:null;
                        lstRelCon.add(obj);
                        }
                    }          
                            
                if(!lstRelCon.isEmpty()){
                    try{
                        insert lstRelCon;
                    }
                    catch(Exception e){
                        string errorMessage = e.getMessage();
                        AuraHandledException auraEx = new AuraHandledException(errorMessage);
                        auraEx.setMessage(errorMessage);
                        throw auraEx;
                    }                
                }            
            }
        }
    
        /*
            * Wrapper class which is required for converting input string 
        */
        
        public class RelatedConWrapper{ 
            Public String typePiclst;
            Public String userId;
            Public String contactId;
            Public String woRecId;
            Public string tempAllIds;
            Public string memberId;
        }       
    }
    /*
    JSON:    
    [{"Type__c":"Watcher (Account);Watcher (Technical)","Title__c":"Sr Product Manager","Email__c":"piyer@illumina.com.invalid","Name":"Pooja Iyer","User__c":"0053l00000D5dXRAAZ"},
    {"Type__c":"","Title__c":"Information Technology Consultant","Email__c":"pshalwadi@illumina.com","Name":"Pooja Shalwadi","User__c":"0053l00000G1gMiAAJ"}]
    */ 
