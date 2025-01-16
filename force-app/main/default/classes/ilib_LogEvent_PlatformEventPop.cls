/**
*    @author Suraj Dhankar       
*    @date 15/05/2022         
*    @description   PS Log Framework Class for Pop Emit at seq 1v (CMSI-4)
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*/

public class ilib_LogEvent_PlatformEventPop implements IPsLog {
    
    public static ilib_LogScope root;
    public static ilib_LogScope current;
    public static Map<String, ilib_LogScope> nameToScope = new Map<String, ilib_LogScope>();
    public static Integer totalLineCount = 0;
    public static final String SLOW_TRANSACTION_LOG_TITLE_PREFIX = 'Slow: ';
    public static String requestId;
    public static final String DEFAULT_SCOPE_NAME = 'NO TITLE GIVEN';
    public static List<ilib_LogQuery.Data> queries = new List<ilib_LogQuery.Data>();
    public static final Integer MAX_LOG_LENGTH = 990000; // iMB minus a bit of buffer
									
    public static Integer seq = 0;
    public static Integer one = 1;
    public static String emitScopeRootMethod;
    public static Boolean persistenceConfiguredForThisUser = false;
    public static boolean isParentPublished = false;
    public static String lastSetTitle;
    public static final string POP_CHILD = 'Pop_Child';
    public static Map<String,String> titleToLinkKeyMap = new Map<String,String>();
	public static String linkKey;
    public static Map<String, Integer> seqToLinkKey = new Map<String, Integer>();
    public static Map<String, Integer> scopeToLinkKey = new Map<String, Integer>();
    public static Map<String, Integer> levelToLinkKey = new Map<String, Integer>();
    public static Map<String,String> linkKeyToTitleMap = new Map<String,String>();
    public static List<String> linkKeySet = new List<String>();																				 


    private static void publishPopParent(String value){

        if(!persistenceConfiguredForThisUser){
            persistenceConfiguredForThisUser = ilib_LogEvent.isUserConfiguredToPersistLogs(value);
        }

        linkKey = UtilsObject.getRandom(15);
        linkKeySet.add(linkKey);
        
       

        if(persistenceConfiguredForThisUser){
            ilib_logEvent.publishParameter publishParameters = new  ilib_logEvent.publishParameter(value, null, ilib_LogEvent.loggingUserId, null, null, ilib_LogEvent.getTransactionId(), ilib_LogEvent.getWorkstream(),ilib_LogEvent.getLogCategory(),'Pop_Parent',linkKey);
            IlmnLogs.publish(publishParameters);
        }
 

        if(value.contains('Trigger-')){
            system.debug('@@Scope'+value);
            seqToLinkKey.put(linkKey,-1);
        }
        titleToLinkKeyMap.put(value,linkKey);
        
    }



    private static String rootTitle {
        get { return root.scope; }
        set
        {
        ilib_LogEvent.message('ignore-log-debugging setTitle CALLED ' + value);
            if (String.isBlank(value)) return;
			 

            if (nameToScope.isEmpty())
            {
                // first title given
                root.scope = value;
                root.limitz = new ilib_Limitz();
											 
                publishPopParent(value);
                nameToScope.put(linkKey, root);
                

			   
           
                System.debug('Log published, will be persisted');

            }
            else
            {
                // subsequent name given
                
                if (titleToLinkKeyMap.containsKey(value))
                {   
                   
                    logInternalWarning('You added a duplicate title ' + value + ', it was ignored. This is not recommended since your emit() calls may be off.');
                }
                else
                {
                   // push(value);
													
                    publishPopParent(value);
                    nameToScope.put(linkKey, current);
                    
                }
            }
        }
    }

    /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param -
*    
******/

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

     /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param - String Title
*    
******/

    public static void setTitle(String title)
    { 
        system.debug('@@SDScope'+title);
        rootTitle = title;
    }
			


