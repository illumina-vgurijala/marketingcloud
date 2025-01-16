/**
*  @date   2023-10-16
*  @description    helper class for annual pricing schedule
*  @Test Class for above 90% coverage.
*  @Test Class for atleast 75% coverage.
   -
*  Modification Log:
*  ------------------------------------------------------------------------------------
*      Developer            Date          Description
*      Rajbabu Boopalan     2018-07-09    initial version
*      Gerardo Garcia       2024-04-23    Fix test to avoid dependency on metadata by doing mock data.
*  ------------------------------------------------------------------------------------
*/
public with sharing class AnnualPricingScheduleHelper {
    private static final String LOG_TITLE = 'AnnualPricingScheduleHelper';
    public static Boolean mockEnable = false;
    public static Datetime testDateTime;
    public static List<AnnualPricingScheduleWrapper> testAnnualPricingSchedules;
    
    /**
     *  @author Rajbabu Boopalan
     *  @description  Method to return annual price change dates for quotes
     *  @parameter Opp and Quote/Proposal
     *  @return  map of quote id to annual price change date
     **/
    public Map<Id,Datetime> getAnnualPriceChangeDatebyProposal(
        List<Apttus_Proposal__Proposal__c> lstProposals, Map<Id, Opportunity> idToOpportunity){
        ilib_LogEvent.push(LOG_TITLE+'.getAnnualPriceChangeDatebyProposal()');
        ilib_LogEvent.info('idToOpportunity : '+idToOpportunity);
        ilib_LogEvent.info('lstProposals : '+lstProposals);

        Map<Id,Datetime> proposalIdToAPCDate = new Map<Id,Datetime>();

        Map<String,set<Datetime>> priceListTypeToSetOfAPCD = getFilteredAnnualPriceChangeDate(lstProposals, idToOpportunity);
        ilib_LogEvent.message('priceListTypeToSetOfAPCD: '+priceListTypeToSetOfAPCD);

        for(Apttus_Proposal__Proposal__c proposal:lstProposals) {
            //--- For each proposal identify the valid APCD
            String priceListType = (String.isNotBlank(proposal.Apttus_Proposal__Opportunity__r.Price_List_Type__c)) ? proposal.Apttus_Proposal__Opportunity__r.Price_List_Type__c:'';
            boolean isOpportunityMapHasPriceListType = idToOpportunity != null && idToOpportunity.containsKey(proposal.Apttus_Proposal__Opportunity__c) 
                && idToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Price_List_Type__c != null ? TRUE:FALSE;
            priceListType = String.isBlank(priceListType) && isOpportunityMapHasPriceListType ? idToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Price_List_Type__c:priceListType;
            
            if(String.isNotBlank(priceListType) && priceListTypeToSetOfAPCD.containsKey(priceListType)) {
                Datetime validAPCD = null;
                for(Datetime curAPCD:priceListTypeToSetOfAPCD.get(priceListType)) {
                    ilib_LogEvent.info('curAPCD :'+curAPCD);
                    if(curAPCD < getTime()) {
                        continue;
                    }else if(validAPCD != null && curAPCD < validAPCD 
                        && curAPCD > proposal.Apttus_QPConfig__PricingDate__c) {
                        validAPCD = curAPCD;
                    }else if(validAPCD == null && curAPCD > proposal.Apttus_QPConfig__PricingDate__c) {
                        validAPCD = curAPCD;
                    }
                }
                ilib_LogEvent.info('validAPCD :'+validAPCD);
                proposalIdToAPCDate.put(proposal.id,validAPCD);
            }
        }

        ilib_LogEvent.info('proposalIdToAPCDate : '+proposalIdToAPCDate);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return proposalIdToAPCDate;
    }

    private Map<String,set<Datetime>> getFilteredAnnualPriceChangeDate(List<Apttus_Proposal__Proposal__c> lstProposals, Map<Id, Opportunity> idToOpportunity){
        ilib_LogEvent.push(LOG_TITLE+'.getFilteredAnnualPriceChangeDate()');
        Set<String> setPriceTypes = new Set<String>();
        Map<String,set<Datetime>> priceListTypeToSetOfAPCD= new Map<String,set<Datetime>>();

        if(!lstProposals.isEmpty()) {
            //--- Create a set of price list types of all quotes
            for(Apttus_Proposal__Proposal__c proposal:lstProposals) {
                boolean isOpportunityMapHasPriceListType = idToOpportunity != null && idToOpportunity.containsKey(proposal.Apttus_Proposal__Opportunity__c) 
                    && idToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Price_List_Type__c != null ? TRUE:FALSE;
                ilib_LogEvent.message('isOpportunityMapHasPriceListType : '+isOpportunityMapHasPriceListType);
                if(String.isNotBlank(proposal.Apttus_Proposal__Opportunity__r.Price_List_Type__c)) {
                    setPriceTypes.add(proposal.Apttus_Proposal__Opportunity__r.Price_List_Type__c);
                }else if(isOpportunityMapHasPriceListType) {
                    setPriceTypes.add(idToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Price_List_Type__c);
                }
            }
        }

        ilib_LogEvent.message('setPriceTypes : '+setPriceTypes);

        if(!setPriceTypes.isEmpty()) {
            List<AnnualPricingScheduleWrapper> lstAPSchedules = getAnnualPricingSchedules();
            ilib_LogEvent.message('lstAPSchedules : '+ JSON.serializePretty(lstAPSchedules));
            //--- Filter null and past dates, then group Annual Price Change Dates by Price List Type
            for(AnnualPricingScheduleWrapper apcd:lstAPSchedules) {
                ilib_LogEvent.message('apcd.priceChangeDate : '+apcd.priceChangeDate);
                ilib_LogEvent.message('apcd.priceListType : '+apcd.priceListType);
                ilib_LogEvent.message('Date Time Now  '+ getTime());
                if(apcd.priceChangeDate == null || apcd.priceChangeDate < getTime()) { //expired
                    continue;
                }else if(priceListTypeToSetOfAPCD.containsKey(apcd.priceListType)) {
                    priceListTypeToSetOfAPCD.get(apcd.priceListType).add(apcd.priceChangeDate);
                }else {
                    Set<Datetime> setAPCD = new Set<Datetime>();
                    setAPCD.add(apcd.priceChangeDate);
                    priceListTypeToSetOfAPCD.put(apcd.priceListType, setAPCD);
                }
            }
            //--- End of filtering
        }
        ilib_LogEvent.message('priceListTypeToSetOfAPCD : '+ priceListTypeToSetOfAPCD);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return priceListTypeToSetOfAPCD;
    }

    private static Datetime getTime() {
        return Test.isRunningTest() && mockEnable ? testDateTime : Datetime.now();
    }

    private static List<AnnualPricingScheduleWrapper> getAnnualPricingSchedules() {
        if(Test.isRunningTest() && mockEnable) {
            return testAnnualPricingSchedules;
        } else {
            List<AnnualPricingSchedule__mdt> pricings = AnnualPricingSchedule__mdt.getAll().values();
            List<AnnualPricingScheduleWrapper> wrapper = new List<AnnualPricingScheduleWrapper>();
            for(AnnualPricingSchedule__mdt pricing : pricings) {
                wrapper.add(new AnnualPricingScheduleWrapper(pricing));
            }
            return wrapper;
        }
    }

    /**
     * Class that is used for filling data from AnnualPricingSchedule__mdt or being used as mockdata during testing.
     */
    public class AnnualPricingScheduleWrapper {
        public DateTime priceChangeDate;
        public String priceListType;
        public String label;
        public String qualifiedAPIName;

       /** Common constructor */
        public AnnualPricingScheduleWrapper() { }

        /** Constructor by using metadata */
        public AnnualPricingScheduleWrapper(AnnualPricingSchedule__mdt metadata) {
            this.priceChangeDate = metadata.PriceChangeDate__c;
            this.priceListType = metadata.PriceListType__c;
            this.label = metadata.MasterLabel;
            this.qualifiedAPIName = metadata.QualifiedApiName;
        }
    }

}