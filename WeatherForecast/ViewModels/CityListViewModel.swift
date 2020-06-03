import Foundation
import Domain

enum CityListViewModelAction: Actionable {
  case isLoading(Bool)
  case itemSelected(CityType)
  case itemsUpdated([CityPresentableModel])
}

protocol CityListViewModelType: BaseViewModelType {
  var filteredItems: [CityPresentableModel] { get }

  func load()
  func select(item: CityPresentableModel)
  func search(by text: String)
}

class CityListViewModel: BaseViewModel, CityListViewModelType {
  let getCitiesUseCase: GetCitiesUseCase
  let converter: CityPresentableModelConverterType

  private var originalItems: [CityType] = []

  private var items: [CityPresentableModel] = [] {
    didSet {
      filteredItems = items
    }
  }

  private(set) var filteredItems: [CityPresentableModel] = [] {
    didSet {
      post(CityListViewModelAction.itemsUpdated(items))
    }
  }

  init(getCitiesUseCase: GetCitiesUseCase,
       converter: CityPresentableModelConverterType = CityPresentableModelConverter()) {
    self.getCitiesUseCase = getCitiesUseCase
    self.converter = converter
  }

  override func postInitialActions() {
    post(CityListViewModelAction.isLoading(false))
  }

  func load() {
    post(CityListViewModelAction.isLoading(true))
    getCitiesUseCase.get { [weak self] result in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.post(CityListViewModelAction.isLoading(false))
        self.originalItems = result.value ?? []
        self.items = self.converter.from(result.value ?? [])
      }
    }
  }

  func select(item: CityPresentableModel) {
    guard let city = originalItems.first(where: { $0.id == item.id }) else { return }
    post(CityListViewModelAction.itemSelected(city))
  }

  func search(by text: String) {
    if text.count > 0 {
      filteredItems = items.filter { $0.name.lowercased().contains(text.lowercased()) }
    } else {
      filteredItems = items
    }
  }
}