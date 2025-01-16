/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: Service Class to be used by Client to trigger the pipeline
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27           Initial Version
*         Kushal Shah                 2021-09-28           DCP-49429: Added logic for MFN Aprovals
*         Bharath Varma               2021-12-07           DCP-50961: Added logic for AgreementLine Approvals
*         Avina                       2022-06-29           CMSI-91 Added Instrumentation
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsService implements IApprovalsAPI {

    private static final String LOG_TITLE = 'ApprovalsService';//CMSI-91
    private List<Apttus_Proposal__Proposal_Line_Item__c> quoteLines;
    private List<Apttus__AgreementLineItem__c> agreementLines;
    private final Approvals.SupportData supportData;

    private static final String YES = 'Yes';

    /*
    *   @description:
    *   Quote Line constructor
    *   instantiated through init() only
    */
    private ApprovalsService(Approvals.QuoteLineInputs inputs)
    {
        this.quoteLines = inputs.quoteLines;
        this.supportData = new ApprovalsSupportDataQuoteLine().prepareSupportData(inputs);
    }

    /*
    *   @description:
    *   DCP-50961: Agreement Line constructor
    *   instantiated through init() only
    */
    private ApprovalsService(Approvals.AgreementLineInputs inputs)
    {
        this.agreementLines = inputs.agreementLines;
        this.supportData = new ApprovalsSupportDataAgreementLine().prepareSupportData(inputs);
    }

    // Quote Lines init, will discover later how to manage other objects
    /*
    *   @description: 
    *   this method is called by the client and constructor is private here
    *   returns instance of this class and creates a new one if not already present
    */
    public static IApprovalsAPI init(Approvals.QuoteLineInputs inputs)
    {
        return new ApprovalsService(inputs);
    }

    /*
    *   @description: 
    *   DCP-50961: this method is called by the client and constructor is private here
    *   returns instance of this class and creates a new one if not already present
    */
    public static IApprovalsAPI init(Approvals.AgreementLineInputs inputs)
    {
          return new ApprovalsService(inputs);
    }

    /*
    *   @description: this public method is called by the client 
    *   In this case it is Proposal Line Item Trigger
    *   Performs tasks like running the entire Approval Pipeline and Stamping output values on fields
    */
    public Approvals.QuoteHeaderUpdates processQuoteLines()
    {
        ilib_LogEvent.push(LOG_TITLE + '.processQuoteLines()');//CMSI-91
        // init output structure
        Approvals.QuoteHeaderUpdates headerUpdates = new Approvals.QuoteHeaderUpdates();

        // support class that takes pipeline results and can appropriately update the lines and headers
        IApprovalsOutputProcessor outputProcessor = new ApprovalsOutputQuoteLine(supportData.idToAccountOwner);
        ilib_LogEvent.info('outputProcessor-->: '+outputProcessor);//CMSI-91

        for (Apttus_Proposal__Proposal_Line_Item__c quoteLine : quoteLines)
        {
            // process quote lines
            Approvals.Outputs outputs = executePipeline(getQuoteLineSteps(), quoteLine);
            ilib_LogEvent.message('executePipeline outputs :::: ' + JSON.serialize(outputs));

            // use outputs to update quote lines
            outputProcessor.stampValues(quoteLine, outputs);
            // prepare updates the client will apply to headers
            outputProcessor.addHeaderOutputValues(quoteLine, outputs, headerUpdates);
        }
        ilib_LogEvent.pop();

        return headerUpdates;
    }

    /*
    *   @description: 
    *   executes all Pipeline Approval Steps 
    *   returns single Output wrapper containing results of all steps
    */
    private Approvals.Outputs executePipeline(List<IApprovalsStep> steps, Object record)
    {
        Approvals.Outputs result = new Approvals.Outputs();

        for (IApprovalsStep step : steps)
        {
            result = step.execute(record, result);
        }

        ilib_LogEvent.message('executePipeline result :::: '+JSON.serialize(result));
        return result;
    }

    /*
    *   @description: 
    *   Creates instances of all Approval Steps which are expected to run in Pipeline
    *   Any new class which will calculate Approvals must be added here  
    */
    public List<IApprovalsStep> getQuoteLineSteps()
    {
        return new List<IApprovalsStep>
        {
            new ApprovalsQuoteLinePromotions(Approvals.StepName.PROMOTION_1, supportData),
            new ApprovalsQuoteLinePromotions(Approvals.StepName.PROMOTION_2, supportData),
            new ApprovalsQuoteLinePromotions(Approvals.StepName.PROMOTION_3, supportData),
            new ApprovalsQuoteLinePromotions(Approvals.StepName.PROMOTION_4, supportData),
            new ApprovalsQuoteLinePromotions(Approvals.StepName.PROMOTION_5, supportData),
            new ApprovalsQuoteLineMaterialNumber(supportData),
            new ApprovalsQuoteLineMaterialGroup(supportData),
            new ApprovalsQuoteLineDiscount(supportData),
            new ApprovalsQuoteLineMaterialNumberCustom(supportData),
            new ApprovalsQuoteLineMaterialGroupCustom(supportData),
            new ApprovalsQuoteLineDiscountCustom(supportData),
            new ApprovalsQuoteLineMFN(supportData) //DCP-49429
        };
    }

    /*
    *   @description: 
    *   DCP-50961: Creates instances of all Approval Steps which are expected to run in Pipeline
    *   Any new class which will calculate Approvals must be added here  
    */
    public List<IApprovalsStep> getAgreementLineSteps()
    {
        return new List<IApprovalsStep>
        {
            new ApprovalsAgreementLineMaterialNumber(supportData),
            new ApprovalsAgreementLineMaterialGroup(supportData),
            new ApprovalsAgreementLineDiscount(supportData),
            new ApprovalsAgreementLineMatNumCustom(supportData),
            new ApprovalsAgreementLineMatGrpCustom(supportData),
            new ApprovalsAgreementLineDiscCustom(supportData),
            new ApprovalsAgreementLineMFN(supportData)
        };
    }

    /*
    *   @description: this public method is called by the client 
    *   DCP-50961: In this case it is Agreement Line Item Trigger
    *   Performs tasks like running the entire Approval Pipeline and Stamping output values on fields
    */
    public Approvals.AgreementHeaderUpdates processAgreementLines()
    {
        ilib_LogEvent.push(LOG_TITLE + '.processAgreementLines()');//CMSI-91
        // init output structure
        Approvals.AgreementHeaderUpdates headerUpdates = new Approvals.AgreementHeaderUpdates(supportData);
        ilib_LogEvent.info('headerUpdates-->: '+headerUpdates);//CMSI-91

        // support class that takes pipeline results and can appropriately update the lines and headers
        IApprovalsOutputProcessor outputProcessor = new ApprovalsOutputAgreementLine(supportData.idToAgreement);
        ilib_LogEvent.info('outputProcessor-->: '+outputProcessor);//CMSI-91

        // agreements have a step where prices are calculated from the discount
        // since it stamps values (and errors) on the lines, it doesn't fit in the pipeline
        ApprovalsAgreementLinePriceCalculator priceCalculator = new ApprovalsAgreementLinePriceCalculator(supportData);

        for (Apttus__AgreementLineItem__c agreementLine : agreementLines)
        {
            if (agreementLine.Discontinued__c == YES) { continue; }

            priceCalculator.calculate(agreementLine);

            Approvals.Outputs outputs = executePipeline(getAgreementLineSteps(), agreementLine);
            ilib_LogEvent.message('executePipeline outputs :::: ' + JSON.serialize(outputs));

            // use outputs to update quote lines
            outputProcessor.stampValues(agreementLine, outputs);
            // prepare updates the client will apply to headers
            outputProcessor.addHeaderOutputValues(agreementLine, outputs, headerUpdates);
        }

        headerUpdates.updatesForExistingLines();

        ilib_LogEvent.info('headerUpdates.agreementsToRevert ' + headerUpdates.agreementsToRevert);
        ilib_LogEvent.info('headerUpdates.agreementsWithHierarchyError ' + headerUpdates.agreementsWithHierarchyError);
        ilib_LogEvent.info('headerUpdates.agreementsWithMatrixError ' + headerUpdates.agreementsWithMatrixError);
        ilib_LogEvent.info('headerUpdates.agreementsToUpdate ' + headerUpdates.agreementsToUpdate);
        
        ilib_LogEvent.pop();

        return headerUpdates;
    }

}