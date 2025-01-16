/**
*   @author Milan Savaliya
*   @date 2018-10-30
*   @description    
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description
*           Milan                       2018-10-26
*           Joshith K                   2019-01-11       Opportunity sync qote with sharing enabled 
*           Rahul Sharma                2019-01-22       Adding logic to update cart owner
*           Govind Dubey                2019-05-22       Modified logic with Invocable method
*           Rahul Bishnoi               2019-12-05       DCP-30367 Adding start date, end date to quote line items.
*           Rahul Bishnoi               2020-01-27       DCP-31767 Adding ERP_Line_Number_Id to line items.
*           Joshith k                   2020-04-15       PRB0043537--Map fields in cart line item from Opp Line item,changed subscribtion to triggers.
*			Joshith k                   2020-09-11       removed PRB0043537 changes as part of apttus upgrade.
*           Rahul Bishnoi               2021-10-1        Modified applyLineItemValuesToCarts to avoid Invalid query locator due to subquery.
*           Koustubh Masurkar           2022-01-06       INC0369724 - Added check to fix bug of 'List index out of bounds'
*           Aman Tyagi                  2022-03-30       CodeScan Fixes
*           Adithi Acharya              2022-08-18       DCP-56258- Auto Population of Informatics details
*           @prem ranjan                2023-01-09       Code scan fix ((APEX) Comment is required)
*   ------------------------------------------------------------------------------------
**/

