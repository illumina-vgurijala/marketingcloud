/**
*    @author        
*    @date          
*    @description   PS Log Framework Class
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*     Developer           Date           Description
*     Anshaj              4/12/2022      CMSI-2 & CMSI-3 : Introduced methods to allow Feature Flag Driven Architecture of PS Log Framework and 
*                                        to capture Workstream 
*     Nitin               4/12/2022      CMSI-6: methods to generate the Transaction Id
*     Pranay              4/21/2022      CMSI-11 : Implement interface for the PS Log framework
*	  Suraj 			  05/15/2022     CMSI-4 :  Publish at seq 1 for pop implementation
*     Rohan/Pooja         09/02/2022     DCP-56231: pass transaction Id to SubFlow and created wrapper class to pass the value to the flow
*     Rajbabu Boopalan    03/12/2024     CMCM-5579 Handle PublishImmediateDML limit error	
*/
public without sharing class ilib_LogEvent {

    public static cs_Apex_Settings__c apexSettings;
    public static Id loggingUserId;
    private static Boolean persistLogs = false;
    private static IPsLog psIterface;
    private static String transactionId;
    public static final String SALES = 'Sales';
    public static final String SERVICE = 'Service';
    public static final String MARKETING = 'Marketing';
    //CMSI-3 Added workstream variable
	  public static String workstream='';

    public static final String PERSISTED_QUERY_LOG_TITLE_PREFIX = 'Query: ';

    public static final String SLOW_QUERY_LOG_TITLE_PREFIX = 'Slow Query: ';
    //CMSI-2 Added startTime, isOn, categoryFlag variables
    private static Long startTime;
    private static Boolean isOn= true;
    private static Boolean categoryFlag = true;
    //CMSI-2 Added settings and USERSTR here to starting in order to fix codescan errors
    private static ilib_LogSettings settings;
    private static final string USERSTR = '005';
    //CMSI-2 Added fineFlag, debugFlag, infoFlag and errorFlag variables
    private static Boolean fineFlag = false;
    private static Boolean debugFlag = false;
    private static Boolean infoFlag = false;
    private static Boolean errorFlag = false;
    public static Category logCategory = Category.Apex;
    private static Boolean categorySet = false;
    public static Boolean queryFlag = false;
    //CMSI-9
    public static string recType = 'Emit';
     /**
     * @author 
     * @description getter and setter for rootTile. NOTE: prefer to replace calls to this (set) with the above method
     */
    public static String rootTitle {
        get { return getImplementationClass().getRootTitle(); }
        set
        {
            if(!isOn)return;
            getImplementationClass().setTitle(value);
        }
    }
    /**
     * @author Anshaj
     * @description CMSI-37 Method to set the Workstream
     */
    public static void setWorkstream(String strWorkstream){
        if(string.isNotBlank(strWorkstream)){
            workstream = strWorkstream;
        }
    }
        /**
     * @author Anshaj
     * @description CMSI-37 Method to get the Workstream
     */
    public static String getWorkstream(){
        return workstream;
    }
    
     /**
     * @author Nitin
     * @description Enum for Log Category (CMSI-5)
     */
    public enum Category { Apex, Batchable,restInterface, Queueable, Soql}

    /**
     * @author 
     * @description Log Level values and API
     */
    public enum Level { DEBUG, INFO, ERROR, FINE}

    /**
     * @author Pranay
     * @description Returns the instance of implemetation class of IPsLog interface
     */
    public static IPsLog getImplementationClass(){

        if(psIterface != null){
            return psIterface;
        }else if(getSettings().InterfaceClass == null){ 
            psIterface = (IPsLog) Type.forName('ilib_LogEvent_PlatformEventEmit').newInstance();
            
        }else if(psIterface == null){
            psIterface =  (IPsLog) Type.forName(getSettings().InterfaceClass).newInstance();
            
        }
        return psIterface;
        
        
    }


    /**
     * @author 
     * @description Returns the current log settings (CMSI-2)
     */
    public static ilib_LogSettings getSettings()
    {
        if (settings == null) {
            settings = new ilib_LogSettings();
            System.debug('@@settings at first run --> '+settings);
            setLogCategory(logCategory);
        }

        return settings;
    }
        /**
*    @author      Anshaj  
*    @date        26/04/2022
*    @description   CMSI-2 : Method to get Custom Setting Detail with logginUserId or ProfileId
*/
public static void getApexSetting(){
        
    if(apexSettings == null){
        apexSettings = cs_Apex_Settings__c.getInstance();
    }
}


    // ******************************
    // public API
    // ******************************
    /**
     * @author 
     * @description set the title of the log. This is also used to filter which logs are persisted
     * @modification- CMSI-3 Added isOn check. CMSI-5 setting log category
     */
    public static void setTitle(String logTitle)
    {
	 try {  
            getSettings();
            if(!isOn())return;
            getImplementationClass().setTitle(logTitle);
        } 
        catch (Exception ex) {logError(ex);}
    }
/**
*    @author  Anshaj      
*    @date          12/04/2022
*    @description   setTitle method to capture workstream alongwith title
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      12/04/2022         CMSI-3 : Added setTitle method to capture Workstream
*              Anshaj                      12/04/2022         CMSI-3 : Added isOn check
     
*/
    public static void setTitle(String logTitle, String workstream)
    { 
        try {
                getSettings();
                setWorkstream(workstream);
                if(!isOn())return;
                getImplementationClass().setTitle(logTitle);
                
        } 
        catch (Exception ex) {logError(ex);}
    }
    /**
*    @author  Nitin      
*    @date          25/05/2022
*    @description   setTitle method to capture transaction Id  along with title
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              
*/
    public static void setBatchTitle(String logTitle, string transId)
    {
        try { 
            getSettings();
            transactionId = transId;
            if(!isOn())return;
            getImplementationClass().setTitle(logTitle);
        } 
        catch (Exception ex) {logError(ex);}
    }



    /**
     * @author Illumina
     * @description Push this named scope onto the log stack
     * @modification- CMSI-3 Added isOn check
     */
    public static void push(String scope)
    {
        try{
            System.debug('Push:' + scope);
            if(!isOn())return;
            getImplementationClass().push(scope);
        }
        catch(Exception ex){logError(ex);}
    }

    /**
*    @author  Illumina   
*    @date          
*    @description  Add the given message to the scope last pushed 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      26/04/2022           CMSI-3 - Added isOn check
*              Anshaj                      26/04/2022           CMSI-2 Added fineFlag check
*/
    public static void message(String message)
    {
        try{
            System.debug('Debug : '+ message);
            if(!debugFlag || !isOn)return;
            getImplementationClass().debug(message);
        }catch(Exception ex){logError(ex);}
    }
/**
*    @author  Anshaj      
*    @date          
*    @description   CMSI-3 - method to log Fine level logs. Added isOn check and try catch mechanism
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      26/04/2022           CMSI-2 Added fineFlag check
*/
     public static void fine(String message)
     {
         try{
         System.debug('Fine : '+ message);
         if(!fineFlag || !isOn)return;
         getImplementationClass().fine(message);
        }
          catch(Exception ex){logError(ex);}
        
    }
 /**
*    @author  Anshaj      
*    @date          
*    @description   CMSI-3 - method to log Error level logs. Added isOn check and try catch mechanism
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*               Anshaj                      26/04/2022           CMSI-2 Added errorFlag check
*/
     public static void error(String message)
     {
         try{
         System.debug('Error : '+ message);
         if(!errorFlag || !isOn)return;
         getImplementationClass().error(message);
        }
          catch(Exception ex){logError(ex);}
        
    }
/**
*    @author  Anshaj      
*    @date          
*    @description   CMSI-3 - method to log Info level logs. Added isOn check and try catch mechanism
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      26/04/2022           CMSI-2 Added infoFlag check
*/
     public static void info(String message)
     {
         try{
         System.debug('Info : '+ message);
         if(!infoFlag || !isOn)return;
         getImplementationClass().info(message);
        }
          catch(Exception ex){logError(ex);}
        
    }

    /**
     * @author Illumina
     * @description Add the given message to the scope last pushed
     * @modification- CMSI-2 Added debugFlag check, CMSI-3 Added isOn check
     */
    public static void message(ilib_LogQuery.Data query)
    {
        try{
            System.debug('Query : '+ query);
            if(!isOn)return;
            getImplementationClass().debug(query);
        }catch(Exception ex){logError(ex);}
    }

    /**
     * @author Illumina
     * @description Pop the current scope
     * @modification- CMSI-3 Added isOn check
     */
    public static void pop()
    {
        try{
            if(!isOn)return;
            getImplementationClass().pop();
        }catch(Exception ex){logError(ex);}
    }

    /**
     * @author Illumina
     * @description method to emit the log
     * @modification - CMSI-3 Added isOn check
     */
    public static void emit()
    {
        try{
        if(!isOn())return;
        getImplementationClass().emit();
        }catch(Exception ex){logError(ex);}
    }

    /**
     * @author 
     * @description Emits the current log state to the Log__e platform event
     * @modification - CMSI-3 : added isOn check, CMSI-11 : added code to get implementation class
     */
    public static void emit(String emitScopeName)
    {
        try{
        if(!isOn())return;
        ilib_LogEvent.message('ignore-log-debugging emit CALLED ' + emitScopeName);
        getImplementationClass().emit(emitScopeName);
        }catch(Exception ex){logError(ex);}
    }

    /**
     * @author Illumina
     * @description Method to force persist logs
     */
    public static void forcePersistLogs()
    {
        persistLogs = true;
    }

    /**
     * @author Illumina
     * @description Method to force persist logs and link to error
     */
    public static void forcePersistLogsAndLinkToError()
    {
        persistLogs = true;
      
    }

    /**
     * @author Illumina
     * @description Method to set logging user id
     * @modification- CMSI-2 replaced string '005' with USERSTR variable to fix codescan error
     * @param Id userId
     */
    public static void setLoggingUserId(Id userId)
    {
        if (userId == null) return;

        String strUserId = String.valueOf(userId);
        //CMSI-2 replaced string '005' with USERSTR variable to fix codescan error
        if (strUserId.substring(0, 3) != USERSTR) return;

        loggingUserId = userId;
    }

    // ******************************
    // sugar methods
    // ******************************

    /**
     * @author Illumina
     * @description logError method to exception in the logs if caught any during the loggin transaction
     * @modification - CMSI-2 : added isOn variable assignment and checks related to isOn and errorFlag. Added stack trace and type of exception
     * @param Exception e
     */
    public static void logError(Exception e)
    {
	 try{
         //cmsi-2 added isOn assignment, isOn check and errorFlag check & removed setLogLevelError method
         
        if(!errorFlag || !isOn() ||  e == null) return;
            isOn = false;
            push('EXCEPTION');
            error(e.getMessage().abbreviate(4000));
            //cmsi-2 added stacktrace and type
            error(e.getStackTraceString().abbreviate(4000));
            error(e.getTypeName().abbreviate(4000));
            pop();

            }catch(Exception ex){system.debug('Exception in logError method => '+ex.getMessage());}
    }


    /**
     * @author : Illumina
     * @description the client doesn't need 4 lines in every catch block
     * @param Exception e
     */
     public static void logInternalWarning(String message)
    {
        ilib_LogEvent.push('INTERNAL WARNING');
        ilib_LogEvent.message(message);
        ilib_LogEvent.pop();
    }

    /**
     * @author Illumina
     * @description Method to check of any persisting allowed or not
     * @return Boolean
     */
    public static Boolean isAnyPersistingAllowed()
    {
        ilib_LogSettings setting = getSettings();

        // all persistence can be turned off
        if (setting.disableAllPersistence)
        {
            System.debug(LoggingLevel.ERROR, 'PS Log persistence disabled');
            return false;
        }

        // if persistence is paused because of too many event publishes this hour
        if (setting.pausePublishesUntil != null
            && setting.pausePublishesUntil > Datetime.now()
        ) {
            System.debug(LoggingLevel.ERROR, 'PS Log persistence paused until ' + setting.pausePublishesUntil);
            return false;
        }

        return true;
    }

    /**
     * @author Illumina
     * @description Method to if the transaction is slow and persistable
     * @return Boolean
     */
    public static Boolean isTransactionSlowAndPersistable(Long elapsedTime)
    {
        Boolean persistSlowTransactions = isSlowTransactionPersistenceAllowed();

        return persistSlowTransactions && elapsedTime >= (1000 * getSettings().slowTransactionThreshold);
    }

    /**
     * @author Illumina
     * @description Method to if persistance allowed for slow transaction
     * @return Boolean
     */
    public static Boolean isSlowTransactionPersistenceAllowed()
    {
        if (getSettings().disableSlowTransactionPersistence)
        {
            System.debug(LoggingLevel.ERROR, 'PS Log slow transaction persistence disabled');
            return false;
        }

        return true;
    }

    /**
     * @author Illumina
     * @description Method to if query is slow and persistable
     * @return Boolean
     */
    public static Boolean isQuerySlowAndPersistable(Long elapsedTime)
    {
        Boolean persistSlowQueries = isSlowQueryPersistenceAllowed();

        return persistSlowQueries && elapsedTime >= (1000 * getSettings().slowQueryThreshold);
    }

    /**
     * @author Illumina
     * @description Method to if persistance allowed for slow query
     * @return Boolean
     */
    public static Boolean isSlowQueryPersistenceAllowed()
    {
        if (getSettings().disableSlowQueryPersistence)
        {
            System.debug(LoggingLevel.ERROR, 'PS Log slow query persistence disabled');
            return false;
        }

        return true;
    }

    /**
     * @author Illumina
     * @description Method to if user is configured to persists logs
     * @modification - CMSI-2 modified first if block as there is already a method created to get custom settings
     * @return Boolean
     */
    public static Boolean isUserConfiguredToPersistLogs(String emitScopeName)
    {
        //CMSI-2 modified below if block
        if (apexSettings == null){
            getApexSetting();
        }

        // determine if we publish or if we just debug for this user
        if (apexSettings != null)
        {
            // publish if save all turned on for this user
            persistLogs = persistLogs || apexSettings.Persist_All_ILMN_Logs__c;
            // publish if this particular scope name is turned on for this user
            persistLogs = persistLogs || (apexSettings.ILMN_Logs_to_Persist__c != null && apexSettings.ILMN_Logs_to_Persist__c.contains(emitScopeName));
        }

        return persistLogs;
    }

    /**
     * @author Illumina
     * @description Method to truncate a string to defined max length
     * @param String val, Integer maxLength
     * @return String
     */
    public static String truncateTo(String val, Integer maxLength)
    {
        if (val != null && val.length() > maxLength)
            return val.substring(0, maxLength);
        else
            return val;
    }
    
    /**
    *    @author  Illumina
    *    @date          
    *    @description 
    *    Param - 
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *            Anshaj Sinha                  21/04/2022           CMSI-3 Added Workstream field
    *            Nitin                         06/05/2022           CMSI-5 passing log category as parameter
    *            Suraj                         05/17/2022           CMSI-9 Supress individual query records
    */
	public static void handleQueryPersistence(Boolean persistenceConfiguredForThisUser,List<ilib_LogQuery.Data> queries, String linkKey)
    {
       
        List<ilib_LogQuery.Data> slowQueriesToPersist = new List<ilib_LogQuery.Data>();

        for (ilib_LogQuery.Data query : queries)
        {
            if (ilib_LogEvent.isQuerySlowAndPersistable(query.getExecutionTime()))
                slowQueriesToPersist.add(query);
            
        }
        List<publishParameter> lstSlowQueryPublishDetails =new List<publishParameter>(); //CMCM-5579 
        List<publishParameter> lstQueryPublishDetails =new List<publishParameter>(); //CMCM-5579        
        for (ilib_LogQuery.Data slowQuery : slowQueriesToPersist)
        {
            String title = ilib_LogEvent.truncateTo(SLOW_QUERY_LOG_TITLE_PREFIX + slowQuery.getName(), 255);
            String serializedLimitz = JSON.serialize(new ilib_Limitz(slowQuery));
            //CMSI-5 passing log category as parameter
            publishParameter publishParameters= new publishParameter(title, slowQuery.flushToText(), ilib_LogEvent.loggingUserId, slowQuery.getExecutionTime(), serializedLimitz, ilib_LogEvent.getTransactionId(), ilib_LogEvent.getWorkstream(), Category.Soql,recType, linkKey);
            lstSlowQueryPublishDetails.add(publishParameters);		//CMCM-5579
            System.debug('Query log published, will be persisted');
        }
        if(!lstSlowQueryPublishDetails.isEmpty()) {
            IlmnLogs.publishList(lstSlowQueryPublishDetails); 	    //CMCM-5579
        }
        //CMSI-58 new records for Soql category will be created if log level is debug and log category is apex
        if(!queryFlag)return;
        for (ilib_LogQuery.Data query : queries)
            {   
                String title = ilib_LogEvent.truncateTo(PERSISTED_QUERY_LOG_TITLE_PREFIX + query.getName(), 255);
                String serializedLimitz = JSON.serialize(new ilib_Limitz(query));
                publishParameter publishParameters= new publishParameter(title, query.flushToText(), ilib_LogEvent.loggingUserId, query.getExecutionTime(), serializedLimitz, ilib_LogEvent.getTransactionId(), ilib_LogEvent.getWorkstream(), Category.Soql,recType, linkKey);
                lstQueryPublishDetails.add(publishParameters);      //CMCM-5579
                System.debug('Query log published, will be persisted');
            }
            IlmnLogs.publishList(lstQueryPublishDetails);     //CMCM-5579

    }

    /**
     * @author : Anshaj
     * @description : CMSI-2 : Method to check which log level is selected and assign corresponding flags to true accordingly
     * @param : psLogLevel
     */
    public static void setLogLevel(Level psLogLevel){
        switch on psLogLevel {
            when FINE {
                fineFlag = true;
                debugFlag = true;
                infoFlag = true;  
                errorFlag = true;
            }
            when DEBUG {
                debugFlag = true;
                infoFlag = true;  
                errorFlag = true;
            }
            when INFO {
                infoFlag = true;   
                errorFlag = true;  
            }
            when ERROR {
                errorFlag = true;
            }
            when else {
                debugFlag = true;
                infoFlag = true;  
                errorFlag = true;
            }
        }

        //setLogCategory(logCategory);
        isOn = Feature.isOn('PSLog');
        startTime = System.currentTimeMillis();
    }


    /**
*    @author  Nitin     
*    @date       
*    @description   CMSI-5 method to set log category
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Anshaj                       29/04/2022           CMSI-2 - assigning value of log category in categoryFlag
*             Anshaj                       02/06/2022           CMSI-58 - added if block for assignment of queryFlag
*/
    public static void setLogCategory(Category cat){
        categoryFlag = getSettings().Apex;
        if(getSettings().Apex && (debugFlag || fineFlag)){
            queryFlag= true;
        }
        
        if(cat==Category.restInterface){
                logCategory=Category.restInterface;
                categoryFlag = getSettings().restInterface;
                categorySet=true;
                if(categoryFlag==true) isOn=true;
        }
        else if(system.isBatch() || cat==Category.Batchable){
                logCategory=Category.Batchable;
                categoryFlag = getSettings().Batchable;
                categorySet=true;
        } 
        else if(system.isQueueable() || cat==Category.Queueable){
                logCategory=Category.Queueable;
                categoryFlag = getSettings().Queueable;
                categorySet=true;
        }

       
}

/**
*    @author  Nitin     
*    @date       
*    @description   CMSI-5 method to get the log category
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static Category getLogCategory(){
        return logCategory;
    }

   

    /**
     * @author Anshaj
     * @description  CMSI-2 : Method to check if Feature flag, log category are on and limits used is under control 
     */
    public static boolean isOn(){
       
        return isOn && categoryFlag && !isLimitUsageExceeding();
    }
       
    /**
     * @author Anshaj 
     * @description  CMSI-2 : Method to check if time interval is greater than 0.5 second
     */
    private static boolean isLimitUsageExceeding(){
        boolean timeFlag = false;
        ilib_LogSettings logsettingcs = getSettings();
        if((system.currentTimeMillis() - startTime)>logsettingcs.defCheckInterval){
           
            timeFlag = checkLimitsUsage();
            startTime = System.currentTimeMillis();
        }
        return timeFlag;
    }

    /**
     * @author  Anshaj 
     * @description CMSI-2 : Method to check if limits reached is greater than 70%
     */
    private static boolean checkLimitsUsage(){
        boolean limitFlag = false;
        Decimal cpuTimeUsed = (decimal.valueOf(limits.getCPUTime())/decimal.valueOf(limits.getLimitCpuTime()))*100;
        Decimal heapUsed = (decimal.valueOf(limits.getHeapSize())/decimal.valueOf(limits.getLimitHeapSize()))*100;
       
        
        if(heapUsed > getSettings().heapSizeThreshold || cpuTimeUsed > getSettings().cpuTimeThreshold){
           
          // system.debug('@@loggging Stopped'); 
         //  getImplementationClass().emit();
         //  limitFlag = true;
         //  isOn = false;

         system.debug('@@loggging Stopped'); 

         getImplementationClass().emit();

         limitFlag = true;

         //isOn = false;
         isOn = false;
        }
        return limitFlag;
    }


     /**
    *    @author        
    *    @date          
    *    @description   
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *             Nitin							 4/12/2022			 CMSI-6 gettransaction id
    */
	public static String getTransactionId() {
        
		if(String.isBlank(transactionId)) {
			transactionId = generateTransactionID();
		}
		return transactionId;
	}

    /**
    *    @author        
    *    @date          
    *    @description  
    *    Modification Log:
        param - transaction id 
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *             Nitin							 4/12/2022			 CMSI-6 setting transaction id
    */
	public static void setTransactionId(string reqId)
    {
        transactionId= reqId;
    }
    /**
    *    @author        
    *    @date          
    *    @description 
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *             Nitin							 4/12/2022			 CMSI-6 generating transaction id
    */
	public static String generateTransactionID(){
		
		String aesHex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
		return aesHex.substring(0,8) + '-' + aesHex.substring(8,12) + '-' + aesHex.substring(12,16) + '-' + aesHex.substring(16,20) + '-' + aesHex.substring(20);
		
	}

    /**
*    @author Nitin, Anshaj       
*    @date          
*    @description: creating a wrapper class to pass the parameters in publish method
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
public class publishParameter {
    public String title{get; set;}
    public String logData{get; set;}
    public Id userId{get; set;}
    public Long elapsedTime{get; set;} 
    public String serializedLimitz{get; set;} 
    public String tid{get; set;}
    public String strWorkstream{get; set;}
    public ilib_LogEvent.Category cat{get; set;}
    public String rcType{get; set;}//CMSI-9
	public String linkKey{get; set;}									
        /**
*    @author Nitin, Anshaj       
*    @date          
*    @description: creating a wrapper class to pass the parameters in publish method
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
   public publishParameter(String title, String logData, Id userId, Long elapsedTime, String serializedLimitz, String tid, String workstream,ilib_LogEvent.Category cat, String recType,String linkKey){
       this.title=title;
       this.logData=logData;
       this.userId=userId;
       this.elapsedTime=elapsedTime;
       this.serializedLimitz=serializedLimitz;
       this.tid=tid;
       strWorkstream=workstream;
       this.cat=cat;
       this.rcType = recType; //CMSI-9
	   this.linkKey = linkKey;
   }
}

/**
* @description :DCP-56231:This method is called in Subflow to get the transaction Id and set it in flow
* @return List<String> 
**/
@InvocableMethod(label='Get Exception log variables for Flow' description='Returns the list of transaction Id and process type to be used for exception log of Flows.')
    public static List<FlowOutPutVariables> getFlowExceptionLogVariables(){
    List<FlowOutPutVariables> lstFlowOPVariable = new List<FlowOutPutVariables>();
    FlowOutPutVariables flowOPVar= new FlowOutPutVariables();
    flowOPVar.strTransactionId=getTransactionId();
    flowOPVar.isAsyncProcess=false;
    if(System.isQueueable() || system.isBatch() || system.isFuture() || system.isScheduled() || getLogCategory() == Category.restInterface){
        flowOPVar.isAsyncProcess=true;
    }
    lstFlowOPVariable.add(flowOPVar);
    System.debug('FlowOutPutVariables--->'+lstFlowOPVariable);
    return lstFlowOPVariable;

    }

/*
*Description:DCP-56231: wrapper class to hold the out variable for the flow
*/
public class FlowOutPutVariables {
    @InvocableVariable
    public string strTransactionId;
    @InvocableVariable
    public Boolean isAsyncProcess;
}

}