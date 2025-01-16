/**
*    @author Pranay   
*    @date          
*    @description   Implemetation class for IPsLog class for CMSI -11.
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Anshaj Sinha                  21/04/2022          CMSI-3 Added setTitle method and modified log level methods and getLoggingLevel method
*             Suraj Dhankar                 07/07/2022          CMSI-60 Add Linkey to link records using linkkey	
*             Rajbabu Boopalan              03/12/2024          CMCM-5579 Handle PublishImmediateDML limit error	
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/

public class ilib_LogEvent_PlatformEventEmit implements IPsLog {
    
    public static ilib_LogScope root;
    public static ilib_LogScope current;
    public static Map<String, ilib_LogScope> nameToScope = new Map<String, ilib_LogScope>();
    public static Integer intTotalLineCount = 0;
    public static final String SLOW_TRANSACTION_LOG_TITLE_PREFIX = 'Slow: ';
    public static String strRequestId;
    public static final String DEFAULT_SCOPE_NAME = 'NO TITLE GIVEN';
    public static List<ilib_LogQuery.Data> queries = new List<ilib_LogQuery.Data>();
    public static final Integer MAX_LOG_LENGTH = 990000; // iMB minus a bit of buffer
	public static String linkKey;
    
    public static List<String> linkKeySet = new List<String>();
    public static Map<String,String> scopeLinkeyMap = new Map<String,String>();

    /**
*    @author Pranay   
*    @date          
*    @description  
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    private static String rootTitle {
        get { return root.scope; }
        set
        {
        ilib_LogEvent.message('ignore-log-debugging setTitle CALLED ' + value);
            if (String.isBlank(value)) return;

            if (nameToScope.isEmpty())
            {
                // first title given
                linkKey = UtilsObject.getRandom(15);
                linkKeySet.add(linkKey);
                
                root.scope = value;
                root.limitz = new ilib_Limitz();
                nameToScope.put(linkKey, root);
                scopeLinkeyMap.put(value,linkKey);

            }
            else
            {
                // subsequent name given
                if (scopeLinkeyMap.containsKey(value))
                {
                    logInternalWarning('You added a duplicate title ' + value + ', it was ignored. This is not recommended since your emit() calls may be off.');
                }
                else
                {
                    push(value);
                    linkKey = UtilsObject.getRandom(15);
                    linkKeySet.add(linkKey);
                    nameToScope.put(linkKey, current);
                    scopeLinkeyMap.put(value,linkKey);
                }
            }
        }
    }
    /**
*    @author Pranay   
*    @date          
*    @description  
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static string getRootTitle(){
        return rootTitle;
    }

    static
    {
        reset();
    }

    @TestVisible
    private static void logInternalWarning(String message)
    {
        ilib_LogEvent.push('INTERNAL WARNING');
        ilib_LogEvent.message(message);
        ilib_LogEvent.pop();
    }
    
    /**
     * @author Pranay
     * @description Method to set title for log
     */
    public static void setTitle(String title)
    { 
        rootTitle = title;
    }

	
     /**
     * @author Pranay
     * @description Implemetation methos for push
     */
    public static void push(String scope)
    {
        if (String.isBlank(scope)) return;
        ilib_LogScope newScope = new ilib_LogScope();
        newScope.scope = scope;
        newScope.limitz = new ilib_Limitz();
        newScope.parent = current;
        current.logEntries.add(newScope);
        current = newScope;
    }

    private static void reset()
    {
        root = current = new ilib_LogScope();
        nameToScope.clear();
    }

   
    
   
    /**
     * @author Pranay
     * @description Pop the current scope
     */
    public static void pop()
    {
        if (current == null)
        root = current = new ilib_LogScope();

        // defaults provided to solve null pointer
        ilib_Limitz poppedScopeLimitz = (current.limitz == null)
            ? new ilib_Limitz(true) // all zero values
            : current.limitz;

            current.limitz = new ilib_Limitz(poppedScopeLimitz);

        if (current.parent != null)
            current = current.parent;
          
    }


   
  /**
*    @author  
*    @date          
*    @description 
*    Param - 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Anshaj Sinha                  21/04/2022           CMSI-3 Added Workstream field
*/
    private static void handleTransactionPersistence(Boolean persistenceConfiguredForThisUser, String emitScopeName, String rootTitle)
    {
        
        Long elapsedTime = 0;
        // find scope corresponding to emitScopeName
        // which is the "root" for this emit
         ilib_LogScope emitRoot;
        
        if(nameToScope.containsKey(linkKey)){
            emitRoot = nameToScope.get(linkKey);
        }
        if (emitRoot == null) emitRoot = root;

        if (emitRoot == null) {return;}

        if(emitRoot.scope != Null && emitRoot.scope != DEFAULT_SCOPE_NAME) {
            emitScopeName =  emitRoot.scope;  
        }
        // serialize structured text
        String formattedLogText = ilib_LogScope.flush(emitRoot);
        System.debug(formattedLogText);

        emitRoot.logEntries = new List<Object>();

        Boolean isSlowTransaction = ilib_LogEvent.isTransactionSlowAndPersistable(elapsedTime);

        // if transaction was slow or user is configured to persist on this transaction
        if (persistenceConfiguredForThisUser || isSlowTransaction)
        {
            processTransaction(emitRoot, emitScopeName, isSlowTransaction, formattedLogText);
        }

        if (emitScopeName == rootTitle)
        {
            // if emitting the root we are done, clear all state
            reset();
        }
        else
        {
            finishTransaction(emitScopeName);
        }
    }

     /*****************************************************************************************
     *method added to get called from handleTransactionPersistence() to resolve NPath Complexity
     ******************************************************************************************/
    public static void processTransaction(ilib_LogScope emitRoot,String emitScopeName,Boolean isSlowTransaction, String formattedLogText){
         
         
         // default values
        String serializedLimitz = '';
        Long elapsedTime = 0;

        // if no title was found, try to find something
         
         Boolean noTitleGiven = String.isBlank(emitScopeName);
         String displayTitle = noTitleGiven ? findDisplayTitleFromRoot() : emitScopeName;

         // the flush call adds the end time
         // get limits information for publish call
         if (emitRoot != null)
         {
             serializedLimitz = JSON.serialize(emitRoot.limitz);
             elapsedTime = (emitRoot.limitz != null) ? emitRoot.limitz.elapsedTime : 0;
         }
         
         String logTitle = ilib_LogEvent.truncateTo(isSlowTransaction ? SLOW_TRANSACTION_LOG_TITLE_PREFIX + displayTitle : displayTitle, 255);
         //CMSI-5 passing log category as parameter and passing the parameters through wrapper class
        ilib_logEvent.publishParameter publishParameters = new  ilib_logEvent.publishParameter(logTitle, formattedLogText, ilib_LogEvent.loggingUserId, elapsedTime, serializedLimitz, ilib_LogEvent.getTransactionId(), ilib_LogEvent.getWorkstream(),ilib_LogEvent.getLogCategory(),ilib_logEvent.recType, linkKey);
        IlmnLogs.publish(publishParameters);
        System.debug('Log published, will be persisted');
    }

     /*****************************************************************************************
     *method added to get called from handleTransactionPersistence() to resolve NPath Complexity
     ******************************************************************************************/
    public static void finishTransaction(String emitScopeName){
        if (nameToScope.containsKey(linkKey))
        {
            // adding sub-scope perform auto-push
            // do auto-pop so the limits calcs are correct
            pop();
            // when emitting a sub-scope, we are done with it, in part
            // remove it from the map but leave the lines in for emits of parent scope(s)
            nameToScope.remove(linkKey);

            Integer i = linkKeySet.size() - 1;
            
            if(i >= 0){
                linkKeySet.remove(i);
                if(i - 1 >= 0){
                    
                    linkKey = linkKeySet.get(i - 1);
                    system.debug('@@SDLinkKeySwitched'+linkKey);
                }
            }
        }

        if(scopeLinkeyMap.containsKey(emitScopeName)){
            scopeLinkeyMap.remove(emitScopeName);
        }
    }

    /**
     * @author
     * @description 
     */
    public static void emit()
    {
        emit(root.scope);
    }

    /**
     * @author
     * @description if no title was given and root scope is blank. Make best effort to find a title
     */
    private static String findDisplayTitleFromRoot()
    {
        String displayTitle = DEFAULT_SCOPE_NAME;

        if (root != null && root.logEntries != null)
        {
            for (Object l : root.logEntries)
            {
                if (l instanceof ilib_LogScope)
                {
                    displayTitle = ((ilib_LogScope)l).scope;
                    break;
                }
                if (l instanceof ilib_LogLine)
                {
                    displayTitle = ((ilib_LogLine)l).message;
                    break;
                }
            }
        }

        return displayTitle;
    }

    /**
     * @author
     * @description 
     */
    public static void emit(String emitScopeName)
    {
        
        if (! ilib_LogEvent.isAnyPersistingAllowed()) return;

        Boolean persistenceConfiguredForThisUser = ilib_LogEvent.isUserConfiguredToPersistLogs(emitScopeName);

        // find root title
        // if the user never set a title use the default
        Boolean noTitleGiven = String.isBlank(emitScopeName);
        String rtTitle = noTitleGiven ? DEFAULT_SCOPE_NAME : root.scope;

        handleTransactionPersistence(persistenceConfiguredForThisUser, emitScopeName, rtTitle);

      
        ilib_LogEvent.handleQueryPersistence(persistenceConfiguredForThisUser,queries,linkKey);
        queries.clear();
        
    }

   

