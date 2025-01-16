/**
*    @author        Adyasha Satapathy
*    @date          2020-08-17
*    @description   JS for LWC
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Adyasha Satapathy              17 Aug 2020         DCP-40018, To create a Component with a button which when clicked navigates to a Tableau Dashboard
*             Adyasha Satapathy              04 Sep 2020         DCP-40026, Use of Custom labels to store Tableau URLs,
                                                                 To add a new button which when clicked navigates to another Tableau Dashboard
*------------------------------------------------------------- ------------------------------------------------------------------------------------------------------
*/

import { LightningElement } from 'lwc';
import OpportunityLabel from '@salesforce/label/c.TableauURL_OpportunityDetail';
import DiscountLabel from '@salesforce/label/c.TableauURL_DiscountOverview';
import { NavigationMixin } from 'lightning/navigation';
export default class TableauQuickLinks extends NavigationMixin(LightningElement) {
    navigateToTableauOpportunityDetail() {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": OpportunityLabel
            }
        });
    }
    navigateToTableauDiscountSummary() {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": DiscountLabel
            }
        });
    }
}