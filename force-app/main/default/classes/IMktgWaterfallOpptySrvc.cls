/**
 *   @author: Deep Diwakar
*    @date:   Aug-10-2023
*    @description: Interface for Marketing waterfall service
*    @Test Class: TestProcessContactsOnOpportunityClose
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Aug-10-2023        DCP-60131: Initial version
*    --------------------------------------------------------------------------------------------------
 */

 public interface IMktgWaterfallOpptySrvc {

    void executeWaterfallOpptyLogic(Set<Id> setContactIds);

}