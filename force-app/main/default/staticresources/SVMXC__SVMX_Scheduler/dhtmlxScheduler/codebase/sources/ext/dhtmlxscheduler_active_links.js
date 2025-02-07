/*
dhtmlxScheduler v.4.2.0 Professional

This software is covered by DHTMLX Enterprise License. Usage without proper license is prohibited.

(c) Dinamenta, UAB.
*/
Scheduler.plugin(function(scheduler){

scheduler.config.active_link_view = "day";
scheduler._active_link_click = function(e){
	var start = e.target || event.srcElement;
	var to = start.getAttribute("jump_to");
	var s_d = scheduler.date.str_to_date(scheduler.config.api_date);
	if (to) {
		scheduler.setCurrentView(s_d(to), scheduler.config.active_link_view);
		if (e && e.preventDefault)
			e.preventDefault();
		return false;
	}
};
scheduler.attachEvent("onTemplatesReady", function() {
	var do_wrapper = function(key, fullname){
		fullname = fullname || (key+"_scale_date");

		if(!scheduler.templates['_active_links_old_'+ fullname]){
			scheduler.templates['_active_links_old_'+ fullname] = scheduler.templates[fullname];
		}
		var week_x = scheduler.templates['_active_links_old_'+ fullname];
		var d_s = scheduler.date.date_to_str(scheduler.config.api_date);
		scheduler.templates[fullname] = function(date) {
			return "<a jump_to='" + d_s(date) + "' href='#'>" + week_x(date) + "</a>";
		};
	};

	do_wrapper("week");
	do_wrapper("", "month_day");
	if (this.matrix){
		for (var key in this.matrix)
			do_wrapper(key);
	}

	this._detachDomEvent(this._obj, "click", scheduler._active_link_click);
	dhtmlxEvent(this._obj, "click", scheduler._active_link_click);
});

});