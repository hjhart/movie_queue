// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require_tree .


$(document).ready(function() {
//function(request, response) {
//            console.debug("Request term", request.term)
//            console.debug("Response", response)
//
//            $.ajax({
//                url: "/movielist.json",
//                dataType: "jsonp",
//                data: {
//                    q: request.term
//                },
//                success: function(data) {
//                    console.debug(data)
//                    response($.each(data);
//                }
//            });
//        }
    $("input[id=movie_adder]").autocomplete({
//        source: ["shrek 1", "shrek 2", "shrek 3"],
        source: "/movielist.json" + $("input[id=movie_adder]").val(),
//        source: "/movielist.json?q=shrek",
        minLength: 2,
//        select: function(event, ui) {
//            console.debug(ui.item ?
//                    "Selected: " + ui.item.label :
//                    "Nothing selected, input was " + this.value);
//        },
        open: function() {
            console.debug($(this).val())
        }
//        close: function() {
//            $(this).removeClass("ui-corner-top").addClass("ui-corner-all");
//        }
    });

    $('input[value="rtfetch"]').click(function(e) {
        e.preventDefault();
        select = $('select[name="movie[name]"]')
        input = $('input[name="movie[search_term]"]')
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
            }
        });
    })
})