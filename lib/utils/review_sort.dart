enum ReviewSort {
  mostRecent('Most Recent'),
  oldest('Oldest'),
  mostLiked('Most Liked'),
  leastLiked('Least Liked');

  final String label;
  const ReviewSort(this.label);
}
