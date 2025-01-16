/**
*    @author Vinay S Reddy
*    @date   2025-08-27
*    @description   CMCM-8277 : Scheduled Batch To Close Territory Plan
*    Test classes for 75%: TestScheduleBatchTerritoryPlanClosure
*    Test Classes for 90%: TestScheduleBatchTerritoryPlanClosure
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Vinay S Reddy                2024-08-27            Initial Version
*    -----------------------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class ScheduleBatchTerritoryPlanClosure extends ilib_ScheduleAndBatch implements Schedulable,Database.Stateful{
    
    public static final String NULLSTR = 'Null';
    public List <Database.SaveResult> saveResults = new List <Database.SaveResult>();
    AsyncApexJob job;
    public static final string LOG_TITLE = 'ScheduleBatchTerritoryPlanClosure';
    public static final string CLOSED='Closed';
    List<Plan_Strategy__c> strategies = new List<Plan_Strategy__c>();
    List<Plan_Objective__c> objectives = new List<Plan_Objective__c>();
    Set<Id> planIdWithStrategy = new set<Id>();
    /**
* @author Vinay
* @description execute method of Scheduler
**/
    public override void execute(SchedulableContext sc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE+'.execute()');
        
        ilib_LogEvent.info('Schedule Job');
        Database.executeBatch(new ScheduleBatchTerritoryPlanClosure());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    
    /**
* @author Vinay
* @description start method of Batch
**/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE+'.start()');
        
        // Fetching Plans whose End_Date__c is within the last 30 days
        String query = 'SELECT Id, Status__c FROM Plan__c WHERE End_Date__c < LAST_N_DAYS:30';
        
        ilib_LogEvent.info('strQuery: '+query);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
        return Database.getQueryLocator(query);
    }
    
    /**
* @author Vinay
* @description execute method of Batch
**/
    public  void execute(Database.BatchableContext bc,  List<Plan__c> planList)
    {
        try {
            if (planList == null || planList.isEmpty()) {
                return;
            }
            
            Set<Id> planIds = collectPlanIds(planList);
            Map<Id, List<Plan_Strategy__c>> planToStrategiesMap = fetchStrategiesByPlanIds(planIds);
            Map<Id, List<Plan_Objective__c>> strategyToObjectivesMap = fetchObjectivesByStrategyIds(planToStrategiesMap);
            List<Plan__c> plansToUpdate = checkAndUpdatePlans(planList, planToStrategiesMap, strategyToObjectivesMap);
            
            if (!plansToUpdate.isEmpty()) {
                updatePlans(plansToUpdate,bc);
            }
        } catch (Exception e) {
            // Handle exception by logging or any other mechanism as needed
            System.debug('Error in execute method: ' + e.getMessage());
        }
    } 

    /**
* @author Vinay
* @description execute method of Batch
**/   
    
    public  Set<Id> collectPlanIds(List<Plan__c> planList) {
        Set<Id> planIds = new Set<Id>();
        for (Plan__c plan : planList) {
            if (plan != null) {
                planIds.add(plan.Id);
            }
        }
        return planIds;
    }
    
    /**
* @author Vinay
* @description Method to perform DML update on Plan__c records
**/  
    
    public void updatePlans(List<Plan__c> plansToUpdate,Database.BatchableContext bc) {
        try {
            if (plansToUpdate != null && !plansToUpdate.isEmpty()) {
                
                saveResults.addAll(Database.update(plansToUpdate, false));
                handleSaveResults(saveResults, 'Updating Plan Status');
                ApexExceptions.emitSaveErrors(saveResults, LOG_TITLE );
                job = [SELECT Id,ApexClass.Name, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
                 ilib_LogEvent.info('Name of Batch Apex ==>'+job.ApexClass.Name);
	             ilib_LogEvent.info('Job Details: '+job);
            }
        } 
        catch (DmlException e) {
            // Log any exceptions that occurred during the update operation
            System.debug('Error in updatePlans: ' + e.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    
    /**
* @author Vinay
* @description Method to fetch Plan_Strategy__c records by Plan__c IDs
**/  
    
    public Map<Id, List<Plan_Strategy__c>> fetchStrategiesByPlanIds(Set<Id> planIds) {
        Map<Id, List<Plan_Strategy__c>> planToStrategiesMap = new Map<Id, List<Plan_Strategy__c>>();
        try {
            if (planIds == null || planIds.isEmpty()) {
                return planToStrategiesMap;
            }
            
            strategies = new PlanStrategySelector().selectPlanStrategies(planIds);
            for (Plan_Strategy__c strategy : strategies) {
                if (!planToStrategiesMap.containsKey(strategy.Plan__c)) {
                    planToStrategiesMap.put(strategy.Plan__c, new List<Plan_Strategy__c>());
                }
                planToStrategiesMap.get(strategy.Plan__c).add(strategy);
                planIdWithStrategy.add(strategy.Plan__c);
            }
        } catch (Exception e) {
            System.debug('Error in fetchStrategiesByPlanIds: ' + e.getMessage());
        }
        return planToStrategiesMap;
    }
    
    /**
* @author Vinay
* @description  Method to fetch Plan_Objective__c records by Plan_Strategy__c IDs
**/ 
    
    public Map<Id, List<Plan_Objective__c>> fetchObjectivesByStrategyIds(Map<Id, List<Plan_Strategy__c>> planToStrategiesMap) {
        Map<Id, List<Plan_Objective__c>> strategyToObjectivesMap = new Map<Id, List<Plan_Objective__c>>();
        try {
            if (planToStrategiesMap == null || planToStrategiesMap.isEmpty()) {
                return strategyToObjectivesMap;
            }
            
            Set<Id> strategyIds = new Set<Id>();
            for (List<Plan_Strategy__c> strategies : planToStrategiesMap.values()) {
                for (Plan_Strategy__c strategy : strategies) {
                    strategyIds.add(strategy.Id);
                }
            }
            
            
            objectives = new PlanObjectiveSelector().selectPlanObjectives(strategyIds);
            for (Plan_Objective__c objective : objectives) {
                if (!strategyToObjectivesMap.containsKey(objective.Plan_Strategy__c)) {
                    strategyToObjectivesMap.put(objective.Plan_Strategy__c, new List<Plan_Objective__c>());
                }
                strategyToObjectivesMap.get(objective.Plan_Strategy__c).add(objective);
            }
        } catch (Exception e) {
            System.debug('Error in fetchObjectivesByStrategyIds: ' + e.getMessage());
        }
        return strategyToObjectivesMap;
    }
    /**
* @author Vinay
* @description  Method to fetch Plan_Objective__c records by Plan_Strategy__c IDs
**/ 
    public List<Plan__c> checkAndUpdatePlans(List<Plan__c> planList, Map<Id, List<Plan_Strategy__c>> planToStrategiesMap, Map<Id, List<Plan_Objective__c>> strategyToObjectivesMap) {
        List<Plan__c> plansToUpdate = new List<Plan__c>();
        Map<Id, Boolean> planAllObjectivesClosedMap = new Map<Id, Boolean>();
        Map<Id, Id> strategyToPlanMap = new Map<Id, Id>(); // Map to track Plan__c by Strategy__c ID
        Map<Id, Boolean> planHasOpenObjectivesMap = new Map<Id, Boolean>(); // Track which Plans have open objectives
        try {
            if (planList == null || planList.isEmpty()) {
                return plansToUpdate;
            }
            
            //Initialize the map with all plans assuming all objectives are closed
       
            initializingMapwithAllPlans(planList,planAllObjectivesClosedMap,planHasOpenObjectivesMap,planToStrategiesMap);
                   
            // Prefetch all Plan_Strategy__c records and map them to their Plan__c
           
            for (Plan_Strategy__c strategy : strategies) {
                strategyToPlanMap.put(strategy.Id, strategy.Plan__c);
            }
            
            //Collect all Plan_Objective__c records in a single list
            collectAllPlans(strategyToObjectivesMap, strategyToPlanMap,planHasOpenObjectivesMap);

            
            
            // Finalize plans that need to be updated
            for (Plan__c plan : planList) {
                if (plan != null && (planAllObjectivesClosedMap.containsKey(plan.Id) && !planHasOpenObjectivesMap.get(plan.Id) || !planIdWithStrategy.contains(plan.Id))) {
                    plan.Status__c = CLOSED;
                    plansToUpdate.add(plan);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in checkAndUpdatePlans: ' + e.getMessage());
        }
        return plansToUpdate;
    }
        /**
        * @author Vinay
        * @initialing all plans
        **/  
        public void initializingMapwithAllPlans(List<Plan__c> planList,Map<Id, Boolean> planAllObjectivesClosedMap,Map<Id, Boolean> planHasOpenObjectivesMap, Map<Id, List<Plan_Strategy__c>> planToStrategiesMap){
            for (Plan__c plan : planList) {
                if (plan != null && planToStrategiesMap.containsKey(plan.Id)) {
                    planAllObjectivesClosedMap.put(plan.Id, true);
                    planHasOpenObjectivesMap.put(plan.Id, false); 
                }
            }
        }

        /**
        * @author Vinay
        * @initialing all plans
        **/ 
        public void collectAllPlans(Map<Id, List<Plan_Objective__c>> strategyToObjectivesMap, Map<Id,Id> strategyToPlanMap,Map<Id,Boolean> planHasOpenObjectivesMap){
            // Collect all Plan_Objective__c records in a single list   
            //Set<Id> strategyIds = strategyToObjectivesMap.keySet(); 
            
            // Process objectives to determine open status
            for (Plan_Objective__c objective : objectives) {
                if (objective.Objective_Status__c != CLOSED && objective.IsActive__c == true) {
                    Id planId = strategyToPlanMap.get(objective.Plan_Strategy__c);
                    if (planId != null) {
                        planHasOpenObjectivesMap.put(planId, true); 
                    }
                }
            }

        }
    
        /**
* @author Vinay
* @description method to handle save results
**/  
    public void handleSaveResults(List < Database.SaveResult > saveResults, String objectType) {
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        for (Database.SaveResult saveResult: saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error e: saveResult.getErrors()) {
                   // System.debug(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    ilib_LogEvent.info(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    //System.debug(objectType + ' fields that affected this error: ' + e.getFields());
                    ilib_LogEvent.info(objectType + ' fields that affected this error: ' + e.getFields());
                    //System.debug(objectType + ' record that affected this id: ' + saveResult.getId());
                    ilib_LogEvent.info(objectType + ' record that affected this id: ' + saveResult.getId());
                }
            }
            if (saveResult.isSuccess()) {
                System.debug('Success Status for plan records   ' + saveResult);
                ilib_LogEvent.info('Success Status for plan records  ' + saveResult);
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit(); 
    }
    
    /**
* @author Vinay
* @description finish method of Batch
**/
    public override void finish(Database.BatchableContext bc)
    {
    }
}