/**
*    @author: prashanth 
*    @date:   20-Jan-2021
*    @description:  Batch Class to create PM plans for active service contracts
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*             Prashanth                   20-Jan-2021           Initial Development      
*/
global With Sharing class BatchCreatePMPlans extends ilib_ScheduleAndBatch implements Database.AllowsCallouts{
    global static final string STATUS_ACTIVE = 'Active';
    global static final Map<String, String> MAPSTRINGTOSTRINGBATCHSIZE = UtilsSettings.getCustomMetadataMap('PM_Plan_Batch');
    /**
    * Description: method to schedule this batch class with batch size as 10.
    */
    public override void execute(SchedulableContext sc)
    {
        BatchCreatePMPlans b = new BatchCreatePMPlans();
        Database.executebatch(b, 10);
    }
    /**
    * method: start
    * Params: Database.BatchableContext
    * Description: queries for active service contracts which has PM offerings and valid covered products for the last 10 days.
    * return: Database.QueryLocator
    */
    global override Database.QueryLocator start(Database.BatchableContext objBatchableContext){
        //choose the 2020-11-1 by default if there is no metadata record.
        Date dtStartDate = Date.newInstance(2020, 11, 1);
        //get parameter values from custom metadata if present
        if (!MAPSTRINGTOSTRINGBATCHSIZE.isEmpty()){
            try{
                dtStartDate = Date.valueOf(MAPSTRINGTOSTRINGBATCHSIZE.get('StartDateRange'));// load batch from custom metadata
            }catch (Exception e){
                System.debug('Inside BatchCreatePMPlans the exception is '+e.getMessage());
                ApexExceptions.emit('BatchCreatePMPlans',e);
            }
        }
        //DCP-43163
        String stringFinalQuery = 'SELECT Id,SVMXC__Start_Date__c, SVMXC__End_Date__c, Status__c from SVMXC__Service_Contract__c where Status__c =:STATUS_ACTIVE and SVMXC__Start_Date__c >=:dtStartDate and Id In (Select SVMXC__Service_Contract__c from SVMXC__PM_Offering__c) AND Id NOT in (Select SVMXC__Service_Contract__c from SVMXC__PM_Plan__c where SVMXC__Status__c =: STATUS_ACTIVE)';
        System.debug('stringFinalQuery--:'+stringFinalQuery);
        return Database.getQueryLocator(stringFinalQuery);
    }
    /**
    * method: execute
    * Params: Database.BatchableContext , List<sObject> lstRecords
    * Description: calls a method from service utiltiy collection for creating PM plans
    * return: void
    */
    global override void execute(Database.BatchableContext objBatchableContext, List<sObject> lstRecords){
        //set of service contract Ids for which PM plans needs to be created.
        Set<Id> setContractIds = new Set<Id>();
        for(SVMXC__Service_Contract__c objServiceContract: (List<SVMXC__Service_Contract__c>)lstRecords){
            setContractIds.add(objServiceContract.Id);
        }
        System.debug('setContractIds--:'+setContractIds);
        //call the method from service utility collection class which creates PM plans
        if(!setContractIds.isEmpty()){
            ServiceUtilityCollection.createPMPlansFromPMOfferings(setContractIds);
        }    
    }
    /**
    * Method: finish
    * Params: Database.BatchableContext
    * Description: This is a mandatory method for batchable interface
    * return: void
    */
    global override void finish(Database.BatchableContext objBatchableContext){
        /*This is mandatory method for batchable interface*/
        System.debug('objBatchableContext--:'+objBatchableContext);
    }
}