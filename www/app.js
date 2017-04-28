(function(win) {
  var doctitle = document.title;
  
  $('li.treeview')
    .addClass('active')
    .find('.treeview-menu')
    .addClass('menu-open');
    
  // ensure tab in the url is loaded on start
  if (location.hash) {
    $('a[data-toggle]').removeAttr('data-start-selected');
    $('a[href="' + location.hash + '"]').attr("data-start-selected", 1);
  }
  
  $('a[data-toggle]').click(function(e) {
    var node = $(this);
    var title = node.text() + ' - ' + doctitle;
    history.pushState(null, title, "./" + node.attr("href"));
  });
})(window);
