/**
 *    @author KD
 *    @date   30-March-2021
 *    @description  Trigger Handler for CaseChangeEvent
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *     KD                           6-June-2021           INC0326077  : Delete existing junncction record when case region is updated.
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class CaseChangeEvents extends ilib_SObjectDomain{
    public static final String SETUP_NOTIFICATION_DETAIL = 'Notification Details Setup';
	public static final String HEADER_CHANGE_TYPE_CREATE = 'CREATE';
	public static final String HEADER_CHANGE_TYPE_UPDATE = 'UPDATE';
    public static Set<String> setNewCaseId = new Set<String>();
    /*
     * Constructor for CaseChangeEvents
     */
    public CaseChangeEvents(List<CaseChangeEvent> sObjectList)
    {
        super(sObjectList);
        configuration.disableTriggerCRUDSecurity();
    }
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
         * Constructor for Account Plans
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CaseChangeEvents(sObjectList);
        }
    }
    /**
     *  @author       : KD
     *  @description  : afterinsert handler
     *  @return       : void
     */
    public override void onAfterInsert(){
        Set<String> setFieldUpdate = new Set<String>();
        Set<String> setConcernCaseChanges = new Set<String>();
        List<CaseChangeEvent> lstCaseChangeEvent = (List<CaseChangeEvent>)records;
        Set<String> setRegionChangeCases = new Set<String>();
        Notification_Detail__c objSetupNotificationDetails = new NotificationDetailsSelector().getSetUpNotificationDetail();
        Map<String,Set<String>> mapCaseIdToFieldUpdate = new Map<String,Set<String>>();
         setFieldUpdate.addAll(objSetupNotificationDetails.Rule_Syntax__c.split('\\|'));
        for(CaseChangeEvent objCaseCDC : lstCaseChangeEvent){
            EventBus.ChangeEventHeader header = objCaseCDC.ChangeEventHeader;
            System.debug('--Event--->'+header);
            // Sample : eventbus.ChangeEventHeader[getChangedFields=(Subject, LastModifiedDate);getChangeOrigin=com/salesforce/api/soap/51.0;client=SfdcInternalAPI/;getChangeType=UPDATE;getCommitNumber=362054664831;getCommitTimestamp=1616953798000;getCommitUser=0051N000008PrIBQA0;getDiffFields=();getEntityName=Case;getNulledFields=();getRecordIds=(5002i000006wvzMAAQ);getSequenceNumber=1;getTransactionKey=00002ac7-b732-d0ae-5fd9-c19da8aeefc1;]
            if(header.changetype == HEADER_CHANGE_TYPE_CREATE){
                //In case of Case creation
                setConcernCaseChanges.addAll(header.getRecordIds());
                setNewCaseId.addAll(header.getRecordIds());
            }
            if(header.changetype == HEADER_CHANGE_TYPE_UPDATE){
                if(header.changedFields.contains('Region__c')){
                    setRegionChangeCases.addAll(header.getRecordIds());
                }
                // In case of Case update
                for (String field : header.changedFields){
                    if(setFieldUpdate.contains(field)){
                        // Check if mentioned fields are updated
                        mapCaseIdToFieldUpdate.put(header.getRecordIds()[0],new Set<String>(header.changedFields));
                        setConcernCaseChanges.addAll(header.getRecordIds());
                        break;
                    }
                }
            }
        }
        System.debug('Set of Case id for notification -->'+setConcernCaseChanges);
        System.debug('Set of Case id for mapCaseIdToFieldUpdate -->'+mapCaseIdToFieldUpdate);
        try{
            if(!setRegionChangeCases.isEmpty()){
                deleteExistingMSTeamNotification(setRegionChangeCases);
            }
            upsertMSTeamNotificationRecords(setConcernCaseChanges,mapCaseIdToFieldUpdate,setFieldUpdate);
        }catch(Exception e){
            System.debug('Exception-->'+e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
            ApexExceptions.emit('CaseChangeEvents',e);
        }
    }
    /**
     * @author KD
     * @description method to create juntion records of MS_Team_Notification object
     * @param Set of case id
     */
    public static void upsertMSTeamNotificationRecords(Set<String> idCaseids,Map<String,Set<String>> mapCaseIdToFieldUpdate,Set<String> setFieldUpdate){
        
        List<Case> lstCase = new CasesSelector().selectCasesFromSetIdsDynamicField(new Set<Id>( (List<Id>)new List<String>( idCaseids ) ),setFieldUpdate);
        List<Notification_Detail__c> lstNotification = new NotificationDetailsSelector().selectAllActiveRecords();
        Map<Id,List<MS_Team_Notification__c>> mapExistingCaseidToMSNotification = new Map<Id,List<MS_Team_Notification__c>>();
        List<MS_Team_Notification__c> lstMSTeamNotification = new MSTeamNotificationsSelector().selectByCaseAndActive(idCaseids);
        List<MS_Team_Notification__c> lstMSTeamNotificationToUpsert = new List<MS_Team_Notification__c>();
        if(!lstMSTeamNotification.isEmpty())
            mapExistingCaseidToMSNotification= UtilsCollection.getMapOfIdToSObjects(lstMSTeamNotification,'Case__c');
        lstMSTeamNotificationToUpsert.addAll(
            CaseChangeEventsService.fetchMSTeamNotificationRecords(
                lstCase,
                setNewCaseId,
                mapExistingCaseidToMSNotification,
                lstNotification,
                mapCaseIdToFieldUpdate)
            ); 
        if(!lstMSTeamNotificationToUpsert.isEmpty())
            Database.upsert(lstMSTeamNotificationToUpsert);
    }
    /**
     * @author KD
     * @description method to delete juntion records of MS_Team_Notification object
     * @param Set of case id
     */
    public static void deleteExistingMSTeamNotification(Set<String> setRegionChangeCases){
        List<MS_Team_Notification__c> lstMSTeamNotification = new MSTeamNotificationsSelector().selectByCaseAndActive(setRegionChangeCases);
        if(!lstMSTeamNotification.isEmpty()){
            delete lstMSTeamNotification;
        }
    }
}