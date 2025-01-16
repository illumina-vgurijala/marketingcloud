/*@ author       : Maruthi
* @ date         : 09-Feb-2022
* @ Description  : PM-122: R/Q Contact Eligible Queueable
*/
public with sharing class RQContactEligibleQueueable implements Queueable {
    Set<Id> setOrderIds;
    public static final String CODEPARAMETERORDERTYPE = 'Order_Types_For_Contact_Eligibility';
    public static final String DISTRIBUTOR = 'Distributor';
    public static final String SOLDTO ='Sold To';
    private static final String LOG_TITLE = 'RQContactEligibleQueueable';
    public static final String RQCONTACTELIGIBLE ='R_Q_Contact_Eligible__c';

    /*@ author       : Maruthi
    * @ date         : 09-Feb-2022
    * @ Description  : This is the Constructor for RQContactEligibleQueueable
    */
    public RQContactEligibleQueueable(Set<Id> setOrderIds) {
        this.setOrderIds = setOrderIds;         
    }

    /*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This Method to invoke  
    */
    public void execute(QueueableContext context) {  
        ilib_LogEvent.push(LOG_TITLE +'.updateRQContactEligible');  
        try {
            ilib_LogEvent.message('setOrderIds--'+setOrderIds);
            Set<Id> setAccountIds = new Set<Id>();        
            List<Code_Parameter__mdt> codeParameter =new CodeParametersSelector().selectCodeParameterByDeveloperName(new set<String>{CODEPARAMETERORDERTYPE});               
            List<String> orderTypeList = codeParameter[0].Value__c.split(',');  
            List<Apttus_Config2__Order__c> listOrder = new ApttusOrdersSelector().selectOrdersByIds(setOrderIds);            
            setAccountIds = RQContactEligibleHelper.getRQAccountId(listOrder,orderTypeList); //CMCM-698
            List<Account> updateListAccount = getUpdateList(setAccountIds); 
            ilib_LogEvent.message('updateListAccount--'+updateListAccount);
            if(!updateListAccount.isEmpty()) {                
                Update updateListAccount;
            }
            ilib_LogEvent.pop();
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE+'.updateRQContactEligible',e);
            throw e;
        }  		
    }

    /*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: TASK0754014-This Method to get update list 
    */
    private List<Account> getUpdateList(Set<Id> setAccountIds) { 
        
        List<Account> lstAccount = new AccountsSelector().selectRQAccounts(setAccountIds);  
		//added as part of TASK0754014
        List<AccountHistory> lstAccountHistory = new AccountHistorySelector().selectObjectHistory(setAccountIds,RQCONTACTELIGIBLE);
        Set<Id> setAccId = new Set<Id>();
        for(AccountHistory accHis : lstAccountHistory) {
            if(accHis.OldValue == True && accHis.NewValue == False) {
                setAccId.add(accHis.AccountId);    
            }             
        }                  
        List<Account> updateListAccount = new List<Account>();
        for(Account objAcc : lstAccount) {   
            if(setAccId.isEmpty() || !setAccId.isEmpty() && !setAccId.contains(objAcc.Id)) {
                objAcc.R_Q_Contact_Eligible__c = true;
                updateListAccount.add(objAcc);  
            }             
        }
        
        return updateListAccount;
    }
}