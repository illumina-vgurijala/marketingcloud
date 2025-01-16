/*@ author       : Rohit Sahu
* @ date         : 05-11-2024
* @ Description  : Batch class to update keyMethod record
* 100% Code Coverage: TestBatchToUpdateKeyMethod
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rohit Sahu             05-11-2024             Initial version
*
*/
global class BatchToUpdateKeyMethod implements Database.Batchable<sObject>
{    
    private static final String LOG_TITLE = 'BatchToUpdateKeyMethod';
    private List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    private List<String> errors = new List<String>();
    /**
* @author:Rohit Sahu
* @date: 05-11-2024
* @description: Required start method for batch
* @param: bc - batch context
* @return: query
*/
    /*Query for updating fields through batch*/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator([SELECT id,Key_Methods__c FROM Account_Plan__c where Key_Methods__c includes ('Cancer Research','Chromatin Accessibility','Circulating RNA Profiling','Circulating Tumor DNA Profiling','Comprehensive Genomic Profiling','Epigenetics','Human Whole-Genome Sequencing','Methylation Sequencing','Multiomics','Population-Scale Studies','Proteomics','Single-Cell Gene Expression','Spatial Transcriptomics','Transcriptomics','Tumor-Normal Sequencing','Whole-Exome Sequencing','Targeted Resequencing with Enrichment','Amplicon Sequencing','Microbial Whole Genome sequencing','Shotgun Metagenomics','Liquid biopsy','Immune profiling','NIPT','Preimplantation Genetic Screening/Testing')]);
    }
    /**
* @author: Rohit Sahu
* @date: 05-11-2024
* @description: Required execute method for batch
* @param: bc - batch context
* @return: void
*/    
    /*Execute method of Batch Class*/    
    global void execute(Database.BatchableContext bc, list<Account_Plan__c> scope ) 
    {   
        list<Key_Method__c> kmList = new list<Key_Method__c>();
        for(Account_Plan__c accp:scope)
        {   
            list<string> keyMethodList=accp.Key_Methods__c.split(';');
            
            for(string keyMethodValue:keyMethodList)
            { 
                Key_Method__c keyM =new Key_Method__c();
                keyM.Account_Plan__c=accp.ID;
                keyM.Key_Method__c =keyMethodValue;
                kmList.add(keyM);
            }
        
        }
        //Insert key method records
        if(!kmList.isEmpty())
        {   
            saveResults.clear();
            saveResults.addAll(Database.insert(kmList, false));
            handleSaveResults(saveResults, 'KEYMETHOD Object', errors);
        }
    }
    // Method to handle save results and errors
    private void handleSaveResults(List<Database.SaveResult> saveResults, String objectType, List<String> errors)
    {
        for (Database.SaveResult saveResult : saveResults)
        {
            if (!saveResult.isSuccess())
            {
                for (Database.Error e : saveResult.getErrors())
                {
                    errors.add(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    System.debug(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    System.debug(objectType + ' fields that affected this error: ' + e.getFields());
                    System.debug(objectType + ' record that affected this id: ' + saveResult.getId());
                }
            }
        }
    }
    /**
* @author: Rohit sahu
* @date: 05-11-2024
* @description: Required final method for batch
* @param: bc - batch context
* @return: void
*/
    global void finish(Database.BatchableContext bc)
    {
        ilib_LogEvent.push(LOG_TITLE + '.finish()');
        system.debug('Batch Job Completed.');
        ilib_LogEvent.info('No work for finish method.');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
    }
    
}