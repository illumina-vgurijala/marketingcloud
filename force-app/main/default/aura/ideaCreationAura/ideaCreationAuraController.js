({
	handleRecordNavigation : function(component, event, helper) {
		let workspaceAPI = component.find("workspace");
		let ideaId = event.getParam('ideaId');
		let closeTabId = workspaceAPI.getEnclosingTabId();

		workspaceAPI.isConsoleNavigation().then((response) => {
			if (response) {
				workspaceAPI.openTab({
					recordId: ideaId,
					focus: true
				}).then(() => {
					workspaceAPI.closeTab({
						tabId: closeTabId
					});
				}).catch((error) => {
					component.find("child-lwc").handleNavigationError(error);
				});
			} else {
				component.find("child-lwc").navigateToCreatedIdea(ideaId);
			}
		})
	}
})