    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class for Utility Settings implementation
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Todd Newman                                      Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/

public with sharing class UtilsSettings {

    private static final String LOG_TITLE = 'UtilsSettings';
    private static final String CODE_PARAM_AUTOMATED_USERS = 'Automated_Users';
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve CustomMetadataMap based on the custom metadata config name
    *  @Param       : String
    *  @Return      : Map<String, String>
    */
    public static Map<String, String> getCustomMetadataMap(String settingName)
    {
        Map<String, String> settings = new Map<String, String>();

        List<Code_Parameter__mdt> rawSettings =
            [SELECT Id, MasterLabel, DeveloperName, Value__c, Description__c
             FROM Code_Parameter__mdt
             WHERE DeveloperName = :settingName];

        if (rawSettings.size() > 0)
        {
            Code_Parameter__mdt param = rawSettings.get(0);

            Matcher matchedSetting = Pattern.compile('(.+?):\\s*(.+?)(?:\\r*\\n|$)').matcher(param.Value__c);

            while (matchedSetting.find())
            {
                settings.put(matchedSetting.group(1).trim(), matchedSetting.group(2).trim());
            }
        }

        return settings;
    }

    // NOTE: not used yet 
    // this is a handy function to check if the running user has a custom permission
    // I have no doubt this will be used in this org - probably when the merge account
    // requirements come through
//    private static Map<String, CustomPermission> customPermissionCache = new Map<String, CustomPermission>();
//    public static Boolean hasCustomPermission(Set<String> permissions)
    //    {
//        List<String> permissionsCopy = new List<String>(permissions);
//        for (Integer i=permissionsCopy.size() - 1; i>=0; i--)
//        {
//            String p = permissionsCopy.get(i);
//            if (customPermissionCache.containsKey(p))
//                permissionsCopy.remove(i);
//        }
//
//        if (permissionsCopy.size() > 0)
//        {
//            for (CustomPermission cp : [SELECT Id, DeveloperName
//                    FROM CustomPermission
//                    WHERE NamespacePrefix = ''
//                    AND DeveloperName in :permissionsCopy]
//            ) {
//                customPermissionCache.put(cp.DeveloperName, cp);
//            }
//        }
//
//        List<CustomPermission> customPermissions = new List<CustomPermission>();
//        for (String p : permissions)
//            customPermissions.add(customPermissionCache.get(p));
//
//        Set<Id> customPermissionIds = UtilsCollection.getSetOfIds(customPermissions, 'Id');
//
//        List<SetupEntityAccess> permissionAssignments =
//            [SELECT SetupEntityId, SetupEntityType
//            FROM SetupEntityAccess
//            WHERE SetupEntityId in :customPermissionIds AND
//            ParentId IN (SELECT PermissionSetId
//                FROM PermissionSetAssignment
//                WHERE AssigneeId = :UserInfo.getUserId())
//            ];
//
//        return !permissionAssignments.isEmpty();
//    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve CustomMetadata picklist map based on the parameter values
    *  @Param       : Two parameters of type String and Boolean
    *  @Return      : Map<String, Map<String,String>>
    */

    public static Map<String, Map<String,String>> getCustomMetadataPicklistMap(String objectAPIName,String externalSystem, Boolean booIsOutbound)
    {
        Map<String, Map<String,String>> picklistValues = new Map<String, Map<String,String>>();

        List<External_System_Picklist_Mapping__mdt> rawSettings =
            [SELECT Id, MasterLabel, DeveloperName, External_System__c, External_System_Value__c
             ,Object_API_Name__c,Picklist_Field_API_Name__c,Salesforce_Value__c
             FROM External_System_Picklist_Mapping__mdt
             WHERE Object_API_Name__c = :objectAPIName AND External_System__c =: externalSystem];

        if (rawSettings.size() > 0)
        {
            for(External_System_Picklist_Mapping__mdt picklistMapping: rawSettings) {
                if(!picklistValues.containskey(picklistMapping.Picklist_Field_API_Name__c)) {
                    picklistValues.put(picklistMapping.Picklist_Field_API_Name__c, new Map<String,String>());
                }   
                if(booIsOutbound) {
                    picklistValues.get(picklistMapping.Picklist_Field_API_Name__c).put(picklistMapping.Salesforce_Value__c,picklistMapping.External_System_Value__c);
                
                } else {
                    picklistValues.get(picklistMapping.Picklist_Field_API_Name__c).put(picklistMapping.External_System_Value__c,picklistMapping.Salesforce_Value__c);
                    
                }
                    
            }
        }

        return picklistValues;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve get integer from map value
    *  NOTE: maybe move to UtilsCollection?
    *  @Param       : Map<String, String>, String, Integer
    *  @Return      : Integer
    */
    
    public static Integer parseIntegerFromSettingsMap(Map<String, String> values, String keyName, Integer defaultValue)
    {
        Integer res = defaultValue;
        if (values.containsKey(keyName))
        {
            try
            {
                res = Integer.valueOf(values.get(keyName));
            }
            catch (Exception e) { 
				/* let pass and use default */
				System.debug('Inside UtilsSettings.apxc the exception is '+e.getMessage());
                ApexExceptions.emit('exception',e);
			}
        }

        return res;
    }
    public static List<String> CPQCLM_RO_Approver_Steps{
        get{
            if(CPQCLM_RO_Approver_Steps == null){
                List<Code_Parameter__mdt> lstApprovalSteps = [SELECT Id, MasterLabel, DeveloperName, Value__c, Description__c
                                                              FROM Code_Parameter__mdt WHERE DeveloperName = 'CPQCLM_RO_Approver_Steps'];
                CPQCLM_RO_Approver_Steps = lstApprovalSteps[0].Value__c.split(',');
            }
            return CPQCLM_RO_Approver_Steps;
        }
        set;
    }

    /***
     * @author Gerardo Garcia
     * @description Allow to identify if the current user is an automated user
     * @return Boolean
     */
    public static Boolean isAutomatedUser(){
        ilib_LogEvent.push(LOG_TITLE + '.isAutomatedUser()');
        List<String> lstOfAutomatedUsers = Code_Parameter__mdt.getInstance(CODE_PARAM_AUTOMATED_USERS)?.Value__c?.split(';');
        ilib_LogEvent.message('lstOfAutomatedUsers:' + lstOfAutomatedUsers);

        if(lstOfAutomatedUsers == null || lstOfAutomatedUsers.isEmpty()) {
            ilib_LogEvent.info('Code Parameter "Automated_Users" does not have values');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return false;
        }

        String userName = UserInfo.getName();
        ilib_LogEvent.message('userName:' + userName);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
        return  lstOfAutomatedUsers.contains(userName);
    }

}