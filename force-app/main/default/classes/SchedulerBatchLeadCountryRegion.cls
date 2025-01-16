/**
*    @author: Pankaj 
*    @date:   13-Dec-2018
*    @description:  Scheduler class for BatchLeadCountryRegionMapping 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        13-Dec-2018        Initial Development
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class SchedulerBatchLeadCountryRegion  implements Schedulable{
    /*
    *  Description: Execute method of the batch job
    */
    public void execute(SchedulableContext ctx){
        BatchLeadCountryRegionMapping objBatch=new BatchLeadCountryRegionMapping();
        String sch='0 0 * * * ?';
        System.schedule('BatchLeadCountryRegionMapping'+system.now(), sch , objBatch);
    }
}