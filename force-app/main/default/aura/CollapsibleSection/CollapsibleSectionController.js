({
    handleSectionHeaderClick : function(component, event, helper) {
        let button = event.getSource();
        button.set('v.state', !button.get('v.state'));

        let sectionContainer = component.find('collapsibleSectionContainer');
        $A.util.toggleClass(sectionContainer, "slds-is-open");
    }
})