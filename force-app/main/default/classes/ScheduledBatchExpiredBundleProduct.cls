/*@ author       : Joshith k
* @ date         : 05-11-2018
* @ Description  : DCP 11324 Batch update to Inactivate Bundle products with supressed expiration date
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Joshith k        05-11-2018                 Initial version
* Nesar Mohan      01-04-2022                 CodeScan Fix
* Nishan Shetty    09-06-2022                DCP-50962 - Batch manager implementation
* Satya Swain      09 Dec 2022               Added Codescan fix for Variable Naming Convention
*/
global with sharing class ScheduledBatchExpiredBundleProduct extends ilib_BatchDeferrable implements Database.Stateful {
                  
    /*
    *  @Author      : Joshith k
    *  @Description : Method to execute the batch
    *  @Param       : SchedulableContext
    *  @Return      : void
    */

    global override void execute(SchedulableContext ctx){
        integer defaultBatchsize=10;
        Map<String, String> params = UtilsSettings.getCustomMetadataMap('Batch_BundleProduct_Inactive');
        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'ProductBatchSize', defaultBatchsize);

        if (batchSize < 1 || batchSize > 200){
            batchSize = defaultBatchsize;
        }
        //DCP-50962
		 ilib_BatchManager.executeBatch(new ScheduledBatchExpiredBundleProduct(),batchsize);
    }

    /*
    *  @Author      : Joshith k
    *  @Description : start method to query bundle product with expiration date surpassed and active
    *  @Param       : Database.BatchableContext
    *  @Return      : Database.QueryLocator
    */

    global override Database.QueryLocator start(Database.BatchableContext bc){
        DateTime dtoday = DateTime.now();
        String strSoql = 'SELECT id,isactive FROM product2  where Apttus_Config2__ConfigurationType__c=\'Bundle\' and Apttus_Config2__ExpirationDate__c< :dtoday and isactive=true';

        return Database.getQueryLocator(strSoql);
    }

    /*
    *  @Author      : Joshith k
    *  @Description : execute method to inactivate products of query result
    *  @Param       : Database.BatchableContext, List<sObject>
    *  @Return      : void
    */

    global override void execute(Database.BatchableContext bc, List<sObject> lstScope){
        list<product2> listToUpdate = new list<product2>();
        for (product2 p : (list<product2>)lstScope){
            p.isactive = false;
            listToUpdate.add(p);
        }
        update listToUpdate;
    }
        
    /*
    *  @Author      : Joshith k
    *  @Description : finish method
    *  @Param       : Database.BatchableContext
    *  @Return      : void
    */
    
    global Override void finish(Database.BatchableContext objBatchableContext) {
    }
	
	 // ************************************************************************************************
    // Deferrable implementation
	//DCP-50962
    // ************************************************************************************************

     /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs()
    {
        return JSON.serialize('No input for this class');
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) { }  
    

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to get default val
    *  @Param       : None
    *  @Return      : Integer
    */
    public override Integer getDefaultBatchSize()
    {
      return 200;
    }

}