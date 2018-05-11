function get_search_response() {
    var params = $('#search-page-form').serialize();
    $.get('/search.ajax?' + params, function (data) {
        render_template(data);
    });
}

function render_template(data) {
    console.log(data);
    var template = $('#template').html();
    var rendered = Mustache.render(template, data);
    $('#results').html(rendered);
    $('html,body').animate({ scrollTop: 0 }, 300);
}

function reset_page() {
    $('input#request-page').val(1);
}

$('#search-page-form').submit(function(event) {
    event.preventDefault();
    reset_page();
    get_search_response();
});

$(document).on('change', '.xapian-filter', function(event) {
    reset_page();
    get_search_response();
});

$(document).on('click', '.search-page', function(event) {
    event.preventDefault();
    var page = $(this).data('page');
    if (page) {
        $('input#request-page').val(page);
        get_search_response();
    }
});

$(document).on('click', '#reset-filters', function(event) {
    $('.xapian-filter-checkbox').prop('checked', false);
    reset_page();
    get_search_response();
});
