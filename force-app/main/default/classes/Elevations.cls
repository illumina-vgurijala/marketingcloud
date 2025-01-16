/**
* @author: Deepika Ayyavari
* @date Dec-2021
* @group ElevationTrigger
* @description Trigger Handler on Elevation used to handle the functionality when user triggers an event.
*
* Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *       Developer                      Date                Description
 *    Deepika Ayyavari              15-Dec-2021         Initial Version
 *    Vignesh Sethuramalingam       02-Mar-2022         Logic to send notifications.
 *    Rohan                         30-May-2022         Logic to check Elevation Member For Elevation Category
 */

public with sharing class Elevations extends ilib_SObjectDomain{
    private static final String LOG_TITLE = 'Elevation';
    public static final String ELEVATION_CREATE = 'Elevation_Technical_Create_Status';
    public static final String ELEVATION_REOPEN = 'Elevation_Reopen_Status';
    public static final Id TECHNICAL_ELEVATION_RECORDTYPE = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
    public static final Id ACCOUNT_ELEVATION_RECORDTYPE = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();
    public static final String OPEN_STATUS = '_Open';
    public static final String HOT_SITE = 'Hot Site';
    public static final String WATCHER_TYPE = 'Executive Summary Key Stakeholder';
    public static List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>();
    public static final String PERMISSION_SET_RPS_FSM = 'RPS_FSM_FAM';
    public static Boolean hasPermission = false; 
    

    /*constructor. call to super class constructor
    */
    public Elevations(List<Elevations__c> sObjectList)
    {
        super(sObjectList);
        ilib_LogEvent.rootTitle = LOG_TITLE;
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**Constructor */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Elevations(sObjectList);
        }
    }

    /**
    *  @author Deepika Ayyavari
    *  @description - To be executed, on before Update.              
    **/
	public override void onBeforeUpdate (Map<Id, SObject> mapOld){    
        queryForExecution(records); 
        populateElevationOwner(records , mapOld);
        checkPermissionSetAssignment(records); 
    }
	
	/**
    *  @author Deepika Ayyavari
    *  @description - To be executed, on after update.              
    **/
    public override void onAfterUpdate (Map<Id, SObject> mapOld){
        system.debug('records:::'+records);
        queryForExecution(records);
        checkElevationForNotification(records , mapOld);
    }

	/**
    *  @author Deepika Ayyavari
    *  @description - To be executed, on after insert.              
    **/
    public override void onAfterInsert(){
        system.debug('records 52:::'+records);
        queryForExecution(records);
        checkElevationForNotification(records , null);
    }
  
	/* 
    Description: Method to populate Elevation Owner based on custom Owner field.
    Return: Void
    */
	public void populateElevationOwner(List<SObject> records, Map<Id,SObject> oldRecords){
		for(Elevations__c objElevation : (List<Elevations__c>) records) {
            if(objElevation.Elevation_Owner__c != NULL) {
			    objElevation.OwnerId = objElevation.Elevation_Owner__c;
            }
		}
	}
	
	
    /* 
    Description: Method to check Elevation Records for Notifications.
    Return: Void
    */
    public void checkElevationForNotification(List<SObject> records, Map<Id,SObject> oldRecords){
			Map<Id,SVMXC__Service_Order__c> mapWORecords= new Map<Id,SVMXC__Service_Order__c>(lstWorkOrder);
			Map<string,string> mapNotifications = new Map<string,string>();
			Map<string,Set<Id>> mapSendEmailNotifications = new Map<string,Set<Id>>();
			Map<string,set<string>> mapEmailSettingAccountId = new Map<string,set<string>>();

            if(oldRecords != Null){
                mapNotifications.put(TECHNICAL_ELEVATION_RECORDTYPE+OPEN_STATUS,Label.Technical_Elevation_Reopen_Notification);
                mapNotifications.put(ACCOUNT_ELEVATION_RECORDTYPE+'_Closed',Label.Account_Elevation_Closure_Notification);
                mapNotifications.put(ACCOUNT_ELEVATION_RECORDTYPE+OPEN_STATUS,Label.Elevation_Account_Reopen_Status_Metadata);
                mapNotifications.put(TECHNICAL_ELEVATION_RECORDTYPE+'_'+Label.Elevation_Status_Closed_Actions_Complete,Label.Elevation_Technical_Close_Status_Metadata);
                mapNotifications.put(TECHNICAL_ELEVATION_RECORDTYPE+'_'+Label.Elevation_Status_Closed_Actions_Could_Not_Be_Completed,Label.Elevation_Technical_Close_Status_Metadata);
            } else {
                mapNotifications.put(ACCOUNT_ELEVATION_RECORDTYPE+OPEN_STATUS,label.Elevation_Account_Open_Status_Metadata);
                mapNotifications.put(TECHNICAL_ELEVATION_RECORDTYPE+OPEN_STATUS,label.Technical_Elevation_Create_Notification);
            }

			for(Elevations__c objElevation : (List<Elevations__c>) records){
				Elevations__c objOldTechElevation;
                if(oldRecords != Null){
                    objOldTechElevation = (Elevations__c)(oldRecords.get(objElevation.Id));
                }

				if( ((oldRecords != Null && objElevation.Elevation_Status__c != objOldTechElevation.Elevation_Status__c)  || oldRecords == Null ) &&
                    mapNotifications.containsKey(objElevation.RecordTypeId+'_'+objElevation.Elevation_Status__c)){
					
                    String strEmailSetting = mapNotifications.get(objElevation.RecordTypeId+'_'+objElevation.Elevation_Status__c);
					if(!mapSendEmailNotifications.containsKey(strEmailSetting)){
						mapSendEmailNotifications.put(strEmailSetting , new Set<Id>());
						mapEmailSettingAccountId.put(strEmailSetting, new set<string>());
					}
					mapSendEmailNotifications.get(strEmailSetting).add(objElevation.Id);
					mapEmailSettingAccountId.get(strEmailSetting).add(  mapWORecords.get(objElevation.Work_Order__c).SVMXC__Company__c );
				}
			}
            system.debug('mapSendEmailNotifications:::'+mapSendEmailNotifications+'@@@'+mapEmailSettingAccountId);
            if(mapSendEmailNotifications != null && !mapSendEmailNotifications.isEmpty()){
                sendElevationNotification( mapSendEmailNotifications, mapEmailSettingAccountId);
            }
		
    }

     /**
    *  @author Deepika Ayyavari
    *  @description - fetching elevation records from selector class.              
    **/

    public void queryForExecution(List<Sobject> records){
        Set<Id> setWO = new Set<Id>();
        for(Elevations__c objElevation : (List<Elevations__c>) records){
            setWO.add(objElevation.Work_Order__c);
        }
            
        lstWorkOrder = new WorkOrdersSelector().selectWorkOrders(setWO);
    }


    /* 
    Description: Method to fetch Account to field support and send Notifications.
    Return: Void
    */
    public void sendElevationNotification( Map<String, Set<Id>> mapSendEmailNotifications , Map<String,Set<String>> mapEmailSettingAccountId ){
			//Iterating and calling SOQL inside a for loop considering it is as a limited set of notifications.
			for(String strEmailSetting : mapSendEmailNotifications.keyset() ){
				Send_Email_Setting__mdt objEmailSetting = Send_Email_Setting__mdt.getInstance(strEmailSetting);
				Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = new Map<Id,Map<String,Account_to_Field_Support__c>>();
				if(!String.isBlank(objEmailSetting.To_Address_Roles__c)){
					Set<String> setAFSRoles = new Set<String>();
					setAFSRoles.addAll(objEmailSetting.To_Address_Roles__c.split(';'));

					accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(mapEmailSettingAccountId.get(strEmailSetting) ,setAFSRoles); 
				}
                List<Elevations__c> lstElevationsRecord = new ElevationsSelector().selectElevations(mapSendEmailNotifications.get(strEmailSetting));
				system.debug('lstElevationsRecord:::'+lstElevationsRecord);
                SendEmailNotification.getSendEmailParamaters( strEmailSetting , lstElevationsRecord , accountIdToFSERoles , 'Work_Order__r.SVMXC__Company__c');
			}
        
    }

    /**
    * @description 
    * @author  | 05-27-2022 
    * @param records 
    * @param oldRecords 
    **/
    public void checkElevationMemberForElevationCategory(List<SObject> records) {
        Map<Id,Elevations__c> woIdBYElevationRecord = new Map<Id,Elevations__c>();
        List<Related_Contacts__c> lstRelCon = new List<Related_Contacts__c>();
        Set<Id> setWOIds = new Set<Id>();        
        try {
            for(Elevations__c objElevation : (List<Elevations__c>) records) {
                if(objElevation.recordTypeId == ACCOUNT_ELEVATION_RECORDTYPE && objElevation.Work_Order__c != null && objElevation.Elevation_Category__c == HOT_SITE ) {
                    setWOIds.add(objElevation.Work_Order__c);
                    woIdBYElevationRecord.put(objElevation.Id,objElevation);
                }
            }                     
            if(!woIdBYElevationRecord.isEmpty()) {                
                RelatedContactsSelector objRCSelector = new RelatedContactsSelector();
                lstRelCon =  objRCSelector.selectElevationMembersByCategory(setWOIds);                        
                validateMemberForElevation(lstRelCon, woIdBYElevationRecord);             
            }
        }
        catch(Exception e) {
            //catch the exception
            ApexExceptions.emit('Elevations', e);
        }             
    }

    /**
    * @description 
    * @author Rohan | 06-09-2022 
    * @param lstWatchers 
    * @param mapIdBYElevationRecord 
    **/
    public void validateMemberForElevation(List<Related_Contacts__c> lstWatchers, Map<Id,Elevations__c> mapIdBYElevationRecord){
        Map<Id,Integer> accElevationBYExecTypeCount = new Map<Id,Integer>();
        if(lstWatchers.isEmpty()){
            for(Elevations__c eleObj : mapIdBYElevationRecord.values()) {               
                eleObj.addError(System.label.Elevation_Category_Validaton_Message);                                                
            }
        }   
        if(!lstWatchers.isEmpty()){
            for(Related_Contacts__c rcObj :lstWatchers) { 
                
                if(!accElevationBYExecTypeCount.containsKey(rcObj.Elevated_Work_Order__c) && rcObj.Type__c != WATCHER_TYPE){
                    accElevationBYExecTypeCount.put(rcObj.Elevated_Work_Order__c,1);                        
                }
                else if(accElevationBYExecTypeCount.containsKey(rcObj.Elevated_Work_Order__c) && rcObj.Type__c == WATCHER_TYPE) {
                    accElevationBYExecTypeCount.put(rcObj.Elevated_Work_Order__c,0);
                }                                                                       
            }
            
            if(!accElevationBYExecTypeCount.isEmpty()) { 
                for(Elevations__c eleObj : mapIdBYElevationRecord.values()) {
                    if(accElevationBYExecTypeCount.containsKey(eleObj.Work_Order__c) && accElevationBYExecTypeCount.get(eleObj.Work_Order__c) == 1 ){
                        eleObj.addError(System.label.Elevation_Category_Validaton_Message);
                    }                                   
                }
            }     
        }        
        
    }

    /**
    * @description 
    * @author Rohan | 06-09-2022 
    * @param records 
    **/
    public void checkElevationCategoryValidation(List<SObject> records){
        Map<Id,SVMXC__Service_Order__c> mapWorkOrderId = new Map<Id,SVMXC__Service_Order__c>(lstWorkOrder);
                      
        try {
            for(Elevations__c objElevation : (List<Elevations__c>) records) {
                if(objElevation.recordTypeId == ACCOUNT_ELEVATION_RECORDTYPE && objElevation.Work_Order__c != null 
                 && objElevation.Elevation_Category__c == HOT_SITE
                 && (String.isBlank(objElevation.Success_Criteria__c) || objElevation.Elevation_Owner__c == null 
                    || mapWorkOrderId.get(objElevation.Work_Order__c).Business_Impact_to_Customer__c == null 
                    || mapWorkOrderId.get(objElevation.Work_Order__c).Business_Impact_to_Illumina__c == null)) {
                        objElevation.addError(System.label.Elevation_Hot_Site_Validation_Message);
                }
            }
        }
        catch(Exception e) {
            //catch the exception
            ApexExceptions.emit('Elevations', e);
        }
    }

    /**
    * @description Check for RPS and Product Support permission set
    * @author  Rohan| 06-28-2022 
    **/
    public void checkPermissionSetAssignment(List<SObject> records){
        hasPermission = FeatureManagement.checkPermission(PERMISSION_SET_RPS_FSM);
        if(hasPermission){
            checkElevationMemberForElevationCategory(records);
            checkElevationCategoryValidation(records);
        } 
    }
}