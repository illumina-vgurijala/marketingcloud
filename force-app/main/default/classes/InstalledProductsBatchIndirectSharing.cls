/***************************************************************************************************************************************
* NAME   : InstalledProductsBatchIndirectSharing 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                    DATE                    DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gerardo Garcia           2023-12-07                  CMCM-4772 Change Constructor and query locator to receive account Ids
* --------------------------------------------------------------------------------------------------------------------------------------
*/
global class InstalledProductsBatchIndirectSharing implements Database.Batchable<SObject>
{
    global Set<Id> accountIds;

		/*
		 * description - InstalledProductsBatchIndirectSharing method
    */ 
    global InstalledProductsBatchIndirectSharing(Set<Id> accountIds)
    {
        this.accountIds = accountIds;
    }

		/*
		 * description - start method
         */ 
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator('SELECT Id, SVMXC__Product__c, SVMXC__Company__c ' +
                'FROM SVMXC__Installed_Product__c ' +
                'WHERE SVMXC__Company__c IN :accountIds');
    }

		/*
		 * description - execute method
         */ 
    global void execute(Database.BatchableContext bc, List<sObject> lstRecords)
    {
        InstalledProductsService.shareWithDistributorUsers(lstRecords);
    }

		/*
		 * description - finish method
         */ 
    global void finish(Database.BatchableContext bc) {  }

}