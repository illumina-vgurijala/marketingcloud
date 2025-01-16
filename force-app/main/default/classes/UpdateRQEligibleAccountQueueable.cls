/*@ author       : Saddam
* @ date         : 22-02-2022
* @ Description  : Account update Queueable,PM-33
*
*/
public with sharing class UpdateRQEligibleAccountQueueable implements Queueable {
   
    List<Account> listOfAccounts;
    private static Boolean stoprecurssion = false;
    
   
     /*@ author       : Saddam
    * @ date         : 22-02-2022
    * @ Description  : This is the Constructor for AccountUpdateQueueable, PM-33
    */
    public UpdateRQEligibleAccountQueueable(List<Account> listOfAccounts) {
        this.listOfAccounts = listOfAccounts;
    }
    
    /*
    *  @AUTHOR:  Saddam
    *  @DESCRIPTION: This Method to update the Accounts when ACR updated, pm-33
    */
    public void execute(QueueableContext context) {    
        try {
            if(!listOfAccounts.isEmpty() && !stoprecurssion) {
                update listOfAccounts;
            }
        } catch(Exception e) {
            //catch the exception 
            ApexExceptions.emit('Accounts', e);
        }  
    }          
}