public with sharing class OpportunitySyncToQuotes extends ilib_SObjectDomain{

    private static String logTitle = 'TTN Opportunity-Cart Line Sync';
    /*
    * @Author:Milan Savaliya
    * @Description : parameterized Constructor of the class OpportunitySyncToQuotes
    * @param: List<OpportunitySyncToQuote__e> sObjectList
    * @return: NA
    */
    public OpportunitySyncToQuotes(List<OpportunitySyncToQuote__e> sObjectList) {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    /*
    * @Author:Milan Savaliya
    * @Description :Constructor class implementing methods of ilib_SObjectDomain interface
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
            /**
            * @Author:Milan Savaliya
            * @Description : Construct Method
            * @param: List<OpportunitySyncToQuote__e> sObjectList
            * @return: ilib_SObjectDomain
            */
        public ilib_SObjectDomain construct(List<OpportunitySyncToQuote__e> sObjectList) {
            return new OpportunitySyncToQuotes(sObjectList);
        }
    }
    /*
    * @Author:Milan Savaliya
    * @Description :overriding onAfterInsert() method
    * @param : none
    * @return: void
    */
    public override void onAfterInsert()
    {
        List<Id> listRecordIDs = new List<Id>();
        for(OpportunitySyncToQuote__e obj:(List<OpportunitySyncToQuote__e>)records){
            if(String.isNotBlank(obj.QuoteId__c))
                listRecordIDs.add(obj.QuoteId__c);
        }
        opportunitySyncToQuoteWithSharing(listRecordIDs);
    }

    /*
    * @Author:Milan Savaliya
    * @Description : Opportunity sync qote with sharing enabled
    * @param: List<Id> recordIds
    * @return: void
    */
    public static void opportunitySyncToQuoteWithSharing(List<Id> recordIds)
    {
        if (recordIds == null) return;

        ilib_LogEvent.rootTitle = logTitle;
        ilib_LogEvent.push('opportunitySyncToQuoteWithSharing');
        ilib_LogEvent.message('recordIds ' + recordIds);

        try
        {
            List<Apttus_Proposal__Proposal__c> listQuotes = new ApttusProposalsSelector().selectByQuoteId(new Set<Id>(recordIds));
            ilib_LogEvent.message('quote list size ' + listQuotes.size());

            // map OLI ID to a wrapper to some of its values
            Map<Id, List<UtilsCart.LineItemWrapper>> idToLineItemWrappers = mapIdToLineItemWrappers(listQuotes);
            if (idToLineItemWrappers.isEmpty())
            {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }

            Map<Id, Apttus_Proposal__Proposal__c> cartIdToQuote = new Map<Id, Apttus_Proposal__Proposal__c>();
            Map<Id, Apttus_Config2__ProductConfiguration__c> idToCart = new Map<Id, Apttus_Config2__ProductConfiguration__c>();

            // for each quote create a cart
            // aslo build two maps for later
            for (Apttus_Proposal__Proposal__c objQuote : listQuotes)
            {
                if (!idToLineItemWrappers.containsKey(objQuote.Apttus_Proposal__Opportunity__c))
                    continue;

                Id cartId = UtilsCart.createCartForQuote(objQuote.Id);
                ilib_LogEvent.message('new cart ' + cartId);

                UtilsCart.addMultiProducts(cartId, idToLineItemWrappers.get(objQuote.Apttus_Proposal__Opportunity__c));
                Apttus_Config2__ProductConfiguration__c objProductConfiguration = new Apttus_Config2__ProductConfiguration__c(
                    Id = cartId,
                    Apttus_Config2__Status__c = 'Saved',
                    OwnerID=objQuote.Owner.Id
                );
                //commented reprice as reprice is already done during validate cart.
                
                //UtilsCart.doReprice(cartId);

                cartIdToQuote.put(cartId, objQuote);
                idToCart.put(objProductConfiguration.Id, objProductConfiguration);
            }

            // update the new carts with some values from the opportunity line items
            applyLineItemValuesToCarts(idToCart, cartIdToQuote, idToLineItemWrappers);
        }
        catch (Exception e)
        {
            ApexExceptions.emit(logTitle, recordIds[0], e); //Koustubh, 2022-01-07 :- INC0369724 - Added record id while logging exception because it's tough to identify the criteria for which the exception occurs
            ilib_LogEvent.push('EXCEPTION');
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ilib_LogEvent.pop();
        }

        ilib_LogEvent.message('Completed successfully');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    * @Description : Map Id to Line item
    * @param: List<Id> listQuotes
    * @return: Map<Id, List<UtilsCart.LineItemWrapper>>
    */
    private static Map<Id, List<UtilsCart.LineItemWrapper>> mapIdToLineItemWrappers(List<Apttus_Proposal__Proposal__c> listQuotes)
    {
        Map<Id, List<UtilsCart.LineItemWrapper>> idToLineItemWrappers = new Map<Id, List<UtilsCart.LineItemWrapper>>();

        // retrieve the line items from parent opportunities
        Set<Id> setOpportunityIds = UtilsCollection.getSetOfIds(listQuotes, 'Apttus_Proposal__Opportunity__c');
        List<OpportunityLineItem> oppLineItems = new OpportunityLineItemsSelector().selectOpportunityLineItems(setOpportunityIds);
        ilib_LogEvent.message('line item count ' + oppLineItems.size());

        // map opportunity ID to wrapped line items
        for (OpportunityLineItem objOpportunityLineItem : oppLineItems)
        {
            if (!idToLineItemWrappers.containsKey(objOpportunityLineItem.OpportunityId))
                idToLineItemWrappers.put(objOpportunityLineItem.OpportunityId, new List<UtilsCart.LineItemWrapper>());

            UtilsCart.LineItemWrapper liWrapper = new UtilsCart.LineItemWrapper(objOpportunityLineItem);
            ilib_LogEvent.message('line item wrapper: ' + liWrapper);
            idToLineItemWrappers.get(objOpportunityLineItem.OpportunityId).add(liWrapper);
        }

        return idToLineItemWrappers;
    }

    /*
    * @Description : Method  applyLineItemValuesToCarts
    * @param: Map<Id,record>
    * @return: void
    */
    private static void applyLineItemValuesToCarts(Map<Id, Apttus_Config2__ProductConfiguration__c> idToCart, Map<Id, Apttus_Proposal__Proposal__c> cartIdToQuote, Map<Id, List<UtilsCart.LineItemWrapper>> idToLineItemWrappers)
    {
        ilib_LogEvent.push('applyLineItemValuesToCarts');

        //DCP-30367 Adding start date, end date to cart line items
        List<Apttus_Config2__LineItem__c> lstUpdateLineItems = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__LineItem__c> lstCartLineItems = new ApttusLineItemsSelector().selectLineItemsByConfigId(cartIdToQuote.keySet());
        Map<Id,List<Apttus_Config2__LineItem__c>> liMap = UtilsCollection.getMapOfIdToSObjects(lstCartLineItems, 'Apttus_Config2__ConfigurationId__c');
        for (Apttus_Config2__ProductConfiguration__c conf : new ApttusProductConfigurationsSelector().selectById(cartIdToQuote.keySet()))
        {
            ilib_LogEvent.message('working on cart ' + conf.Id);
            Integer count = 0;
            for (Apttus_Config2__LineItem__c li : liMap.get(conf.Id))
            {

                //Koustubh, 2022-01-06 :- INC0369724 - Added check to fix bug of 'List index out of bounds'
                List<UtilsCart.LineItemWrapper> liList = new List<UtilsCart.LineItemWrapper>();
                liList = idToLineItemWrappers.get(cartIdToQuote.get(li.Apttus_Config2__ConfigurationId__c).Apttus_Proposal__Opportunity__c);
                if (liList.isEmpty() || liList.size()<=count)
                    continue;

                UtilsCart.LineItemWrapper liWrapper = liList.get(count);

                ilib_LogEvent.message('updating line item ' + li.Id);
                ilib_LogEvent.message('using wrapper ' + liWrapper);

                li.Apttus_Config2__StartDate__c = liWrapper.startDate;
                li.Apttus_Config2__EndDate__c =  liWrapper.endDate;
                li.ERP_Line_Number_Id__c = liWrapper.ERP_Line_Number_Id; //DCP-31767
                li.Serial_Number__c = liWrapper.Serial_Number; //DCP-31767
                li.Registrant_Contact__c= liWrapper.registrantContact;//DCP-56258
                //PRB0043537
                //removed PRB0043537 changes as part of apttus upgrade.

                if (!lstUpdateLineItems.contains(li))
                {
                    ilib_LogEvent.message('updated line ' + li.Apttus_Config2__Quantity__c + ', ' + li.Shipping_In_Close_Quarter__c);
                    lstUpdateLineItems.add(li);  
                }

                count = count + 1;
            }
        }

        ilib_LogEvent.message('updated line count ' + lstUpdateLineItems.size());
		if (!lstUpdateLineItems.isEmpty())
            update lstUpdateLineItems;

        // update re-priced carts
        if (!idToCart.isEmpty())
        {
            ilib_LogEvent.message('updated cart count ' + idToCart.values().size());
            update idToCart.values();

            // share newly-created carts
            TAPSBatches.publish(idToCart.keySet());
        }

        ilib_LogEvent.pop();
    }
    /*
    * @Author:Milan Savaliya
    * @Description : it is dummy method
    * @param: List<Id> recordIds
    * @return: void
    */
    @InvocableMethod(Label='OpportunitySyncToQuoteWithsharing')
    public static void dummyMethod(List<Id> recordIds)
    {
        // need to be removed once the process builders deleted
    }
}