/***************************************************************************************************************************************
 * NAME   : QualityRecordJunctions
 * DESCRIPTION  : Domain class for QualityRecordJunctionTrigger
 *				      
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 04-Apr-2022  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gladis             	04-Apr-2022          Initial Version
  ****************************************************************************************************************************************/ 
public with sharing class QualityRecordJunctions extends ilib_SObjectDomain {
    
    private static final String LOG_TITLE = 'QualityRecordJunctions';
    public static final String QUALITY_RECORD_JUNC_QUEUEABLE ='QualityRecordJunctionQueueable';
    public static final String  LINK_INITIATED= 'Link Initiated';
    public static final String  DE_LINK_INITIATED= 'DeLink Initiated';
    
    /*Constructor. call to super class constructor
    */
    public QualityRecordJunctions(List<Quality_Record_Junction__c> sObjectList)
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
            return new QualityRecordJunctions(sObjectList);
        }
    }
    
    /*
     * Description - onAfterInsert method
	 * return - void
     */
    public override void onAfterInsert()
    { 
        //Method to any Async execution after QRJ Insert goes here. 
        asyncProcessesOnAfterQRJInsert(records);
    }

    /*
     * Description - onAfterUpdate method
	 * return - void
     */
    public override void onAfterUpdate(Map<Id, SObject> mapOld)
    {
        //Method to any Async execution after QRJ Update goes here. 
        asyncProcessesOnAfterQRJUpdate(mapOld);
    }  

    /*
    *  @AUTHOR Gladis
    *  @DESCRIPTION - Method to any Async execution after QRJ Insert goes here. 
    *  @PARAM :   List of Sobject
    *  @RETURN : void
    */
    public static void asyncProcessesOnAfterQRJInsert(List<Sobject> records) {

        ilib_LogEvent.push(LOG_TITLE + '.asyncProcessesOnAfterQRJInsert()');
        Set<Id> setLinkInitiatedIds = new Set<Id>();
        ilib_Queueablethread  queueableThreadAfterInsert = new ilib_Queueablethread('QualityRecordJuncAfterInsert');

        for(Quality_Record_Junction__c objQualityRecordJunc : (List<Quality_Record_Junction__c>)records) {
            if(String.isNOTBlank(objQualityRecordJunc.EtQ_Integration_Status__c) && (objQualityRecordJunc.EtQ_Integration_Status__c == LINK_INITIATED || objQualityRecordJunc.EtQ_Integration_Status__c == DE_LINK_INITIATED)){
                setLinkInitiatedIds.add(objQualityRecordJunc.id);   
            }
        }

        if(!setLinkInitiatedIds.isEmpty()) {
            queueableThreadAfterInsert.logandQueue(new QualityRecordJunctionQueueable('sendQILinkDelinkToETQInsert',setLinkInitiatedIds),QUALITY_RECORD_JUNC_QUEUEABLE,'sendQILinkDelinkToETQ');	
        }

        //Enqueue Job
        if (queueableThreadAfterInsert != null && !queueableThreadAfterInsert.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThreadAfterInsert,ilib_LogEvent.SERVICE);
        }
        ilib_LogEvent.emit();
        ilib_LogEvent.pop();
    }

    /*
    *  @AUTHOR Gladis
    *  @DESCRIPTION - Method to any Async execution after QRJ Update goes here. 
    *  @PARAM :   Old Map
    *  @RETURN : void
    */
    public static void asyncProcessesOnAfterQRJUpdate(Map<Id, SObject> mapOld) {

        ilib_LogEvent.push(LOG_TITLE + '.asyncProcessesOnAfterQRJUpdate()');
        Set<Id> setLinkInitiatedIds = new Set<Id>();
        ilib_Queueablethread  queueableThreadAfterUpdate = new ilib_Queueablethread('QualityRecordJuncAfterUpdate');

        for(Id qualityRecordJuncId : mapOld.keySet()) {
            Quality_Record_Junction__c objNewRecord = (Quality_Record_Junction__c)Trigger.newMap.get(qualityRecordJuncId);
            Quality_Record_Junction__c objOldRecord = (Quality_Record_Junction__c)mapOld.get(qualityRecordJuncId);

            if(objNewRecord.EtQ_Integration_Status__c != objOldRecord.EtQ_Integration_Status__c && (objNewRecord.EtQ_Integration_Status__c == LINK_INITIATED || objNewRecord.EtQ_Integration_Status__c == DE_LINK_INITIATED )) {
                setLinkInitiatedIds.add(objNewRecord.id);   
            }
        }

        if(!setLinkInitiatedIds.isEmpty()) {
            queueableThreadAfterUpdate.logandQueue(new QualityRecordJunctionQueueable('sendQILinkDelinkToETQUpdate',setLinkInitiatedIds),QUALITY_RECORD_JUNC_QUEUEABLE,'sendQILinkDelinkToETQ');	
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
    public static void sendQILinkDelinkToETQ(set<Id> setQRJIds) {
        ilib_LogEvent.push(LOG_TITLE + '.sendQILinkDelinkToETQ()');
        EtQLinkDelinkQIDataSender etqLinkDelinkInterface;
        try {
            if(setQRJIds!=null && !setQRJIds.IsEmpty()) {
                for(Quality_Record_Junction__c objQualityRecordJunc:new QualityRecordJunctionSelector().selectQRJ(setQRJIds)) {
                    etqLinkDelinkInterface = new EtQLinkDelinkQIDataSender();
                    if(!Test.isRunningTest()) {
                        etqLinkDelinkInterface.callout(objQualityRecordJunc.Id);
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
}