/**
 *    @author KD
 *    @date   11-Aug-2020
 *    @description : Controllerr class for Plan Representative
 *    @Test Class for 90% Code Coverage- TestPlanRepresentativeController
 *    @Test Class for 75% Code Coverage- TestPlanRepresentativeController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Akshay Mohan                   12-Aug-2020         Changes for DCP-39673: Manage Users
 *    Akshay Mohan                   18-Aug-2020         Changes for DCP-39966: Cascade Hierarchy for Add Users
 *    Anisha Bharti                  01-Sept-2020        changes for DCP-39621: get user profile
 *    KD                             14-Sept             DCP-40041 : Notify Overlay user for Plan creation
 *   Juned                         24-09-21             @description DCP-48251
 *  Nishan Shetty                  21-Sept-2022          DCP-56402 Code Scan Issue.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class PlanRepresentativeController {
    public static final String ROLE_CODE_PARAMETER = 'Plan_DefaultUserRole';
    public static final String CPROLE_CODE_PARAMETER = 'Plan_CPUsers';
    public static final String ROLE_DELIMITER = ';';
    
    private static Id idOverlayRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Overlay_Plan').getRecordTypeId();
    private static String strTPrecordId;
    private static Map<Id,UserTerritory2Association> mapUserIdToUTA = new Map<Id,UserTerritory2Association>();
    private static String strBaseURL;
    private static Set<Id> setParentTerritoryId; //DCP-39966 DCP-56402[CodeScan Fix]
    private static Set<String> setRemovedKeys; //DCP-56402[CodeScan Fix]
    public static boolean catchException = false;
    public static final String ERROR_MSG = 'throwing custom exception';
    //DCP-39673: wrapper class to be used in manage user section
    /**
    *  @author Akshay
    *  @description Wrapper class
    **/
    public virtual class UserAssociation {//DCP-56402[CodeScan Fix]
        public final String strRole ,strUserName,strUserId;//DCP-56402[CodeScan Fix]
        /**
        *  @author Akshay
        *  @description Wrapper class
        **/
        public UserAssociation() {}//DCP-56402[CodeScan Fix]
        /**
        *  @author Akshay
        *  @description Wrapper class constructor
        **/
        public UserAssociation(UserTerritory2Association objUTA) {//DCP-56402[CodeScan Fix]
            this.strRole = objUTA.RoleInTerritory2;
            this.strUserName  = objUTA.User.name;
            this.strUserId  = objUTA.UserId;
        }
        /**
        *  @author Akshay
        *  @description Wrapper class constructor
        **/
        public UserAssociation(Plan__c objPlan,String strRoleName) {//DCP-56402[CodeScan Fix]
            this.strRole = strRoleName;
            this.strUserName  = objPlan.Plan_Owner_Name__c;
            this.strUserId  = objPlan.OwnerId;
        }
        /**
        *  @author Akshay
        *  @description Wrapper class constructor
        **/
        public UserAssociation(Plan_Representative_Association__c objPRA,String strRoleName) {//DCP-56402[CodeScan Fix]
            this.strRole = strRoleName;
            this.strUserName  = objPRA.User__r.Name;
            this.strUserId  = objPRA.User__c;
        }
        /**
        *  @author Akshay
        *  @description return Plan_Representative_Association__c object
        *  @param : Plan id
        **/
        public Plan_Representative_Association__c getSObject(String strPlanId) {//DCP-56402[CodeScan Fix]
            return new Plan_Representative_Association__c(User__c=strUserId,Territory_Plan__c=strPlanId);
        }
    }
    /**
    *  @author Akshay
    *  @description wrapper class for Plan Representative data table
    */
    public class UserPlanAssociation extends UserAssociation {//DCP-56402[CodeScan Fix]
        public string strPlanURL ,strPlanName ;
        Boolean boolHasOverlay;
        /**
        *  @author Akshay
        *  @description Wrapper class constructor
        **/
        public UserPlanAssociation(UserTerritory2Association objUTA) {//DCP-56402[CodeScan Fix]
            super(objUTA);
            this.boolHasOverlay = false;
        }
        /**
        *  @author Akshay
        *  @description Wrapper class constructor
        **/
        public UserPlanAssociation(Plan__c objPlan,String strRoleName) {//DCP-56402[CodeScan Fix]
            super(objPlan,strRoleName);
            this.strPlanURL = '/'+objPlan.id;
            this.strPlanName = objPlan.Name;
            this.boolHasOverlay = true;
        }
        /**
        *  @author Akshay
        *  @description Wrapper class constructor
        **/
        public UserPlanAssociation(Plan_Representative_Association__c objPRA,String strRoleName) {//DCP-56402[CodeScan Fix]
            super(objPRA,strRoleName);
            this.boolHasOverlay = false;
        }
    }

    /**
    *  @author KD
    *  @description to fetch Overlay Plan
    *  @param Plan Record Id
    *  @return String
    **/
    @AuraEnabled(cacheable = true)
    public static String initRecords(String recordId) {//DCP-56402[CodeScan Fix]
        try {//DCP-56402[CodeScan Fix]
            strTPrecordId=recordId;
            List<UserPlanAssociation> lstUserTerritory2AssociationWrap = getCurrentUsers();
            boolean channelPartnerProfile = PlanRepresentativeControllerHelper.isChannelPartnerProfile(); //to fetch if user is of channel Partner profile
            Map<String,String> mapLabels = new Map<String,string>{
                'UI_Error_Message_No_Territory_Plan' => Label.UI_Error_Message_No_Territory_Plan,
                'UI_Label_Add_Representative' => Label.UI_Label_Add_Representative,
                'UI_Label_Remove_Representative' => Label.UI_Label_Remove_Representative,
                'UI_Message_No_Representative' => Label.UI_Message_No_Representative,
                'UI_Label_Remove_User' => Label.UI_Label_Remove_User,
                'UI_Label_Add_User' => Label.UI_Label_Add_User,
                'UI_Message_User_Notify' => Label.UI_Message_User_Notify
            };
            if(catchException == true){
                throw new AuraHandledException(ERROR_MSG);
            }
            return '{"lstUserTerritory2AssociationWrap": '+JSON.serialize(lstUserTerritory2AssociationWrap )+','
                    +' "mapLabels": '+JSON.serialize(mapLabels)+','
                    +' "channelPartnerProfile": '+channelPartnerProfile+'}';
                    } catch(Exception e) { //DCP-56402[CodeScan Fix]
            catchException = false;
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /**DCP-39673
    *  @author Akshay
    *  @description to fetch Users who can be added to plan
    *  @param Plan Record Id
    *  @return String JSON of List<UserAssociation>
    **/
    @AuraEnabled
    public static String getAddUsers(String recordId) {//DCP-56402[CodeScan Fix]
        try {//DCP-56402[CodeScan Fix]
            strTPrecordId=recordId;

            List<Plan__c> lstPlan = new PlanSelector().getTerritoryPlanbyId(strTPrecordId);
            Plan__c objPlan = lstPlan[0];

            // Fetch overlay plans on territory record is on
            List<UserPlanAssociation> lstUserTerritory2AssociationWrap = new List<UserPlanAssociation>();
            Set<Id> setCurrentReps = getTerritoryUsersWithOverlayPlan(objPlan,lstUserTerritory2AssociationWrap);
            
            // Fetch all parent territory in hierarchy
            getDefaultRoleUsersWithOverlayPlan(setCurrentReps,lstUserTerritory2AssociationWrap);

            //release heap
            lstUserTerritory2AssociationWrap=null;
        
            //DCP-39966: Add users from parent territories that are not already added
            List<UserAssociation> lstUserWrap = new List<UserAssociation>();
            getUsersFromParentTerritoryForAdd(objPlan.Territory_Code__c,setCurrentReps,lstUserWrap);
            
            //DCP-48251: Add users of All Heirarchy.
            if(objPlan.Channel_Partner__c != Null && String.isNotBlank(objPlan.Channel_Partner__c)) {//DCP-56402[CodeScan Fix]
                getAllUsers(objPlan.Channel_Partner__c);
            }

            //Add users from same territory not already showing
            for(Id idUser: mapUserIdToUTA.keySet()) {//DCP-56402[CodeScan Fix]
                if(!setCurrentReps.contains(idUser)) {//add only users that are not showing //DCP-56402[CodeScan Fix]
                    lstUserWrap.add(new UserAssociation(mapUserIdToUTA.get(idUser)));
                    setCurrentReps.add(idUser);
                }
            }

            System.debug('lstUserWrap: ' + lstUserWrap);
            if(catchException == true){
                throw new AuraHandledException(ERROR_MSG);
            }
            return JSON.serialize(lstUserWrap);
            } catch(Exception e) {//DCP-56402[CodeScan Fix]
            catchException = false;
            logException(e);
            throw new AuraHandledException(e.getMessage());

        }
    }

    /**DCP-39673
    *  @author Akshay
    *  @description to add Users to plan
    *  @param JSON of users to be added
    *  @param Plan Record Id
    *  @return String JSON of List<UserPlanAssociation>
    **/
    @AuraEnabled
    public static String addUsers(String strJSON,String strRecordId) {//DCP-56402[CodeScan Fix]
    try {//DCP-56402[CodeScan Fix]
            if(catchException == true){
                throw new AuraHandledException(ERROR_MSG);
            }
            strTPrecordId=strRecordId;
            System.debug('strJSON: ' + strJSON);
            List<UserAssociation> lstUserWrap= (List<UserAssociation>)JSON.deserialize(strJSON,List<UserAssociation>.class);
            System.debug('lstUserWrap: ' + lstUserWrap);
            Map<Id,Plan_Representative_Association__c> mapPRA = new Map<Id,Plan_Representative_Association__c>();
            for(UserAssociation wrapUA: lstUserWrap) {//DCP-56402[CodeScan Fix]
                mapPRA.put(wrapUA.strUserId,wrapUA.getSObject(strRecordId));
            }
            System.debug('mapPRA: ' + mapPRA);
            List<Plan_Representative_Association__c> lstPRA = new List<Plan_Representative_Association__c>();
            for(Plan_Representative_Association__c objExisting: new PlanRepresentativeAssociationSelector().getRemovedUsersByTPId(strRecordId)) {//DCP-56402[CodeScan Fix]
                if(mapPRA.containsKey(objExisting.User__c)) {//DCP-56402[CodeScan Fix]
                    lstPRA.add(objExisting);
                    mapPRA.remove(objExisting.User__c);
                }
            }
            System.debug('lstPRA to Delete: ' + lstPRA);
            if(!lstPRA.isEmpty()) {//DCP-56402[CodeScan Fix]
                delete lstPRA;
            }   
            lstPRA = mapPRA.values();
            System.debug('lstPRA to insert: ' + lstPRA);
            if(!lstPRA.isEmpty()) {//DCP-56402[CodeScan Fix]
                insert lstPRA;
            }
            return JSON.serialize(getCurrentUsers());
            } catch(Exception e) {//DCP-56402[CodeScan Fix]
            catchException = false;
            logException(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**DCP-39673
    *  @author Akshay
    *  @description to add Users to plan
    *  @param JSON of users to be removed
    *  @param Plan Record Id
    *  @return String JSON of List<UserPlanAssociation>
    **/
    @AuraEnabled
    public static String removeUsers(String strJSON,String strRecordId) {//DCP-56402[CodeScan Fix]
        try {//DCP-56402[CodeScan Fix]
            if(catchException == true){
                throw new AuraHandledException(ERROR_MSG);
            }
            strTPrecordId=strRecordId;
            System.debug('strJSON: ' + strJSON);
            List<UserAssociation> lstUserWrap= (List<UserAssociation>)JSON.deserialize(strJSON,List<UserAssociation>.class);
            System.debug('lstUserWrap: ' + lstUserWrap);
            Map<Id,Plan_Representative_Association__c> mapPRA = new Map<Id,Plan_Representative_Association__c>();
            for(UserAssociation wrapUA: lstUserWrap) {//DCP-56402[CodeScan Fix]
                Plan_Representative_Association__c objPRA = wrapUA.getSObject(strRecordId);
                objPRA.Is_Removed__c=true;
                mapPRA.put(wrapUA.strUserId,objPRA);
            }
            System.debug('mapPRA: ' + mapPRA);
            List<Plan_Representative_Association__c> lstPRA = new List<Plan_Representative_Association__c>();
            for(Plan_Representative_Association__c objExisting: new PlanRepresentativeAssociationSelector().getAddedUsersByTPId(strRecordId)) {//DCP-56402[CodeScan Fix]
                if(mapPRA.containsKey(objExisting.User__c)) {//DCP-56402[CodeScan Fix]
                    lstPRA.add(objExisting);
                    mapPRA.remove(objExisting.User__c);
                }
            }
            System.debug('lstPRA to Delete: ' + lstPRA);
            if(!lstPRA.isEmpty()) {//DCP-56402[CodeScan Fix]
                delete lstPRA;
            }
            lstPRA = mapPRA.values();
            System.debug('lstPRA to insert: ' + lstPRA);
            if(!lstPRA.isEmpty()) {//DCP-56402[CodeScan Fix]
                insert lstPRA;
            }
            return JSON.serialize(getCurrentUsers());
            } catch(Exception e) {//DCP-56402[CodeScan Fix]
            catchException = false;
            logException(e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    *  @author KD
    *  @description to fetch Overlay Plan
    *  @param Plan Record Id
    *  @return List<UserPlanAssociation>
    **/
    private static List<UserPlanAssociation> getCurrentUsers() {//DCP-56402[CodeScan Fix]
        List<Plan__c> lstPlan = new PlanSelector().getTerritoryPlanbyId(strTPrecordId);
        Plan__c objPlan = lstPlan[0];
        
        // Fetch overlay plans on territory record is on
        
        List<UserPlanAssociation> lstUserTerritory2AssociationWrap = new List<UserPlanAssociation>();
        Set<Id> setCurrentReps = getTerritoryUsersWithOverlayPlan(objPlan,lstUserTerritory2AssociationWrap);
        
        // Fetch all parent territory in hierarchy
        getDefaultRoleUsersWithOverlayPlan(setCurrentReps,lstUserTerritory2AssociationWrap);
        
        return lstUserTerritory2AssociationWrap;
    }

    
    /**
    *  @author Akshay
    *  @description fetch the overlay plans based on owner of the users on the territory of the plan
    *  @param Plan Record Id
    *  @return String
    **/
    private static Set<Id> getTerritoryUsersWithOverlayPlan(Plan__c objPlan, List<UserPlanAssociation> lstUserTerritory2AssociationWrap) {//DCP-56402[CodeScan Fix]
        //DCP-39966: get user acrros hierarchy
        setParentTerritoryId = new TerritoriesSelector().getTerritoryCodeIncludingParents(new Set<String>{objPlan.Territory_Code__c});
        List<UserTerritory2Association> lstUserInTerritory = new UserTerritory2AssociationSelector().selectByTerritoryId(setParentTerritoryId);
        Set<Id> setOverlayUserIds=new Set<Id>();
        for(UserTerritory2Association objUTA : lstUserInTerritory) {//DCP-56402[CodeScan Fix]
            mapUserIdToUTA.put(objUTA.UserId,objUTA);
        }    
        List<Plan__c> lstOverlayPlanInTerritory = new PlanSelector().getPlanbyOwnerandRecordId(mapUserIdToUTA.keySet(),idOverlayRecordType);
        for(Plan__c objOverlayPlan : lstOverlayPlanInTerritory) {//DCP-56402[CodeScan Fix]
            if(isRemoved(objOverlayPlan.OwnerId)) {continue;}//if it's a removed record don't add //DCP-56402[CodeScan Fix]
            lstUserTerritory2AssociationWrap.add(new UserPlanAssociation(objOverlayPlan,mapUserIdToUTA.get(objOverlayPlan.OwnerId).RoleInTerritory2));
            setOverlayUserIds.add(objOverlayPlan.OwnerId);
        }
        System.debug('lstUserTerritory2AssociationWrap from current territory->'+lstUserTerritory2AssociationWrap);
        for(Plan_Representative_Association__c objAddedRep: new PlanRepresentativeAssociationSelector().getAddedUsersByTPId(strTPrecordId)) {//DCP-56402[CodeScan Fix]
            if(mapUserIdToUTA.containsKey(objAddedRep.User__c)) {//DCP-56402[CodeScan Fix]
                lstUserTerritory2AssociationWrap.add(new UserPlanAssociation(objAddedRep,mapUserIdToUTA.get(objAddedRep.User__c).RoleInTerritory2));
                setOverlayUserIds.add(objAddedRep.User__c);
            }
        }
        System.debug('lstUserTerritory2AssociationWrap from added records->'+lstUserTerritory2AssociationWrap);
        System.debug('setOverlayUserIds->'+setOverlayUserIds);
        return setOverlayUserIds;
    }

    /**
    *  @author Akshay
    *  @description fetch the overlay plans based on owner of the users on the territory of the plan
    *  @param Plan Record Id
    *  @return String
    **/
    private static void getDefaultRoleUsersWithOverlayPlan(Set<Id> setCurrentReps,List<UserPlanAssociation> lstUserTerritory2AssociationWrap) {//DCP-56402[CodeScan Fix]
        
        // Fetch user based on default hierarchy
        List<String> lstDefaultRole = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{ROLE_CODE_PARAMETER})[0].value__c.split(ROLE_DELIMITER);
        List<UserTerritory2Association> lstDefaultPlanReps = new UserTerritory2AssociationSelector().selectUsersByTerritoriesAndRoles(setParentTerritoryId,lstDefaultRole);
        for(UserTerritory2Association objUTA : lstDefaultPlanReps) {
            if(!setCurrentReps.contains(objUTA.UserId) && !isRemoved(objUTA.UserId)) {
                lstUserTerritory2AssociationWrap.add(new UserPlanAssociation(objUTA));
                setCurrentReps.add(objUTA.UserId);
            }
        }
        
        System.debug('lstUserTerritory2AssociationWrap final list->'+lstUserTerritory2AssociationWrap);
        System.debug('setCurrentReps->'+setCurrentReps);
        
    }

    /**
    *  @author Akshay
    *  @description fetch the Users from parent territories. First check in highest territory then the lower territories
    *  @param String strTerritoryCode,Set<Id> setCurrentReps,List<UserAssociation> lstUsers
    *  @return List<UserAssociation>
    **/
    private static void getUsersFromParentTerritoryForAdd(String strTerritoryCode,Set<Id> setCurrentReps,List<UserAssociation> lstUsers) {//DCP-56402[CodeScan Fix]
        
        List<Territory2> lstParentTerritories = new TerritoriesSelector().getByTerritoryCode(new Set<String>{strTerritoryCode});
        Territory2 objT = lstParentTerritories[0];
        if (String.isNotBlank(objT.ParentTerritory2Id)) {//DCP-56402[CodeScan Fix]
            addUsersInTerritory(objT.ParentTerritory2Id,setCurrentReps,lstUsers);
        }
        if (String.isNotBlank(objT.ParentTerritory2.ParentTerritory2Id)) {//DCP-56402[CodeScan Fix]
            addUsersInTerritory(objT.ParentTerritory2.ParentTerritory2Id,setCurrentReps,lstUsers);
        }
        if (String.isNotBlank(objT.ParentTerritory2.ParentTerritory2.ParentTerritory2Id)) {//DCP-56402[CodeScan Fix]
            addUsersInTerritory(objT.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,setCurrentReps,lstUsers);
        }
        if (String.isNotBlank(objT.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id)) {//DCP-56402[CodeScan Fix]
            addUsersInTerritory(objT.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,setCurrentReps,lstUsers);
        }  
    }

    /**
    *  @author Akshay
    *  @description Add users from territory passed
    *  @param Id idTerritory, Set<Id> setCurrentReps,List<UserAssociation> lstUsers
    *  
    **/
    private static void addUsersInTerritory(Id idTerritory, Set<Id> setCurrentReps,List<UserAssociation> lstUsers) {//DCP-56402[CodeScan Fix]
        
        for(UserTerritory2Association objUTA: new UserTerritory2AssociationSelector().selectByTerritoryId(new Set<Id>{idTerritory})) {//DCP-56402[CodeScan Fix]
            if(!setCurrentReps.contains(objUTA.UserId)) {//add only users that are not already added//DCP-56402[CodeScan Fix]
                lstUsers.add(new UserAssociation(objUTA));
                setCurrentReps.add(objUTA.UserId);
            }
        }
        
    }

    /**
    *  @author Akshay
    *  @description compute removed set
    *  @param Plan Record Id
    *  @return String
    **/
    private static Set<String> getRemovedKeys() {//DCP-56402[CodeScan Fix]
        if(setRemovedKeys!=null) {//DCP-56402[CodeScan Fix]
            return setRemovedKeys;
        }
        setRemovedKeys= new Set<String>();
        for(Plan_Representative_Association__c objRemovedRep: new PlanRepresentativeAssociationSelector().getRemovedUsersByTPId(strTPrecordId)) {//DCP-56402[CodeScan Fix]
                setRemovedKeys.add(objRemovedRep.User__c);
        }
        System.debug('setRemovedKeys: '+setRemovedKeys);
        return setRemovedKeys;
    }

    /**
    *  @author Akshay
    *  @description check if overlayplan was manually removed
    *  @param User Record Id
    *  @return String
    **/
    private static Boolean isRemoved(String strUserId) {//DCP-56402[CodeScan Fix]
        return getRemovedKeys().contains(strUserId);
    }
    /**DCP-40041
    *  @author Kushagra Desai
    *  @description DCP-40041 : Notify Overlay user for Plan creation
    *  @param Plan Id and Overllay User id
    *  @return void
    **/
    @AuraEnabled
    public static void notifyOverlayUser(String strPlanId,String strOverlayUserId) {//DCP-56402[CodeScan Fix]
    try {//DCP-56402[CodeScan Fix]
            if(catchException == true){
                throw new AuraHandledException(ERROR_MSG);
            }
            strBaseURL=System.Url.getOrgDomainUrl().toString().split('=')[1].remove(']')+'/';
            System.debug('strBaseURL: '+strBaseURL);
            List<Plan__c> lstPlan = new PlanSelector().getTerritoryPlanbyId(strPlanId);
            EmailTemplate emailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{Label.Overlay_Notification_Template})[0];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSaveAsActivity(false);
            email.setSubject(emailTemplate.Subject);
            email.setToAddresses(new List<String>{strOverlayUserId});
            email.setCcAddresses(new List<String>{lstPlan[0].OwnerId});
            email.setHtmlBody(replaceBindVariables(emailTemplate.HtmlValue,lstPlan[0]));
            email.setPlainTextBody(replaceBindVariables(emailTemplate.Body,lstPlan[0]));
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email } );

            } catch(Exception e) {//DCP-56402[CodeScan Fix]
            catchException = false;
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /**
    * @author KD
    * @date   23-Oct-2020
    * @description  Replace content with Plan attributes
    */
    private static String replaceBindVariables(String strContent,Plan__c objPlan) {//DCP-56402[CodeScan Fix]
        String strReplaced = strContent.replaceAll('(\\{!Plan__c\\.Name\\})',objPlan.Name);
        strReplaced=strReplaced.replaceAll('(\\{!Plan__c\\.OwnerFullName\\})',objPlan.Plan_Owner_Name__c);  
        strReplaced=strReplaced.replaceAll('(\\{!TODAY\\(\\) \\+ 7\\})',(Date.Today()+7).format());
        strReplaced=strReplaced.replaceAll('(\\{!Plan__c\\.Link\\})',strBaseURL+objPlan.Id);
        strReplaced=strReplaced.remove('<![CDATA[');
        strReplaced=strReplaced.remove(']]>');
        return strReplaced;
    }
    /*
    *  @author KD
    *  @description Error handling
    *  @param Exception
    **/
    public static void logException(Exception e) {//DCP-56402[CodeScan Fix]
        System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
        System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
        System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
        System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
        System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
    }
    /*
    *  @author Juned
    *  @description DCP-48251
    *  @param Plan Object
    **/
    public static void getAllUsers(String channelPartner) {//DCP-56402[CodeScan Fix]
        try {//DCP-56402[CodeScan Fix]
            if(catchException == true){
                throw new AuraHandledException(ERROR_MSG);
            }
            List<String> lstMasterLabel = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CPROLE_CODE_PARAMETER})[0].Values_Text__c.split(ROLE_DELIMITER);
            Code_Parameter__mdt planCpUser = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CPROLE_CODE_PARAMETER})[0];
            List<ObjectTerritory2Association> lstUserInTerritory = new ObjectTerritory2AssociationsSelector().indirectTerritoryPlanByMasterLabel(channelPartner, lstMasterLabel);
            Id assignedTerritory = null;
            if(!lstUserInTerritory.isEmpty()) {
                assignedTerritory = lstUserInTerritory[0].Territory2ID;
            }
            
            if(assignedTerritory!= null) {//DCP-56402[CodeScan Fix]
                Set<Id> setAccounts = new Set<Id>();
                
                lstUserInTerritory = new ObjectTerritory2AssociationsSelector().selectByTerritoryId(new Set<Id>{assignedTerritory});
                for(ObjectTerritory2Association objTerritory2Association : lstUserInTerritory) {//DCP-56402[CodeScan Fix]
                    setAccounts.add(objTerritory2Association.objectId);
                }
                
                List<Account> lstAccount = new AccountsSelector().selectAccounts(setAccounts);
                
                for(Account objAccount : lstAccount) {//DCP-56402[CodeScan Fix]
                    if(!planCpUser.PickListValue__c.split(ROLE_DELIMITER).contains(objAccount.Account_Group__c )) {
                        setAccounts.remove(objAccount.Id);
                    }
                }
                
                Set<Id> setTerritories = new Set<Id>();
                
                List<ObjectTerritory2Association> lstObjectTerritory2Association = new ObjectTerritory2AssociationsSelector().selectByAccountIds(setAccounts);
                for(ObjectTerritory2Association objTerritory2Association : lstObjectTerritory2Association) {//DCP-56402[CodeScan Fix]
                    setTerritories.add(objTerritory2Association.Territory2ID);
                }

                Set<Id> setParentTerritories = new Set<Id>();
                Map<Id, Set<Id>> lstParentTerritories = new TerritoriesSelector().selectTerritoriesInHierarchy(setTerritories);
                for(Id territoryId : lstParentTerritories.keySet()) {
                    setParentTerritories.addAll(lstParentTerritories.get(territoryId));
                    setParentTerritories.add(territoryId);
                }

                List<String> lstDefaultRole = planCpUser.value__c.split(ROLE_DELIMITER);
                List<UserTerritory2Association> lstUTA = new UserTerritory2AssociationSelector().selectUsersByTerritoriesAndRoles(setParentTerritories, lstDefaultRole);
                for(UserTerritory2Association uta: lstUTA) {
                    mapUserIdToUTA.put(uta.UserId, uta);
                }
            }
            } catch(Exception e) {//DCP-56402[CodeScan Fix]
            catchException = false;
            throw new AuraHandledException(e.getMessage()); 
        }   
    }
}