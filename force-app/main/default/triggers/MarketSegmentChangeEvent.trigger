/**
*    @author: Deep Diwakar
*    @date:   Dec-21-2023
*    @description:  MarketSegmentChangeEvent platform event trigger
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Deep Diwakar                  Dec-21-2023      CMCM-4697: After insert event trigger
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger MarketSegmentChangeEvent on MarketSegmentChangeEvent__e (after insert) {
    ilib_SObjectDomain.triggerHandler(MarketSegmentChangeEvents.class);
}