     /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param - String Scope
*    
******/
    public static void push(String scope)
    {
        if (String.isBlank(scope)) return;
        ilib_LogScope newScope = new ilib_LogScope();
        newScope.scope = scope;
        newScope.limitz = new ilib_Limitz();
        newScope.parent = current;
        current.logEntries.add(newScope);
        current = newScope;

       

        
        if(seqToLinkKey.containsKey(linkKey)){
            seqToLinkKey.put(linkKey,seqToLinkKey.get(linkKey) + 1);
        }else{
            seqToLinkKey.put(linkKey,1);
        }

        system.debug('@@SDPush'+seqToLinkKey.get(linkKey)+' '+scope);
		

        if(seqToLinkKey.containsKey(linkKey) && seqToLinkKey.get(linkKey) == one){
            nameToScope.put(scope+linkKey, current);
            linkKeyToTitleMap.put(linkKey,scope);
        }

        

       

    }
	
    /*******
*    @author illumina 
*    @date          
*    @description 
******/
    public static void initializeSequence(){
        // seq = 0;
     }
    
    private static void reset()
    {
        //ilib_LogEvent.setLogLevel(ilib_logEvent.Level.DEBUG);
        root = current = new ilib_LogScope();
        nameToScope.clear();
    }




       /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param -
*    
******/
    public static void pop()
    {  

        if (current == null)
        root = current = new ilib_LogScope();

        // defaults provided to solve null pointer
        ilib_Limitz poppedScopeLimitz = (current.limitz == null)
            ? new ilib_Limitz(true) // all zero values
            : current.limitz;

            current.limitz = new ilib_Limitz(poppedScopeLimitz);

            system.debug('@@SDPop'+' '+current);    

        if (current.parent != null)
            current = current.parent;

            system.debug('@@SDPop'+' '+current);
        
        system.debug('@@SDPop'+seqToLinkKey.get(linkKey)+' '+emitScopeRootMethod);

      

        if(seqToLinkKey.containsKey(linkKey) && seqToLinkKey.get(linkKey) == one && linkKeyToTitleMap.containsKey(linkKey) && nameToScope.containsKey(linkKeyToTitleMap.get(linkKey)+linkKey)){
            //system.debug('@@SDEmitMethod'+nameToScope.get(emitScopeRootMethod));
            ilib_LogEvent.recType = 'Pop_Child';
            publishCurrentSeq(linkKeyToTitleMap.get(linkKey));
            //nameToScope.remove(linkKeyToTitleMap.get(linkKey)+linkKey);
            //CMSI-4 reset current for new logs lined to be added in future
            current.logEntries = new List<Object>();
        }

        if(seqToLinkKey.containsKey(linkKey)){
            if(seqToLinkKey.get(linkKey) >= 0){
                seqToLinkKey.put(linkKey,seqToLinkKey.get(linkKey) - 1);
            }
            
        }

        
          
    }
    
  /**
*    @author Suraj Dhankar  
*    @date   15/05/2022        
*    @description 
*    Param - String emitScopeName, String rootTitle
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Anshaj Sinha                  21/04/2022           CMSI-3 Added Workstream field
*/
    private static void handleTransactionPersistence(String emitScopeName, String rootTitle, boolean isMethodPop)
    {
        Long elapsedTime = 0;
        // find scope corresponding to emitScopeName
        // which is the "root" for this emit
		ilib_LogScope emitRoot;
        if(isMethodPop && nameToScope.containsKey(emitScopeName+linkKey)){
            emitRoot = nameToScope.get(emitScopeName+linkKey);
        }else if(nameToScope.containsKey(linkKey)){
            emitRoot = nameToScope.get(linkKey);
        }										   
        if (emitRoot == null) emitRoot = root;

        // serialize structured text
        String formattedLogText = ilib_LogScope.flush(emitRoot);
       
		System.debug(formattedLogText);							   

        Boolean isSlowTransaction = ilib_LogEvent.isTransactionSlowAndPersistable(elapsedTime);

        // if transaction was slow or user is configured to persist on this transaction
        if (persistenceConfiguredForThisUser || isSlowTransaction)
        {
            processTransaction(emitRoot, emitScopeName, isSlowTransaction, formattedLogText, isMethodPop);
        }

        if (emitScopeName == rootTitle)
        {
            // if emitting the root we are done, clear all state
            reset();
        }
        else
        {   
            finishTransaction(emitScopeName, isMethodPop);
           
        }
    }

