({
    doInit : function(cmp, evt, helper) {

    },

    onPageReferenceChange: function(cmp, evt, helper) {
        cmp.set("v.displayForm", true);

        const currentPageContext = cmp.get("v.pageReference");
        console.log('currentPageContext-->>'+ JSON.stringify(currentPageContext));

        if(currentPageContext) {

            if(currentPageContext.attributes.actionName === 'edit') {
                cmp.set("v.recordId", currentPageContext.attributes.recordId);
            }

            const previousPageContext = helper.decodeAddressContext(currentPageContext);

            if(previousPageContext){
                cmp.set("v.parentId", previousPageContext.attributes.recordId);
                if('Competitive_Complementary_Technology__c' !== previousPageContext.attributes.objectApiName)
                    cmp.set("v.parentObjectName", previousPageContext.attributes.objectApiName);
            }

            // TODO: find out a way to figure out why new button is opened as modal, by now we identify by ICPP site. I'll be done on Phase 2
            if(window.location) {

                const path = window.location.pathname.split('/');
                if('ICPP' === path[1]) {
                    cmp.set("v.openOnICPP", true);
                    cmp.set("v.isShow", true);
                }
            }
        } else {
            //it comes from global action.
            cmp.set("v.isRecordtypeScreen", true);
            cmp.set("v.isGlobalAction", true);
            cmp.set("v.isShow", true);
        }

    },

    handleSaveSuccess: function(cmp, evt, helper) {
        const recordId = evt.getParam('recordId');
        const parentId = evt.getParam('parentId');
        const parentObjectName = evt.getParam('parentObjectName');

        const isOpenOnICPP = cmp.get("v.openOnICPP");
        const isGlobalAction = cmp.get("v.isGlobalAction");

        if(isGlobalAction) {
            $A.get("e.force:closeQuickAction").fire();
            helper.navigateToRecord(cmp, recordId);
        } else if(isOpenOnICPP || helper.isFromParentDetailPage(cmp)) {
            helper.closeSubTab(cmp);
            helper.navigateToCCTViewList(cmp, parentId, parentObjectName);
        } else {
            helper.closeSubTab(cmp);
            helper.navigatePreviousPage(cmp);
        }

        if(helper.isFromParentDetailPage(cmp)) { // it's from related table view list. Refresh to see new record.
            helper.delayedRefresh();
        }

        cmp.set("v.displayForm", false);
    },

    handleCancelButton: function(cmp, evt, helper) {
        $A.get("e.force:closeQuickAction").fire();

        const isOpenOnICPP = cmp.get("v.openOnICPP");
        const isGlobalAction = cmp.get("v.isGlobalAction");

        if(!isOpenOnICPP && !isGlobalAction) {
            //history.back();
            helper.closeSubTab(cmp);
            helper.navigatePreviousPage(cmp);
        }

        cmp.set("v.displayForm", false); // Start by destroying the lwc.
        cmp.set("v.displayForm", true); // Next re-add lwc.
    },

})