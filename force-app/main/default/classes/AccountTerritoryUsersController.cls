/*@ author       : Akshay Mohan
* @ date         : 07-06-2018
* @ Description  : US-1565 Controller class for the related list component
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-06-2018                 Initial version
* Joshith K             22-09-2019                 US-27886 Added Global Territory Logic
* Prabhsimran Singh     09-09-2020                 DCP-39733 refactor checkGlobalTerritory() from static to dynamic
* Saddam                08-Dec-2022             Codescan Fix , Varaible naming convention. 
*/
public with sharing class AccountTerritoryUsersController {
                    
public static String globalTerrittoryName='';
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  return list of users filtering out unrequired roles
    * @param Account Id
    */
    @AuraEnabled
    public static String getUsers(String strAccountId)
    {
        System.debug('strAccountId: ' + strAccountId);
        Set<Id> setAccountIds = new Set<Id> {strAccountId};
        

        List<UserTerritory2Association> lstUserAssociations = getUserAssociations(setAccountIds);
        System.debug('lstUserAssociations: ' + lstUserAssociations);

        //load labels in controller for better performance
        Map<String, String> labelToValue = getlabelToValues();

        return '{ "lstUserAssociations":' + JSON.serialize(lstUserAssociations) +
            ', "labelToValue":' + JSON.serialize(labelToValue) +
        '}';
    }

    private static List<UserTerritory2Association> getUserAssociations(Set<Id> setAccountIds)
    {   //Global Territory Logic US-27886
        Boolean isFoundGLobalTerritory=false;
        Set<String>setCodeParamName=new Set<String>{'Global_Territory_Name'};
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
        if(lstCodeParam.size()>0)
            globalTerrittoryName=lstCodeParam[0].value__c;
        // find leaf territories associated with this account
        //Set<Id> setTerritoryIds = UtilsCollection.getSetOfIds(new ObjectTerritory2AssociationsSelector().selectByAccountIds(setAccountIds), 'Territory2Id');
        Set<Id> setTerritoryIds=new Set<Id>();
        Set<Id> setGlobalTerritoryIds=new Set<Id>();
        for(ObjectTerritory2Association objectTerritoryAssoc:new ObjectTerritory2AssociationsSelector().selectByAccountIds(setAccountIds)){
            setTerritoryIds.add(objectTerritoryAssoc.Territory2Id);
            if(!isFoundGLobalTerritory){
                isFoundGLobalTerritory=checkGlobalTerritory(objectTerritoryAssoc);
                if(isFoundGLobalTerritory){
                    setGlobalTerritoryIds.add(objectTerritoryAssoc.Territory2Id);
                }
            }

        }
        Integer territorySize=setTerritoryIds.size();
        if(territorySize>1&&isFoundGLobalTerritory){
                setTerritoryIds.removeAll(setGlobalTerritoryIds);
        }

        // get all parent territories too
        Set<Id> territoryIdsIncludingParents = new TerritoriesSelector().getTerritoryIdsIncludingParents(setTerritoryIds);
        System.debug('territoryIdsIncludingParents: ' + territoryIdsIncludingParents);

        // get roles that should be excluded from the final list
        Map<String, String> settingKeyToValues=new Map<String, String>();
        if(territorySize==1&&isFoundGLobalTerritory){
             settingKeyToValues = UtilsSettings.getCustomMetadataMap('Exclude_Global_Territory_User_Role');
        }else {
             settingKeyToValues = UtilsSettings.getCustomMetadataMap('Exclude_Territory_User_Roles_On_Account');
        }
        
       
        Set<String> setExcludeRoles = new Set<String>(settingKeyToValues.get('Roles').split('\\|'));
        System.debug('setExcludeRoles: ' + setExcludeRoles);

        // query for users that do not have excluded roles
        return new UserTerritory2AssociationSelector().selectWithDisplayDetailsByTerritoryId(territoryIdsIncludingParents, setExcludeRoles);
    }

    private static Map<String, String> getlabelToValues()
    {
        Map<String, String> labelToValue = new Map<String, String>();

        labelToValue.put('UI_Label_Account_Territory_Users_Column_Header_User_Name', Label.UI_Label_Account_Territory_Users_Column_Header_User_Name);
        labelToValue.put('UI_Label_Account_Territory_Users_Column_Header_Role', Label.UI_Label_Account_Territory_Users_Column_Header_Role);
        labelToValue.put('UI_Label_Account_Territory_Users_Column_Header_Territory_Level', Label.UI_Label_Account_Territory_Users_Column_Header_Territory_Level);
        labelToValue.put('UI_Label_Account_Territory_Users_Column_Header_Email', Label.UI_Label_Account_Territory_Users_Column_Header_Email);
        labelToValue.put('UI_Label_Account_Territory_Users_Column_Header_Last_Modified', Label.UI_Label_Account_Territory_Users_Column_Header_Last_Modified);
        labelToValue.put('UI_Label_Account_Territory_Users_Title', Label.UI_Label_Account_Territory_Users_Title);
        labelToValue.put('UI_Label_Account_Territory_Users_No_Records', Label.UI_Label_Account_Territory_Users_No_Records);

        return labelToValue;
    }
     /*
    * @author Joshith K
    * @date   22-09-2019
    * @description US 27886 return true if Global Territory
    * @param Object Territory Association record
    */
    private static Boolean checkGlobalTerritory(ObjectTerritory2Association objectterAssociation)
    {   
         system.debug('global territory name'+globalTerrittoryName);
        set<string>parentTerritoryNames=new Set<String>();
        String parentTerritoryField = 'Territory2.ParentTerritory2.Name';
        while(TerritoriesSelector.getValue(objectterAssociation,parentTerritoryField) != null){
            parentTerritoryNames.add((String)TerritoriesSelector.getValue(objectterAssociation,parentTerritoryField));
            parentTerritoryField = parentTerritoryField.removeEnd('Name')+'ParentTerritory2.Name';
        }
           
        return parentTerritoryNames.contains(globalTerrittoryName);
    }
}