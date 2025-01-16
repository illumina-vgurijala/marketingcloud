global virtual with sharing class ilib_ScheduleAndBatch implements Schedulable, Database.Batchable<sObject> {

    /*
     * Base class for scheduled and/or batched classes
     *
     * Implement one or both sets of methods as needed
     * REQUIRED: add the construct() method below in your child class
     *
     * Add other interfaces as needed (e.g. Stateful)
     */

    // Interface used to aid in constructing instances
    public interface IConstructable
    {
        ilib_ScheduleAndBatch construct();
    }

    // TODO: be sure to include this in your child class
    // public class Constructor implements ilib_ScheduleAndBatch.IConstructable
    // {
    //     public ilib_ScheduleAndBatch construct()
    //     {
    //         return new MyClass();
    //     }
    // }

    // schedulable methods - if overridded no exception will be thrown
    global virtual void execute(SchedulableContext sc) { throw new UnsupportedOperationException(); }

    // batchable methods - if overridded no exception will be thrown
    global virtual Database.QueryLocator start(Database.BatchableContext bc) { throw new UnsupportedOperationException(); }
    global virtual void execute(Database.BatchableContext bc, List<sObject> scope) { throw new UnsupportedOperationException(); }
    global virtual void finish(Database.BatchableContext bc) { throw new UnsupportedOperationException(); }

}