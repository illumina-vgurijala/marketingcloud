/***************************************************************************************************************************************
 * NAME   : QualityRecords
 * DESCRIPTION  : Domain class for QualityRecordTrigger
 *				      
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 04-Apr-2022  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gladis             	04-Apr-2022          Initial Version. QACM-15 Async process when QI Creation is initiated.
 * Gladis               14-Apr-2022          QACM-644 Added method deleteQualityJuncRecOnVoid to delete the related Quality Record Junction records
  ****************************************************************************************************************************************/ 
public with sharing class QualityRecords extends ilib_SObjectDomain {

    private static final String LOG_TITLE = 'QualityRecords';
    public static final String QUALITY_RECORD_QUEUEABLE ='QualityRecordQueueable';
    public static final String  QI_CREATION_INITIATED= 'QI Creation Initiated';
    public static final String  STRING_VOID = 'Void';
    
    /*Constructor. call to super class constructor
    */
    public QualityRecords(List<Quality_Record__c> sObjectList)
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
            return new QualityRecords(sObjectList);
        }
    }
    
    /*
     * Description - onAfterInsert method
	 * return - void
     */
    public override void onAfterInsert()
    { 
        //Method to any Async execution after QR Insert goes here. 
        asyncProcessesOnAfterQRInsert(records);
    }

    /*
     * Description - onAfterUpdate method
	 * return - void
     */
    public override void onAfterUpdate(Map<Id, SObject> mapOld)
    {
        //Method to any Async execution after QR Update goes here. 
        asyncProcessesOnAfterQRUpdate(mapOld);
        deleteQualityJuncRecOnVoid(mapOld); //QACM-644
    }  

    /*
    *  @AUTHOR Gladis
    *  @DESCRIPTION - Method to any Async execution after QR Insert goes here. 
    *  @PARAM :   List of Sobject
    *  @RETURN : void
    */
    public static void asyncProcessesOnAfterQRInsert(List<Sobject> records) {

        ilib_LogEvent.push(LOG_TITLE + '.asyncProcessesOnAfterQRInsert()');
        Set<Id> setQICreationInitiatedIds = new Set<Id>();
        ilib_Queueablethread  queueableThreadAfterInsert = new ilib_Queueablethread('QualityRecordsAfterInsert');

        for(Quality_Record__c objQualityRecord : (List<Quality_Record__c>)records) {
            if(String.isNOTBlank(objQualityRecord.EtQ_Integration_Status__c) && objQualityRecord.EtQ_Integration_Status__c == QI_CREATION_INITIATED) {
                setQICreationInitiatedIds.add(objQualityRecord.id);   
            }
        }

        if(!setQICreationInitiatedIds.isEmpty()) {
            queueableThreadAfterInsert.logandQueue(new QualityRecordQueueable('sendQICreationToETQInsert',setQICreationInitiatedIds),QUALITY_RECORD_QUEUEABLE,'sendQICreationToETQInsert');	
        }

        //Enqueue Job
        if (queueableThreadAfterInsert != null && !queueableThreadAfterInsert.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThreadAfterInsert,ilib_LogEvent.SERVICE);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    *  @AUTHOR Gladis
    *  @DESCRIPTION - Method to any Async execution after QR Update goes here. 
    *  @PARAM :   Old Map
    *  @RETURN : void
    */
    public static void asyncProcessesOnAfterQRUpdate(Map<Id, SObject> mapOld) {

        ilib_LogEvent.push(LOG_TITLE + '.asyncProcessesOnAfterQRUpdate()');
        Set<Id> setQICreationInitiatedIds = new Set<Id>();
        ilib_Queueablethread  queueableThreadAfterUpdate = new ilib_Queueablethread('QualityRecordsAfterUpdate');

        for(Id qualityRecordId : mapOld.keySet()) {
            Quality_Record__c objNewRecord = (Quality_Record__c)Trigger.newMap.get(qualityRecordId);
            Quality_Record__c objOldRecord = (Quality_Record__c)mapOld.get(qualityRecordId);

            if(objNewRecord.EtQ_Integration_Status__c != objOldRecord.EtQ_Integration_Status__c && objNewRecord.EtQ_Integration_Status__c == QI_CREATION_INITIATED) {
                setQICreationInitiatedIds.add(objNewRecord.id);   
            }
        }

        if(!setQICreationInitiatedIds.isEmpty()) {
            queueableThreadAfterUpdate.logandQueue(new QualityRecordQueueable('sendQICreationToETQUpdate',setQICreationInitiatedIds),QUALITY_RECORD_QUEUEABLE,'sendQICreationToETQUpdate');
        }

        //Enqueue Job
        if (queueableThreadAfterUpdate != null && !queueableThreadAfterUpdate.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThreadAfterUpdate,ilib_LogEvent.SERVICE);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    * @AUTHOR        Gladis
    * @DESCRIPTION - QACM-15 Method to call the EtQCreateQIDataSender to make the callout.
    * @PARAM :       set<Id> 
    * @RETURN : void
    **/
    public static void sendQICreationToETQ(set<Id> setQRIds) {
        ilib_LogEvent.push(LOG_TITLE + '.sendQICreationToETQ()');
        EtQCreateQIDataSender etqCreationInterface; 
        try {
            if(setQRIds!=null && !setQRIds.IsEmpty()) {
                for(Quality_Record__c objQualityRecord:new QualityRecordSelector().selectQR(setQRIds)) {
                    etqCreationInterface = new EtQCreateQIDataSender();
                    if(!Test.isRunningTest()) {
                        etqCreationInterface.callout(objQualityRecord.Id);
                    }
                }
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }      
    }

    /*
    *  @AUTHOR Gladis
    *  @DESCRIPTION - QACM-644 Method to delete the related Quality Record Junction records. 
    *  @PARAM :   Old Map
    *  @RETURN : void
    */
    public static void deleteQualityJuncRecOnVoid(Map<Id, SObject> mapOld) {
        ilib_LogEvent.push(LOG_TITLE + '.deleteQualityJuncRecOnVoid()');
        Set<Id> setVoidIds = new Set<Id>();
        List<Quality_Record_Junction__c> lstQRJRecords= new List<Quality_Record_Junction__c>();
        
        try {
            for(Id qualityRecordId : mapOld.keySet()) {
            Quality_Record__c objNewRecord = (Quality_Record__c)Trigger.newMap.get(qualityRecordId);
            Quality_Record__c objOldRecord = (Quality_Record__c)mapOld.get(qualityRecordId);
                if(objNewRecord.Current_Phase__c != objOldRecord.Current_Phase__c && objNewRecord.Current_Phase__c == STRING_VOID) {
                    setVoidIds.add(objNewRecord.id);   
                }
            }
            for(Quality_Record__c objQualityRecord: new QualityRecordSelector().selectQR(setVoidIds)) {
                if(objQualityRecord.Quality_Record_Junctions__r.size() > 0) {
                    lstQRJRecords.addAll(objQualityRecord.Quality_Record_Junctions__r);
                }
            }
            
            if(!lstQRJRecords.isEmpty()) {
                Delete lstQRJRecords;
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
    }
}