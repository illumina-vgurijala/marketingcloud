/**
 * Pagination.js
 * This JS file handles all the functions relation to the pagination of the matrix Entries.
 */
var itemsPerPage = 10;
var items = j$(".section tbody tr");
var currentPage = 1;


j$(document).ready(function () {

    itemsPerPage = parseInt(j$(".itemsPerPage").val());
    currentPage = parseInt(j$("#pageNumber").val());

    j$("body").off("click", "#prevPagination");
    j$("body").on("click", "#prevPagination", function (event) {
        var pageNumber = currentPage <= 1 ? 1 : currentPage - 1;
        changePage(pageNumber);
    });

    j$("body").off("click", "#nextPagination");
    j$("body").on("click", "#nextPagination", function (event) {
        var maxPages = Math.ceil(j$(".section tbody tr").size() / itemsPerPage) <= 0 ? 1 : Math.ceil(j$(".section tbody tr").size() / itemsPerPage);
        var pageNumber = currentPage >= maxPages ? maxPages : currentPage + 1;
        changePage(pageNumber);
    });

    j$("body").off("change", "#pageNumber");
    j$("body").on("change", "#pageNumber", function (event) {

        var pageNumber = parseInt(j$(this).val());
        if(!pageNumber || isNaN(pageNumber) || pageNumber <= 0){
            pageNumber = 1;
        }
        changePage(pageNumber);
    });

    j$("body").off("change", ".itemsPerPage");
    j$("body").on("change", ".itemsPerPage", function (event) {

        itemsPerPage = parseInt(j$(this).val());
        changePage(currentPage);
    });

    updatePage();



});


function updatePage() {
    changePage(currentPage);
}

function changePage(pageNumber) {

    // someone changed page, lets hide/show trs appropriately
    var maxPages = Math.ceil(j$(".matrixEntryRow").size() / itemsPerPage);
    maxPages = maxPages <= 0 ? 1 : maxPages;
    currentPage = pageNumber > maxPages ? maxPages : pageNumber;

    // set page number if current page number greater than max page number
    j$("#pageNumber").val(currentPage + "/" + maxPages);

    var showFrom = itemsPerPage * (currentPage - 1);
    var showTo = showFrom + itemsPerPage;
    j$(".matrixEntryRow").hide() // first hide everything, then show for the new page
             .slice(showFrom, showTo).show();

    // enable disable next prev
    if(currentPage == 1){
        j$("#prevPagination").addClass("disabled");
    } else {
        j$("#prevPagination").removeClass("disabled");
    }
    if(maxPages == currentPage){
        j$("#nextPagination").addClass("disabled");
    } else {
        j$("#nextPagination").removeClass("disabled");
    }
}