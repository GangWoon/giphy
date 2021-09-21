# Giphy

# 디자인 패턴
뷰는 오로지 화면을 렌더링하는 역활을 하고 비즈니스 로직을 한 곳에서 처리하도록 리덕스 패턴을 사용했습니다. <br>
[Redux](https://gangwoon.tistory.com/23) <br>
<img width="924" alt="Screen Shot 2021-09-22 at 4 38 29" src="https://user-images.githubusercontent.com/48466830/134236634-7d3414e7-3798-4235-8c9c-74f66e272389.png">

<img width="924" alt="Screen Shot 2021-09-22 at 4 42 09" src="https://user-images.githubusercontent.com/48466830/134237202-aca07b66-82fe-4bd6-8099-b305109650fb.png">

<img width="924" alt="Screen Shot 2021-09-22 at 4 43 39" src="https://user-images.githubusercontent.com/48466830/134237212-d4171e7d-3db5-4e89-af28-73fa50d3e212.png">


### Action

뷰에서 이벤트가 발생할 때 전달되는 객체입니다.
``` Swift
    enum Action: Equatable {
        case searchBarChanged(String)
        case searchButtonTapped
        case listItemTapped(Int)
        case replaceItems(key: String, data: Data)
        case appendEffect(AnyCancellable?)
    }

```

<br>

### State

View를 꾸미는 상태와 Store에서 사용하는 상태를 뜻합니다. <br>
View.State와 Store.State는 같거나 다를 수 있습니다.
``` Swift
    // MARK: - Store가 관리하는 State
    struct State: Equatable {       
        var query: String
        var items: [Item]
        var effect

    // MARK: - View가 관리하는 State
    func update(with state: [Data]) {
        ...
    }

```

<br>

### Environment
Dependency Container입니다.  <br>
Reducer 내부에서 복잡한 로직을 제거하고, 테스트할 수 있게 만들어주는 객체입니다.(제어권을 갖고 오도록 도와주는 객체)

``` Swift
    struct Environment {
        let scheduler: DispatchQueue
        let presentDetailView: (String, Data) -> Void
        let search: (String) -> AnyPublisher<(String, Data), Never>
    }
```

<br>

### Navigator
화면 전환에 대한 책임을 갖는 객체입니다. 

``` Swift
    struct Navigator {
        
        // MARK: - Navigator에서 사용하는 Dependency라고 생각하면 됩니다.
        struct Container {
            let scheduler: DispatchQueue
            let documentFileManager: DocumentFileManager
        }
        
        private let viewController: UIViewController
        private let container: Container
        
        // MARK: - 화면 전환
        func presentDetailView(id: String, metaData: Data) {
               ...
        }
    }
``` 

<br>

### Reducer


Action과 State를 사용해서 새로운 State를 만들거나 Effect를 발생시키는 역할을 합니다. <br>
Effect란 Reducer 내부에 State를 변경하지 않는 경우를 말합니다. (ex. 비동기적으로 데이터를 받는 상황, 화면 전환) <br>
State는 구조체이기 때문에 클로저 내부에서 값을 변경할 수 없습니다. 이 문제를 해결하기 위해 새로운 Action을 방출하도록 구현합니다.

``` Swift
        func reduce(
            _ action: SearchListViewController.Action,
            state: inout State
        ) -> AnyPublisher<SearchListViewController.Action, Never>? {
            switch action {
            // MARK: - Effect가 발생합니다.
            case .searchButtonTapped:
                ...
                return environment.search(state.query)
                    .map { SearchListViewController.Action.replaceItems($0) }
                    .eraseToAnyPublisher()
                    
            // MARK: - Effect가 발생하지 않습니다.
            case let .replaceItems(items):
                state.items.append(items)
            }
            
            return nil
        }

```

<br>

### Store

위 네 가지를 보유하며, Viwe와 직접적으로 통신하는 객체입니다. <br>

``` Swift
final class SearchListViewStore {
    private var reducer: Reducer
    var updateView: (([Data]) -> Void)? // MARK: - View로 State 전달
    @Published private var state: State
    private let environment: Environment
}


``` 

<br>
<br>
<br>

# 고민한 점
## 비동기 방식으로 UI 업데이트 (스트림 분리)

URL -> Data -> UIImage 일련 변경하는 과정을 동기적으로 처리하게 되면, UI가 멈춰있는 현상을 발견했습니다. <br>
아래 사진처럼 URL 배열을 서버로부터 받게 되면, URL -> Data -> UIImage 작업을 비동기적으로 처리해서 최종적으론 UIImage를 뷰에 비동기적으로 반영되도록 구현했습니다.<br>
스트림을 분리하면서 SearchListViewController에 있는 비즈니스 로직 전부를 제거할 수 있었습니다.
<img width="1031" alt="Screen Shot 2021-09-20 at 17 45 02" src="https://user-images.githubusercontent.com/48466830/133976636-3e0270ef-bc8e-4d1d-826c-a12c3b02bc27.png"> 

### 수정전 코드
``` Swift
        return urlSession.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GIPHYData.self, decoder: decoder)
            .map(\.urls)
            .replaceError(with: [])

```

### 수정한 코드
``` Swift
    func fetchItems(query: String) -> AnyPublisher<UIImage?, Never> {
        ...
        return urlSession.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GIPHYData.self, decoder: decoder)
            .map(\.urls)
            .flatMap { items in
                return items.publisher
                    .flatMap { url in
                        // MARK: - 비동기적으로 데이터 전달
                        return urlSession.dataTaskPublisher(for: url)
                            .map { (url.absoluteString, $0.data) }
                            .replaceError(with: ("", Data()))
                    }
            }
            .replaceError(with: ("", Data()))
            .eraseToAnyPublisher()
    }

```

<br>
<br>

## Fire and Forget Effect <br>
Server API를 호출할 때마다 Effect가 저장되고 지워지지 않는 심각한 버그를 발견했습니다.(스트림을 분리하면서 발생한 Side Effect입니다.) <br>
디버깅 결과 Effect가 발생할 때 마다 저장되는 걸 확인 후 Effect를 사용하고 제거하도록 수정했습니다.
<img width="490" alt="Screen Shot 2021-09-20 at 23 09 47" src="https://user-images.githubusercontent.com/48466830/134016956-ff0cbd33-5ab1-4860-a0de-52a5344e81cd.png">

### 수정전 코드
``` Swift
    private func fireEffectAndForget(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        effect
            .sink { self.reducer.reduce($0, state: &self.state) }
            .store(in: &cancellables)
    }
```

### 수정한 코드
``` Swift
    private func fireEffectAndForget(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        var cancellable: AnyCancellable?
        cancellable = effect
            .sink(receiveCompletion: { result in
                guard case .finished = result,
                      let cancellable = cancellable else { return }
                // MARK: - Forget Effect
                self.cancellables.remove(cancellable)
            }, receiveValue: { action in
                // MARK: - Fire Effect
                self.reducer.reduce(action, state: &self.state)
            })
        cancellable?
            .store(in: &cancellables)
    }
```

<br>
<br>

## 유효하지 않은 Effect 취소
중첩적인 API 요청을 할 때 이전 요청들은 의미가 없는 데이터를 요청하며 사용자에게 혼란스러운 UX를 제공합니다. <br>
해당 문제를 해결하기 위해서 Effect를 관리하도록 수정했습니다.

### 수정전 코드
``` Swift
    private func fireEffectAndForget(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        var cancellable: AnyCancellable?
        cancellable = effect
            .sink(receiveCompletion: { result in
                guard case .finished = result,
                      let cancellable = cancellable else { return }
                self.cancellables.remove(cancellable)
            }, receiveValue: { action in
                self.reducer.reduce(action, state: &self.state)
            })
        cancellable?
            .store(in: &cancellables)
    }
```

### 수정한 코드
``` Swift
    private func fireEffectAndForget(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        var cancellable: AnyCancellable?
        cancellable = effect
            .sink(receiveCompletion: { result in
                guard case .finished = result,
                      let cancellable = cancellable else { return }
                self.cancellables.remove(cancellable)
            }, receiveValue: { action in
                self.reducer.reduce(action, state: &self.state)
            })
        // MARK: - Handle Effects
        reducer.reduce(.appendEffect(cancellable), state: &state)
        cancellable?
            .store(in: &cancellables)
    }
```

<br>
<br>

## File IO 시점 변경
DetailViewController에서 즐겨찾기 버튼을 눌렀을 때마다 File IO가 발생하고 있었습니다.
빈번한 File IO를 제거하고자, 버튼이 눌릴 때마다 발생하던 작업을 앱 생명주기에 적절한 시점으로 변경했습니다.

### 수정전 코드
``` Swift
        func presentDetailView(id: String, metaData: Data) {
            ...
            let environment = DetailViewStore.Environment(scheduler: container.scheduler) { [weak manager] in
                return manager?.readFavorites(id) ?? false
            } toggleFavorites: { [weak manager] in
                manager?.updateFavorites(id, value: $0)
                // MARK: - File IO
                manager?.updateDocuments()
            }
```

### 수정한 코드
``` Swift
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ...
        // MARK: - 앱이 실행되고 나서 파일로부터 데이터를 읽어옴
        documentFileManager.readDocuments()

    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // MARK: - 앱이 종료되기 전 안전한 시점에서 데이터를 갱신함.
        documentFileManager.updateDocuments()
    }    
```


<br>
<br>

## 메모리 누수 제거
Store와 ViewController 관계로부터 발생할 수 있는 메모리 누수를 제거했습니다. <br>
Closure Capture List에서 발생하는 메모리 누수를 신경 썼습니다.
### 코드

``` Swift
        store.updateView = { [weak searchListViewController] items in
            searchListViewController?.update(with: items)
        }
```

<br>
<br>

## No Protocol
DI를 하는 과정에서 프로토콜을 사용해서 추상화시키지 않았습니다. 다수의 프로토콜은 읽는 사람이 이해하기 어려운 코드를 작성한다고 생각했습니다. <br>
모든 구체 타입을 각 객체가 갖고 있는 게 아닌, 클로져 주입을 통한 인터페이스 분리 및 추상화를 구현했습니다.

``` Swift
    struct Environment {
        let scheduler: DispatchQueue
        let presentDetailView: (String, Data) -> Void
        let search: (String) -> AnyPublisher<(String, Data), Never>
    }
```


<br>
<br>
<br>

# 추가로 구현하고 싶었던 스펙
## List Item 순서 보장
스트림 분리로 인해서 Data를 URL 배열 순서대로 받는 게 아닌, 다운받는 순서대로 UI가 그려지고 있습니다. <br>
이를 해결할 방법은 스트림 분리과정에서 URL 배열의 인덱스를 같이 넘기는 겁니다. 해당 인덱스로 뷰를 업데이트하는 방식을 구현하게 되면 URL 배열 순서대로 업데이트시킬 수 있습니다.
해당 과정에서 Out Of Bounds가 발생할 수 있는데, 이 문제는 빈값을 넘기고 값이 도착했을 때 정상적인 값을 변경하면서 다시 셀을 업데이트시키는 방식으로 해결할 수 있을 겁니다.

<br>
<br>

## DocumentFileManager 제어권 분리
Reducer와 달리 테스트하기가 어려웠습니다. <br> 
근본적인 문제점은 제어권을 쉽게 가져올 수 없는 환경이어서, 테스트 환경을 직접 맞춰야 했기 때문에 그렇게 느꼈던 거 같습니다. <br>
이 문제점을 해결하려면 제어권을 개발자에게 가져와야 한다는 생각이 들었습니다.


<br>
<br>
<br>

# Test Code

<img width="267" alt="Screen Shot 2021-09-22 at 4 18 19" src="https://user-images.githubusercontent.com/48466830/134233975-b161e38a-75cc-47b8-8e00-e89ba3171552.png">

## Reducer Test Coverage 100%
SearchListViewController와 DetailViewController에서 각각 사용하는 Reducer 내부 로직은 전부 제어 가능하도록 구현했습니다.

<br>
<br>

# 화면 구성
## 설계
### SearchListViewController
<img width="700" alt="Screen Shot 2021-09-20 at 17 21 10" src="https://user-images.githubusercontent.com/48466830/133974854-33efc703-b927-45f0-8e56-0e3dc41daf57.png">

### DetailViewController
<img width="700" alt="Screen Shot 2021-09-20 at 23 58 59" src="https://user-images.githubusercontent.com/48466830/134222332-b249d3f5-af85-4264-a038-d132503c2e95.png">

<br>
<br>

## 구현 화면
### SearchListViewController, DetailViewController
<img width="400" alt="Screen Shot - iPhone 12 mini - 2021-09-20" src="https://user-images.githubusercontent.com/48466830/133974995-03a1ad3a-c22d-4f32-ab6c-a79172593165.png"> <img width="400" alt="Screen Shot - iPhone 12 mini - 2021-09-20" src= "https://user-images.githubusercontent.com/48466830/134222430-844d0ad8-e19f-4e47-8adb-1cccc90a2ad3.png">

<br>
<br>

## Snapshot Test
### SearchListViewController, DetailViewController
<img width="400" alt="Screen Shot - iPhone 12 mini - 2021-09-20" src="https://user-images.githubusercontent.com/48466830/134222516-12dd9347-84f2-4941-8f2e-6e752bd0dd21.png"> <img width="400" alt="Screen Shot - iPhone 12 mini - 2021-09-20" src="https://user-images.githubusercontent.com/48466830/134222577-eeac0637-d2ed-4c11-af85-0a4a6af11488.png">