    /*****************************************************************************************
     *method added to get called from handleTransactionPersistence() to resolve NPath Complexity
     ******************************************************************************************/
    public static void processTransaction(ilib_LogScope emitRoot, String emitScopeName,Boolean isSlowTransaction, String formattedLogText, Boolean isMethodPop){
        
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
         ilib_logEvent.publishParameter publishParameters = new  ilib_logEvent.publishParameter(logTitle, formattedLogText, ilib_LogEvent.loggingUserId, elapsedTime, serializedLimitz, ilib_LogEvent.getTransactionId(), ilib_LogEvent.getWorkstream(),ilib_LogEvent.getLogCategory(),ilib_LogEvent.recType,linkKey);  
         IlmnLogs.publish(publishParameters);
         
         System.debug('Log published, will be persisted');
    }

     /*****************************************************************************************
     *method added to get called from handleTransactionPersistence() to resolve NPath Complexity
     ******************************************************************************************/
    public static void finishTransaction(String emitScopeName, Boolean isMethodPop){
        if(isMethodPop){
            if (nameToScope.containsKey(emitScopeName+linkKey)){
                nameToScope.remove(emitScopeName+linkKey);
            }
            
        }else{
            if (nameToScope.containsKey(linkKey)){
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
            if(titleToLinkKeyMap.containsKey(emitScopeName)){
                titleToLinkKeyMap.remove(emitScopeName);  
            }
        }

   }

     /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param -
*    
******/

    public static void emit()
    {
        
        emit(root.scope);
    }


    

    // if no title was given and root scope is blank
    // make best effort to find a title
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



     /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param - String EmitScope
*    
******/
    public static void emit(String emitScopeName)
    {
        system.debug('@@SDScopeEmit'+emitScopeName);
        if (! ilib_LogEvent.isAnyPersistingAllowed()) return;

        ilib_LogEvent.recType = 'Pop_Parent';

        //CMSI-4
        if(!persistenceConfiguredForThisUser){
            persistenceConfiguredForThisUser = ilib_LogEvent.isUserConfiguredToPersistLogs(emitScopeName);
        }    

        // find root title
        // if the user never set a title use the default
        Boolean noTitleGiven = String.isBlank(emitScopeName);
        String rootTitle = noTitleGiven ? DEFAULT_SCOPE_NAME : root.scope;

        handleTransactionPersistence(emitScopeName, rootTitle, false);

          
        ilib_LogEvent.recType = 'Pop_Child';
        
        ilib_LogEvent.handleQueryPersistence(persistenceConfiguredForThisUser,queries,linkKey);
        queries.clear();
        
    }


     /*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param - String EmitScope
*    
******/
public static void publishCurrentSeq(String emitScopeName)
{
    
    if (! ilib_LogEvent.isAnyPersistingAllowed()) return;

    //CMSI-4
    if(!persistenceConfiguredForThisUser){
        persistenceConfiguredForThisUser = ilib_LogEvent.isUserConfiguredToPersistLogs(emitScopeName);
    }    

    // find root title
    // if the user never set a title use the default
    Boolean noTitleGiven = String.isBlank(emitScopeName);
    String rootTitle = noTitleGiven ? DEFAULT_SCOPE_NAME : root.scope;

    handleTransactionPersistence(emitScopeName, rootTitle, true);

   
    
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
    ++totalLineCount;
    if (totalLineCount > ilib_LogEvent.getSettings().lineCountCap) return;
    String msg='ERROR : '+message;
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
    ++totalLineCount;
    if (totalLineCount > ilib_LogEvent.getSettings().lineCountCap) return;
    String msg ='INFO : '+message;
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
    ++totalLineCount;
    if (totalLineCount > ilib_LogEvent.getSettings().lineCountCap) return;
    String msg='DEBUG : '+message;
    // INC0324110: length of stored string is capped to length <= lineLengthCap
    current.logEntries.add(new ilib_LogLine(msg.abbreviate(ilib_LogEvent.getSettings().lineLengthCap)));        
}
/*******
*    @author Suraj Dhankar 
*    @date 15/05/2022         
*    @description - CMSI-4
*    Param - ilib_LogQuery.Data query
*    
******/
public void debug(ilib_LogQuery.Data query){
    if (query == null) return;
    System.debug(query.flushToText());

   
    current.logEntries.add(query);
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
    ++totalLineCount;
    if (totalLineCount > ilib_LogEvent.getSettings().lineCountCap) return;
    String msg= 'FINE : '+message;
    current.logEntries.add(new ilib_LogLine(msg.abbreviate(ilib_LogEvent.getSettings().lineLengthCap)));
}}