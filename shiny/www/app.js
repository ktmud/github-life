(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
  
ga('create', 'UA-1080811-21', 'auto');
ga('send', 'pageview');

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
