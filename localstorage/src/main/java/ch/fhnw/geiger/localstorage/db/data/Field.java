package ch.fhnw.geiger.localstorage.db.data;

import ch.fhnw.geiger.localstorage.SearchCriteria;

/**
 * <p>Field reflects the available ordinals in a node.</p>
 */
public enum Field {
  OWNER(1, SearchCriteria.ComparatorType.STRING),
  NAME(2, SearchCriteria.ComparatorType.STRING),
  PATH(3, SearchCriteria.ComparatorType.STRING),
  KEY(4, SearchCriteria.ComparatorType.STRING),
  VALUE(5, SearchCriteria.ComparatorType.STRING),
  TYPE(6, SearchCriteria.ComparatorType.STRING),
  VISIBILITY(7, SearchCriteria.ComparatorType.STRING),
  LAST_MODIFIED(8, SearchCriteria.ComparatorType.DATETIME);

  private final SearchCriteria.ComparatorType comparator;
  private final int id;

  Field(int id, SearchCriteria.ComparatorType comparator) {
    this.comparator = comparator;
    this.id = id;
  }

  public SearchCriteria.ComparatorType getComparator() {
    return comparator;
  }

  public int getId() {
    return id;
  }

}