/**
*    @author  
*    @date          
*    @description 
*    Param - message
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Anshaj Sinha                  21/04/2022           CMSI-3 Added method to cover Error level logs
*/
   public void error(String message)
   {
       if (String.isBlank(message)) return;
       ++intTotalLineCount;
       if (intTotalLineCount >  ilib_LogEvent.getSettings().lineCountCap) { return;}
       string msg='ERROR : '+message;
       current.logEntries.add(new ilib_LogLine(msg.abbreviate(ilib_LogEvent.getSettings().lineLengthCap)));
   }
  /**
*    @author  
*    @date          
*    @description 
*    Param - message
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Anshaj Sinha                  21/04/2022           CMSI-3 Added method to cover Info level logs
*/
   public void info(String message)
   {
       if (String.isBlank(message)) return;
       ++intTotalLineCount;
       if (intTotalLineCount > ilib_LogEvent.getSettings().lineCountCap) { return;}
       string msg='INFO : '+message;
       current.logEntries.add(new ilib_LogLine(msg.abbreviate(ilib_LogEvent.getSettings().lineLengthCap)));
   }
  /**
    *    @author  
    *    @date          
    *    @description 
    *    Param - message
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *            Anshaj Sinha                  21/04/2022         CMSI-3 Added prefix DEBUG in message
    */
   public void debug(String message)
   {
       if (String.isBlank(message)) return;
       // INC0324110: count of stored strings is capped at lineCountCap
       ++intTotalLineCount;
       if (intTotalLineCount >ilib_LogEvent.getSettings().lineCountCap) { return;}
       string msg='DEBUG : '+message;
       // INC0324110: length of stored string is capped to length <= lineLengthCap
       current.logEntries.add(new ilib_LogLine(msg.abbreviate(ilib_LogEvent.getSettings().lineLengthCap)));        
   }

   /**
    *    @author  
    *    @date          
    *    @description 
    *    Param - message
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *            Anshaj Sinha                  21/04/2022           CMSI-3 Added method to cover Fine level logs
    *            Anshaj Sinha                  02/06/2022           CMSI-58 Added if block with queryFlag
    */
    public void debug(ilib_LogQuery.Data query){
        if (query == null) return;
        System.debug(query.flushToText());
        queries.add(query);
    }
  /**
    *    @author  
    *    @date          
    *    @description 
    *    Param - message
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *            Anshaj Sinha                  21/04/2022           CMSI-3 Added method to cover Fine level logs
    */
   public void fine(String message)
   {
       if (String.isBlank(message)) return;
       ++intTotalLineCount;
       if (intTotalLineCount > ilib_LogEvent.getSettings().lineCountCap) { return;}
       string msg = 'FINE : '+message;

       current.logEntries.add(new ilib_LogLine(msg.abbreviate(ilib_LogEvent.getSettings().lineLengthCap)));
   }

}