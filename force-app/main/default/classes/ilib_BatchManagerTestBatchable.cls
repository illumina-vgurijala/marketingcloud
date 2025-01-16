/*
This is a class exclusively used by the test class ilib_BatchManagerTest

Dummy comments were added to pass codescan. There is no real functionality here to comment
*/
public with sharing class ilib_BatchManagerTestBatchable extends ilib_BatchDeferrable {

    /* Dummy comment */
    public class Inputs
    {
        public String val;

        /* Dummy comment */
        public Inputs(String val)
        {
            this.val = val;
        }
    }

    @TestVisible
    private Inputs inputs;

    /* no-arg constructor needed so class can be restored */
    public ilib_BatchManagerTestBatchable() { }

    /* Dummy comment */
    public ilib_BatchManagerTestBatchable(String val)
    {
        this.inputs = new Inputs(val);
    }


    /* Dummy comment */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /* Dummy comment */
    public override void restoreInputs(String serializedInputs)
    {
        this.inputs = (ilib_BatchManagerTestBatchable.Inputs)JSON.deserialize(serializedInputs, ilib_BatchManagerTestBatchable.Inputs.class);
    }

    /* Dummy comment */
    public override Integer getDefaultBatchSize()
    {
        return 1;
    }

    /* Dummy comment */
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(
            'SELECT Id ' +
            'FROM Product2 ' +
            'LIMIT 1'
        );
    }

    /* Dummy comment */
    public override void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Product_Localization__c> translations = new List<Product_Localization__c>();

        for (Product2 prod : (List<Product2>)scope)
        {
            translations.add(new Product_Localization__c(
                Product__c = prod.Id,
                Name = inputs.val,
                Product_Name_Local__c = inputs.val
            ));
        }

        insert translations;
    }

    /* Dummy comment */
    public override void finish(Database.BatchableContext bc) { }

}