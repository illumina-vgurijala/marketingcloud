/**
*    @author: Pankaj 
*    @date:   13-Dec-2018
*    @description:  Scheduler class for BatchContactCountryRegionMapping 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        13-Dec-2018        Initial Development
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class SchedulerBatchContactCountryRegion  implements Schedulable{
    /*
    *  Description: Execute method of the batch job
    */
    public void execute(SchedulableContext ctx){
        BatchContactCountryRegionMapping objBatch=new BatchContactCountryRegionMapping();
        String sch='0 0 * * * ?';
        System.schedule('BatchContactCountryRegionMapping'+system.now(), sch , objBatch);
    }
}