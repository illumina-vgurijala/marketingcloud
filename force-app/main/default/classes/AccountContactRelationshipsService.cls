/****************************************************************************************************************************************
* NAME         : AccountContactRelationshipsService
* DESCRIPTION  : Handler class for AccountContactRelationship Logic 
*                    
* @AUTHOR : Saddam
* @DATE   : 21-Mar-2022 
* 
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
  Saddam                21-Mar-2022           Initial Version.PM-33 and PM-430
  Avina                 13-Jun-2022           CMSI-68,Added Instrumentation 
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class AccountContactRelationshipsService {

     //Boolean varaible to stop recursion 
     private static Boolean stopRecurssion = false;

     private static final String LOG_TITLE = 'AccountContactRelationshipsService';

    // 
    /* @author     : saddam
     * @param      : Acr list of records
     * @return     : N/A
     * @Description: To check Acr records if there are R/Q or not and update the Account field ,pm-33, PM-430
     **/
    public static void updateRQContactCompliant( List<AccountContactRelation> acrRecords) {  

        ilib_LogEvent.push(LOG_TITLE + '.updateRQContactCompliant()');
        //Receives setofid of Account by passing Acr records
        Set<Id> setOfAccIds = UtilsCollection.getSetOfIds(acrRecords, 'AccountId');
        ilib_LogEvent.info('setOfAccIds-->: '+setOfAccIds);//CMSI-68

        //Stores the Accountlist returned from accountservice class
        List<Account> accountUpdateList=new List<Account>();
        if (!Test.isRunningTest()) {
          //Returns List<Account> for update after checking the contacts or Acr Records
          accountUpdateList = AccountsService.updateRqAccount(setOfAccIds);
        }

        ilib_LogEvent.info('accountUpdateList-->: '+UtilsCollection.getSetOfIds(accountUpdateList));

        //updates the list of Account received in queuable class
        if(!system.isQueueable() && !stopRecurssion && accountUpdateList!=NUll && !accountUpdateList.isEmpty()) {
          stopRecurssion =true;
          asyncUpdateAccountCompliance(accountUpdateList); 
        } 
         ilib_LogEvent.pop();          
    }

    // 
    /* @author     : Saddam 
     * @param      : account list of records
     * @return     : N/A
     * @Description: Records passed from updateRQContactCompliant() to call queueablemethod ,pm-33, PM-430
     * Date:18-APR-22
     **/
    public static void asyncUpdateAccountCompliance(List<Account> accountUpdateList) {

      ilib_LogEvent.push(LOG_TITLE + '.asyncUpdateAccountCompliance()');
      
      //Calling queueable method 
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('AcrAccountupsert');  
        ilib_LogEvent.info('accountUpdateList-->: '+UtilsCollection.getSetOfIds(accountUpdateList));//CMSI-68
        AccountRQComplianceUpdateQueueable objAccountQueueable= new AccountRQComplianceUpdateQueueable(accountUpdateList);
        queueableThread.logAndQueue(objAccountQueueable,'AccountRQComplianceUpdateQueueable','execute'); 
        //CMSI-36 Workstream passed to framework
        ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES); 
        ilib_LogEvent.pop();  
  } 
}
