/*
 * Created By : Mukul Pandey
 * Date : 10/15/2023
 * Description : Logic to fetch associated codes and code library records.
 * CMCM-105
*/
public with sharing class AddAssociatedCodeController {
    /*
     * Method to get list of associated codes.
     */

    @AuraEnabled
    public static List<Associated_Codes__c> getAssociatedCodesLwc(Id recordId, String objAPIName){
        try{
            String caseObj = 'Case';
            String woObj = 'SVMXC__Service_Order__c';
            List<Associated_Codes__c> associatedRecords = new List<Associated_Codes__c>();
            if(objAPIName==caseObj){
                associatedRecords = new AssociatedCodeSelector().getAssociatedCodesOnCase(recordId);
            }
            else if(objAPIName==woObj){
                List<SVMXC__Service_Order__c> woRecords = new WorkOrdersSelector().getWorkOrdersOnCase(recordId);  
                associatedRecords = new AssociatedCodeSelector().getAssociatedCodesFromWorkOrderOrCase(recordId, woRecords[0].SVMXC__Case__c); 
            }
            return associatedRecords;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
	 /*
     * Method to get list of code library.
     */
    @AuraEnabled(cacheable=true)
    public static list<Code_Library__c> getCodeLibrary(String caseType){
        try{
            return new CodeLibrarySelector().getCodeLibraryByCaseType(caseType); 
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }    
    /*
     * Method to get User Data.
     */
    @AuraEnabled(cacheable=true)
    public static String getUserAndCodeLibraryTypeInfo(){ 
        String jsonOutput = '';
        try{
            List<Profile> userProfileList = new ProfilesSelector().getProfilesById(new Set<Id>{Userinfo.getProfileId()});    
            String codePickListVals = '[';
            for( Schema.PicklistEntry pickListVal : Code_Library__c.Code_Type__c.getDescribe().getPicklistValues()){
                codePickListVals += '{"label":"' + pickListVal.getLabel() + '","value":"'+ pickListVal.getValue() + '"},';
            }
            codePickListVals = codePickListVals.substring(0,codePickListVals.length()-1);  
            codePickListVals += ']';
            if(!userProfileList.isEmpty()){
                jsonOutput = '{"profileId":"' + userProfileList[0].Id + '","profileName":"' + userProfileList[0].Name + '","userType":"' + Userinfo.getUserType() + '","values":' + codePickListVals +'}'; 
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        } 
        return jsonOutput;
    }
    
    /*
     * Retrieves the 'IVD_Workflow' feature flag from the custom metadata
     */
    @AuraEnabled(cacheable=true)
    public static Feature_Flag__mdt getIVDWorkflow() {
        try {
            Feature_Flag__mdt featureFlag = Feature_Flag__mdt.getInstance('IVD_Workflow');
            return featureFlag;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
}