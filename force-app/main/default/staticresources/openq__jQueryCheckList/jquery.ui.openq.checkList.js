(function($) {
	$.widget("ui.checkList", {	
		options: {
			listItems : [],
			selectedItems: [],
			effect: 'blink',
			onChange: {},
			objTable: '',
			icount: 0
		},
		
		_create: function() {
			var self = this, o = self.options, el = self.element;

			// generate outer div
			var container = $('<div/>').addClass('checkList');

			// generate toolbar
			var toolbar = $('<div/>').addClass('cl_toolbar');
			var chkAll = $('<input/>').attr('type','checkbox').addClass('chkAll').click(function(){
				var state = $(this).prop('checked');
				o.objTable.find('.chk:visible').prop('checked', state);
				self._selChange();

			});
			var txtfilter = $('<input/>').attr('type','text').addClass('cl_txtFilter').keyup(function(){
				self._filter($(this).val());
			});
			toolbar.append(chkAll);
			toolbar.append($('<div/>').addClass('cl_filterBox').text('filter').append(txtfilter));

			// generate list table object
			o.objTable = $('<table/>').addClass('cl_table');
			
			container.append(toolbar);
			container.append(o.objTable);
			el.append(container);

			self.loadList();
		},

		_addItem: function(listItem){
			var self = this, o = self.options, el = self.element;

			var itemId = 'itm' + (o.icount++);	// generate item id
			var itm = $('<tr/>');
			var chk = $('<input/>').attr('type','checkbox').attr('id',itemId)
					.addClass('chk')
					.attr('data-text',listItem.text)
					.attr('data-value',listItem.value)
					.prop('checked', true)
					.click(function(){
						var state = $(this).prop('checked');
						if(!state){
							$('.chkAll').prop('checked', false);
						}
					});
			
			itm.append($('<td/>').append(chk));
			var label = $('<label/>').attr('for',itemId).text(listItem.text);
			itm.append($('<td/>').append(label));
			o.objTable.append(itm);

			// bind selection-change
			el.delegate('.chk','click', function(){self._selChange()});
		},

		loadList: function(){
			var self = this, o = self.options, el = self.element;

			o.objTable.empty();
			$.each(o.listItems,function(){
				self._addItem(this);
			});
		},

		_selChange: function(){
			var self = this, o = self.options, el = self.element;

			// empty selection
			o.selectedItems = [];

			// scan elements, find checked ones
			o.objTable.find('.chk').each(function(){	
				if($(this).prop('checked')){
					o.selectedItems.push({
						text: $(this).attr('data-text'),
						value: $(this).attr('data-value')
					});
					$(this).parent().addClass('cl_highlight').siblings().addClass('cl_highlight');
				}else{
					$(this).parent().removeClass('cl_highlight').siblings().removeClass('cl_highlight');
				}
			});

			// fire onChange event
			o.onChange.call();
		},

		_filter: function(filter){
			var self = this, o = self.options, el = self.element;

			o.objTable.find('.chk').each(function(){	
				if($(this).attr('data-text').toLowerCase().indexOf(filter.toLowerCase())>-1)
				{
					$(this).parent().parent().show(o.effect);
				}
				else{
					$(this).parent().parent().hide(o.effect);
				}
			});
		},

		getSelection: function(){
			var self = this, o = self.options, el = self.element;
			return o.selectedItems;
		},

		setData: function(dataModel){
			var self = this, o = self.options, el = self.element;
			o.listItems = dataModel;
			self.loadList();
			self._selChange();
		}
	});
})(jQuery); 