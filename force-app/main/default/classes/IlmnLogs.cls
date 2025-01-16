/*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: NOTE: how the exception and debug logs are linked
    *  1. ilib_LogEvent generates a link key when logs start getting created
    *  2. when an ApexException is emitted, check for presence of that key which indicates there will be log(s) to link to
    *  3. if so, store it with the exception. Also set persist and link booleans ilib_LogEvent
    *  4. if the boolean is set, save the random string to the Log platform event
    *  5. in Logs class, resolve the key with persisted exception logs
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Todd Newman                                      Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix 
            Nitin                         4/12/2022           CMSI-6: support for the Transaction Id
            Nitin                         5/6/2022            CMSI-5 populating Log Category 
            Suraj                       17-May-2022           CMSI-4  : Emit on Every Pop with Seq 1
            Pranay                      21-Apr-2022           CMSI-11 : Implement interface for the PS Log framework
            Saurabh                     23/01/2024              Bulikfication of EventBus.Publish method
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/
    public with sharing class IlmnLogs extends ilib_SObjectDomain {

        // NOTE: how the exception and debug logs are linked
        //
        // 1. ilib_LogEvent generates a link key when logs start getting created
        // 2. when an ApexException is emitted, check for presence of that key which indicates there will be log(s) to link to
        // 3. if so, store it with the exception. Also set persist and link booleans ilib_LogEvent
        // 4. if the boolean is set, save the random string to the Log platform event
        // 5. in Logs class, resolve the key with persisted exception logs
        
        
        //public static final String TID = LogUtil.getRequestId(); //Created by nitin
           // private final String TID = LogUtil.getRequestId();
        
       // private static final Integer USE_CHECK_FREQUENCY = 1000; // 1 in ...
        private static String logCat;
        private static ilib_LogSettings settings;
        private static final string STR_INTERFACE='restInterface';
        public static final string POP_CHILD = 'Pop_Child';
        public static final string POP_PARENT = 'Pop_Parent';
        public static final string EMIT = 'Emit';
        public static final string SOQL = 'Soql';
        public static final Integer ONE = 1;
        private static final Integer TEST_LIMIT_ROWS_PROCESS = 100;
    
            //CMSI-4
        private static List<String> transIdList = new List<String>();
        private static List<String> transIdListParent = new List<String>();
        private static List<String> linkKey = new List<String>();
        private static List<String> linkKeyParent = new List<String>();
          
        private static  Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.getGlobalDescribe().get('ILMN_Debug_Log__c').getDescribe().getRecordTypeInfosByDeveloperName(); // CMSI-4											 
     
             
        private static  List<ILMN_Debug_Log__c> logsToPersist = new List<ILMN_Debug_Log__c>();
        private static  Map<Id,ILMN_Debug_Log__c> logsToUpdate = new Map<Id,ILMN_Debug_Log__c>();
        private static  Map<String,ILMN_Debug_Log__c> logsToUpdateTemp = new Map<String,ILMN_Debug_Log__c>();
       
    
         /**
            *    @author        
            *    @date          
            *    @description   
                 param- sObjectList
            *    Modification Log:
            *    ------------------------------------------------------------------------------------------------------------------------------------------------
            *             Developer                      Date                Description
            *           
            */
        public IlmnLogs(List<ILMN_Log__e> sObjectList)
        {
            super(sObjectList);
        }
        /*
        * Boilerplate which is required for base class instantiation logic
        */
    
        public class Constructor implements ilib_SObjectDomain.IConstructable
        {
             /**
            *    @author        
            *    @date          
            *    @description   
                 param- sObjectList
            *    Modification Log:
            *    ------------------------------------------------------------------------------------------------------------------------------------------------
            *             Developer                      Date                Description
            *           
            */
            public ilib_SObjectDomain construct(List<SObject> sObjectList)
            {
                return new IlmnLogs(sObjectList);
            }
        }
    
        /**
    *    @author        
    *    @date          
    *    @description   
         param- publishDetails
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *             Nitin							 4/12/2022			 CMSI-6 passing transaction ID as parameter instead of link key
                    Nitin                          5/6/2022            CMSI-5 populating Log Category
         Suraj                           5/12/2022      CMSI-4 Emit on Pop seq           							1																																																									
    */
    public static void publish(ilib_LogEvent.publishParameter publishDetails)
    {
        publishList(new List<ilib_LogEvent.publishParameter>{publishDetails});
    }
    
    /**
    *    @description           : Converts params into ILMN_Log__e to be later published. If is on the limits sends them as schedule to be later processed.
    *    @param publishDetails  : parameters logs to be published on EventBus
    */
    public static void publishList(List<ilib_LogEvent.publishParameter> lstPublishDetails) {

        if(lstPublishDetails == null) {
            System.debug(LoggingLevel.ERROR, 'lstPublishDetails is null');
            return;
        }

        // make sure logging persistence is allowed by configuration
        ilib_LogSettings setting=  getSettings();

        if (setting.disableAllPersistence)
        {
            System.debug(LoggingLevel.ERROR, 'PS Log persistence disabled');
            return;
        }

        if (setting.pausePublishesUntil != null
            && setting.pausePublishesUntil > Datetime.now()
        ) {
            System.debug(LoggingLevel.ERROR, 'PS Log persistence paused until ' + setting.pausePublishesUntil);
            return;
        }

        List<ILMN_Log__e> lstLogEvents = new List<ILMN_Log__e>();
        List<ilib_LogEvent.publishParameter> pendingLongEvents = new List<ilib_LogEvent.publishParameter>();
        Integer limitList = getLimitRowsToProcess();

        for(Integer i = 0; i < lstPublishDetails.size(); i++) {
            ilib_LogEvent.publishParameter publishDetails = lstPublishDetails.get(i);

            if(i < limitList ) {

                String logCat = String.valueOf(publishDetails.cat);

                if (String.valueOf(publishDetails.cat) == STR_INTERFACE) {
                    logCat = 'Interface'; 
                }

                // all clear, publish/persist the log
                ILMN_Log__e log = new ILMN_Log__e(
                    Title__c = publishDetails.title,
                    Data__c = publishDetails.logData,
                    User_Id__c = publishDetails.userId,
                    Elapsed_Time__c = publishDetails.elapsedTime,
                    Limits__c = publishDetails.serializedLimitz,
                    //Nitin: CMSI-6 transaction id is stored in Transaction_Id__c field
                    Transaction_Id__c = publishDetails.tid,
                    Workstream__c = publishDetails.strWorkstream,
                    Log_Categorization__c= logCat,
                    recordTypeName__c = publishDetails.rcType, //CMSI-4
                    link_key__c = 	publishDetails.linkKey
                );

                lstLogEvents.add(log);
                System.debug('@@SDPublish' + log);
            } else {
                pendingLongEvents.add(publishDetails);
            }

        }

        if(!lstLogEvents.isEmpty()) {
            Integer maxPIDLimit = Limits.getLimitPublishImmediateDML();
            Integer consumedPID = Limits.getPublishImmediateDML();

            if(consumedPID < maxPIDLimit){
                System.debug('Number of message events to be published:' + lstLogEvents.size());
                EventBus.publish(lstLogEvents);

                if(pendingLongEvents.size() > 0) {
                    System.debug('Starting Queueable Logging due pending list:' + pendingLongEvents.size());
                    System.enqueueJob(new Ilib_LogEvent_PlatformEventEmitQueueable(pendingLongEvents));
                }

            } else {
                System.debug('Starting Queueable Logging due maxPIDLimit:' + maxPIDLimit + ' consumedPID:' + consumedPID);
                System.enqueueJob(new Ilib_LogEvent_PlatformEventEmitQueueable(lstPublishDetails));
            }
        }
    }

    /**
     * @decription: Gives Limit number of rows to process. Test context is unable to publish more than 500 messages events.
     */
    private static Integer getLimitRowsToProcess() {
        return Test.isRunningTest() ?  TEST_LIMIT_ROWS_PROCESS : Limits.getLimitDMLRows();
    }

         /**
            *    @author        
            *    @date          
            *    @description   
            *    Modification Log:
            *    ------------------------------------------------------------------------------------------------------------------------------------------------
            *             Developer                      Date                Description
            *           
            */
        public override void onAfterInsert()
        {
    
            if (checkUsageThisTime())
            {
                suspendPublishForRestOfHour();
            }
    
            saveDebugLogRecords();
        }
        /**
    *    @author        
    *    @date          
    *    @description   
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *             Nitin							 4/12/2022			 CMSI-6 populating transaction id and org id in ILMN Debug log object
                  Suraj                           05/15/2022         CMSI-4- Emit on every pop with seq 0
                  Nitin                          5/6/2022            CMSI-5 populating Log Category in ILMN Debug logs        
                      
    */
        private void saveDebugLogRecords()
        {
            // confirm user IDs exist by querying User table
           Map<Id, User> idToUser = confirmUserIdsExist();
        
            for (ILMN_Log__e log : (List<ILMN_Log__e>)records)
            {
                // find confirmed user ID
                Id userId = null;
                if (idToUser.containsKey(log.User_Id__c)) userId = idToUser.get(log.User_Id__c).Id;
             
    
                ILMN_Debug_Log__c logToPersist = new ILMN_Debug_Log__c(
                    Title__c = log.Title__c,
                    Data__c = log.Data__c,
                    Data_Length__c = log.Data__c == null ? 0 : log.Data__c.length(),
                  
                   Transaction_Id__c=log.Transaction_Id__c,
                   Workstream__c = log.Workstream__c,
                  
                       User__c = userId,
                    Elapsed_Time__c = log.Elapsed_Time__c,
                    //CMSI-6 populating org id in ILMN Debug logs
                    Org_Id__c= UserInfo.getOrganizationId(),
                    Log_Categorization__c=log.Log_Categorization__c,
                    recordtypeid = rtMapByName.get(log.recordTypeName__c).getRecordTypeId(), // CMSI-4
                    link_key__c = log.link_key__c
                );
    
                // if limits were passed in, parse out some values
                ilib_Limitz limitz = parseLimits(log.Limits__c); //CMSI-11
                if (limitz != null)
                {
                    logToPersist.Limits__c = limitz.toString();
                    logToPersist.DML__c = limitz.dml;
                    logToPersist.SOQL__c = limitz.soql;
                    logToPersist.CPU__c = limitz.cpu;
                }
    
                processPopParentChildLinking(log,logToPersist);
                
            }
            
           
    
            processPopParentUpdate();
    
            processDMLs();
    
            
            
        }
    
    
        private static void processDMLs(){
            
            // safely save log records
            if (!logsToPersist.isEmpty())
            {
                List<Database.SaveResult> results = Database.insert(logsToPersist, false);
                ApexExceptions.emitSaveErrors(results, 'IlmnLogs');
            }
    
            if(!transIdList.isEmpty()){
                populateParent(transIdList,logsToPersist,linkKey,rtMapByName);
            }
    
             // safely save log records
             if (!logsToPersist.isEmpty())
             {
                logsToPersist.addAll(logsToUpdate.values());
                 List<Database.SaveResult> results = Database.update(logsToPersist, false);
                 ApexExceptions.emitSaveErrors(results, 'IlmnLogs');
             }
    
        }
    
        private static void processPopParentUpdate(){

            
            
            if(! (linkKeyParent.isEmpty() || transIdListParent.isEmpty() )){
    
                List<ILMN_Debug_Log__c> ilmnDLog =  new ILMNDebugLogSelector().selectIlmnDebugLogsByTid(transIdListParent,linkKeyParent);
    
                for(ILMN_Debug_Log__c ilmn : ilmnDLog){
                    if(logsToUpdateTemp.containskey(ilmn.Transaction_Id__c + ilmn.link_key__c) ){
                        ILMN_Debug_Log__c ilmnnested = logsToUpdateTemp.get(ilmn.Transaction_Id__c + ilmn.link_key__c);
                        ilmnnested.id = ilmn.id;
                            
                        logsToUpdate.put(ilmnnested.id,ilmnnested); 
                             
                            
                    }
                    
                }
            }

            if(!logsToUpdateTemp.isEmpty()){
                for(ILMN_Debug_Log__c ilmn : logsToUpdateTemp.values()){
                    if(logsToUpdate.isEmpty() ||  !logsToUpdateTemp.containsKey(ilmn.Transaction_Id__c + ilmn.link_key__c) && logsToUpdate.containsKey(logsToUpdateTemp.get(ilmn.Transaction_Id__c + ilmn.link_key__c).Id)){
                        logsToPersist.add(ilmn);
                    }

                }
            }
    
    
    
        }
    
        private static void processPopParentChildLinking(ILMN_Log__e log,ILMN_Debug_Log__c logToPersist){
            
            system.debug('@@processlinkingKeys'+ log.recordTypeName__c + ' ' + log.Log_Categorization__c);
            if(log.recordTypeName__c == POP_CHILD || log.recordTypeName__c == EMIT && log.Log_Categorization__c == SOQL){
                transIdList.add(log.Transaction_Id__c);
               
                if(logToPersist.link_key__c != Null){   
                    system.debug('@@SDLinkKey'+logToPersist.link_key__c);
        
                    linkKey.add(logToPersist.link_key__c);
                    
                }
                logsToPersist.add(logToPersist);
                
            }else if(log.recordTypeName__c == POP_PARENT){
    
                if(logToPersist.CPU__c != Null ){
                    transIdListParent.add(log.Transaction_Id__c);
                    linkKeyParent.add(log.link_key__c);
                    logsToUpdateTemp.put(log.Transaction_Id__c+log.link_key__c,logToPersist);
                }else{
                    logsToPersist.add(logToPersist);
    
                }
    
            }else{
                logsToPersist.add(logToPersist);
            }
    
        }
    
        private static void populateParent(List<String> transIdList,List<ILMN_Debug_Log__c> logsToPersist,List<String> linkKey,Map<String,Schema.RecordTypeInfo> rtMapByName ){
    
           Map<String,Id> ilmnTransIdMap = new Map<String,Id>();
    
            if(!transIdList.isEmpty()){
               
                List<ILMN_Debug_Log__c> ilmnLog =  new ILMNDebugLogSelector().selectIlmnDebugLogsByTid(transIdList,linkKey);
    
                for(ILMN_Debug_Log__c ilmn : ilmnLog){
                    ilmnTransIdMap.put(ilmn.link_key__c,ilmn.Id);
                }
        
                for (ILMN_Debug_Log__c log : logsToPersist){
                    if(!ilmnTransIdMap.isEmpty() && ilmnTransIdMap.containsKey(log.link_key__c) && ilmnTransIdMap.get(log.link_key__c) != log.Id){
                        log.Parent_Log__c = ilmnTransIdMap.get(log.link_key__c);
                    }   
                }
            }
    
    
        }
    
           /*
            *  @Author      : Todd Newman
            *  @Description : Method to return User Ids
            *  @Param       : None
            *  @Return      : Map<Id, User>
            */
        
            private Map<Id, User> confirmUserIdsExist()
            {
                Set<Id> userIds = UtilsCollection.getSetOfIds(records, 'User_Id__c');
                return new Map<Id, User> ([SELECT Id FROM User WHERE Id IN :userIds]);
            }
        
         /*
            *  @Author      : Todd Newman
            *  @Description : Method to deserialize and parse the parameter value
            *  @Param       : String
            *  @Return      : ilib_LogEvent.Limitz
            */
            private ilib_Limitz parseLimits(String serialized)//CMSI-11
            {
                if (String.isBlank(serialized)) return null;
        
                try
                {
                    return (ilib_Limitz)JSON.deserialize(serialized, ilib_Limitz.class);//CMSI-11
                }
                catch (Exception e)
                {
                    return null;
                }
            }
        
             /*
            *  @Author      : Todd Newman
            *  @Description : Method to retrieve ilib_LogSettings
            *  @Param       : None
            *  @Return      : ilib_LogSettings
            */
            private static ilib_LogSettings getSettings()
            {
                if (settings == null) settings = ilib_LogEvent.getSettings();
        
                return settings;
            }
        
            /*
            *  @Author      : Todd Newman
            *  @Description : Method for unit testing coverage
            *  @Param       : None
            *  @Return      : Boolean
            */
        
            @TestVisible
            private Boolean checkUsageThisTime()
            {
                //CMSI-5
                ilib_LogSettings setting= getSettings();
                // query usage
                ilib_LogEventUsage.Data usageData = new ilib_LogEventUsage().query();
                Decimal publishUsePercentage = usageData.getPercentUsed();
        
                // if usage is below threshold, no worries
                return publishUsePercentage > setting.publishPercentThreshold;
            }
        
         /*
            *  @Author      : Todd Newman
            *  @Description : Method for unit testing coverage
            *  @Param       : None
            *  @Return      : Void
            */
            @TestVisible
            private void suspendPublishForRestOfHour()
            {
                
        
                // calculate top of next hour
                Datetime hourFromNow = Datetime.now().addHours(1);
                Datetime topOfHour = Datetime.newInstance(hourFromNow.year(), hourFromNow.month(), hourFromNow.day(), hourFromNow.hour(), 0, 0);
        
                // store top of next hour in settings
                ilib_LogSettings.updateMetadataPauseDate(topOfHour);
            }
 }