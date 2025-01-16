/*@ author       : Rahul Bishnoi
* @ date         : 02-12-2020
* @ Description  : Batch to Sync ERP Line Number Id of Asset line item with Order Line Item 
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rahul Bishnoi           02-12-2020                 Initial version
* Satya Swain             09 Dec 2022         Added Codescan fix for Variable Naming Convention
*/


global with sharing class BatchToPopulateErpLineNoIdAssetLI extends ilib_ScheduleAndBatch implements Database.Stateful{
    public String query;

    /*@ author       : Rahul Bishnoi
    * @ date         : 02-12-2020
    * @description  start method override
    *
    */
    global override Database.QueryLocator start(Database.BatchableContext bc){
        this.query = 'SELECT Id,ERP_Line_Number_Id__c, Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__AssetLineItemId__r.ERP_Line_Number_Id__c = null AND Apttus_Config2__AssetLineItemId__c !=null';
        return Database.getQueryLocator(query);
    }

    /*@ author       : Rahul Bishnoi
    * @ date         : 02-12-2020
    * @description  execute method override
    *
    */
    global override void execute(Database.BatchableContext bc, List<sObject> scope){

        List<Apttus_Config2__OrderLineItem__c> lstOli = (List<Apttus_Config2__OrderLineItem__c>)scope;
        System.debug('lstOli: '+lstOli);
        Map<Id,Apttus_Config2__AssetLineItem__c> mapIdToAli = new Map<Id,Apttus_Config2__AssetLineItem__c>();
        for(Apttus_Config2__OrderLineItem__c oli : lstOli)
        {
            Apttus_Config2__AssetLineItem__c ali = new Apttus_Config2__AssetLineItem__c();
            ali.ERP_Line_Number_Id__c = oli.ERP_Line_Number_Id__c;
            ali.id = oli.Apttus_Config2__AssetLineItemId__c;
            mapIdToAli.put(ali.id,ali);
        }
        System.debug('mapIdToAli: '+mapIdToAli);
        List<Database.SaveResult> res;
        if(!mapIdToAli.isEmpty())
            res = Database.update(mapIdToAli.values(), false);
        else {
            return;
        }
        String mailBody='';
        Integer index = 0;
        for(Database.SaveResult inst : res)
        {
            if (!inst.isSuccess() || Test.isRunningTest()) {
                System.debug('Record ID : ' + mapIdToAli.values().get(index).id);
                for(Database.Error err : inst.getErrors()) {
                    mailBody = mailBody + 'The following error has occurred.\n';        
                    mailBody = mailBody + err.getStatusCode() + ': ' + err.getMessage() + '.\n';
                    mailBody = mailBody + 'For Record ID : ' + mapIdToAli.values().get(index).id + '.\n';
                    mailBody = mailBody + 'fields that affected this error: ' + err.getFields() + '\n\n';
                }         
            }
            index++;
        }
        if(!String.IsBlank(mailBody) || Test.isRunningTest())
        {
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            String[] sendingTo = new String[]{'amohan@illumina.com'};
            String[] sendingTocAdd = new String[]{'rbishnoi@illumina.com'};
            semail.setToAddresses(sendingTo); 
            semail.setCcAddresses(sendingTocAdd); 
            semail.setSubject('Batch To Sync Asset ERP Line No. Id FAILED!');
            if(String.IsBlank(mailBody)) mailBody = 'Running Test, All Good';
            semail.setPlainTextBody(mailBody); 

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail}); 
        }
        

    }
    /**
    * @author Rahul Bishnoi
    * @date   09-Feb-2022
    * @description   Overriding finish method for batch
    * @params Database.BatchableContext bc
    * @return void
    */
    global override void finish(Database.BatchableContext bc){}
}