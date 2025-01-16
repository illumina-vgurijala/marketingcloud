/**
 *   @author: Deep Diwakar
*    @date:   Nov-27-2023
*    @description: Decorator class for calculating area of work for leads
*    @Test Class: TestAreaOfWorkLeadDecorator
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Nov-27-2023        CMCM-4510: Initial version
*         Deep Diwakar       Dec-18-2023        CMCM-4510: Adjust to implement ilib_SObjectDecorator
*    --------------------------------------------------------------------------------------------------
*/

 public with sharing class AreaOfWorkLeadDecorator extends ilib_SObjectDecorator {

    private static final String LOG_TITLE = 'AreaOfWorkLeadDecorator';

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: Constructor
     * @param: List of lead records
     */
    public AreaOfWorkLeadDecorator(List<SObject> lstSObjectRecords) {
        super(lstSObjectRecords);
    }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: Overriding method to calculate Area of Work in Insert scenario
     * @param: none
     * @return: void
     */
    public override void decorate() {
        ilib_LogEvent.push(LOG_TITLE + '.decorate');
        this.calculateAreaOfWork();
        ilib_LogEvent.pop();
    }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: Overriding method to calculate Area of Work in Update scenario
     * @param: none
     * @return: void
     */
    public override void decorate(Map<Id, sObject> mapOfOldRecords) {
        ilib_LogEvent.push(LOG_TITLE + '.decorate with map param');
        this.calculateAreaOfWork();
        ilib_LogEvent.pop();
    }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: This method creates mapping for Area of Interest to Area of Work
     * @param: none
     * @return: void
     */
    private void calculateAreaOfWork() {
        ilib_LogEvent.info('calculating are of work - ' + LOG_TITLE + '.calculateAreaOfWork');

        List<Lead> lstLead = (List<Lead>) lstRecords;
        Map<String, String> mapAoIToAoW = new Map<String, String>();

        // get AoI to AoW mapping
        mapAoIToAoW = LeadsHelper.getAoIToAowMapping();

        for (Lead lead : lstLead) {
            String areaOfInterest = lead.Area_Of_Interest__c;

            // if AoW has value or AoI is empty or AoI has multiple values then don't set AoW
            if (!String.isBlank(lead.Area_Of_Work__c) || String.isBlank(areaOfInterest)
                    || areaOfInterest.contains(';')) {
                continue;
            }

            ilib_LogEvent.message('areaOfInterest: ' + areaOfInterest);

            String areaOfWork = mapAoIToAoW.get(lead.Area_Of_Interest__c);

            ilib_LogEvent.message('areaOfWork: ' + areaOfWork);

            if (!String.isBlank(areaOfWork)) {
                lead.Area_Of_Work__c = areaOfWork;
            }

        }

    }

}