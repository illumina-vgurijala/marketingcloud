/**
*    @author: Gopi 
*    @date:   01-Aug-2023
*    @description:  Scheduler class for BatchToUpdateCompliance 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Gopi                        01-Aug-2023        Initial Development
*    ------------------------------------------------------------------------------------ 
*                    
*/

public class ScheduleBatchToUpdateCompliance  implements Schedulable{
    /*
    *  Description: Execute method of the batch job
    */
    public void execute(SchedulableContext ctx){
        BatchToUpdateCompliance schedulebatch= new BatchToUpdateCompliance();
		Database.executeBatch(schedulebatch,1);
    }
}