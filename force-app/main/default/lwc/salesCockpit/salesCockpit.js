/**
*    @author        Priya Mukherjee
*    @date          2023-07-31
*    @description   JS for LWC
 Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Priya Mukherjee              31 Jul 2023        CMCM-708, To create a Component with two button which when clicked navigates to provided URL
*             
*------------------------------------------------------------- ------------------------------------------------------------------------------------------------------

*    */
import { LightningElement } from 'lwc';
import GlobalSalesCockpit from '@salesforce/label/c.Sales_Cockpit_Global';
import GlobalSalesManagementCockpit from '@salesforce/label/c.Sales_Management_Cockpit_Global';
import { NavigationMixin } from 'lightning/navigation';

export default class SalesCockpit extends NavigationMixin(LightningElement) {
    navigateToSalesCockpitGlobal() {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": GlobalSalesCockpit
            }
        });
    }
    navigateToSalesManagementCockpitGlobal() {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": GlobalSalesManagementCockpit
            }
        });
    }

}