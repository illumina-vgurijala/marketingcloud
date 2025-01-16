/**
 *    @author         : Illumina
 *    @date           :
 *    @description    : Wrapper class for ilib_QueueableJob
 *    Test class for 90% coverage:
 *    Test class for 75% coverage:
 *	  Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public class ilib_QueueableJobWrapper {

    //hold reference to Queueable object that need to be executed
    public Queueable queueableJob;

    //data used to  information on Loggging purposes 
    public String methodName;
    public String className;

    //used to store the recordId(value of LogItem record) after the Job is logged to DB and is chained for execution and is later used to update Job status in log Items object.
    public String queueableLogItemId;

    /**
     *  @author      : Illumina
     *  @description : Constructor for ilib_QueueableJobWrapper
     *  @param       : Queueable, String, String
     *  @return      : NA
    */
    public ilib_QueueableJobWrapper(Queueable queueableJob, String className, String methodName)
    {
        this.queueableJob = queueableJob;
        this.methodName = methodName;
        this.className = className;
    }

}