/**
*    @author Govind Dubey
*    @date   9th May 2019
*    @description   batch job for Category and Product Association 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                   9th May 2019		 INC0206147 - scheduled product batch job
*             Aman Tyagi                     31st Mar 2022       CodeScan Fixes         
*    ------------------------------------------------------------------------------------
**/
global class SchedulerHierarchyViewUpdateJob extends ilib_ScheduleAndBatch{

    /*
    * @Author: Govind Dubey
    * @Description : execute method
    * @param : SchedulableContext ctx
    * @return : void
    */
    global override void execute(SchedulableContext ctx){
        Integer defaultBatchSize = 1;
        // Check all products and if there is new Product or change in Products then only run the batch
        List<Product2> lstProducts = new ProductsSelector().selectProductsForBatch();
        List<Product2> lstUpdateProducts = new List<Product2>();
        if(!lstProducts.isEmpty()){
            for(Apttus_Config2__ClassificationName__c category : [select Id from Apttus_Config2__ClassificationName__c WHERE Apttus_Config2__Active__c = true]){
            	Database.executeBatch(new Apttus_Config2.HierarchyViewUpdateJob(category.Id), defaultBatchSize);
            }
            for(Product2 objProduct : lstProducts){
                objProduct.Process_For_Batch__c = false;
                lstUpdateProducts.add(objProduct);
            }
            update lstUpdateProducts;
        }
    }
}