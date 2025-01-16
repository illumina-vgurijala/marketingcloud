var j$ = jQuery.noConflict();
var selectedSort = 'Name',
    sortOrder = 'Name',
    searchText = '%%',
    reverse = false,
    selectedAlpha = '';

j$(document).ready(function() {
    setSelectedSort();
    j$('body').on('keyup', '#searchText', function() {
        j$('#alphaMount a').removeClass('selected');
        searchEntities('%' + j$(this).val() + '%', false);
        selectedAlpha = '';
    });
    j$('body').on('click', '.entitySort', function() {
        j$('.entitySort').removeClass('selected');
        j$(this).addClass('selected');
        j$(this).toggleClass('reverse');
    });
    j$('body').on('click', '.entity-tabs li', function() {
        j$('.entity-tabs li').toggleClass('selected');
    });
});
function displaySpinner() {
    j$('.overlay').show();
}

function hideSpinner() {
    j$('.overlay').hide();
}

function searchEntities(searchTextParam, usingAlpha) {
    searchText = searchTextParam;
    searchAF(searchText, sortOrder, usingAlpha);
}

function sortEntities(sortOrderParam) {
    selectedSort = sortOrderParam;
    if (sortOrderParam == sortOrder) {
        reverse = true;
        sortOrder = sortOrderParam + ' DESC';
    } else {
        reverse = false;
        sortOrder = sortOrderParam;
        searchText = '%%';
        selectedAlpha = '';
    }
    j$('.overlay').hide();
    searchAF(searchText, sortOrder, false);
}

function setSelectedSort() {
    j$('.' + selectedSort).closest('th').css('background','#e0e3e6');
    j$('.' + selectedSort).addClass('selected');
    if(reverse) {
        j$('.' + selectedSort).append('<span class="DESC"></span>');
    } else {
        j$('.' + selectedSort).append('<span class="ASC"></span>');
    }
}