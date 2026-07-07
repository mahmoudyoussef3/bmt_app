/// Sort order for Route Details' available-trips list.
enum TripSort { earliest, priceLow, seatsHigh }

String tripSortLabel(TripSort sort) {
  return switch (sort) {
    TripSort.earliest => 'Earliest departure',
    TripSort.priceLow => 'Lowest price',
    TripSort.seatsHigh => 'Most seats',
  };
}
