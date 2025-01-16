/*
 * jQuery UI ColumnView by Apttus 0.0.1
 *
 * Depends:
 *   jquery.ui.core.js
 *   jquery.ui.widget.js
 */
(function ($, undefined) {

  $.widget('apttus.columnview', {
    version: '0.0.1',
    classes: 'ui-columnview clear',
    options: {
      columns: 0,
      subMenuClass: '',
      getData: function () {
        alert('You must override the getData(parentId) method. See the documentation.');
        return false;
      }
    },

    _create: function () {
      var
        el = this.element;

      el.empty();
      el.addClass(this.classes)
        .attr({
          role: 'columnview'
        });

      this._on({
        'click .columnview-li': this._itemSelected
      });
	   
      var rootObjects = getData();
      this._addColumn(rootObjects);
      
    },

    _destroy: function () {
      this.element
        .removeClass(this.classes)
        .removeAttr('role')
        .text('');
    },

    _addColumn: function (data) {
      var
        column,
        that = this;
      if (data !== undefined) {
        if (typeof data === 'string') {
          column = $('<ul class="columnview">');
          $('<li>')
              .addClass('columnview-li')
              .append(data)
              .appendTo(column);
        } else if(data.length > 0){
            column = $('<ul class="columnview">');
            $.each(data, function (index, value) {
              $('<li>')
                .addClass('columnview-li')
                .data('identifier', value.identifier)
                .append('&nbsp;&nbsp;'+value.display)
                .append(value.hasSubMenu ? $('<span>').addClass(that.options.subMenuClass) : '')
                .appendTo(column)
                .addClass(value.hasSubMenu ? 'apt-nonleaf-node' : 'apt-leaf-node');
            });
        }

        if(column){
          column.appendTo(this.element);

          this._setOptions({ 'columns': this.element.find('.columnview').length });
          this._trigger('change', null, { columns: this.options.columns });
        }
      }
    },

    _itemSelected: function (event) {
      var
        selected = $(event.currentTarget),
        currentColumn = selected.parent('ul'),
        selectedItemId = selected.data('identifier');

      currentColumn.find('li').removeClass('ui-state-active');
      selected.addClass('ui-state-active');
      currentColumn.nextAll().remove();
      this._addColumn(getData(selectedItemId));
      if(selected.hasClass('apt-nonleaf-node')){
        event.stopPropagation();
      }
    }
  });

})(jQuery);