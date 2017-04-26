{
  option: function(item, escape) {
    return '<div>' +
    '<span class="title">' +
    '<span class="name"><i class="icon source"></i>' + escape(item.name) + '</span>' +
    '<span class="by">' + escape(item.owner_login) + '</span>' +
    '</span>' +
    '<span class="description">' + escape(item.description) + '</span>' +
    '<ul class="meta">' +
      (item.lang ? '<li class="language">' + escape(item.lang) + '</li>' : '') +
    '<li class="stars"><span>' + escape(item.stars) + '</span> stars</li>' +
    '<li class="forks"><span>' + escape(item.forks) + '</span> forks</li>' +
    '</ul>' +
    '</div>';
  }
}