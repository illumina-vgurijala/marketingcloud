/*@ author       : Saddam
* @ date         : 18-02-2022
* @ Description  : Account update Queueable ,pm-33
*
*/
public with sharing class AccountRQComplianceUpdateQueueable implements Queueable {
   
    List<Account> listOfAccounts;
    private static Boolean stoprecurssion = false;

     /*@ author       : Saddam
    * @ date         : 18-02-2022
    * @ Description  : This is the Constructor for AccountUpdateQueueable-pm-33
    */
    public AccountRQComplianceUpdateQueueable(List<Account> listOfAccounts) {
        this.listOfAccounts = listOfAccounts;
    }
    
    /*
    *  @AUTHOR:  Saddam
    *  @DESCRIPTION: This Method to update the Accounts when ACR updated/Inserted.pm-33
    */
    public void execute(QueueableContext context) {             
      try {
        if (!listOfAccounts.isEmpty() && !stoprecurssion) {
          stoprecurssion=true;
          upsert listOfAccounts;
        }
      } catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('Accounts', e);
       }    
    }
}