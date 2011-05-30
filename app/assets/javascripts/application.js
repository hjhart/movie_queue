// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .


$(document).ready(function() {

    $('input[value="rtfetch"]').click(function(e) {
        e.preventDefault();
        select = $('select[name="movie[name]"]')
        input = $('input[name="movie[name]"]')
        query = input.val()

        $.ajax({
            url: "/movielist.json?q=" + query,
            success: function(data) {
                console.debug("Data:", data)
                select.children().remove()
                selects = ""
                $.each(data, function(index, element) {
                    selects += "<option value=\"" + element + "\">" + element + "</option>"
                })
                console.debug(selects)
                select.html(selects)
                select.removeAttr("disabled")
                input.attr("disabled", "true")
            }
        });
    })
})