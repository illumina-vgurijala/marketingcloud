/**
*    @author Satya Swain
*    @date   2020-01-28
*    @description  Class to create Dummy Quotes when SAP and SFDC have uneven quote numbers
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Satya Swain                     2020-01-29         Initial Version as part of PRB0043346
*            Jitesh Lakhwani                 6-July-2022        Code Scan fixes of Comments
*            Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
*/
public class InsertQuotationViaBatch implements Database.Batchable<Integer>, Database.Stateful {

    /*
        Batch Size should be 10
        Disable ApttusProposalTrigger before calling the Batch
    */

    private static final String CODE_TITLE = 'Insert Dummy Quotes';

    Id opportunityId;
    Integer intFactor;
    Integer intRecordsCreated;
    Id lastQuoteId;

    /**
    * @description: InsertQuotationViaBatch class Constructor
    * @param : None
    * @return: None
    */
    public InsertQuotationViaBatch()
    {
        intRecordsCreated = 0;

        Opportunity objOpportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE StageName NOT IN :Opportunities.CLOSED_STATUSES ORDER BY CreatedDate DESC LIMIT 1];
        opportunityId = objOpportunity.Id;
        System.debug('@@@@ Opportunity Stage Name: ' + objOpportunity.StageName);

        // retrive the number of quotes to create
        // it would probably be better to retrieve the highest quote number desired (e.g. Q-0012345)
        // but that would require more parsing and work so we'll trust the people who execute this to do proper math
        Code_Parameter__mdt objCodeParameter = [
            SELECT Id, DeveloperName, Value__c
            FROM Code_Parameter__mdt
            WHERE DeveloperName = 'Quotation_Insertion_Factor'];

        try
        {
            intFactor = Integer.valueOf(objCodeParameter.Value__c);
        }
        catch (Exception e)
        {
            intFactor = -1;
            ApexExceptions.emit(CODE_TITLE, null, e);
        }

        // don't ever create dummy quotes in production
        if (Organizations.isProduction())
            intFactor = -1;
    }

    /**
    * @description: Batch class start method
    * @param : Database.batchableContext info
    * @return: Iterable<Integer>
    */
    public Iterable<Integer> start(Database.batchableContext info)
    {
       return Test.isRunningTest()? new IntegerIterator(10):new IntegerIterator(intFactor);
    }

    /**
    * @description: Batch class execute method to create Quotes for opportunities
    * @param : Database.batchableContext info
    * @return: Iterable<Integer>
    */
    public void execute(Database.batchableContext info, List<Integer> scope)
    {
        System.debug('@@@@ scope size: ' + scope.size());
        List<Apttus_Proposal__Proposal__c> lstQuotesToInsert = new List<Apttus_Proposal__Proposal__c>();

        for (Integer i = 0; i < scope.size(); i++)
        {
            lstQuotesToInsert.add(new Apttus_Proposal__Proposal__c(
                Apttus_Proposal__Opportunity__c = opportunityId
            ));
        }

        if (!lstQuotesToInsert.isEmpty())
        {
            insert lstQuotesToInsert;

            // set stateful variables for output report
            try
            {
                intRecordsCreated = intRecordsCreated + lstQuotesToInsert.size();
                lastQuoteId = lstQuotesToInsert.get(lstQuotesToInsert.size() - 1).Id;
            }
            catch (Exception e) {
                // added for Sonarqube
                System.debug('Error occured in InsertQuoteViaBatch class, details: '+e);
            } // not critical functionality
        }
    }

    /**
    * @description: Batch class finish method
    * @param : Database.batchableContext info
    * @return: Iterable<Integer>
    */
   public void finish(Database.batchableContext info)
   {
    ilib_LogEvent.setTitle(CODE_TITLE);
    ilib_LogEvent.push('finish');
    ilib_LogEvent.info('Quote created count' + String.valueOf(intRecordsCreated) +'----');
    ilib_LogEvent.info('Last created id' + lastQuoteId +'----');
    ilib_LogEvent.pop();
       /* ilib_LogEvent.quickEmit(CODE_TITLE, new Map<String, String> {
           'Quote created count' => String.valueOf(intRecordsCreated),
            'Last created id' => lastQuoteId
        });*/
    ilib_LogEvent.emit();
  }

}