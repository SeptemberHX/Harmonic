/**
 * A generic data source for ArkUI's LazyForEach component.
 * Requires the data type T to have an 'id' property (string or number).
 */
export class GenericLazyDataSource<T> implements IDataSource {
  private items: T[] = []; // Internal storage for items of type T
  private listeners: DataChangeListener[] = []; // Listeners registered by LazyForEach

  constructor(initialData: T[] = []) {
    this.items = initialData;
  }

  /**
   * Updates the data source with a new array of items and notifies listeners.
   * @param newData The new array of data items.
   */
  public updateData(newData: T[]): void {
    this.items = newData;
    this.notifyDataReload(); // Notify LazyForEach about the data change
    console.log(`GenericLazyDataSource updated with ${this.items.length} items.`);
  }

  /**
   * Returns the total number of items in the data source.
   * Required by IDataSource.
   */
  totalCount(): number {
    return this.items.length;
  }

  /**
   * Returns the data item at the specified index.
   * Returns null if the index is out of bounds.
   * Required by IDataSource.
   * @param index The index of the item to retrieve.
   */
  getData(index: number): T | null {
    if (index < 0 || index >= this.items.length) {
      console.error(`DataSource: Index ${index} out of bounds.`);
      return null;
    }
    return this.items[index];
  }

  // --- Listener Management (Required by IDataSource) ---

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  // --- Notification Method ---

  /**
   * Notifies all registered listeners that the entire dataset needs to be reloaded.
   * Call this after updating the internal 'items' array.
   */
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      try {
        listener.onDataReloaded();
      } catch(error) {
        console.error("Error notifying listener:", error);
      }
    });
  }

  // Optional: Implement notifyDataAdd, notifyDataDelete, notifyDataChange for finer-grained updates
  // Example:
  // notifyDataAdded(index: number): void {
  //   this.listeners.forEach(listener => listener.onDataAdded(index));
  // }
}